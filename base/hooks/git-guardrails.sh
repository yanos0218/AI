#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅.
# 되돌리기 어려운 명령은 auto 모드에서도 반드시 사용자 확인 프롬프트를 띄우게 한다.
# CLAUDE.md의 "확인 후 진행" 목록을 문장이 아니라 실행 시점에 강제하는 장치.
# 차단(deny)이 아니라 확인(ask)이므로, 사용자가 승인하면 그대로 실행된다.
set -u

input="$(cat)"

pattern='git[[:space:]]+push|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-[A-Za-z]*f|git[[:space:]]+branch[[:space:]]+-D|git[[:space:]]+checkout[[:space:]]+--|git[[:space:]]+restore[[:space:]]+\.|git[[:space:]]+tag[[:space:]]+-d|--no-verify|npm[[:space:]]+publish|gh[[:space:]]+release[[:space:]]+create|gh[[:space:]]+repo[[:space:]]+delete|rm[[:space:]]+-[A-Za-z]*r[A-Za-z]*f|Remove-Item[^|]*-Recurse'

if printf '%s' "$input" | grep -Eq "$pattern"; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"되돌리기 어려운 명령입니다 (git-guardrails). 실행 전 사용자 확인이 필요합니다."}}
JSON
fi

exit 0
