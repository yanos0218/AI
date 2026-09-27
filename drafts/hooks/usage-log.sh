#!/usr/bin/env bash
# 토큰 사용 기록 훅(Issue #136) — Claude Code Stop 훅(응답이 끝날 때마다)으로 등록한다.
# 세션 기록(transcript_path)에서 지난번 이후 새 줄만 읽어 턴별 컨텍스트 크기·출력 토큰과
# 큰 도구 결과(도구 이름과 글자 수만)를 로컬에 쌓고, 로컬 HTML 대시보드를 다시 쓴다.
# API를 부르지 않으므로 기록·대시보드 조회에 토큰이 들지 않는다. 명령·파일 내용은 저장하지 않는다.
#
# 사용법
#   (Stop 훅)                 stdin으로 훅 입력 JSON을 받는다
#   bash usage-log.sh --check  세션 시작 크기가 30일 중앙값보다 20% 넘게 늘었으면 한 줄 출력(session-start-check용)
#   bash usage-log.sh --render 대시보드만 다시 쓴다
# 기록 위치: ${CLAUDE_CONFIG_DIR:-~/.claude}/usage-log/ (시험할 때는 USAGE_LOG_DIR로 바꾼다)
# 한계: 서브에이전트 기록은 별도 파일이라 포함하지 않는다(그쪽은 /usage 기여도로 본다).
# 등록은 "async": true로 한다. Windows에서 파이썬 시작만 0.5초 넘게 걸려, 동기로 걸면 응답마다 그만큼 늦어진다.
set -u

# Windows는 python3가 스토어 별칭이라 느려(0.6초+) python을 먼저 쓴다. Mac·Linux는 python3만 있는 경우가 많다
PY="$(command -v python || command -v python3 || true)"
[[ -n "${PY}" ]] || exit 0
MODE="${1:-stop}"
input=""
[[ "${MODE}" == "stop" ]] && input="$(cat)"

# 훅 입력을 stdin으로 넘기므로 프로그램은 -c로 준다(heredoc을 python -로 넘기면 stdin을 뺏긴다)
read -r -d '' PROG <<'PY'
import datetime, html, json, os, sys

MODE = sys.argv[1]
BASE = os.environ.get('USAGE_LOG_DIR') or os.path.join(
    os.environ.get('CLAUDE_CONFIG_DIR') or os.path.expanduser('~/.claude'), 'usage-log')
REC = os.path.join(BASE, 'records.jsonl')
STATE = os.path.join(BASE, 'state.json')
PAGE = os.path.join(BASE, 'dashboard.html')
KEEP_DAYS = 30
BIG_CHARS = 20000   # 이보다 큰 도구 결과만 기록
ALERT_RATIO = 1.2   # 세션 시작 크기가 중앙값의 120%를 넘으면 알림
MIN_SESSIONS = 6    # 비교할 과거 세션이 이보다 적으면 알리지 않음


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')


