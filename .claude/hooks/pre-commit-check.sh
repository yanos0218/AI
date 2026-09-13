#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅 — 이 저장소 전용.
# `git commit`을 실행하려 할 때 문서 상한·markdownlint·shellcheck를 먼저 돌리고,
# 실패하면 커밋 자체를 막는다(permissionDecision: deny). 지금까지는 "커밋 전에
# 검사를 돌린다"가 제 습관이었을 뿐 강제 장치가 없었다 — "강제할 건 CLAUDE.md
# 문장이 아니라 훅으로"라는 이 저장소 원칙을 검증에도 적용한 것(2026-09-13).
set -u
cd "$(dirname "${0}")/../.." || exit 0

input="$(cat)"
cmd="$(printf '%s' "${input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"

# git commit이 아니면 조용히 통과
printf '%s' "${cmd}" | grep -Eq 'git[[:space:]]+commit' || exit 0

fail=0
msg=""

# 1. 문서 상한·필수 파일 — 항상 실행(가볍다)
if ! out=$(bash tools/check-docs.sh 2>&1); then
  fail=1
  msg="${msg}\\ncheck-docs.sh 실패:\\n$(printf '%s' "${out}" | tail -5)"
fi

# 2. markdownlint — 스테이징된 .md가 있을 때만
if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q '\.md$'; then
  if ! out=$(npx --yes markdownlint-cli2 "**/*.md" 2>&1); then
    fail=1
    msg="${msg}\\nmarkdownlint 실패:\\n$(printf '%s' "${out}" | tail -8)"
  fi
fi

# 3. shellcheck — 스테이징된 .sh가 있을 때만
sh_files="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.sh$' || true)"
if [[ -n "${sh_files}" ]]; then
  if ! out=$(printf '%s\n' "${sh_files}" | xargs npx --yes shellcheck -S warning 2>&1); then
    fail=1
    msg="${msg}\\nshellcheck 실패:\\n$(printf '%s' "${out}" | tail -8)"
  fi
fi

if [[ "${fail}" = 1 ]]; then
  reason="$(printf '%s' "${msg}" | tr '\n' ' ' | sed 's/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"pre-commit-check 실패, 커밋 차단: %s"}}\n' "${reason}"
fi
exit 0
