#!/usr/bin/env bash
# PreToolUse(Edit/Write/MultiEdit/NotebookEdit/Bash/PowerShell) 훅 — 이 저장소 전용.
# "기본 영역" base/ (배포되는 원본)을 고치려 하면 사용자 확인 프롬프트를 띄운다.
# 작업 중 떠오른 개선을 기본 영역에 슬쩍 넣는 일을 막는 장치. 기본 영역에 넣는 것은
# 검증이 끝나고 사용자가 명시적으로 "기본에 반영해"라고 한 뒤여야 한다.
# 초안은 drafts/ 아래에서 작업한다(자유). base/skills/_template 처럼 _로 시작하는 스킬 폴더도 예외.
set -u

input="$(cat)"
tool="$(printf '%s' "${input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"

# base/ 아래 경로. 단 base/skills/_* 는 제외
is_baseline() { grep -Eq '(^|[/\\"'"'"' ])base[/\]' | grep -Evq '(^|[/\\"'"'"' ])base[/\]skills[/\]_' ; }
# base/... 토큰 중 _template 같은 예외를 지우고 판단
strip_exempt() { sed -E 's#([A-Za-z]:)?[^ "'"'"']*base[/\]skills[/\]_[^ "'"'"']*##g'; }

hit=0
case "${tool}" in
  Edit|Write|MultiEdit|NotebookEdit)
    target="$(printf '%s' "${input}" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | strip_exempt)"
    printf '%s' "${target}" | grep -Eq '(^|[/\\"'"'"' ])base[/\]' && hit=1
    ;;
  Bash|PowerShell)
    cmd="$(printf '%s' "${input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1 | strip_exempt)"
    writes='(>|sed[[:space:]]+-i|tee[[:space:]]|(^|[;&| ])(cp|mv|rm|python|python3)[[:space:]]|git[[:space:]]+mv|Set-Content|Out-File|Copy-Item|Move-Item|Remove-Item|Add-Content)'
    if printf '%s' "${cmd}" | grep -Eq '(^|[/\\"'"'"' ])base[/\]' && printf '%s' "${cmd}" | grep -Eq "${writes}"; then hit=1; fi
    ;;
esac

if [[ "${hit}" = 1 ]]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"기본 영역(base/) 변경입니다 (baseline-guard). 검증이 끝나고 사용자가 기본 반영을 요청한 변경이 맞는지 확인하세요. 초안은 drafts/ 에서."}}
JSON
fi
exit 0
