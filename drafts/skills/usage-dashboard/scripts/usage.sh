#!/usr/bin/env bash
# 토큰 사용 기록·대시보드(Issue #136). usage-dashboard 스킬이 사용자 요청으로 부른다.
# 훅은 설정에 항상 등록돼 있어도 켜짐 표시 파일(usage-log/enabled)이 없으면 바로 끝난다.
# 설정 업데이트(install.sh)는 usage-log/를 건드리지 않으므로 기록이 유지된다.
# API를 부르지 않으므로 기록·조회에 토큰이 들지 않는다. 명령·파일 내용은 저장하지 않는다.
#
# 사용법: bash usage.sh <명령>
#   hook      Stop 훅(async 등록). 메인 기록과 그 세션의 서브에이전트 기록에서 새 줄만 읽는다
#   enable    켜기 — 남아 있는 대화 기록(기본 30일 보관)을 한 번 훑어 채우고 대시보드를 만든다
#   disable   끄기 — 표시 파일만 지운다(쌓인 기록은 남김)
#   open      대시보드를 다시 만들고 브라우저로 연다
#   render    대시보드만 다시 만든다
#   status    켜짐 여부와 기록 기간
#   check     세션 시작 크기가 중앙값보다 20% 넘게 늘었으면 한 줄 출력
# 저장: ${CLAUDE_CONFIG_DIR:-~/.claude}/usage-log/ (시험할 때는 USAGE_LOG_DIR, USAGE_PROJECTS_DIR로 바꾼다)
#   hourly.json  시간 단위 합계(메인/서브에이전트 종류별), 영구 보관
#   starts.jsonl 세션 시작 크기, 영구 보관
#   tools.jsonl  2만 자 넘는 도구 결과(도구 이름·크기만), 90일 보관
# 대상은 Windows·Mac(브라우저로 보는 화면). UI 없는 Linux 서버는 켜지 않는다(2026-09-27 결정).
set -u

HOME_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
LOG="${USAGE_LOG_DIR:-${HOME_DIR}/usage-log}"
MODE="${1:-hook}"

if [[ "${MODE}" == "hook" ]] && [[ ! -f "${LOG}/enabled" ]]; then
  cat >/dev/null
  exit 0
fi

# Windows는 python3가 스토어 별칭이라 느려(0.6초+) python을 먼저 쓴다. Mac·Linux는 python3만 있는 경우가 많다
PY="$(command -v python || command -v python3 || true)"
[[ -n "${PY}" ]] || { echo "python이 없습니다"; exit 1; }

# 훅 입력을 stdin으로 넘기므로 프로그램은 -c로 준다(heredoc을 python -로 넘기면 stdin을 뺏긴다)
read -r -d '' PROG <<'PY'
import datetime, glob, html, json, os, sys

MODE = sys.argv[1]
HOME = os.environ.get('CLAUDE_CONFIG_DIR') or os.path.expanduser('~/.claude')
BASE = os.environ.get('USAGE_LOG_DIR') or os.path.join(HOME, 'usage-log')
PROJECTS = os.environ.get('USAGE_PROJECTS_DIR') or os.path.join(HOME, 'projects')
HOURLY, STARTS, TOOLS = (os.path.join(BASE, n) for n in ('hourly.json', 'starts.jsonl', 'tools.jsonl'))
STATE, PAGE = os.path.join(BASE, 'state.json'), os.path.join(BASE, 'dashboard.html')
BIG_CHARS = 20000     # 이보다 큰 도구 결과만 기록
TOOL_DAYS = 90
ALERT_RATIO = 1.2     # 세션 시작 크기가 중앙값의 120%를 넘으면 알림
MIN_SESSIONS = 6


def parse_ts(ts):
    try:
        return datetime.datetime.fromisoformat(str(ts).replace('Z', '+00:00')).astimezone()
    except ValueError:
        return datetime.datetime.now().astimezone()


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


