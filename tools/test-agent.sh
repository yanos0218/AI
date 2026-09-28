#!/usr/bin/env bash
# 에이전트 발동 시험 — 같은 폴더의 에이전트 .md 전부를 --agents JSON으로 넘기고 새 세션(claude -p)으로 사용자 말을
# 던진 뒤, 어느 에이전트에 위임했는지·에이전트 안 도구 호출·훅 차단·토큰·비용을 추출한다(Issue #131).
#   bash tools/test-agent.sh <에이전트.md> <시나리오 저장소> "<사용자 말>" [--model 모델] [--tools "Read,Agent"] [--turns N]
#   프로젝트 .claude/agents/에 넣으면 -p 세션은 신뢰 전 폴더라 frontmatter hooks가 건너뛰어진다(공식 문서, 2026-09-26 실측).
#   --agents로 넘긴 정의와 ~/.claude/agents/의 훅은 신뢰 절차 없이 돈다 — 그래서 --agents 파일 형식(v2.1.281+)을 쓴다.
#   "bash ~/.claude/hooks/<훅>.sh"는 설치 전일 수 있으므로 저장소 base/hooks/<훅>.sh 절대 경로로 바꿔 넘긴다(없으면 drafts/hooks/).
#   --installed: 폴더 대신 이미 설치된 ~/.claude/agents/를 그대로 쓴다(설치본 시험, 훅 경로도 설치본).
#   omitClaudeMd(v2.1.271+) 등 최신 필드는 CLI 버전을 탄다 — 필요하면 CLAUDE_BIN으로 다른 실행 파일을 지정한다.
set -u
cd "$(dirname "${0}")/.." || exit 1
AGENT="${1:?에이전트 파일}"; FIX="${2:?시나리오 저장소}"; PROMPT="${3:?사용자 말}"; shift 3
INSTALLED=0; MODEL="claude-sonnet-5"; TOOLS="Read,Glob,Grep,Agent,Bash(ls*),Bash(cat*),Bash(git status*)"; TURNS=12
while [[ $# -gt 0 ]]; do case "${1}" in
  --model) MODEL="${2}"; shift 2;; --tools) TOOLS="${2}"; shift 2;; --turns) TURNS="${2}"; shift 2;; --installed) INSTALLED=1; shift;; *) echo "모르는 옵션 ${1}"; exit 2;; esac; done
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || echo "${HOME}/.local/bin/claude.exe")}"
PY="$(command -v python3 || command -v python)"
[[ -d "${FIX}/.git" ]] || { echo "시나리오 저장소가 git 저장소가 아님: ${FIX}"; exit 2; }

name="$(basename "${AGENT}" .md)"
[[ -f "${HOME}/.claude/agents/${name}.md" ]] && echo "== 주의: 같은 이름의 전역 에이전트가 설치돼 있음(--agents 쪽이 우선)"
# 빈 배열은 ${a[@]+"${a[@]}"}로 펼친다. Mac 기본 bash 3.2는 set -u에서 빈 "${a[@]}"를 unbound 오류로 멈춘다(2026-09-29)
agents_args=()
if [[ "${INSTALLED}" = 0 ]]; then
hooks_abs="$(pwd)"
agents_json="${FIX}.agents.json"
# 실제 사용처럼 같은 폴더의 에이전트를 전부 넘긴다(설명끼리 경쟁하는 상황에서 맞는 쪽이 골라지는지 봄)
# 변환에 실패하면(예: Mac Homebrew 파이썬엔 PyYAML이 없음) 에이전트 없이 세션이 떠 "토큰 0"만 나오므로 여기서 멈춘다(2026-09-29)
PYTHONIOENCODING=utf-8 "${PY}" - "$(dirname "${AGENT}")" "${hooks_abs}" "${agents_json}" <<'PY' || { echo "에이전트 정의 변환 실패. PyYAML이 있는 파이썬을 PATH 앞에 두고 다시 실행(예: 가상환경에 pip install pyyaml)"; exit 2; }
import glob, io, json, os, re, sys, yaml
src, hooks_abs, out = sys.argv[1:4]
agents = {}
for f in sorted(glob.glob(os.path.join(src, '*.md'))):
    text = re.sub(r'bash ~/\.claude/hooks/(\S+?\.sh)',
                  lambda m: f"bash {hooks_abs}/{'base' if os.path.exists(os.path.join(hooks_abs, 'base/hooks', m[1])) else 'drafts'}/hooks/{m[1]}",
                  io.open(f, encoding='utf-8').read())
    _, fm, body = text.split('---', 2)
    meta = yaml.safe_load(fm)
    name = meta.pop('name')
    meta.pop('color', None)
    for k in ('tools', 'disallowedTools'):  # --agents JSON은 목록만 받는다(쉼표 문자열이면 Invalid input)
        if isinstance(meta.get(k), str): meta[k] = [t.strip() for t in meta[k].split(',')]
    meta['prompt'] = body.strip()
    agents[name] = meta
