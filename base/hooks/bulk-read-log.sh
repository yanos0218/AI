#!/usr/bin/env bash
# PostToolUse(Bash|PowerShell) 훅 초안 — 전역용.
# 실시간으로 Claude에게 알리는 건 기술적으로 안 됨을 실제 세션 3개로 확인함
# (PreToolUse/PostToolUse의 systemMessage·평문 stdout 전부 트랜스크립트 로그에만
# 남고 모델 컨텍스트엔 주입되지 않음, 2026-09-15). 그래서 config-changelog.sh와
# 같은 방식 — 조용히 기록만 하고, 쌓인 개수가 기준을 넘으면 다음 세션 시작 때
# session-start-check.sh가 알려준다(사후 로그 + 개수 기준 점검).
#
# 대상 패턴은 bulk-read-warn.sh(초안, 미채택)와 같다: 대량 조회로 알려진
# gh issue list --json body/comments, 큰 --limit 등.
set -u
input="$(cat)"
cmd="$(printf '%s' "${input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"

pattern='gh[[:space:]]+issue[[:space:]]+list[^"]*--json[^"]*(body|comments)|gh[[:space:]]+api[^"]*/(issues|comments)[^"]*--jq|--limit[[:space:]]+([2-9][0-9]|[0-9]{3,})|git[[:space:]]+log[^"]*-p[^"]*--all'
printf '%s' "${cmd}" | grep -Eq "${pattern}" || exit 0

home="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
log="${home}/bulk-read-log.md"
[[ -f "${log}" ]] || printf '# 대량 조회 로그 (bulk-read-log 훅이 자동 기록)\n\n서브에이전트 위임 없이 직접 실행한, 대량 조회로 보이는 명령들. 쌓인 개수가 session-start-check.sh 기준을 넘으면 다음 세션에서 알려준다. 검토 후 비운다(월 점검 3번과 같은 방식).\n\n| 시각 | 명령 | 작업 폴더 |\n| --- | --- | --- |\n' > "${log}"
short="$(printf '%s' "${cmd}" | tr '\n' ' ' | cut -c1-160 | sed 's/|/\\|/g')"
printf '| %s | %s | %s |\n' "$(date '+%Y-%m-%d %H:%M')" "${short}" "$(pwd)" >> "${log}"
exit 0