class Store:
    def __init__(self):
        self.state = load_json(STATE, {'files': {}, 'tools_pruned': ''})
        self.hourly = load_json(HOURLY, {})
        self.new_starts, self.new_tools = [], []

    def add_file(self, path, kind, sid, proj):
        """kind: 'main' 또는 'sub:<에이전트 종류>'. 지난번 읽은 곳 다음부터만 읽는다."""
        off = self.state['files'].get(path, 0)
        try:
            if os.path.getsize(path) < off:
                off = 0
            with open(path, 'rb') as f:
                f.seek(off)
                data = f.read()
        except OSError:
            return 0
        end = data.rfind(b'\n') + 1          # 쓰는 중인 마지막 줄은 다음에 읽는다
        self.state['files'][path] = off + end
        usage, names = {}, {}
        for raw in data[:end].splitlines():
            try:
                e = json.loads(raw)
            except ValueError:
                continue
            if kind == 'main' and e.get('isSidechain'):
                continue
            if proj == '?' and e.get('cwd'):
                proj = os.path.basename(e['cwd'].rstrip('/\\')) or '?'
            m = e.get('message') or {}
            content = m.get('content') if isinstance(m.get('content'), list) else []
            if e.get('type') == 'assistant':
                for c in content:
                    if c.get('type') == 'tool_use':
                        names[c.get('id')] = c.get('name')
                if m.get('usage'):
                    usage[m.get('id')] = (m['usage'], e.get('timestamp'))
            elif e.get('type') == 'user':
                for c in content:
                    if c.get('type') == 'tool_result':
                        size = len(json.dumps(c.get('content'), ensure_ascii=False))
                        if size >= BIG_CHARS:
                            self.new_tools.append({'ts': parse_ts(e.get('timestamp')).isoformat(timespec='minutes'),
                                                   'proj': proj, 'who': kind, 'tool': names.get(c.get('tool_use_id'), '?'),
                                                   'chars': size})
        first = off == 0
        for u, ts in usage.values():
            t = parse_ts(ts)
            b = self.hourly.setdefault(t.strftime('%Y-%m-%dT%H'), {}).setdefault(kind, {'turns': 0, 'in': 0, 'cache': 0, 'out': 0})
            b['turns'] += 1
            b['in'] += u.get('input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
            b['cache'] += u.get('cache_read_input_tokens', 0)
            b['out'] += u.get('output_tokens', 0)
            if kind == 'main' and first:
                first = False
                ctx = u.get('input_tokens', 0) + u.get('cache_creation_input_tokens', 0) + u.get('cache_read_input_tokens', 0)
                self.new_starts.append({'ts': t.isoformat(timespec='minutes'), 'sid': sid[:8], 'proj': proj, 'ctx': ctx})
        return len(usage)

    def add_session(self, transcript, sid, proj):
        n = self.add_file(transcript, 'main', sid, proj)
        for f in sorted(glob.glob(os.path.join(os.path.dirname(transcript), sid, 'subagents', 'agent-*.jsonl'))):
            meta = load_json(f[:-len('.jsonl')] + '.meta.json', {})
            n += self.add_file(f, 'sub:' + (meta.get('agentType') or '?'), sid, proj)
        return n

    def save(self):
        os.makedirs(BASE, exist_ok=True)
        write_atomic(HOURLY, json.dumps(self.hourly, ensure_ascii=False, sort_keys=True))
        for path, rows in ((STARTS, self.new_starts), (TOOLS, self.new_tools)):
            if rows:
                with open(path, 'a', encoding='utf-8', newline='\n') as f:
                    f.writelines(json.dumps(r, ensure_ascii=False) + '\n' for r in rows)
        today = datetime.date.today().isoformat()
        if self.state.get('tools_pruned') != today:   # 하루 한 번 90일 지난 도구 기록 정리
            cut = datetime.datetime.now().astimezone() - datetime.timedelta(days=TOOL_DAYS)
            keep = [r for r in read_jsonl(TOOLS) if parse_ts(r.get('ts')) >= cut]
            write_atomic(TOOLS, ''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in keep))
            self.state['tools_pruned'] = today
        write_atomic(STATE, json.dumps(self.state, ensure_ascii=False))


