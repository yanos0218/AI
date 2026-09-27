#!/usr/bin/env bash
# 토큰 사용 기록·대시보드(Issue #136). usage-dashboard 스킬이 사용자 요청으로 부른다.
# 훅은 설정에 항상 등록돼 있어도 켜짐 표시 파일(usage-log/enabled)이 없으면 바로 끝난다.
# 설정 업데이트(install.sh)는 usage-log/를 건드리지 않으므로 기록이 유지된다.
# API를 부르지 않으므로 기록·조회에 토큰이 들지 않는다. 명령·파일 내용은 저장하지 않는다.
#
# 사용법: bash usage.sh <명령>
#   hook      Stop 훅(async 등록). 메인 기록과 그 세션의 서브에이전트 기록에서 새 줄만 읽는다
#   enable    켜기 — 남아 있는 대화 기록(기본 30일 보관)을 훑어 채우고 대시보드를 만든다(다시 실행하면 새 부분만)
#   disable   끄기 — 표시 파일만 지운다(쌓인 기록은 남김)
#   open      대시보드를 다시 만들고 브라우저로 연다
#   render    대시보드만 다시 만든다
#   status    켜짐 여부와 기록 기간
#   check     세션 시작 크기가 중앙값보다 20% 넘게 늘었으면 한 줄 출력
# 저장: ${CLAUDE_CONFIG_DIR:-~/.claude}/usage-log/ (시험할 때는 USAGE_LOG_DIR, USAGE_PROJECTS_DIR로 바꾼다)
#   hourly.json  시간 단위 합계(누가·모델별), 영구 보관
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

# 세션 여러 개가 동시에 끝나면 훅도 동시에 돈다. 합계 파일을 읽고-고치고-쓰는 사이에 서로 덮어쓰지 않게
# mkdir 잠금으로 한 번에 하나만 쓰게 한다(gh-throttle.sh와 같은 방식). 1분 넘은 잠금은 죽은 것으로 보고 치운다.
LOCK="${LOG}/.lock"
lock() {
  mkdir -p "${LOG}"
  local i=0
  until mkdir "${LOCK}" 2>/dev/null; do
    if [[ -n "$(find "${LOCK}" -maxdepth 0 -mmin +1 2>/dev/null)" ]]; then rmdir "${LOCK}" 2>/dev/null; continue; fi
    i=$((i + 1))
    [[ "${i}" -gt 150 ]] && return 1
    sleep 0.2
  done
  trap 'rmdir "${LOCK}" 2>/dev/null' EXIT
}

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


def load_hourly():
    """hour → kind → model → 합계. 모델 구분 전(2026-09-27 이전 초안) 기록은 model 'other'로 옮긴다."""
    h = load_json(HOURLY, {})
    for kinds in h.values():
        for kind, v in list(kinds.items()):
            if 'turns' in v:
                kinds[kind] = {'other': v}
    return h


class Store:
    def __init__(self):
        self.state = load_json(STATE, {'files': {}, 'tools_pruned': ''})
        self.hourly = load_hourly()
        self.new_starts, self.new_tools = [], []

    def add_file(self, path, kind, sid, proj):
        """kind: 'main' 또는 'sub:<에이전트 종류>'. 지난번 읽은 곳 다음부터만 읽는다."""
        off = self.state['files'].get(path, 0)
        try:
            size = os.path.getsize(path)
            if size < off:                 # 파일이 줄었으면 처음부터 다시 세지 않고(이중 집계 방지) 끝부터 잇는다
                self.state['files'][path] = size
                return 0
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
                    usage[m.get('id')] = (m['usage'], m.get('model'), e.get('timestamp'))
            elif e.get('type') == 'user':
                for c in content:
                    if c.get('type') == 'tool_result':
                        size = len(json.dumps(c.get('content'), ensure_ascii=False))
                        if size >= BIG_CHARS:
                            self.new_tools.append({'ts': parse_ts(e.get('timestamp')).isoformat(timespec='minutes'),
                                                   'proj': proj, 'who': kind, 'tool': names.get(c.get('tool_use_id'), '?'),
                                                   'chars': size})
        first = off == 0
        for u, model, ts in usage.values():
            if model == '<synthetic>':
                continue
            t = parse_ts(ts)
            b = self.hourly.setdefault(t.strftime('%Y-%m-%dT%H'), {}).setdefault(kind, {}) \
                .setdefault(family(model), {'turns': 0, 'in': 0, 'cache': 0, 'out': 0})
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
        if self.state.get('tools_pruned') != today:   # 하루 한 번: 90일 지난 도구 기록, 지워진 대화 기록의 읽기 위치 정리
            cut = datetime.datetime.now().astimezone() - datetime.timedelta(days=TOOL_DAYS)
            keep = [r for r in read_jsonl(TOOLS) if parse_ts(r.get('ts')) >= cut]
            write_atomic(TOOLS, ''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in keep))
            self.state['files'] = {p: o for p, o in self.state['files'].items() if os.path.isfile(p)}
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
    now = datetime.datetime.now().astimezone()
    tools = sorted((r for r in read_jsonl(TOOLS) if parse_ts(r['ts']) >= now - datetime.timedelta(days=7)),
                   key=lambda r: -r['chars'])[:15]
    data = {'hourly': load_hourly(), 'starts': sorted(read_jsonl(STARTS), key=lambda r: r['ts'])[-60:],
            'tools': tools, 'updated': now.isoformat(timespec='seconds'),
            'enabled': os.path.isfile(os.path.join(BASE, 'enabled'))}
    blob = json.dumps(data, ensure_ascii=False).replace('</', '<\\/')
    os.makedirs(BASE, exist_ok=True)
    write_atomic(PAGE, PAGE_TEMPLATE.replace('__DATA__', blob))


