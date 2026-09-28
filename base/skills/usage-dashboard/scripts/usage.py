#!/usr/bin/env python3
"""토큰 사용 기록 집계(Issue #136). usage.sh가 잠금을 잡은 뒤 부른다 — 직접 실행하지 않는다.

python usage.py <hook|backfill|render|status>
  hook      stdin의 Stop 훅 입력으로 그 세션의 메인·서브에이전트 기록에서 새 줄만 읽는다
  backfill  남아 있는 대화 기록 전체에서 새 줄을 읽는다(켜기 때)
저장(usage-log/):
  hourly.json    시간 → 저장소 → 누가(main/sub:<종류>) → 모델 계열 → {turns, in, cache, out}. 영구
  requests.json  요청(사용자 한 번의 요청과 그에 따른 응답·도구·서브에이전트) 단위 합계와 원인 신호. 90일
  starts.jsonl   세션 시작 크기. 영구
  tools.jsonl    2만 자 넘는 도구 결과(도구 이름·크기). 90일
  details.json   요청별 진행 요약: 요청 원문(최대 2천 자), 응답 앞부분, 도구 호출 요약(명령·경로), 도구 결과 크기와 앞부분. 90일
요청 목록은 첫 80자, 상세는 위 범위만 이 PC에 저장한다(어떤 작업이었는지 알아보기 위해, 2026-09-27 사용자 요청).
화면(dashboard.html)은 details.js를 함께 읽는다. 둘 다 이 PC 안에서만 열린다.
"""
import datetime
import glob
import json
import os
import sys
import time

HOME = os.environ.get('CLAUDE_CONFIG_DIR') or os.path.expanduser('~/.claude')
BASE = os.environ.get('USAGE_LOG_DIR') or os.path.join(HOME, 'usage-log')
PROJECTS = os.environ.get('USAGE_PROJECTS_DIR') or os.path.join(HOME, 'projects')
HOURLY, REQUESTS, STARTS, TOOLS, STATE, PAGE, DETAILS, DETAILS_JS = (os.path.join(BASE, n) for n in (
    'hourly.json', 'requests.json', 'starts.jsonl', 'tools.jsonl', 'state.json', 'dashboard.html', 'details.json', 'details.js'))
TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'dashboard.html')
BIG_CHARS = 20000         # 이보다 큰 도구 결과만 따로 기록
KEEP_DAYS = 90            # 요청·도구 기록 보관 기간
REWRITE_MIN = 10000       # 캐시에 새로 쓴 양이 이보다 크고 읽은 양보다 많으면 "캐시 재작성"으로 본다
IDLE_SEC = 300            # 이보다 오래 쉬고 난 뒤의 재작성은 "쉬어서 캐시 만료"(캐시 수명 5분)
PROMPT_CHARS = 80
PROMPT_FULL = 2000        # 상세에 남기는 요청 원문 길이
EV_MAX, EV_TEXT = 40, 180 # 요청당 상세 단계 수, 단계마다 남기는 글자 수


def parse_ts(ts):
    try:
        return datetime.datetime.fromisoformat(str(ts).replace('Z', '+00:00')).astimezone()
    except ValueError:
        return None


def family(model):
    m = (model or '').lower()
    for f in ('opus', 'sonnet', 'haiku', 'fable'):
        if f in m:
            return f
    return 'other'


def load_json(path, default):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_atomic(path, text):
    tmp = f'{path}.{os.getpid()}.tmp'
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    # Windows는 브라우저가 화면 파일을 읽는 중이면 바꿔치기가 거부된다(2026-09-27 error.log 실측). 잠깐 뒤 다시 시도
    for i in range(5):
        try:
            os.replace(tmp, path)
            return
        except PermissionError:
            if i == 4:
                os.remove(tmp)
                raise
            time.sleep(0.2)


def read_jsonl(path):
    out = []
    try:
        with open(path, encoding='utf-8') as f:
            for line in f:
                try:
                    out.append(json.loads(line))
                except ValueError:
                    pass
    except OSError:
        pass
    return out


def load_hourly():
    """이전 초안 형식(시간→누가→합계, 시간→누가→모델→합계)은 저장소 '?' 아래로 옮긴다."""
    h = load_json(HOURLY, {})
    for hour, lvl in list(h.items()):
        if any(k == 'main' or k.startswith('sub:') for k in lvl):
            for kind, v in list(lvl.items()):
                if 'turns' in v:
                    lvl[kind] = {'other': v}
            h[hour] = {'?': lvl}
    return h


