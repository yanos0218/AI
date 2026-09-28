#!/usr/bin/env bash
# baseline-guard 셸 입구 초안(Issue #144, 이 저장소 전용 .claude/hooks/baseline-guard.sh를 대체할 것).
# 입력에 base 경로가 없으면 하위 프로세스 없이 바로 끝내고, 있으면 파이썬 본체(baseline_guard.py)가 판정한다.
# 옛 셸판은 대상이 아닌 명령에도 7.2초가 걸려 제한 시간(5초)을 넘겼다(Issue #143).
# 확인 창을 띄우는 훅이라 실패하면 확인 창을 띄운다(fail-closed).
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *base/*|*'base\\'*) ;;
  *) exit 0 ;;
esac
ask() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"baseline-guard 검사기를 실행하지 못해 확인을 요청함(파이썬 없음 또는 검사기 오류, ~/.claude/hook-errors.log 참고). base/ 변경이면 사용자 요청이 있었는지 확인하세요."}}'
  exit 0
}
if hash python 2>/dev/null; then PY=python; elif hash python3 2>/dev/null; then PY=python3; else ask; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
out="$(printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/baseline_guard.py")" || ask
printf '%s' "${out}"
exit 0