PAGE_TEMPLATE = r'''<!doctype html><html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>토큰 사용 기록</title><style>
:root{--bg:#f6f6f4;--card:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--ink3:#8a8984;--line:#e4e3df;--hover:#eeede9;--accent:#2a78d6;
--c0:#2a78d6;--c1:#eb6834;--c2:#1baf7a;--c3:#eda100;--c4:#e87ba4}
@media (prefers-color-scheme:dark){:root{--bg:#121211;--card:#1a1a19;--ink:#fff;--ink2:#c3c2b7;--ink3:#8f8e87;--line:#34332f;--hover:#262624;--accent:#3987e5;
--c0:#3987e5;--c1:#d95926;--c2:#199e70;--c3:#c98500;--c4:#d55181}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.5 system-ui,"Malgun Gothic","Apple SD Gothic Neo",sans-serif}
main{max-width:1040px;margin:0 auto;padding:20px 16px 40px}
header{display:flex;justify-content:space-between;align-items:flex-end;gap:12px;flex-wrap:wrap;margin-bottom:14px}
h1{font-size:20px;margin:0}.sub{color:var(--ink2);font-size:13px}.muted{color:var(--ink3)}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;margin-bottom:14px}
.card h2{font-size:15px;margin:0 0 2px}.card p.desc{margin:0 0 10px;color:var(--ink2);font-size:13px}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin-bottom:14px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px 14px}
.kpi .l{color:var(--ink2);font-size:12px}.kpi .v{font-size:22px;font-weight:650;margin-top:2px;font-variant-numeric:tabular-nums}.kpi .s{color:var(--ink3);font-size:12px}
.kpi.warn{border-color:#eda100}.kpi.warn .s{color:var(--ink)}
.bar{display:flex;flex-wrap:wrap;gap:8px 16px;align-items:center;margin-bottom:10px}
.seg{display:inline-flex;border:1px solid var(--line);border-radius:8px;overflow:hidden}
.seg button{font:inherit;font-size:13px;border:0;background:none;color:var(--ink2);padding:5px 11px;cursor:pointer}
.seg button+button{border-left:1px solid var(--line)}.seg button[aria-pressed=true]{background:var(--accent);color:#fff}
.seg button:focus-visible{outline:2px solid var(--accent);outline-offset:-2px}
.lab{color:var(--ink3);font-size:12px;margin-right:6px}
.legend{display:flex;gap:14px;flex-wrap:wrap;font-size:13px;color:var(--ink2);margin:2px 0 6px}
.legend i{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:5px;vertical-align:-1px}
svg{display:block;width:100%;height:auto;overflow:visible}.grid{stroke:var(--line)}.axis{fill:var(--ink3);font-size:11px}
.col:hover .hl{fill:var(--hover)}.col:focus{outline:none}.col:focus .hl{fill:var(--hover)}
.medline{stroke:var(--ink3);stroke-dasharray:4 4}.sline{fill:none;stroke:var(--c0);stroke-width:2}
#tip{position:fixed;pointer-events:none;background:var(--card);border:1px solid var(--line);border-radius:8px;padding:8px 10px;
box-shadow:0 4px 16px rgba(0,0,0,.12);font-size:12px;min-width:170px;display:none;z-index:9}
#tip .t{color:var(--ink2);margin-bottom:4px}#tip .r{display:flex;align-items:center;gap:8px;justify-content:space-between}
#tip .r b{font-variant-numeric:tabular-nums}#tip .k{display:inline-block;width:12px;height:2px;margin-right:6px;vertical-align:3px}
#tip .tot{border-top:1px solid var(--line);margin-top:4px;padding-top:4px}
table{border-collapse:collapse;width:100%;font-size:13px}th{color:var(--ink2);font-weight:500;text-align:left}
td,th{border-bottom:1px solid var(--line);padding:6px 6px}.num{text-align:right;font-variant-numeric:tabular-nums}
.share{display:inline-block;height:6px;border-radius:3px;background:var(--c0);vertical-align:1px;margin-right:6px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:14px}@media (max-width:760px){.two{grid-template-columns:1fr}}
details summary{cursor:pointer;color:var(--ink2);font-size:13px;margin-top:8px}.empty{color:var(--ink3);padding:24px 0;text-align:center}
.off{background:#fff4d6;color:#5a4300;border-radius:8px;padding:8px 12px;margin-bottom:14px;font-size:13px}
@media (prefers-color-scheme:dark){.off{background:#3a2f10;color:#f3dfa3}}
</style></head><body><main>
<header><div><h1>토큰 사용 기록</h1><div class="sub" id="meta"></div></div>
<label class="sub"><input type="checkbox" id="auto"> 30초마다 자동 새로고침</label></header>
<div id="offnote"></div>
<section class="kpis" id="kpis"></section>
<section class="card"><h2>사용량</h2><p class="desc">막대에 마우스를 올리거나 Tab으로 이동하면 자세한 값이 보입니다.</p>
<div class="bar">
<span><span class="lab">기간</span><span class="seg" data-k="view"><button data-v="hour">시간별 48시간</button><button data-v="day">일별 60일</button><button data-v="month">월별 전체</button></span></span>
<span><span class="lab">기준</span><span class="seg" data-k="metric"><button data-v="all">전체</button><button data-v="nocache">캐시 제외</button></span></span>
<span><span class="lab">나눠 보기</span><span class="seg" data-k="split"><button data-v="who">누가</button><button data-v="model">모델</button></span></span>
</div>
<div class="legend" id="legend"></div><div id="chart"></div>
<p class="desc" id="metricnote" style="margin-top:8px"></p>
<details><summary>표로 보기</summary><div id="tbl"></div></details></section>
<div class="two">
<section class="card"><h2>최근 30일 누가 썼나</h2><p class="desc">서브에이전트는 종류별로 나눔</p><div id="who30"></div></section>
<section class="card"><h2>최근 30일 모델별</h2><p class="desc">같은 토큰이라도 모델마다 요금이 다름</p><div id="model30"></div></section>
</div>
<section class="card"><h2>세션 시작 크기</h2><p class="desc">아무 일도 하기 전 기본으로 싣는 양. 스킬·플러그인·MCP·CLAUDE.md가 늘면 올라갑니다. 점선은 중앙값.</p><div id="starts"></div></section>
<section class="card"><h2>큰 도구 결과 (최근 7일, 2만 자 이상)</h2><p class="desc">자주 보이는 도구는 출력을 줄이거나(요약·필터) 서브에이전트로 넘기면 절약됩니다.</p><div id="tools"></div></section>
<p class="muted" style="font-size:12px">로컬 파일이라 이 화면을 보는 데 토큰이 들지 않습니다. 기기마다 따로 쌓이며, 계정 전체 한도는 /usage에서 보세요.</p>
</main><div id="tip" role="status" aria-live="polite"></div>
<script>
const D=__DATA__;
const $=s=>document.querySelector(s), NS='http://www.w3.org/2000/svg';
const FAM=['opus','sonnet','haiku','fable','other'], FAMN={opus:'Opus',sonnet:'Sonnet',haiku:'Haiku',fable:'Fable',other:'기타'};
const pad=n=>String(n).padStart(2,'0');
const kHour=d=>`${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}`;
function ko(n){n=Math.round(n);if(n>=1e8)return(n/1e8).toFixed(n>=1e9?0:1)+'억';if(n>=1e4)return(n/1e4).toFixed(n>=1e5?0:1)+'만';return n.toLocaleString()}
function el(t,a,p){const e=document.createElementNS(NS,t);for(const k in a)e.setAttribute(k,a[k]);if(p)p.appendChild(e);return e}
function h(t,cls,txt){const e=document.createElement(t);if(cls)e.className=cls;if(txt!=null)e.textContent=txt;return e}
let S={view:'day',metric:'all',split:'who'};
try{const [v,m,s]=(location.hash.slice(1)||'').split(',');if(v)S={view:v,metric:m||'all',split:s||'who'}}catch(e){}
const val=b=>S.metric==='all'?b.in+b.cache+b.out:b.in+b.out;
function seriesKeys(){if(S.split==='who')return[['main','메인 대화'],['sub','서브에이전트']];
  const used=new Set();for(const k in D.hourly)for(const kind in D.hourly[k])for(const f in D.hourly[k][kind])used.add(f);
  return FAM.filter(f=>used.has(f)).map(f=>[f,FAMN[f]])}
function colorOf(key){if(S.split==='who')return key==='main'?'var(--c0)':'var(--c1)';return `var(--c${FAM.indexOf(key)})`}
function bucketKey(hk){return S.view==='hour'?hk:S.view==='day'?hk.slice(0,10):hk.slice(0,7)}
function periodKeys(){const now=new Date(),out=[];
  if(S.view==='hour'){for(let i=47;i>=0;i--)out.push(kHour(new Date(now-i*36e5)))}
  else if(S.view==='day'){for(let i=59;i>=0;i--)out.push(kHour(new Date(now-i*864e5)).slice(0,10))}
  else{const ks=Object.keys(D.hourly).sort();const st=ks.length?new Date(ks[0].slice(0,7)+'-01T00:00'):now;
    for(let d=new Date(st.getFullYear(),st.getMonth(),1);d<=now;d=new Date(d.getFullYear(),d.getMonth()+1,1))out.push(`${d.getFullYear()}-${pad(d.getMonth()+1)}`)}
  return out}
function rows(){const keys=periodKeys(),m=Object.fromEntries(keys.map(k=>[k,{}]));
  for(const hk in D.hourly){const bk=bucketKey(hk);if(!m[bk])continue;
    for(const kind in D.hourly[hk])for(const f in D.hourly[hk][kind]){const s=S.split==='who'?(kind==='main'?'main':'sub'):f;
      m[bk][s]=(m[bk][s]||0)+val(D.hourly[hk][kind][f])}}
  return keys.map(k=>({k,v:m[k]}))}
function label(k,short){if(k.length===13){const d=k.slice(5,10).replace('-','/');return short?`${+k.slice(11)}시`:`${d} ${+k.slice(11)}시`}
  if(k.length===10)return `${+k.slice(5,7)}/${+k.slice(8)}`;return `${k.slice(0,4)}년 ${+k.slice(5)}월`}
const tip=$('#tip');
function showTip(ev,title,items){tip.replaceChildren();tip.appendChild(h('div','t',title));let tot=0;
  items.forEach(([name,v,c])=>{tot+=v;const r=h('div','r');const l=h('span');const k=h('i','k');k.style.background=c;l.append(k,document.createTextNode(name));r.append(l,h('b',null,ko(v)));tip.appendChild(r)});
  if(items.length>1){const r=h('div','r tot');r.append(h('span',null,'합계'),h('b',null,ko(tot)));tip.appendChild(r)}
  tip.style.display='block';const x=ev.clientX??ev.target.getBoundingClientRect().left,y=ev.clientY??ev.target.getBoundingClientRect().top;
  const w=tip.offsetWidth,H=tip.offsetHeight;tip.style.left=Math.min(innerWidth-w-8,x+14)+'px';tip.style.top=Math.max(8,y-H-10)+'px'}
function hideTip(){tip.style.display='none'}
function axes(s,W,H,L,T,B,max){for(let i=0;i<=4;i++){const y=T+(H-T-B)*i/4;el('line',{x1:L,x2:W,y1:y,y2:y,class:'grid'},s);
  const t=el('text',{x:L-8,y:y+4,class:'axis','text-anchor':'end'},s);t.textContent=ko(max*(1-i/4))}}
function chart(){const box=$('#chart'),R=rows(),K=seriesKeys();box.replaceChildren();
  const lg=$('#legend');lg.replaceChildren();K.forEach(([k,n])=>{const s=h('span');const i=h('i');i.style.background=colorOf(k);s.append(i,document.createTextNode(n));lg.appendChild(s)});
  const total=R.reduce((a,r)=>a+Object.values(r.v).reduce((x,y)=>x+y,0),0);
  if(!total){box.appendChild(h('div','empty','이 기간에는 기록이 없습니다.'));table(R,K);return}
  const W=Math.max(320,box.clientWidth),H=260,L=48,T=8,B=26,max=Math.max(...R.map(r=>Object.values(r.v).reduce((a,b)=>a+b,0)))*1.08;
  const s=el('svg',{viewBox:`0 0 ${W} ${H}`,role:'img','aria-label':'기간별 토큰 사용량'},box);axes(s,W,H,L,T,B,max);
  const slot=(W-L)/R.length,bw=Math.max(2,Math.min(28,slot*.7)),step=Math.ceil(R.length/Math.max(4,Math.floor((W-L)/70)));
  R.forEach((r,i)=>{const g=el('g',{class:'col',tabindex:0},s),x0=L+i*slot;el('rect',{x:x0,y:T,width:slot,height:H-T-B,fill:'transparent',class:'hl',rx:4},g);
    let y=H-B;const segs=K.filter(([k])=>r.v[k]>0);segs.forEach(([k],j)=>{const hh=(H-T-B)*r.v[k]/max;y-=hh;const gap=j<segs.length-1?1:0;
      const top=j===segs.length-1,x=x0+(slot-bw)/2,y1=y+gap,hv=Math.max(0,hh-gap),rad=top?Math.min(3,hv):0;
      el('path',{d:`M${x},${y1+hv} V${y1+rad} Q${x},${y1} ${x+rad},${y1} H${x+bw-rad} Q${x+bw},${y1} ${x+bw},${y1+rad} V${y1+hv} Z`,fill:colorOf(k)},g)});
    const items=K.map(([k,n])=>[n,r.v[k]||0,colorOf(k)]),title=label(r.k);
    g.addEventListener('pointermove',e=>showTip(e,title,items));g.addEventListener('pointerleave',hideTip);
    g.addEventListener('focus',e=>showTip(e,title,items));g.addEventListener('blur',hideTip);
    if(i%step===0||i===R.length-1&&R.length<15){const t=el('text',{x:x0+slot/2,y:H-8,class:'axis','text-anchor':'middle'},s);t.textContent=label(r.k,S.view==='hour'&&!r.k.endsWith('T00'))}});
  table(R,K)}
function table(R,K){const t=h('table'),hd=h('tr');hd.appendChild(h('th',null,'기간'));K.forEach(([,n])=>hd.appendChild(h('th','num',n)));hd.appendChild(h('th','num','합계'));t.appendChild(hd);
  R.slice().reverse().forEach(r=>{const tot=Object.values(r.v).reduce((a,b)=>a+b,0);if(!tot)return;const tr=h('tr');tr.appendChild(h('td',null,label(r.k)));
    K.forEach(([k])=>tr.appendChild(h('td','num',(r.v[k]||0).toLocaleString())));tr.appendChild(h('td','num',tot.toLocaleString()));t.appendChild(tr)});
  $('#tbl').replaceChildren(t)}
function sumSince(from,groupFn){const out={};for(const hk in D.hourly){if(hk<from)continue;for(const kind in D.hourly[hk])for(const f in D.hourly[hk][kind]){const g=groupFn(kind,f);out[g]=(out[g]||0)+val(D.hourly[hk][kind][f])}}return out}
function shareTable(id,obj,nameFn,colorFn){const box=$(id);box.replaceChildren();const e=Object.entries(obj).sort((a,b)=>b[1]-a[1]),tot=e.reduce((a,[,v])=>a+v,0);
  if(!tot){box.appendChild(h('div','empty','기록 없음'));return}const t=h('table');
  e.forEach(([k,v])=>{const tr=h('tr'),td=h('td'),bar=h('span','share');bar.style.width=Math.max(2,70*v/e[0][1])+'px';bar.style.background=colorFn(k);td.append(bar,document.createTextNode(nameFn(k)));
    tr.append(td,h('td','num',ko(v)),h('td','num muted',(100*v/tot).toFixed(1)+'%'));t.appendChild(tr)});box.appendChild(t)}
function kpis(){const now=new Date(),today=kHour(now).slice(0,10)+'T00',wk=kHour(new Date(now-6*864e5)).slice(0,10)+'T00',mo=kHour(now).slice(0,7)+'-01T00';
  const tot=f=>Object.values(sumSince(f,()=>'a')).reduce((a,b)=>a+b,0);const st=D.starts,vals=st.map(s=>s.ctx).sort((a,b)=>a-b);
  const med=vals.length?(vals.length%2?vals[vals.length>>1]:(vals[vals.length/2-1]+vals[vals.length/2])/2):0,last=st.length?st[st.length-1].ctx:0,up=med&&last>med*1.2;
  const k=$('#kpis');k.replaceChildren();[['오늘',tot(today),''],['최근 7일',tot(wk),''],['이번 달',tot(mo),''],
    ['최근 세션 시작 크기',last,up?`중앙값보다 ${Math.round((last/med-1)*100)}% 큼 · /context로 확인`:`중앙값 ${ko(med)}`,up]].forEach(([l,v,s,w])=>{
    const d=h('div','kpi'+(w?' warn':''));d.append(h('div','l',l),h('div','v',ko(v)),h('div','s',s||(S.metric==='all'?'캐시 재사용 포함':'캐시 재사용 제외')));k.appendChild(d)})}
function starts(){const box=$('#starts');box.replaceChildren();const P=D.starts;if(!P.length){box.appendChild(h('div','empty','아직 기록이 없습니다.'));return}
  const W=Math.max(320,box.clientWidth),H=190,L=48,T=10,B=22,max=Math.max(...P.map(p=>p.ctx))*1.12,s=el('svg',{viewBox:`0 0 ${W} ${H}`,role:'img','aria-label':'세션 시작 크기 추이'},box);
  axes(s,W,H,L,T,B,max);const xs=P.map((p,i)=>L+12+(W-L-24)*(P.length>1?i/(P.length-1):.5)),ys=P.map(p=>T+(H-T-B)*(1-p.ctx/max));
  const v=P.map(p=>p.ctx).sort((a,b)=>a-b),med=v.length%2?v[v.length>>1]:(v[v.length/2-1]+v[v.length/2])/2,my=T+(H-T-B)*(1-med/max);
  el('line',{x1:L,x2:W,y1:my,y2:my,class:'medline'},s);el('path',{d:xs.map((x,i)=>(i?'L':'M')+x+','+ys[i]).join(' '),class:'sline'},s);
  P.forEach((p,i)=>{const g=el('g',{class:'col',tabindex:0},s);el('circle',{cx:xs[i],cy:ys[i],r:12,fill:'transparent'},g);
    el('circle',{cx:xs[i],cy:ys[i],r:i===P.length-1?5:3.5,fill:'var(--c0)',stroke:'var(--card)','stroke-width':2},g);
    const title=`${p.ts.slice(5,16).replace('-','/').replace('T',' ')} · ${p.proj}`,items=[['시작 크기',p.ctx,'var(--c0)']];
    g.addEventListener('pointermove',e=>showTip(e,title,items));g.addEventListener('pointerleave',hideTip);g.addEventListener('focus',e=>showTip(e,title,items));g.addEventListener('blur',hideTip)});
  const t=el('text',{x:W,y:my-6,class:'axis','text-anchor':'end'},s);t.textContent='중앙값 '+ko(med)}
function tools(){const box=$('#tools');box.replaceChildren();if(!D.tools.length){box.appendChild(h('div','empty','없음'));return}
  const t=h('table'),hd=h('tr');['시각','프로젝트','누가','도구','글자 수'].forEach((x,i)=>hd.appendChild(h('th',i===4?'num':null,x)));t.appendChild(hd);
  D.tools.forEach(r=>{const tr=h('tr');tr.append(h('td',null,r.ts.slice(5,16).replace('-','/').replace('T',' ')),h('td',null,r.proj),h('td',null,r.who==='main'?'메인':r.who.slice(4)),h('td',null,r.tool),h('td','num',r.chars.toLocaleString()));t.appendChild(tr)});box.appendChild(t)}
function meta(){const u=new Date(D.updated),ks=Object.keys(D.hourly).sort();const ago=Math.max(0,Math.round((Date.now()-u)/60000));
  $('#meta').textContent=`기록 시작 ${ks.length?ks[0].slice(0,10):'-'} · 마지막 갱신 ${ago?ago+'분 전':'방금'}`;
  $('#offnote').replaceChildren();if(!D.enabled){const d=h('div','off','기록이 꺼져 있습니다. 새 사용분은 반영되지 않습니다. Claude에게 "토큰 기록 켜줘"라고 하세요.');$('#offnote').appendChild(d)}
  $('#metricnote').textContent=S.metric==='all'?'전체 = 새 입력 + 캐시 재사용 + 출력. 캐시 재사용분은 요금이 일반 입력의 약 10%라 실제 부담보다 크게 보입니다.':'캐시 제외 = 새 입력 + 출력. 실제 부담에 더 가깝습니다.'}
function all(){document.querySelectorAll('.seg').forEach(g=>g.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',S[g.dataset.k]===b.dataset.v)));
  history.replaceState(null,'','#'+[S.view,S.metric,S.split].join(','));meta();kpis();chart();starts();tools();
  const from=kHour(new Date(Date.now()-30*864e5));
  shareTable('#who30',sumSince(from,k=>k),k=>k==='main'?'메인 대화':k.slice(4),k=>k==='main'?'var(--c0)':'var(--c1)');
  shareTable('#model30',sumSince(from,(k,f)=>f),f=>FAMN[f]||f,f=>`var(--c${Math.max(0,FAM.indexOf(f))})`)}
document.querySelectorAll('.seg').forEach(g=>g.addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;S[g.dataset.k]=b.dataset.v;all()}));
let rz;addEventListener('resize',()=>{clearTimeout(rz);rz=setTimeout(all,150)});
const auto=$('#auto');let on=true;try{on=localStorage.getItem('usage-auto')!=='0'}catch(e){}auto.checked=on;
auto.onchange=()=>{try{localStorage.setItem('usage-auto',auto.checked?'1':'0')}catch(e){}};
try{const y=sessionStorage.getItem('usage-scroll');if(y)scrollTo(0,+y)}catch(e){}
setInterval(()=>{if(auto.checked&&!document.hidden&&tip.style.display!=='block'){try{sessionStorage.setItem('usage-scroll',scrollY)}catch(e){}location.reload()}},30000);
all();
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
    print(f'채움: 대화 기록 {files}개, 새로 읽은 응답 {n:,}건, 기록 기간 {hours[0][:10] if hours else "-"} ~ {hours[-1][:10] if hours else "-"}')
elif MODE == 'render':
    render()
elif MODE == 'check':
    check()
elif MODE == 'status':
    status()
PY

run_py() { PYTHONIOENCODING=utf-8 "${PY}" -c "${PROG}" "$@"; }

case "${MODE}" in
  hook)
    input="$(cat)"
    lock || exit 0
    printf '%s' "${input}" | run_py hook
    ;;
  enable)
    if [[ "$(uname -s)" == "Linux" ]]; then
      echo "Linux 서버는 대상이 아닙니다(화면 없이 쓰는 환경, 2026-09-27 결정). /usage로 확인하세요."
      exit 1
    fi
    mkdir -p "${LOG}" && : > "${LOG}/enabled"
    lock || { echo "다른 기록 작업이 끝나지 않았습니다. 잠시 뒤 다시 실행하세요."; exit 1; }
    echo "켜짐. 남아 있는 대화 기록을 훑는 중(처음 한 번은 수십 초 걸릴 수 있음)..."
    run_py backfill
    echo "대시보드: ${LOG}/dashboard.html"
    ;;
  disable) rm -f "${LOG}/enabled"; run_py render; echo "꺼짐. 쌓인 기록은 ${LOG}에 그대로 있습니다." ;;
  open)
    run_py render
    page="${LOG}/dashboard.html"
    case "$(uname -s)" in
      Darwin) open "${page}" ;;
      MINGW*|MSYS*|CYGWIN*) cmd.exe //c start "" "$(cygpath -w "${page}")" ;;
      *) echo "브라우저로 여세요: ${page}" ;;
    esac
    ;;
  render|check|status) run_py "${MODE}" ;;
  *) echo "사용법: bash usage.sh hook|enable|disable|open|render|status|check"; exit 2 ;;
esac
exit 0