def prompt_text(e):
    """사람이 보낸 요청이면 (첫 80자, 자동 알림 여부), 아니면 None."""
    if e.get('type') != 'user' or e.get('isMeta') or e.get('isCompactSummary'):
        return None
    c = (e.get('message') or {}).get('content')
    if isinstance(c, list):
        if any(isinstance(x, dict) and x.get('type') == 'tool_result' for x in c):
            return None
        c = ' '.join(x.get('text', '') for x in c if isinstance(x, dict) and x.get('type') == 'text')
    if not isinstance(c, str):
        return None
    full = c.strip()
    t = ' '.join(c.split())
    auto = t.startswith('<')     # <task-notification> 같은 자동 알림, <command-...> 같은 명령
    return t[:PROMPT_CHARS], auto, full[:PROMPT_FULL]


def tool_summary(name, inp):
    """도구 호출을 한 줄로: 명령·경로·검색어처럼 무엇을 했는지 알 수 있는 값 하나."""
    if not isinstance(inp, dict):
        return ''
    for key in ('command', 'file_path', 'path', 'pattern', 'url', 'query', 'description', 'skill', 'prompt'):
        v = inp.get(key)
        if isinstance(v, str) and v.strip():
            return ' '.join(v.split())[:EV_TEXT]
    return ''


def result_text(c):
    x = c.get('content')
    if isinstance(x, list):
        x = ' '.join(b.get('text', '') for b in x if isinstance(b, dict) and b.get('type') == 'text')
    return ' '.join(str(x or '').split())[:EV_TEXT]