def age_days(ts):
    try:
        t = datetime.datetime.fromisoformat(ts.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
        return 0
    return (datetime.datetime.now(datetime.timezone.utc) - t).total_seconds() / 86400


def load_json(path, default):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_atomic(path, text):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    os.replace(tmp, path)


def read_records():
    out = []
    try:
        with open(REC, encoding='utf-8') as f:
            for line in f:
                try:
                    out.append(json.loads(line))
                except ValueError:
                    pass
    except OSError:
        pass
    return out


def collect(inp):
    tp, sid = inp.get('transcript_path'), inp.get('session_id') or '?'
    if not tp or not os.path.isfile(tp):
        return
    state = load_json(STATE, {'sessions': {}, 'pruned': ''})
    sess = state['sessions'].get(sid, {'offset': 0, 'turns': 0, 'tools': {}})
    if os.path.getsize(tp) < sess['offset']:
        sess['offset'] = 0
    with open(tp, 'rb') as f:
        f.seek(sess['offset'])
        data = f.read()
    end = data.rfind(b'\n') + 1          # 쓰는 중인 마지막 줄은 다음에 읽는다
    sess['offset'] += end
    usage, big, tools = {}, [], sess.get('tools', {})
    for raw in data[:end].splitlines():
        try:
            e = json.loads(raw)
        except ValueError:
            continue
        if e.get('isSidechain'):
            continue
        m = e.get('message') or {}
        content = m.get('content') if isinstance(m.get('content'), list) else []
        if e.get('type') == 'assistant':
            for c in content:
                if c.get('type') == 'tool_use':
                    tools[c.get('id')] = c.get('name')
            if m.get('usage'):
                usage[m.get('id')] = (m['usage'], m.get('model'), e.get('timestamp'))
        elif e.get('type') == 'user':
            for c in content:
                if c.get('type') == 'tool_result':
                    size = len(json.dumps(c.get('content'), ensure_ascii=False))
                    if size >= BIG_CHARS:
                        big.append((tools.get(c.get('tool_use_id'), '?'), size, e.get('timestamp')))
    proj = os.path.basename((inp.get('cwd') or '').rstrip('/\\')) or '?'
    lines = []
    for u, model, ts in usage.values():
        ctx = u.get('input_tokens', 0) + u.get('cache_read_input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
        lines.append({'kind': 'turn', 'ts': ts or now_iso(), 'sid': sid[:8], 'proj': proj, 'model': model,
                      'ctx': ctx, 'out': u.get('output_tokens', 0), 'first': sess['turns'] == 0})
        sess['turns'] += 1
    for name, size, ts in big:
        lines.append({'kind': 'tool', 'ts': ts or now_iso(), 'sid': sid[:8], 'proj': proj, 'tool': name, 'chars': size})
    sess['tools'] = dict(list(tools.items())[-200:])   # 다음 번 결과 짝 맞추기용, 너무 커지지 않게
    sess['last'] = now_iso()
    state['sessions'][sid] = sess
    if lines:
        with open(REC, 'a', encoding='utf-8', newline='\n') as f:
            f.writelines(json.dumps(r, ensure_ascii=False) + '\n' for r in lines)
    today = datetime.date.today().isoformat()
    if state.get('pruned') != today:     # 하루 한 번 30일 지난 기록 정리
        keep = [r for r in read_records() if age_days(r.get('ts', '')) <= KEEP_DAYS]
        write_atomic(REC, ''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in keep))
        state['sessions'] = {k: v for k, v in state['sessions'].items() if age_days(v.get('last', '')) <= KEEP_DAYS}
        state['pruned'] = today
    write_atomic(STATE, json.dumps(state, ensure_ascii=False))
    render()


def median(values):
    v = sorted(values)
    n = len(v)
    return (v[n // 2] if n % 2 else (v[n // 2 - 1] + v[n // 2]) / 2) if n else 0


def starts(records):
    return sorted((r for r in records if r.get('kind') == 'turn' and r.get('first')), key=lambda r: r['ts'])


def check():
    s = starts(read_records())
    if len(s) < MIN_SESSIONS + 1:
        return
    latest, past = s[-1]['ctx'], [r['ctx'] for r in s[:-1]]
    med = median(past)
    if med and latest > med * ALERT_RATIO:
        print(f'[claude-config] 세션 시작 컨텍스트가 늘었습니다(최근 {latest:,}토큰, 30일 중앙값 {med:,.0f}토큰, '
              f'+{(latest / med - 1) * 100:.0f}%). 스킬·플러그인·MCP·CLAUDE.md가 늘었는지 /context로 확인하세요. '
              f'대시보드: {PAGE}')


def fmt(n):
    if n >= 1000000:
        return f'{n / 1000000:,.1f}M'
    return f'{n / 1000:,.1f}k' if n >= 1000 else str(n)


def svg_dots(points, w=720, h=220):
    """세션 시작 크기 추이: 선 + 점, 점마다 title 툴팁."""
    if not points:
        return '<p class="muted">아직 기록이 없습니다.</p>'
    pad_l, pad_b, pad_t = 56, 28, 12
    ymax = max(p[1] for p in points) * 1.1 or 1
    n = len(points)
    xs = [pad_l + (w - pad_l - 12) * (i / (n - 1) if n > 1 else 0.5) for i in range(n)]
    ys = [pad_t + (h - pad_t - pad_b) * (1 - v / ymax) for _, v in points]
    grid = ''.join(
        f'<line x1="{pad_l}" x2="{w - 12}" y1="{pad_t + (h - pad_t - pad_b) * k / 4:.1f}" y2="{pad_t + (h - pad_t - pad_b) * k / 4:.1f}" class="grid"/>'
        f'<text x="{pad_l - 8}" y="{pad_t + (h - pad_t - pad_b) * k / 4 + 4:.1f}" class="axis" text-anchor="end">{fmt(int(ymax * (1 - k / 4)))}</text>'
        for k in range(5))
    path = ' '.join(f'{"M" if i == 0 else "L"}{x:.1f},{y:.1f}' for i, (x, y) in enumerate(zip(xs, ys)))
    dots = ''.join(
        f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4" class="mark"><title>{html.escape(lab)} · {v:,}토큰</title></circle>'
        for x, y, (lab, v) in zip(xs, ys, points))
    return (f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="세션 시작 컨텍스트 추이">{grid}'
            f'<path d="{path}" class="line"/>{dots}</svg>')


def svg_bars(items, w=720, h=220):
    """세션별 누적 입력 토큰: 세로 막대, 막대마다 title 툴팁."""
    if not items:
        return '<p class="muted">아직 기록이 없습니다.</p>'
    pad_l, pad_b, pad_t = 56, 28, 12
    ymax = max(v for _, v in items) * 1.1 or 1
    n = len(items)
    slot = (w - pad_l - 12) / n
    bw = min(40, max(4, slot - 2))   # 세션이 적을 때 막대가 너무 넓어지지 않게
    grid = ''.join(
        f'<line x1="{pad_l}" x2="{w - 12}" y1="{pad_t + (h - pad_t - pad_b) * k / 4:.1f}" y2="{pad_t + (h - pad_t - pad_b) * k / 4:.1f}" class="grid"/>'
        f'<text x="{pad_l - 8}" y="{pad_t + (h - pad_t - pad_b) * k / 4 + 4:.1f}" class="axis" text-anchor="end">{fmt(int(ymax * (1 - k / 4)))}</text>'
        for k in range(5))
    bars = ''
    for i, (lab, v) in enumerate(items):
        bh = (h - pad_t - pad_b) * v / ymax
        x, y = pad_l + i * slot + 1, h - pad_b - bh
        bars += (f'<path d="M{x:.1f},{h - pad_b} V{y + 4:.1f} Q{x:.1f},{y:.1f} {x + 4:.1f},{y:.1f} H{x + bw - 4:.1f} '
                 f'Q{x + bw:.1f},{y:.1f} {x + bw:.1f},{y + 4:.1f} V{h - pad_b} Z" class="bar">'
                 f'<title>{html.escape(lab)} · {v:,}토큰</title></path>')
    return f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="세션별 누적 입력 토큰">{grid}{bars}</svg>'


def render():
    recs = [r for r in read_records() if age_days(r.get('ts', '')) <= KEEP_DAYS]
    s = starts(recs)[-60:]
    start_pts = [(f"{r['ts'][:16].replace('T', ' ')} {r['proj']}", r['ctx']) for r in s]
    per = {}
    for r in recs:
        if r.get('kind') == 'turn':
            p = per.setdefault(r['sid'], {'ts': r['ts'], 'proj': r['proj'], 'sum': 0, 'turns': 0})
            p['sum'] += r['ctx']
            p['turns'] += 1
    sessions = sorted(per.values(), key=lambda p: p['ts'])[-20:]
    sess_items = [(f"{p['ts'][:16].replace('T', ' ')} {p['proj']} ({p['turns']}턴)", p['sum']) for p in sessions]
    tools = sorted((r for r in recs if r.get('kind') == 'tool' and age_days(r['ts']) <= 7), key=lambda r: -r['chars'])[:15]
    med = median([r['ctx'] for r in s])
    latest = s[-1]['ctx'] if s else 0
    rows = ''.join(f"<tr><td>{html.escape(r['ts'][:16].replace('T', ' '))}</td><td>{html.escape(r['proj'])}</td>"
                   f"<td>{html.escape(str(r['tool']))}</td><td class='num'>{r['chars']:,}</td></tr>" for r in tools)
    start_rows = ''.join(f"<tr><td>{html.escape(lab)}</td><td class='num'>{v:,}</td></tr>" for lab, v in reversed(start_pts))
    page = f'''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta http-equiv="refresh" content="10">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>토큰 사용 기록</title><style>
:root{{--bg:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--grid:#e4e3df;--s1:#2a78d6}}
@media (prefers-color-scheme:dark){{:root{{--bg:#1a1a19;--ink:#fff;--ink2:#c3c2b7;--grid:#34332f;--s1:#3987e5}}}}
body{{margin:0;padding:16px;background:var(--bg);color:var(--ink);font:14px/1.5 system-ui,"Malgun Gothic",sans-serif;max-width:760px}}
h1{{font-size:18px;margin:0 0 4px}}h2{{font-size:15px;margin:24px 0 6px}}.muted{{color:var(--ink2)}}
.tiles{{display:flex;gap:12px;flex-wrap:wrap;margin:12px 0}}.tile{{border:1px solid var(--grid);border-radius:8px;padding:8px 12px}}
.tile b{{display:block;font-size:20px}}svg{{width:100%;height:auto}}.grid{{stroke:var(--grid);stroke-width:1}}
.axis{{fill:var(--ink2);font-size:11px}}.line{{fill:none;stroke:var(--s1);stroke-width:2}}
.mark{{fill:var(--s1);stroke:var(--bg);stroke-width:2}}.bar{{fill:var(--s1)}}
table{{border-collapse:collapse;width:100%}}td,th{{border-bottom:1px solid var(--grid);padding:4px 6px;text-align:left}}.num{{text-align:right}}
</style></head><body>
<h1>토큰 사용 기록</h1><p class="muted">최근 {KEEP_DAYS}일 · 세션 {len(per)}개 · 갱신 {html.escape(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))} · 10초마다 자동 새로고침</p>
<div class="tiles"><div class="tile">최근 세션 시작 크기<b>{latest:,}</b>토큰</div><div class="tile">30일 중앙값<b>{med:,.0f}</b>토큰</div></div>
<h2>세션 시작 컨텍스트 크기</h2><p class="muted">스킬·플러그인·MCP·CLAUDE.md가 늘면 올라간다. 점에 마우스를 올리면 값이 보인다.</p>{svg_dots(start_pts)}
<h2>세션별 누적 입력 토큰(최근 20개)</h2><p class="muted">턴마다 보낸 입력(캐시 포함)의 합. 대화가 길수록 커진다.</p>{svg_bars(sess_items)}
<h2>큰 도구 결과(최근 7일, {BIG_CHARS:,}자 이상)</h2>
<table><tr><th>시각(UTC)</th><th>프로젝트</th><th>도구</th><th class="num">글자 수</th></tr>{rows or '<tr><td colspan="4" class="muted">없음</td></tr>'}</table>
<details><summary>세션 시작 크기 표로 보기</summary><table><tr><th>세션</th><th class="num">토큰</th></tr>{start_rows}</table></details>
<p class="muted">서브에이전트 사용량은 포함하지 않는다(/usage 기여도로 확인). 이 페이지는 로컬 파일이며 토큰을 쓰지 않는다.</p>
</body></html>'''
    write_atomic(PAGE, page)


os.makedirs(BASE, exist_ok=True)
if MODE == 'check':
    check()
elif MODE == 'render':
    render()
else:
    try:
        collect(json.loads(sys.stdin.read() or '{}'))
    except Exception as e:   # 훅 실패가 세션을 방해하지 않게 조용히 기록만
        with open(os.path.join(BASE, 'error.log'), 'a', encoding='utf-8') as f:
            f.write(f'{now_iso()} {type(e).__name__}: {e}\n')
PY

case "${MODE}" in
  --check) PYTHONIOENCODING=utf-8 "${PY}" -c "${PROG}" check ;;
  --render) PYTHONIOENCODING=utf-8 "${PY}" -c "${PROG}" render ;;
  *) printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" -c "${PROG}" stop ;;
esac
exit 0
