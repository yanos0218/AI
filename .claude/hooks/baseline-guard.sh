#!/usr/bin/env bash
# PreToolUse(Edit/Write/MultiEdit/NotebookEdit/Bash/PowerShell) 훅 — 이 저장소 전용.
# "기본 영역"(배포되는 원본: claude-md/, skills/<이름>/, scripts/, vscode/)을 고치려 하면
# 사용자 확인 프롬프트를 띄운다. 작업 중 떠오른 개선을 기본 영역에 슬쩍 넣는 일을 막는 장치.
# 기본 영역에 넣는 것은 검증이 끝나고 사용자가 명시적으로 "기본에 반영해"라고 한 뒤여야 한다.
# 초안은 drafts/ 아래에서 작업한다(자유). skills/_template 처럼 _로 시작하는 폴더도 기본 영역이 아니다.
set -u

input="$(cat)"
tool="$(printf '%s' "$input" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"

# 기본 영역 경로 패턴 (경로 구분자 / 와 \ 모두 허용)
baseline='(^|[/\\"'"'"' ])(claude-md|scripts|vscode)[/\]|(^|[/\\"'"'"' ])skills[/\][^_/\ "'"'"']+([/\]|$|[ "'"'"'])'
# drafts/... 로 시작하는 경로 토큰은 작업 영역이므로 검사 전에 지운다
strip_drafts() { sed -E 's#([A-Za-z]:)?[^ "'"'"']*drafts[/\][^ "'"'"']*##g'; }

hit=0
case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit)
    target="$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | strip_drafts)"
    printf '%s' "$target" | grep -Eq "$baseline" && hit=1
    ;;
  Bash|PowerShell)
    cmd="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1 | strip_drafts)"
    writes='(>|sed[[:space:]]+-i|tee[[:space:]]|(^|[;&| ])(cp|mv|rm|python|python3)[[:space:]]|git[[:space:]]+mv|Set-Content|Out-File|Copy-Item|Move-Item|Remove-Item|Add-Content)'
    if printf '%s' "$cmd" | grep -Eq "$baseline" && printf '%s' "$cmd" | grep -Eq "$writes"; then hit=1; fi
    ;;
esac

if [ "$hit" = 1 ]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"기본 영역(claude-md/, skills/, scripts/, vscode/) 변경입니다 (baseline-guard). 검증이 끝나고 사용자가 기본 반영을 요청한 변경이 맞는지 확인하세요. 초안은 drafts/ 에서."}}
JSON
fi
exit 0
