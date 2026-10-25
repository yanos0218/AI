#!/usr/bin/env python3
"""실시간 세션 현황 서버(Issue #213 초안).

`claude agents --json`(공식 인터페이스, 활성 세션을 JSON으로 주고 끝남)을 몇 초마다 읽어 세션별 상태를 추적하고,
127.0.0.1에만 묶은 작은 웹 서버로 live.html과 /api/state를 준다. 파이썬 표준 라이브러리만 쓴다.

서브에이전트는 `claude agents --json`에 없어서 ${CLAUDE_CONFIG_DIR:-~/.claude}/projects/<프로젝트>/<세션 ID>/subagents/ 아래
agent-<ID>.meta.json(종류·작업 제목·finished)과 agent-<ID>.jsonl(첫 줄의 시작 시각, 파일 수정 시각 = 마지막 활동)에서 읽는다.
이 파일 형식은 문서화되어 있지 않아 Claude Code가 바꾸면 깨질 수 있다. 읽기 전용이고 기록 파일은 첫 줄 외에는 열지 않는다.

- 대화 내용과 전체 경로는 읽지도 보여 주지도 않는다(이름·폴더 이름·종류·작업 제목·상태·시각만).
토큰 사용량은 usage-dashboard가 남기는 `<설정 폴더>/usage-log/hourly.json` 집계를 읽어 쓴다(토큰을 다시 계산하지 않는다, 그 집계는
응답이 여러 줄로 기록될 때 생기는 중복을 이미 보정한다). 같은 서버가 기존 사용량 화면을 /usage/ 아래로 그대로 보여 준다.

- 환경변수: LIVE_PORT(기본 8766), LIVE_POLL_SEC(기본 2), CLAUDE_BIN(claude 실행 파일 경로),
  LIVE_CLAUDE_DIR(설정 폴더, 시험용), LIVE_SHOW_TITLES(0이면 서브에이전트 작업 제목을 숨김),
  LIVE_SHOW_USAGE(0이면 토큰 요약과 /usage/를 끔, 사용량 화면에는 요청 내용 일부가 들어 있음).
"""
import calendar
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
try:
    from http.server import ThreadingHTTPServer      # 파이썬 3.7부터
except ImportError:                                  # Rocky Linux 8의 3.6.8 대응(docs/testing.md "세 OS에서 도는 스크립트 쓰기")
    from socketserver import ThreadingMixIn

    class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
        daemon_threads = True

PORT = int(os.environ.get('LIVE_PORT', '8766'))
POLL_SEC = float(os.environ.get('LIVE_POLL_SEC', '2'))
KEEP_ENDED_SEC = 15 * 60          # 사라진 세션을 "끝남"으로 화면에 남겨 두는 시간
MISSING_POLLS = 3                 # 연속으로 이만큼 안 보여야 끝난 것으로 본다(일시적으로 목록이 비어도 깜박이지 않게)
WINDOW_SEC = 30 * 60              # 서브에이전트를 이 시간 안에 활동한 것만 보여 준다(타임라인 길이)
FRESH_SEC = 90                    # 마지막 활동이 이 안이면 작업 중
END_ESTIMATE_SEC = 10 * 60        # 이보다 오래 활동이 없으면 끝남(추정). 그 사이는 조용함(도구를 오래 실행하는 중일 수 있어 멈춤이라 단정하지 않음)
GONE_END_SEC = 60                 # 부모 세션이 사라졌으면 이 시간 이상 조용한 서브에이전트는 끝남(추정)
SHOW_TITLES = os.environ.get('LIVE_SHOW_TITLES', '1') != '0'
SHOW_USAGE = os.environ.get('LIVE_SHOW_USAGE', '1') != '0'
USAGE_FILES = {'': 'dashboard.html', 'dashboard.html': 'dashboard.html', 'details.js': 'details.js'}   # /usage/ 아래로 내보낼 파일(이 둘만)
HERE = os.path.dirname(os.path.abspath(__file__))


def utf8_stdio():
    """Windows 파이프(cp1252)에서 한글 출력이 죽지 않게 한다. 파이썬 3.6에는 reconfigure가 없다."""
    import io
    for name in ('stdout', 'stderr'):
        stream = getattr(sys, name)
        if hasattr(stream, 'reconfigure'):
            stream.reconfigure(encoding='utf-8', errors='replace')
        elif hasattr(stream, 'buffer'):
            setattr(sys, name, io.TextIOWrapper(stream.buffer, encoding='utf-8', errors='replace', line_buffering=True))