class Store:
    def __init__(self):
        self.state = load_json(STATE, {'files': {}, 'sess': {}, 'pruned': ''})
        self.state.setdefault('sess', {})
        self.hourly = load_hourly()
        self.requests = load_json(REQUESTS, {})
        self.details = load_json(DETAILS, {})
        self.new_starts, self.new_tools = [], []

    def _ev(self, rid, ev):
        d = self.details.setdefault(rid, {'p': '', 'ev': [], 'more': 0})
        if len(d['ev']) < EV_MAX:
            d['ev'].append(ev)
        else:
            d['more'] += 1

    def _req(self, rid, ts, sid, proj, text='', auto=False):
        return self.requests.setdefault(rid, {
            'ts': ts, 'sid': sid[:8], 'proj': proj, 'text': text, 'auto': auto, 'turns': 0, 'in': 0, 'cache': 0,
            'out': 0, 'tools': {}, 'subs': {}, 'models': {}, 'rewrites': 0, 'idle_rewrites': 0, 'rewrite_tokens': 0,
            'compact': 0, 'big': 0})

    def add_file(self, path, kind, sid, proj, parent_rid=None):
        """kind: 'main' 또는 'sub:<종류>'. 서브에이전트 사용량은 그 에이전트를 부른 요청(parent_rid)에 더한다."""
        off = self.state['files'].get(path, 0)
        try:
            size = os.path.getsize(path)
            if size < off:                 # 파일이 줄었으면 처음부터 다시 세지 않고(이중 집계 방지) 끝부터 잇는다
                self.state['files'][path] = size
                return 0, proj
            with open(path, 'rb') as f:
                f.seek(off)
                data = f.read()
        except OSError:
            return 0, proj
        end = data.rfind(b'\n') + 1          # 쓰는 중인 마지막 줄은 다음에 읽는다
        self.state['files'][path] = off + end
        ss = self.state['sess'].setdefault(sid, {'rid': None, 'last': None, 'agents': {}, 'first': True})
        mem = self.state.setdefault('msgs', {}).setdefault(path, {})
        names, n = {}, 0
        first_turn = off == 0 and kind == 'main'
        last_ts = ss['last'] if kind == 'main' else None
        for raw in data[:end].splitlines():
            try:
                e = json.loads(raw)
            except ValueError:
                continue
            if kind == 'main' and e.get('isSidechain'):
                continue
            if proj == '?' and e.get('cwd'):
                proj = os.path.basename(e['cwd'].rstrip('/\\')) or '?'
            ts = e.get('timestamp')
            m = e.get('message') or {}
            content = m.get('content') if isinstance(m.get('content'), list) else []
            if kind == 'main':
                if e.get('type') == 'system' and e.get('subtype') == 'compact_boundary' and ss['rid']:
                    self._req(ss['rid'], ts, sid, proj)['compact'] += 1
                p = prompt_text(e)
                if p:
                    ss['rid'] = e.get('uuid') or f'{sid}:{ts}'
                    self._req(ss['rid'], ts, sid, proj, p[0], p[1])
                    self.details.setdefault(ss['rid'], {'p': '', 'ev': [], 'more': 0})['p'] = p[2]
            rid = parent_rid if kind != 'main' else ss['rid']
            if e.get('type') == 'assistant':
                for c in content:
                    if kind == 'main' and rid and c.get('type') == 'text' and c.get('text', '').strip():
                        self._ev(rid, {'k': 'say', 'x': ' '.join(c['text'].split())[:EV_TEXT]})
                    if c.get('type') == 'tool_use':
                        names[c.get('id')] = c.get('name')
                        if kind == 'main' and rid:
                            self._ev(rid, {'k': 'tool', 'n': c.get('name'), 'x': tool_summary(c.get('name'), c.get('input'))})
                            t = self._req(rid, ts, sid, proj)['tools']
                            t[c.get('name')] = t.get(c.get('name'), 0) + 1
                            if c.get('name') in ('Agent', 'Task'):
                                ss['agents'][c.get('id')] = rid
                u, mid = m.get('usage'), m.get('id')
                if u and m.get('model') != '<synthetic>':
                    # 한 응답이 여러 줄로 남고, 앞줄에는 스트리밍 중간값(출력 토큰이 덜 찬 값)이 들어 있다(이 PC 기록 11,045건 중
                    # 2,053건, 첫 줄만 세면 출력이 약 32% 적게 잡힘, 2026-09-27 확인). 응답별로 지금까지 센 값을 기억해 늘어난 만큼만 더한다.
                    vals = [u.get('input_tokens', 0), u.get('cache_creation_input_tokens', 0),
                            u.get('cache_read_input_tokens', 0), u.get('output_tokens', 0)]
                    prev = mem.get(mid)
                    delta = [max(0, a - b) for a, b in zip(vals, prev)] if prev else vals
                    mem[mid] = [max(a, b) for a, b in zip(vals, prev)] if prev else vals
                    if not any(delta):
                        continue
                    new_turn = prev is None
                    n += new_turn
                    t = parse_ts(ts) or datetime.datetime.now().astimezone()
                    fam = family(m.get('model'))
                    new_in, cache, out = delta[0] + delta[1], delta[2], delta[3]
                    b = self.hourly.setdefault(t.strftime('%Y-%m-%dT%H'), {}).setdefault(proj, {}) \
                        .setdefault(kind, {}).setdefault(fam, {'turns': 0, 'in': 0, 'cache': 0, 'out': 0})
                    b['turns'] += new_turn
                    b['in'] += new_in
                    b['cache'] += cache
                    b['out'] += out
                    if rid:
                        r = self._req(rid, ts, sid, proj)
                        if kind == 'main':
                            r['turns'] += new_turn
                            r['in'] += new_in
                            r['cache'] += cache
                            r['out'] += out
                        else:
                            s = r['subs'].setdefault(kind[4:], {'turns': 0, 'in': 0, 'cache': 0, 'out': 0})
                            s['turns'] += new_turn
                            s['in'] += new_in
                            s['cache'] += cache
                            s['out'] += out
                        r['models'][fam] = r['models'].get(fam, 0) + new_in + out
                        cc = delta[1]
                        if kind == 'main' and new_turn and not first_turn and cc >= REWRITE_MIN and cc > cache:
                            r['rewrites'] += 1
                            r['rewrite_tokens'] += cc
                            lt = parse_ts(last_ts) if last_ts else None
                            if lt and (t - lt).total_seconds() > IDLE_SEC:
                                r['idle_rewrites'] += 1
                    if kind == 'main':
                        last_ts = ts           # 쉰 시간은 직전 API 호출(응답)부터 잰다. 사용자 입력 시각이 아니라
                    if first_turn and new_turn:
                        first_turn = False
                        self.new_starts.append({'ts': t.isoformat(timespec='minutes'), 'sid': sid[:8], 'proj': proj,
                                                'ctx': new_in + cache})
            elif e.get('type') == 'user':
                for c in content:
                    if c.get('type') == 'tool_result':
                        size = len(json.dumps(c.get('content'), ensure_ascii=False))
                        if kind == 'main' and rid:
                            self._ev(rid, {'k': 'res', 'n': names.get(c.get('tool_use_id'), ''), 'c': size,
                                           'err': bool(c.get('is_error')), 'x': result_text(c)})
                        if size >= BIG_CHARS:
                            t = parse_ts(ts) or datetime.datetime.now().astimezone()
                            tool = names.get(c.get('tool_use_id'), '?')
                            self.new_tools.append({'ts': t.isoformat(timespec='minutes'), 'proj': proj, 'who': kind,
                                                   'tool': tool, 'chars': size})
                            if rid:
                                r = self._req(rid, ts, sid, proj)
                                r['big'] = max(r['big'], size)
        self.state['msgs'][path] = dict(list(mem.items())[-50:])   # 다음 번에 이어질 수 있는 최근 응답만 기억
        if kind == 'main':
            ss['last'] = last_ts
            ss['agents'] = dict(list(ss['agents'].items())[-300:])
        return n, proj

    def add_session(self, transcript, sid, proj):
        n, proj = self.add_file(transcript, 'main', sid, proj)
        agents = self.state['sess'].get(sid, {}).get('agents', {})
        for f in sorted(glob.glob(os.path.join(os.path.dirname(transcript), sid, 'subagents', 'agent-*.jsonl'))):
            meta = load_json(f[:-len('.jsonl')] + '.meta.json', {})
            n += self.add_file(f, 'sub:' + (meta.get('agentType') or '?'), sid, proj,
                               agents.get(meta.get('toolUseId')))[0]
        return n

    def save(self):
        os.makedirs(BASE, exist_ok=True)
        today = datetime.date.today().isoformat()
        if self.state.get('pruned') != today:   # 하루 한 번: 90일 지난 요청·도구 기록, 지워진 대화 기록 정보 정리
            cut = datetime.datetime.now().astimezone() - datetime.timedelta(days=KEEP_DAYS)
            self.requests = {k: v for k, v in self.requests.items() if (parse_ts(v['ts']) or cut) >= cut}
            self.details = {k: v for k, v in self.details.items() if k in self.requests}
            keep = [r for r in read_jsonl(TOOLS) if (parse_ts(r.get('ts')) or cut) >= cut]
            write_atomic(TOOLS, ''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in keep))
            self.state['files'] = {p: o for p, o in self.state['files'].items() if os.path.isfile(p)}
            self.state['msgs'] = {p: v for p, v in self.state.get('msgs', {}).items() if p in self.state['files']}
            live = {os.path.basename(p)[:-len('.jsonl')] for p in self.state['files']}
            self.state['sess'] = {k: v for k, v in self.state['sess'].items() if k in live}
            self.state['pruned'] = today
        write_atomic(HOURLY, json.dumps(self.hourly, ensure_ascii=False, sort_keys=True))
        write_atomic(REQUESTS, json.dumps(self.requests, ensure_ascii=False))
        write_atomic(DETAILS, json.dumps(self.details, ensure_ascii=False))
        for path, rows in ((STARTS, self.new_starts), (TOOLS, self.new_tools)):
            if rows:
                with open(path, 'a', encoding='utf-8', newline='\n') as f:
                    f.writelines(json.dumps(r, ensure_ascii=False) + '\n' for r in rows)
        write_atomic(STATE, json.dumps(self.state, ensure_ascii=False))


