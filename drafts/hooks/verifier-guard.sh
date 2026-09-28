#!/usr/bin/env bash
# verifier 에이전트 전용 PreToolUse(Bash) 훅의 셸 입구(Issue #144). 에이전트 frontmatter의 hooks에서만 부른다.
# 판정은 파이썬 본체(verifier_guard.py)가 한다. 셸 문자열 매칭은 입력 JSON 전체를 훑어 따옴표 안의 '>'까지
# 리다이렉션으로 오인했다(옛 주석에 적힌 오탐).
# 막는 훅이라 실패하면 막는다(fail-closed): 파이썬이 없거나 본체가 오류로 끝나면 차단 결정을 대신 낸다.
set -u
IFS= read -r -d '' input || true
deny() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"verifier-guard 검사기를 실행하지 못해 안전하게 차단함(파이썬 없음 또는 검사기 오류, ~/.claude/hook-errors.log 참고). 막혔다고 보고할 것."}}'
  exit 0
}
if hash python 2>/dev/null; then PY=python; elif hash python3 2>/dev/null; then PY=python3; else deny; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
out="$(printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/verifier_guard.py")" || deny
printf '%s' "${out}"
exit 0
