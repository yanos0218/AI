#!/usr/bin/env bash
# verifier 에이전트 전용 PreToolUse(Bash) 훅 — 에이전트 frontmatter의 hooks에서만 부른다.
# verifier는 검사 명령을 "실행만" 하는 역할이라, 파일·저장소·외부 상태를 바꾸는 명령은
# 확인(ask)이 아니라 차단(deny)한다. 전역 git-guardrails.sh(ask)와 달리 승인으로 통과시키지
# 않는다 — 바꿔야 할 일이면 메인 대화가 직접 한다(Issue #131).
# 문자열 매칭이라 따옴표 안의 '>' 같은 것도 막힐 수 있다. 오탐이면 verifier가 "막혔다"고
# 보고하고 메인 대화가 직접 실행하면 된다(과차단 쪽이 안전).
set -u

input="$(cat)"
cmd="$(printf '%s' "${input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"
[[ -n "${cmd}" ]] || exit 0

# 출력 버리기·합치기는 쓰기가 아니므로 지운 뒤 리다이렉션을 본다
stripped="$(printf '%s' "${cmd}" | sed -E 's#[0-9&]?>>?[[:space:]]*/dev/null##g; s#[0-9]?>&[0-9]##g')"

reason=""
if printf '%s' "${cmd}" | grep -Eq '(^|[;&|(][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+(commit|push|reset|checkout|clean|rebase|merge|tag|stash|add|rm|mv|restore|switch|revert|cherry-pick|am|apply|branch|init|clone|pull|fetch)([[:space:]]|$)'; then
  reason="git 상태를 바꾸는 명령"
elif printf '%s' "${cmd}" | grep -Eq '(^|[;&|(][[:space:]]*)(sudo[[:space:]]+)?(rm|rmdir|mv|cp|chmod|chown|touch|mkdir|ln|dd|truncate|tee)([[:space:]]|$)'; then
  reason="파일을 만들거나 바꾸거나 지우는 명령"
elif printf '%s' "${cmd}" | grep -Eq '(sed|perl)[[:space:]]+(-[a-zA-Z]*i|--in-place)'; then
  reason="파일을 제자리에서 고치는 명령"
elif printf '%s' "${stripped}" | grep -Eq '>'; then
  reason="출력을 파일로 쓰는 리다이렉션"
elif printf '%s' "${cmd}" | grep -Eq '(^|[;&|(][[:space:]]*)(npm|pnpm|yarn|bun|pip|pip3|uv|brew|apt|apt-get|dnf|yum|choco|winget)[[:space:]]+(install|i|add|remove|uninstall|publish|update|upgrade)([[:space:]]|$)'; then
  reason="패키지 설치·배포 명령"
elif printf '%s' "${cmd}" | grep -Eq 'gh[[:space:]]+(issue|pr|release|repo|label|workflow|run)[[:space:]]+(create|edit|close|reopen|comment|delete|merge|rerun|cancel|enable|disable)|gh[[:space:]]+api.*(-X|--method)[[:space:]]*(POST|PUT|PATCH|DELETE)'; then
  reason="GitHub에 쓰는 명령"
elif printf '%s' "${cmd}" | grep -Eq 'curl.*((-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|[[:space:]](-d|--data[a-z-]*|-F|--form)[[:space:]])'; then
  reason="외부로 데이터를 보내는 요청"
fi

if [[ -n "${reason}" ]]; then
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"verifier는 검사 실행만 한다(verifier-guard): ${reason}은 차단. 우회하지 말고 막혔다고 보고할 것."}}
JSON
fi
exit 0