def status():
    on = os.path.isfile(os.path.join(BASE, 'enabled'))
    hours = sorted(load_json(HOURLY, {}))
    span = f'{hours[0][:10]} ~ {hours[-1][:10]}' if hours else '기록 없음'
    print(f"{'켜짐' if on else '꺼짐'} · 기록 기간 {span} · 대시보드 {PAGE}")


def render():
    now = datetime.datetime.now().astimezone()
    cut30 = now - datetime.timedelta(days=30)
    reqs = []
    for rid, r in load_json(REQUESTS, {}).items():
        t = parse_ts(r['ts'])
        if not t or t < cut30:
            continue
        sub_new = sum(s['in'] + s['out'] for s in r['subs'].values())
        sub_all = sum(s['in'] + s['cache'] + s['out'] for s in r['subs'].values())
        reqs.append(dict(r, rid=rid, ts=t.isoformat(timespec='minutes'),
                         nocache=r['in'] + r['out'] + sub_new, all=r['in'] + r['cache'] + r['out'] + sub_all))
    keep = {id(r) for key in ('nocache', 'all') for r in sorted(reqs, key=lambda x: -x[key])[:150]}
    tools = sorted((r for r in read_jsonl(TOOLS) if (parse_ts(r['ts']) or cut30) >= now - datetime.timedelta(days=7)),
                   key=lambda r: -r['chars'])[:15]
    data = {'hourly': load_hourly(), 'starts': sorted(read_jsonl(STARTS), key=lambda r: r['ts'])[-60:],
            'tools': tools, 'requests': [r for r in reqs if id(r) in keep],
            'signals': signals(reqs),
            'signals7': signals([r for r in reqs if parse_ts(r['ts']) >= now - datetime.timedelta(days=7)]),
            'signals_prev7': signals([r for r in reqs if now - datetime.timedelta(days=14) <= parse_ts(r['ts']) < now - datetime.timedelta(days=7)]),
            'updated': now.isoformat(timespec='seconds'),
            'enabled': os.path.isfile(os.path.join(BASE, 'enabled'))}
    blob = json.dumps(data, ensure_ascii=False).replace('</', '<\\/')
    with open(TEMPLATE, encoding='utf-8') as f:
        page = f.read().replace('__DATA__', blob)
    os.makedirs(BASE, exist_ok=True)
    det = load_json(DETAILS, {})
    shown = {r['rid']: det[r['rid']] for r in data['requests'] if r['rid'] in det}
    write_atomic(DETAILS_JS, 'window.DETAILS=' + json.dumps(shown, ensure_ascii=False).replace('</', '<\\/') + ';')
    write_atomic(PAGE, page)