def median(values):
    v = sorted(values)
    n = len(v)
    return (v[n // 2] if n % 2 else (v[n // 2 - 1] + v[n // 2]) / 2) if n else 0


def check():
    s = sorted(read_jsonl(STARTS), key=lambda r: r['ts'])[-60:]
    if len(s) < MIN_SESSIONS + 1:
        return
    latest, med = s[-1]['ctx'], median([r['ctx'] for r in s[:-1]])
    if med and latest > med * ALERT_RATIO:
        print(f'[usage-dashboard] 세션 시작 컨텍스트가 늘었습니다(최근 {latest:,}토큰, 중앙값 {med:,.0f}토큰, '
              f'+{(latest / med - 1) * 100:.0f}%). 스킬·플러그인·MCP·CLAUDE.md가 늘었는지 /context로 확인하세요. 대시보드: {PAGE}')


def status():
    on = os.path.isfile(os.path.join(BASE, 'enabled'))
    hours = sorted(load_json(HOURLY, {}))
    span = f'{hours[0][:10]} ~ {hours[-1][:10]}' if hours else '기록 없음'
    print(f"{'켜짐' if on else '꺼짐'} · 기록 기간 {span} · 대시보드 {PAGE}")


def render():
    hourly = load_json(HOURLY, {})
    starts = sorted(read_jsonl(STARTS), key=lambda r: r['ts'])[-60:]
    now = datetime.datetime.now().astimezone()
    tools = sorted((r for r in read_jsonl(TOOLS) if parse_ts(r['ts']) >= now - datetime.timedelta(days=7)),
                   key=lambda r: -r['chars'])[:15]
    agents = {}
    for hour, kinds in hourly.items():
        if hour >= (now - datetime.timedelta(days=30)).strftime('%Y-%m-%dT%H'):
            for kind, b in kinds.items():
                a = agents.setdefault(kind, {'turns': 0, 'total': 0})
                a['turns'] += b['turns']
                a['total'] += b['in'] + b['cache'] + b['out']
    agent_rows = ''.join(
        f"<tr><td>{'메인 대화' if k == 'main' else html.escape(k[4:]) + ' (서브에이전트)'}</td>"
        f"<td class='num'>{v['turns']:,}</td><td class='num'>{v['total']:,}</td></tr>"
        for k, v in sorted(agents.items(), key=lambda kv: -kv[1]['total']))
    tool_rows = ''.join(
        f"<tr><td>{html.escape(r['ts'][:16].replace('T', ' '))}</td><td>{html.escape(r['proj'])}</td>"
        f"<td>{html.escape(r['who'] if r['who'] == 'main' else r['who'][4:])}</td><td>{html.escape(str(r['tool']))}</td>"
        f"<td class='num'>{r['chars']:,}</td></tr>" for r in tools)
    data = json.dumps({'hourly': hourly, 'starts': starts}, ensure_ascii=False).replace('</', '<\\/')
    med = median([r['ctx'] for r in starts])
    latest = starts[-1]['ctx'] if starts else 0
    first_hour = min(hourly) if hourly else ''
    page = PAGE_TEMPLATE.replace('__DATA__', data).replace('__AGENTS__', agent_rows or '<tr><td colspan="3" class="muted">없음</td></tr>') \
        .replace('__TOOLS__', tool_rows or '<tr><td colspan="5" class="muted">없음</td></tr>') \
        .replace('__LATEST__', f'{latest:,}').replace('__MEDIAN__', f'{med:,.0f}') \
        .replace('__SINCE__', html.escape(first_hour[:10] or '기록 없음')) \
        .replace('__UPDATED__', now.strftime('%Y-%m-%d %H:%M:%S'))
    os.makedirs(BASE, exist_ok=True)
    write_atomic(PAGE, page)


PAGE_TEMPLATE = r'''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta http-equiv="refresh" content="10">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>토큰 사용 기록</title><style>
:root{--bg:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--grid:#e4e3df;--s1:#2a78d6;--s2:#eb6834}
@media (prefers-color-scheme:dark){:root{--bg:#1a1a19;--ink:#fff;--ink2:#c3c2b7;--grid:#34332f;--s1:#3987e5;--s2:#d95926}}
body{margin:0;padding:16px;background:var(--bg);color:var(--ink);font:14px/1.5 system-ui,"Malgun Gothic","Apple SD Gothic Neo",sans-serif;max-width:820px}
h1{font-size:18px;margin:0 0 4px}h2{font-size:15px;margin:24px 0 6px}.muted{color:var(--ink2)}
.tiles{display:flex;gap:12px;flex-wrap:wrap;margin:12px 0}.tile{border:1px solid var(--grid);border-radius:8px;padding:8px 12px}.tile b{display:block;font-size:20px}
.tabs button{font:inherit;border:1px solid var(--grid);background:none;color:var(--ink);border-radius:6px;padding:4px 10px;margin-right:6px;cursor:pointer}
.tabs button[aria-pressed=true]{border-color:var(--s1);color:var(--s1);font-weight:600}
.legend{display:flex;gap:14px;margin:6px 0;color:var(--ink2)}.sw{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:4px}
svg{width:100%;height:auto}.grid{stroke:var(--grid)}.axis{fill:var(--ink2);font-size:11px}
.line{fill:none;stroke:var(--s1);stroke-width:2}.dot{fill:var(--s1);stroke:var(--bg);stroke-width:2}
table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid var(--grid);padding:4px 6px;text-align:left}.num{text-align:right}
</style></head><body>
<h1>토큰 사용 기록</h1>
<p class="muted">기록 시작 __SINCE__ · 갱신 __UPDATED__ · 10초마다 자동 새로고침 · 로컬 파일이라 보는 데 토큰이 들지 않음</p>
<div class="tiles"><div class="tile">최근 세션 시작 크기<b>__LATEST__</b>토큰</div><div class="tile">세션 시작 크기 중앙값<b>__MEDIAN__</b>토큰</div></div>
<h2>사용량</h2>
<div class="tabs"><button data-v="hour">시간별(48시간)</button><button data-v="day">일별(60일)</button><button data-v="month">월별(전체)</button></div>
<div class="legend"><span><i class="sw" style="background:var(--s1)"></i>메인 대화</span><span><i class="sw" style="background:var(--s2)"></i>서브에이전트</span></div>
<div id="usage"></div>
<p class="muted">막대 = 보낸 입력(캐시 재사용 포함) + 출력. 막대에 마우스를 올리면 값이 보인다.</p>
<details><summary>표로 보기</summary><table id="usage-table"></table></details>
<h2>세션 시작 컨텍스트 크기</h2><p class="muted">스킬·플러그인·MCP·CLAUDE.md가 늘면 올라간다.</p><div id="starts"></div>
<h2>최근 30일 누가 썼나</h2><table><tr><th>대상</th><th class="num">턴</th><th class="num">토큰</th></tr>__AGENTS__</table>
<h2>큰 도구 결과(최근 7일, 2만 자 이상)</h2>
<table><tr><th>시각</th><th>프로젝트</th><th>누가</th><th>도구</th><th class="num">글자 수</th></tr>__TOOLS__</table>
<script>
const D=__DATA__, NS='http://www.w3.org/2000/svg';
const fmt=n=>n>=1e9?(n/1e9).toFixed(1)+'B':n>=1e6?(n/1e6).toFixed(1)+'M':n>=1e3?(n/1e3).toFixed(1)+'k':String(n);
function el(t,a,p){const e=document.createElementNS(NS,t);for(const k in a)e.setAttribute(k,a[k]);if(p)p.appendChild(e);return e}
function series(view){
  const m={}, now=new Date();
  for(const [h,kinds] of Object.entries(D.hourly)){
    const key=view==='hour'?h:view==='day'?h.slice(0,10):h.slice(0,7);
    const r=m[key]||(m[key]={main:0,sub:0});
    for(const [k,b] of Object.entries(kinds)){const t=b.in+b.cache+b.out; if(k==='main')r.main+=t; else r.sub+=t}
  }
  let keys=Object.keys(m).sort();
  const pad=n=>String(n).padStart(2,'0');
  if(view==='hour'){const c=new Date(now-48*3600e3);const lo=`${c.getFullYear()}-${pad(c.getMonth()+1)}-${pad(c.getDate())}T${pad(c.getHours())}`;keys=keys.filter(k=>k>=lo)}
  if(view==='day'){const c=new Date(now-60*864e5);const lo=`${c.getFullYear()}-${pad(c.getMonth()+1)}-${pad(c.getDate())}`;keys=keys.filter(k=>k>=lo)}
  return keys.map(k=>({k,...m[k]}));
}
function bars(rows,box){
  box.innerHTML='';const W=780,H=240,L=56,B=30,T=10;
  if(!rows.length){box.innerHTML='<p class="muted">이 기간 기록이 없습니다.</p>';return}
  const max=Math.max(...rows.map(r=>r.main+r.sub))*1.1||1, s=el('svg',{viewBox:`0 0 ${W} ${H}`,role:'img','aria-label':'기간별 토큰 사용량'},box);
  for(let i=0;i<=4;i++){const y=T+(H-T-B)*i/4;el('line',{x1:L,x2:W-8,y1:y,y2:y,class:'grid'},s);const t=el('text',{x:L-8,y:y+4,class:'axis','text-anchor':'end'},s);t.textContent=fmt(max*(1-i/4))}
  const slot=(W-L-8)/rows.length,bw=Math.min(36,Math.max(3,slot-2)),step=Math.ceil(rows.length/8);
  rows.forEach((r,i)=>{const x=L+i*slot+(slot-bw)/2;let y=H-B;
    [['main','var(--s1)'],['sub','var(--s2)']].forEach(([k,c])=>{const h=(H-T-B)*r[k]/max;if(h<=0)return;y-=h;
      const rect=el('rect',{x,y:y+ (k==='sub'?0:0),width:bw,height:Math.max(0,h-(k==='sub'?2:0)),fill:c,rx:k==='sub'||!r.sub?3:0},s);
      el('title',{},rect).textContent=`${r.k} · ${k==='main'?'메인':'서브에이전트'} ${r[k].toLocaleString()}토큰`});
    if(i%step===0){const t=el('text',{x:x+bw/2,y:H-10,class:'axis','text-anchor':'middle'},s);t.textContent=r.k.length>10?r.k.slice(5).replace('T',' ')+'시':r.k.slice(r.k.length>7?5:0)}});
}
function table(rows){document.getElementById('usage-table').innerHTML='<tr><th>기간</th><th class="num">메인</th><th class="num">서브에이전트</th></tr>'+
  rows.slice().reverse().map(r=>`<tr><td>${r.k}</td><td class="num">${r.main.toLocaleString()}</td><td class="num">${r.sub.toLocaleString()}</td></tr>`).join('')}
function starts(){const box=document.getElementById('starts'),P=D.starts;if(!P.length){box.innerHTML='<p class="muted">아직 기록이 없습니다.</p>';return}
  const W=780,H=200,L=56,B=16,T=10,max=Math.max(...P.map(p=>p.ctx))*1.1,s=el('svg',{viewBox:`0 0 ${W} ${H}`,role:'img','aria-label':'세션 시작 크기 추이'},box);
  for(let i=0;i<=4;i++){const y=T+(H-T-B)*i/4;el('line',{x1:L,x2:W-8,y1:y,y2:y,class:'grid'},s);const t=el('text',{x:L-8,y:y+4,class:'axis','text-anchor':'end'},s);t.textContent=fmt(max*(1-i/4))}
  const xs=P.map((p,i)=>L+(W-L-16)*(P.length>1?i/(P.length-1):.5)),ys=P.map(p=>T+(H-T-B)*(1-p.ctx/max));
  el('path',{d:xs.map((x,i)=>(i?'L':'M')+x+','+ys[i]).join(' '),class:'line'},s);
  P.forEach((p,i)=>{const c=el('circle',{cx:xs[i],cy:ys[i],r:4,class:'dot'},s);el('title',{},c).textContent=`${p.ts.slice(0,16).replace('T',' ')} ${p.proj} · ${p.ctx.toLocaleString()}토큰`})}
function show(v){document.querySelectorAll('.tabs button').forEach(b=>b.setAttribute('aria-pressed',b.dataset.v===v));const r=series(v);bars(r,document.getElementById('usage'));table(r);location.hash=v}
document.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>show(b.dataset.v));
show((location.hash||'#day').slice(1));starts();
</script></body></html>'''

os.makedirs(BASE, exist_ok=True)
if MODE == 'hook':
    try:
        inp = json.loads(sys.stdin.read() or '{}')
        st = Store()
        if inp.get('transcript_path') and os.path.isfile(inp['transcript_path']):
            st.add_session(inp['transcript_path'], inp.get('session_id') or '?',
                           os.path.basename((inp.get('cwd') or '').rstrip('/\\')) or '?')
            st.save()
            render()
    except Exception as e:   # 훅 실패가 세션을 방해하지 않게 조용히 기록만
        with open(os.path.join(BASE, 'error.log'), 'a', encoding='utf-8') as f:
            f.write(f'{datetime.datetime.now().isoformat()} {type(e).__name__}: {e}\n')
elif MODE == 'backfill':
    st, n, files = Store(), 0, 0
    for tp in sorted(glob.glob(os.path.join(PROJECTS, '*', '*.jsonl'))):
        n += st.add_session(tp, os.path.basename(tp)[:-len('.jsonl')], '?')
        files += 1
    st.save()
    render()
    hours = sorted(st.hourly)
    print(f'채움: 대화 기록 {files}개, 응답 {n:,}건, 기간 {hours[0][:10] if hours else "-"} ~ {hours[-1][:10] if hours else "-"}')
elif MODE == 'render':
    render()
elif MODE == 'check':
    check()
elif MODE == 'status':
    status()
PY

run_py() { PYTHONIOENCODING=utf-8 "${PY}" -c "${PROG}" "$@"; }

case "${MODE}" in
  hook) run_py hook ;;
  enable)
    if [[ "$(uname -s)" == "Linux" ]]; then
      echo "Linux 서버는 대상이 아닙니다(화면 없이 쓰는 환경, 2026-09-27 결정). /usage로 확인하세요."
      exit 1
    fi
    mkdir -p "${LOG}" && : > "${LOG}/enabled"
    echo "켜짐. 남아 있는 대화 기록을 훑는 중(처음 한 번, 수십 초 걸릴 수 있음)..."
    run_py backfill
    echo "대시보드: ${LOG}/dashboard.html"
    ;;
  disable) rm -f "${LOG}/enabled"; echo "꺼짐. 쌓인 기록은 ${LOG}에 그대로 있습니다." ;;
  open)
    run_py render
    page="${LOG}/dashboard.html"
    case "$(uname -s)" in
      Darwin) open "${page}" ;;
      MINGW*|MSYS*|CYGWIN*) cmd.exe //c start "" "$(cygpath -w "${page}")" ;;
      *) echo "브라우저로 여세요: ${page}" ;;
    esac
    ;;
  render|check|status|backfill) run_py "${MODE}" ;;
  *) echo "사용법: bash usage.sh hook|enable|disable|open|render|status|check"; exit 2 ;;
esac
exit 0