_ISO = re.compile(r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?Z$')


def iso_to_ms(text):
    """2026-10-24T12:08:50.361Z 형식을 밀리초로. 파이썬 3.6에는 fromisoformat이 없어 직접 읽는다. 못 읽으면 None."""
    m = _ISO.match(text or '')
    if not m:
        return None
    y, mo, d, h, mi, s, frac = m.groups()
    base = calendar.timegm((int(y), int(mo), int(d), int(h), int(mi), int(s), 0, 0, 0))
    return base * 1000 + int((frac or '0')[:3].ljust(3, '0'))


def claude_dir():
    return os.environ.get('LIVE_CLAUDE_DIR') or os.environ.get('CLAUDE_CONFIG_DIR') or os.path.join(os.path.expanduser('~'), '.claude')


_FIRST_TS = {}      # 기록 파일 경로 -> 첫 줄의 시작 시각(바뀌지 않으므로 한 번만 읽는다)


def first_timestamp_ms(path):
    if path in _FIRST_TS:
        return _FIRST_TS[path]
    ms = None
    try:
        with open(path, 'rb') as f:
            line = f.readline(65536)         # 첫 줄만 읽는다. 기록은 통째로 읽지 않는다(수 MB가 될 수 있음)
        ms = iso_to_ms(json.loads(line.decode('utf-8', errors='replace')).get('timestamp'))
    except (OSError, ValueError, AttributeError):
        ms = None
    if ms is not None:
        _FIRST_TS[path] = ms
    return ms


def scan_subagents(now_ms):
    """최근 WINDOW_SEC 안에 활동한 서브에이전트를 (목록, 읽지 못한 개수)로 돌려준다. 모든 오류는 삼키고 개수로만 알린다."""
    root = os.path.join(claude_dir(), 'projects')
    out, unreadable = [], 0
    try:
        projects = list(os.scandir(root))
    except OSError:
        return out, 0
    for proj in projects:
        try:
            sessions = list(os.scandir(proj.path)) if proj.is_dir() else []
        except OSError:
            continue
        for sess in sessions:
            sub = os.path.join(sess.path, 'subagents')
            try:
                names = os.listdir(sub) if sess.is_dir() else []
            except OSError:
                continue
            for name in names:
                if not (name.startswith('agent-') and name.endswith('.meta.json')):
                    continue
                aid = name[len('agent-'):-len('.meta.json')]
                meta_path = os.path.join(sub, name)
                log_path = os.path.join(sub, 'agent-%s.jsonl' % aid)
                try:
                    last_ms = int(os.path.getmtime(log_path) * 1000)
                except OSError:
                    try:
                        last_ms = int(os.path.getmtime(meta_path) * 1000)
                    except OSError:
                        continue
                if now_ms - last_ms > WINDOW_SEC * 1000:
                    continue
                try:
                    with open(meta_path, 'rb') as f:
                        meta = json.loads(f.read().decode('utf-8', errors='replace'))
                    if not isinstance(meta, dict):
                        raise ValueError('meta가 객체가 아님')
                except (OSError, ValueError):
                    unreadable += 1
                    continue
                started = first_timestamp_ms(log_path)
                if started is None:
                    started = int(os.path.getmtime(meta_path) * 1000)
                depth = meta.get('spawnDepth')
                out.append({
                    'session_id': sess.name, 'agent_id': aid, 'type': str(meta.get('agentType') or ''),
                    'title': str(meta.get('description') or '')[:80] if SHOW_TITLES else '',
                    'finished': meta.get('finished') is True, 'started_ms': started, 'last_ms': max(last_ms, started),
                    'depth': depth if isinstance(depth, int) else None, 'project': proj.name,
                })
    return out, unreadable


def classify_agent(a, parent_alive, now_ms):
    """(상태, 확실한가). 상태는 running·quiet·ended. finished 표시가 없는 옛 기록은 마지막 활동 시각으로 추정한다."""
    if a['finished']:
        return 'ended', True
    age = (now_ms - a['last_ms']) / 1000.0
    if not parent_alive and age > GONE_END_SEC:
        return 'ended', False
    if age <= FRESH_SEC:
        return 'running', True
    if age <= END_ESTIMATE_SEC:
        return 'quiet', False
    return 'ended', False


def usage_summary(now=None):
    """usage-dashboard의 시간별 집계(hourly.json)에서 오늘·최근 5시간 실사용 토큰(입력+출력, 캐시 읽기 제외)을 메인과 서브에이전트로 나눠 돌려준다."""
    out = {'shown': SHOW_USAGE, 'enabled': False, 'available': False}
    if not SHOW_USAGE:
        return out
    base = os.path.join(claude_dir(), 'usage-log')
    out['enabled'] = os.path.exists(os.path.join(base, 'enabled'))
    path = os.path.join(base, 'hourly.json')
    try:
        mtime = os.path.getmtime(path)
        with open(path, 'rb') as f:
            data = json.loads(f.read().decode('utf-8', errors='replace'))
        if not isinstance(data, dict):
            raise ValueError('hourly가 객체가 아님')
    except (OSError, ValueError):
        return out
    now = time.time() if now is None else now
    today = time.strftime('%Y-%m-%d', time.localtime(now))
    last5 = set(time.strftime('%Y-%m-%dT%H', time.localtime(now - i * 3600)) for i in range(5))    # 현재 시각을 포함한 정시 5칸
    totals = {'today': {'main': 0, 'sub': 0}, 'last5h': {'main': 0, 'sub': 0}}
    sub_types = {}
    for hour, projects in data.items():
        in_today, in_last5 = str(hour).startswith(today), hour in last5
        if not (in_today or in_last5) or not isinstance(projects, dict):
            continue
        for kinds in projects.values():
            if not isinstance(kinds, dict):
                continue
            for kind, families in kinds.items():
                if not isinstance(families, dict):
                    continue
                n = 0
                for v in families.values():
                    if isinstance(v, dict):
                        n += int(v.get('in') or 0) + int(v.get('out') or 0)
                side = 'main' if kind == 'main' else 'sub'
                if in_today:
                    totals['today'][side] += n
                    if side == 'sub':
                        sub_types[str(kind)[4:] or '?'] = sub_types.get(str(kind)[4:] or '?', 0) + n
                if in_last5:
                    totals['last5h'][side] += n
    top = sorted(sub_types.items(), key=lambda kv: -kv[1])[:3]
    out.update({'available': True, 'updated_ms': int(mtime * 1000), 'today': totals['today'], 'last5h': totals['last5h'],
                'sub_types_today': [{'type': k, 'tokens': v} for k, v in top]})
    return out


def find_claude():
    """CLAUDE_BIN → PATH의 claude → VS Code 확장 폴더의 가장 높은 버전 순으로 찾는다. 못 찾으면 None."""
    env = os.environ.get('CLAUDE_BIN')
    if env:
        return env if os.path.exists(env) else None
    found = shutil.which('claude')
    if found:
        return found
    pattern = os.path.join(os.path.expanduser('~'), '.vscode', 'extensions', 'anthropic.claude-code-*',
                           'resources', 'native-binary', 'claude*')
    best, best_key = None, None
    for path in glob.glob(pattern):
        if path.endswith('.map'):
            continue
        m = re.search(r'anthropic\.claude-code-(\d+)\.(\d+)\.(\d+)', path)
        key = tuple(int(x) for x in m.groups()) if m else (0, 0, 0)
        if best_key is None or key > best_key:
            best, best_key = path, key
    return best


def fetch_agents():
    """claude agents --json을 실행해 (목록, 오류 메시지)를 돌려준다. 성공이면 오류는 None."""
    binary = find_claude()
    if not binary:
        return None, 'claude 실행 파일을 찾지 못함(CLAUDE_BIN으로 경로를 지정할 수 있음)'
    try:
        proc = subprocess.run([binary, 'agents', '--json'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    except subprocess.TimeoutExpired:
        return None, 'claude agents --json이 15초 안에 끝나지 않음'
    except OSError as e:
        return None, 'claude 실행 실패(%s)' % type(e).__name__
    if proc.returncode != 0:
        return None, 'claude agents --json 종료 코드 %d' % proc.returncode
    try:
        data = json.loads(proc.stdout.decode('utf-8', errors='replace'))
    except ValueError:
        return None, 'claude agents --json 출력이 JSON이 아님(형식이 바뀌었을 수 있음)'
    if not isinstance(data, list):
        return None, 'claude agents --json 출력이 목록이 아님(형식이 바뀌었을 수 있음)'
    return data, None


def folder_of(cwd):
    """전체 경로는 화면에 내보내지 않고 마지막 폴더 이름만 쓴다."""
    parts = re.split(r'[\\/]+', str(cwd or '').rstrip('/\\'))
    return parts[-1] if parts and parts[-1] else '-'


class State:
    """세션별 상태 변화를 기억한다. 스레드 안전."""

    def __init__(self):
        self.lock = threading.Lock()
        self.sessions = {}        # sessionId -> 내부 기록
        self.error = None
        self.last_ok_ms = None
        self.last_try_ms = None
        self.agents = []
        self.agents_unreadable = 0

    def update_agents(self, agents, unreadable):
        with self.lock:
            self.agents = list(agents)
            self.agents_unreadable = unreadable

    def update(self, agents, error, now_ms):
        with self.lock:
            self.last_try_ms = now_ms
            self.error = error
            if error is not None:
                return
            self.last_ok_ms = now_ms
            seen = set()
            for a in agents:
                if not isinstance(a, dict):
                    continue
                sid = str(a.get('sessionId') or a.get('pid') or '')
                if not sid:
                    continue
                seen.add(sid)
                status = str(a.get('status') or '')
                rec = self.sessions.get(sid)
                if rec is None:
                    rec = {'first_seen_ms': now_ms, 'busy_since_ms': None, 'busy_exact': False, 'ended_ms': None, 'status': None, 'missing': 0}
                    self.sessions[sid] = rec
                rec['missing'] = 0
                if rec['ended_ms'] is not None:      # 다시 나타남
                    rec['ended_ms'] = None
                if status == 'busy' and rec['status'] != 'busy':
                    rec['busy_since_ms'] = now_ms
                    rec['busy_exact'] = rec['status'] is not None    # 처음 본 순간부터 busy면 정확한 시작 시각을 모름
                if status != 'busy':
                    rec['busy_since_ms'] = None
                rec['status'] = status
                rec['name'] = str(a.get('name') or '')
                rec['folder'] = folder_of(a.get('cwd'))
                rec['kind'] = str(a.get('kind') or '')
                rec['started_ms'] = a.get('startedAt') if isinstance(a.get('startedAt'), (int, float)) else None
                rec['short_id'] = re.sub(r'[^A-Za-z0-9]', '', str(a.get('sessionId') or ''))[:8]
                rec['sid_full'] = str(a.get('sessionId') or '')
            for sid, rec in list(self.sessions.items()):
                if sid not in seen:
                    rec['missing'] += 1
                    if rec['missing'] >= MISSING_POLLS and rec['ended_ms'] is None:
                        rec['ended_ms'] = now_ms
                if rec['ended_ms'] is not None and now_ms - rec['ended_ms'] > KEEP_ENDED_SEC * 1000:
                    del self.sessions[sid]

    @staticmethod
    def _agents_view(items, parent_alive, now_ms):
        view = []
        for a in items:
            state, exact = classify_agent(a, parent_alive, now_ms)
            view.append({'id': re.sub(r'[^A-Za-z0-9]', '', a['agent_id'])[:8], 'type': a['type'], 'title': a['title'],
                         'state': state, 'exact': exact, 'started_ms': a['started_ms'], 'last_ms': a['last_ms'], 'depth': a['depth']})
        rank = {'running': 0, 'quiet': 1, 'ended': 2}
        view.sort(key=lambda v: (rank[v['state']], -v['last_ms']))
        return view

    def snapshot(self, now_ms):
        with self.lock:
            by_sid = {}
            for a in self.agents:
                by_sid.setdefault(a['session_id'], []).append(a)
            out, known = [], set()
            for rec in self.sessions.values():
                alive = rec['ended_ms'] is None
                if not alive:
                    state = 'ended'
                elif rec['status'] in ('busy', 'idle'):
                    state = rec['status']
                else:
                    state = 'unknown'
                sid = rec.get('sid_full', '')
                known.add(sid)
                out.append({
                    'name': rec.get('name'), 'folder': rec.get('folder'), 'kind': rec.get('kind'), 'short_id': rec.get('short_id'),
                    'state': state, 'raw_status': rec.get('status'),
                    'started_ms': rec.get('started_ms'), 'busy_since_ms': rec['busy_since_ms'], 'busy_exact': rec['busy_exact'],
                    'ended_ms': rec['ended_ms'], 'first_seen_ms': rec['first_seen_ms'],
                    'agents': self._agents_view(by_sid.get(sid, []), alive, now_ms),
                })
            # 세션 목록에는 없지만 최근 서브에이전트 기록이 있는 세션(이미 끝난 세션)
            for sid, items in by_sid.items():
                if sid in known:
                    continue
                out.append({
                    'name': None, 'folder': items[0]['project'].lstrip('-') or '-', 'kind': '', 'short_id': re.sub(r'[^A-Za-z0-9]', '', sid)[:8],
                    'state': 'gone', 'raw_status': None, 'started_ms': None, 'busy_since_ms': None, 'busy_exact': False,
                    'ended_ms': None, 'first_seen_ms': now_ms, 'agents': self._agents_view(items, False, now_ms),
                })
            order = {'busy': 0, 'unknown': 1, 'idle': 2, 'ended': 3, 'gone': 4}
            out.sort(key=lambda s: (order[s['state']], (s['name'] or ''), s['short_id']))
            concurrent = sum(1 for s in out for a in s['agents'] if a['state'] in ('running', 'quiet'))
            return {'server_ms': now_ms, 'ok': self.error is None, 'error': self.error,
                    'last_ok_ms': self.last_ok_ms, 'poll_sec': POLL_SEC, 'window_sec': WINDOW_SEC,
                    'agents_unreadable': self.agents_unreadable, 'concurrent': concurrent, 'sessions': out}


STATE = State()
FETCH = fetch_agents      # 시험에서 바꿔 끼운다
SCAN = scan_subagents


def poll_loop(stop):
    while not stop.is_set():
        now_ms = int(time.time() * 1000)
        agents, error = FETCH()
        STATE.update(agents or [], error, now_ms)
        try:
            STATE.update_agents(*SCAN(now_ms))
        except Exception:                         # 형식이 바뀌어도 세션 화면은 계속 돌게 한다
            STATE.update_agents([], 1)
        stop.wait(POLL_SEC)


class Handler(BaseHTTPRequestHandler):
    server_version = 'live-status'

    def log_message(self, fmt, *args):
        pass

    def _allowed_host(self):
        host = (self.headers.get('Host') or '').lower()
        port = self.server.server_address[1]
        return host in ('127.0.0.1:%d' % port, 'localhost:%d' % port)

    def _send(self, code, body, ctype, csp=None, extra=None):
        data = body if isinstance(body, bytes) else body.encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Content-Security-Policy', csp or "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if not self._allowed_host():          # DNS rebinding 방지: 다른 이름으로 들어온 요청은 거부
            self._send(403, 'forbidden', 'text/plain; charset=utf-8')
            return
        path = self.path.split('?', 1)[0]
        if path in ('/', '/live.html'):
            with open(os.path.join(HERE, 'live.html'), 'rb') as f:
                self._send(200, f.read(), 'text/html; charset=utf-8')
        elif path == '/api/state':
            snap = STATE.snapshot(int(time.time() * 1000))
            snap['usage'] = usage_summary()
            self._send(200, json.dumps(snap, ensure_ascii=False), 'application/json; charset=utf-8')
        elif path == '/usage':
            self._send(301, '', 'text/plain; charset=utf-8', extra={'Location': '/usage/'})
        elif path.startswith('/usage/'):
            self._usage(path[len('/usage/'):])
        else:
            self._send(404, 'not found', 'text/plain; charset=utf-8')

    def _usage(self, rel):
        """기존 사용량 화면을 그대로 내보낸다(허용 목록 두 파일만). 화면 맨 위에 실시간 현황으로 돌아가는 줄만 끼워 넣는다."""
        name = USAGE_FILES.get(rel) if SHOW_USAGE else None
        if name is None:
            self._send(404, 'not found', 'text/plain; charset=utf-8')
            return
        try:
            with open(os.path.join(claude_dir(), 'usage-log', name), 'rb') as f:
                data = f.read()
        except OSError:
            self._send(404, '사용량 기록이 없습니다. usage-dashboard 스킬로 먼저 켜세요.', 'text/plain; charset=utf-8')
            return
        csp = "default-src 'none'; script-src 'self' 'unsafe-inline'; style-src 'unsafe-inline'; img-src data:; connect-src 'self'; frame-ancestors 'none'"
        if name.endswith('.js'):
            self._send(200, data, 'application/javascript; charset=utf-8', csp=csp)
            return
        nav = ('<div style="background:#1d2430;color:#fff;padding:6px 16px;font:14px system-ui,sans-serif">'
               '<a href="/" style="color:#9cc2ff">← 실시간 현황</a> · 이 화면에는 요청 내용 일부가 들어 있습니다</div>').encode('utf-8')
        data = data.replace(b'<body>', b'<body>' + nav, 1)
        self._send(200, data, 'text/html; charset=utf-8', csp=csp)

    def do_POST(self):
        self._send(405, 'method not allowed', 'text/plain; charset=utf-8')

    do_PUT = do_DELETE = do_PATCH = do_POST


def make_server(port):
    return ThreadingHTTPServer(('127.0.0.1', port), Handler)


def main():
    utf8_stdio()
    server = make_server(PORT)
    stop = threading.Event()
    threading.Thread(target=poll_loop, args=(stop,), daemon=True).start()
    print('실시간 세션 현황: http://127.0.0.1:%d/ (끄려면 live.sh stop)' % PORT, flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        stop.set()
        server.server_close()


if __name__ == '__main__':
    main()