def signals(reqs):
    """최근 30일 원인 신호 요약(캐시 제외 기준 토큰)."""
    s = {'requests': len(reqs), 'total': sum(r['nocache'] for r in reqs),
         'rewrites': sum(r['rewrites'] for r in reqs), 'idle_rewrites': sum(r['idle_rewrites'] for r in reqs),
         'rewrite_tokens': sum(r['rewrite_tokens'] for r in reqs), 'compacts': sum(r['compact'] for r in reqs),
         'long': sum(1 for r in reqs if r['turns'] >= 30), 'long_tokens': sum(r['nocache'] for r in reqs if r['turns'] >= 30),
         'sub_tokens': sum(sum(x['in'] + x['out'] for x in r['subs'].values()) for r in reqs),
         'big': sum(1 for r in reqs if r['big'] >= BIG_CHARS), 'auto': sum(1 for r in reqs if r['auto']),
         'auto_tokens': sum(r['nocache'] for r in reqs if r['auto'])}
    return s


def hook_lock():
    """usage.sh의 mkdir 잠금과 같은 폴더를 쓴다(동시에 끝난 세션끼리, enable과도 서로 기다림).
    Windows Git Bash는 하위 프로세스 하나에 0.3초 안팎이라 훅에서는 잠금을 셸 대신 여기서 잡는다."""
    lock = os.path.join(BASE, '.lock')
    for _ in range(150):
        try:
            os.mkdir(lock)
            return lock
        except FileExistsError:
            try:
                if time.time() - os.path.getmtime(lock) > 60:   # 1분 넘은 잠금은 죽은 것으로 보고 치운다
                    os.rmdir(lock)
                    continue
            except OSError:
                pass
            time.sleep(0.2)
    return None


if __name__ == '__main__':
    MODE = sys.argv[1] if len(sys.argv) > 1 else 'hook'
    os.makedirs(BASE, exist_ok=True)
    if MODE == 'hook':
        lock = hook_lock()
        if not lock:
            sys.exit(0)
        try:
            inp = json.loads(sys.stdin.read() or '{}')
            if inp.get('transcript_path') and os.path.isfile(inp['transcript_path']):
                st = Store()
                st.add_session(inp['transcript_path'], inp.get('session_id') or '?',
                               os.path.basename((inp.get('cwd') or '').rstrip('/\\')) or '?')
                st.save()
                render()
        except Exception as e:   # 훅 실패가 세션을 방해하지 않게 조용히 기록만
            with open(os.path.join(BASE, 'error.log'), 'a', encoding='utf-8') as f:
                f.write(f'{datetime.datetime.now().isoformat()} {type(e).__name__}: {e}\n')
        finally:
            os.rmdir(lock)
    elif MODE == 'backfill':
        st, n, files = Store(), 0, 0
        for tp in sorted(glob.glob(os.path.join(PROJECTS, '*', '*.jsonl')), key=os.path.getmtime):
            n += st.add_session(tp, os.path.basename(tp)[:-len('.jsonl')], '?')
            files += 1
        st.save()
        render()
        hours = sorted(st.hourly)
        print(f'채움: 대화 기록 {files}개, 새로 읽은 응답 {n:,}건, 요청 {len(st.requests):,}개, '
              f'기록 기간 {hours[0][:10] if hours else "-"} ~ {hours[-1][:10] if hours else "-"}')
    elif MODE == 'render':
        render()
    elif MODE == 'status':
        status()
