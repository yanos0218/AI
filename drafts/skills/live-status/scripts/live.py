#!/usr/bin/env python3
"""실시간 세션 현황 서버(Issue #213 초안).

`claude agents --json`(공식 인터페이스, 활성 세션을 JSON으로 주고 끝남)을 몇 초마다 읽어 세션별 상태를 추적하고,
127.0.0.1에만 묶은 작은 웹 서버로 live.html과 /api/state를 준다. 파이썬 표준 라이브러리만 쓴다.

- 서브에이전트는 `claude agents --json` 출력에 없어 보여 주지 않는다.
- 대화 내용과 전체 경로는 읽지도 보여 주지도 않는다(이름·폴더 이름·상태·시각만).
- 환경변수: LIVE_PORT(기본 8766), LIVE_POLL_SEC(기본 2), CLAUDE_BIN(claude 실행 파일 경로).
"""
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
            for sid, rec in list(self.sessions.items()):
                if sid not in seen:
                    rec['missing'] += 1
                    if rec['missing'] >= MISSING_POLLS and rec['ended_ms'] is None:
                        rec['ended_ms'] = now_ms
                if rec['ended_ms'] is not None and now_ms - rec['ended_ms'] > KEEP_ENDED_SEC * 1000:
                    del self.sessions[sid]

    def snapshot(self, now_ms):
        with self.lock:
            out = []
            for rec in self.sessions.values():
                if rec['ended_ms'] is not None:
                    state = 'ended'
                elif rec['status'] in ('busy', 'idle'):
                    state = rec['status']
                else:
                    state = 'unknown'
                out.append({
                    'name': rec.get('name'), 'folder': rec.get('folder'), 'kind': rec.get('kind'), 'short_id': rec.get('short_id'),
                    'state': state, 'raw_status': rec.get('status'),
                    'started_ms': rec.get('started_ms'), 'busy_since_ms': rec['busy_since_ms'], 'busy_exact': rec['busy_exact'],
                    'ended_ms': rec['ended_ms'], 'first_seen_ms': rec['first_seen_ms'],
                })
            order = {'busy': 0, 'unknown': 1, 'idle': 2, 'ended': 3}
            out.sort(key=lambda s: (order[s['state']], (s['name'] or '')))
            return {'server_ms': now_ms, 'ok': self.error is None, 'error': self.error,
                    'last_ok_ms': self.last_ok_ms, 'poll_sec': POLL_SEC, 'sessions': out}


STATE = State()
FETCH = fetch_agents      # 시험에서 바꿔 끼운다


def poll_loop(stop):
    while not stop.is_set():
        agents, error = FETCH()
        STATE.update(agents or [], error, int(time.time() * 1000))
        stop.wait(POLL_SEC)


class Handler(BaseHTTPRequestHandler):
    server_version = 'live-status'

    def log_message(self, fmt, *args):
        pass

    def _allowed_host(self):
        host = (self.headers.get('Host') or '').lower()
        port = self.server.server_address[1]
        return host in ('127.0.0.1:%d' % port, 'localhost:%d' % port)

    def _send(self, code, body, ctype):
        data = body if isinstance(body, bytes) else body.encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Content-Security-Policy', "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'")
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
            self._send(200, json.dumps(STATE.snapshot(int(time.time() * 1000)), ensure_ascii=False), 'application/json; charset=utf-8')
        else:
            self._send(404, 'not found', 'text/plain; charset=utf-8')

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
