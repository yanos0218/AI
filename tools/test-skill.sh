#!/usr/bin/env bash
# 스킬 발동 시험 — 시나리오 저장소에 스킬을 프로젝트 스킬로 넣고 새 세션(claude -p)으로 사용자 말을 던진 뒤,
# Skill 호출 여부·도구 호출·최종 답변·비용을 추출한다. 같은 세션에서 /skill을 쳐 보는 것은 발동 시험이 아니다.
#   bash tools/test-skill.sh <스킬 폴더> <시나리오 저장소> "<사용자 말>" [--model 모델] [--tools "Read Glob ..."] [--turns N]
#   예) bash tools/test-skill.sh drafts/skills/x "$TMP/fixtures/A" "테스트 어떻게 해?"
# 기본 모델은 claude-sonnet-5(발동 판단은 Sonnet으로 충분, 비용 절반 이하). 결과 jsonl은 시나리오 저장소 옆 <이름>.jsonl.
set -u
cd "$(dirname "$0")/.." || exit 1
SKILL="${1:?스킬 폴더}"; FIX="${2:?시나리오 저장소}"; PROMPT="${3:?사용자 말}"; shift 3
MODEL="claude-sonnet-5"; TOOLS="Read Glob Grep Skill Bash(ls*) Bash(cat*) Bash(git *)"; TURNS=12
while [ $# -gt 0 ]; do case "$1" in
  --model) MODEL="$2"; shift 2;; --tools) TOOLS="$2"; shift 2;; --turns) TURNS="$2"; shift 2;; *) echo "모르는 옵션 $1"; exit 2;; esac; done
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || echo "$HOME/.local/bin/claude.exe")}"
[ -d "$FIX/.git" ] || { echo "시나리오 저장소가 git 저장소가 아님: $FIX"; exit 2; }

name="$(basename "$SKILL")"
mkdir -p "$FIX/.claude/skills"; rm -rf "$FIX/.claude/skills/$name"; cp -r "$SKILL" "$FIX/.claude/skills/$name"
out="$FIX.$(basename "$FIX").jsonl"
echo "== 스킬 $name → $FIX/.claude/skills/ · 모델 $MODEL · 말: $PROMPT"
# shellcheck disable=SC2086
(cd "$FIX" && unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT && "$CLAUDE_BIN" -p "$PROMPT" --model "$MODEL" \
  --output-format stream-json --verbose --max-turns "$TURNS" --allowedTools $TOOLS) > "$out" 2>"$out.err"

PYTHONIOENCODING=utf-8 python - "$out" "$name" <<'PY'
import json, sys
path, skill = sys.argv[1], sys.argv[2]
tools, texts, result, fired = [], [], None, False
for line in open(path, encoding='utf-8'):
    try: e = json.loads(line)
    except ValueError: continue
    if e.get('type') == 'assistant':
        for c in e['message']['content']:
            if c['type'] == 'tool_use':
                arg = json.dumps(c['input'], ensure_ascii=False)[:120]
                tools.append(f"{c['name']} {arg}")
                if c['name'] == 'Skill' and c['input'].get('skill') == skill: fired = True
            elif c['type'] == 'text': texts.append(c['text'])
    elif e.get('type') == 'result': result = e
print('발동:', '예' if fired else '아니오')
print('도구 호출:'); [print('  ', t) for t in tools]
print('최종 답변:'); print('  ' + (texts[-1] if texts else '(없음)').replace('\n', '\n  ')[:1500])
if result: print(f"turns={result.get('num_turns')} cost=${result.get('total_cost_usd', 0):.2f} subtype={result.get('subtype')}")
PY
echo "== 원본: $out"