json.dump(agents, io.open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('== --agents:', ', '.join(agents))
PY
agents_args=(--agents "${agents_json}")
fi
out="${FIX}.${name}.jsonl"
echo "== 에이전트 ${name} · 모델 ${MODEL} · $("${CLAUDE_BIN}" --version 2>/dev/null) · 말: ${PROMPT}"
IFS=',' read -r -a tool_rules <<<"${TOOLS}"
(cd "${FIX}" && unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT && "${CLAUDE_BIN}" -p "${PROMPT}" --model "${MODEL}" \
  --output-format stream-json --verbose --max-turns "${TURNS}" ${agents_args[@]+"${agents_args[@]}"} --allowedTools "${tool_rules[@]}") > "${out}" 2>"${out}.err" < /dev/null

PYTHONIOENCODING=utf-8 "${PY}" - "${out}" "${name}" <<'PY'
import json, sys
path, agent = sys.argv[1], sys.argv[2]
main_tools, sub_tools, denied, texts, result = [], [], [], [], None
delegated, tok = [], {'main': 0, 'sub': 0}
seen = set()
for line in open(path, encoding='utf-8'):
    try: e = json.loads(line)
    except ValueError: continue
    sub = bool(e.get('parent_tool_use_id'))
    if e.get('type') == 'assistant':
        m = e['message']; u = m.get('usage') or {}
        if m.get('id') not in seen:
            seen.add(m.get('id'))
            tok['sub' if sub else 'main'] += u.get('input_tokens', 0) + u.get('cache_read_input_tokens', 0) + u.get('cache_creation_input_tokens', 0) + u.get('output_tokens', 0)
        for c in m['content']:
            if c['type'] == 'tool_use':
                arg = json.dumps(c['input'], ensure_ascii=False)
                (sub_tools if sub else main_tools).append(f"{c['name']} {arg[:110]}")
                if c['name'] in ('Agent', 'Task') and not sub: delegated.append(c['input'].get('subagent_type', '?'))
            elif c['type'] == 'text' and not sub: texts.append(c['text'])
    elif e.get('type') == 'user':
        for c in (e.get('message') or {}).get('content') or []:
            if isinstance(c, dict) and c.get('type') == 'tool_result' and '(verifier-guard)' in json.dumps(c, ensure_ascii=False):
                denied.append(json.dumps(c.get('content'), ensure_ascii=False)[:140])
    elif e.get('type') == 'result': result = e
print('위임:', ', '.join(delegated) or '(없음)', '|', f"{agent} 발동:", '예' if agent in delegated else '아니오')
print('메인 도구 호출:'); [print('  ', t) for t in main_tools]
print('에이전트 안 도구 호출:'); [print('  ', t) for t in sub_tools]
if denied: print('훅 차단:'); [print('  ', d) for d in denied]
print(f"토큰(턴별 입력+출력 합) 메인={tok['main']} 에이전트={tok['sub']}")
print('최종 답변:'); print('  ' + (texts[-1] if texts else '(없음)').replace('\n', '\n  ')[:1200])
if result: print(f"turns={result.get('num_turns')} cost=${result.get('total_cost_usd', 0):.2f} subtype={result.get('subtype')}")
PY
[[ -s "${out}.err" ]] && { echo "== stderr:"; head -5 "${out}.err"; }
echo "== 원본: ${out}"
