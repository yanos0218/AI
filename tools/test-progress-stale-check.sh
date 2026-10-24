#!/usr/bin/env bash
# .claude/hooks/progress-stale-check.sh 시험(Issue #207). 임시 설정 폴더와 임시 표 파일만 쓴다.
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
#   bash tools/test-progress-stale-check.sh
set -u
cd "$(dirname "${0}")/.." || exit 1
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
hook() { CLAUDE_CONFIG_DIR="${T}/home" PROGRESS_FILE="${T}/progress.md" bash .claude/hooks/progress-stale-check.sh 2>&1; }
# 어느 운영체제에서 돌아도 그 기기 행이 잡히도록 세 행을 모두 만든다
table() { printf '| 표면 | 설치된 것 |\n| --- | --- |\n| Windows | `%s` |\n| Mac mini | `%s` |\n| Linux(RHEL 계열) | `%s` |\n' "$1" "$1" "$1" >"${T}/progress.md"; }

mkdir -p "${T}/home"
printf '%s\n%s\n%s\n' "/x/AI" "v0.14.0-64-gd8d7300" "abc" >"${T}/home/.claude-config-version"

echo "== 1. 행에 설치 버전이 있으면 출력 없음"
table "v0.14.0-64-gd8d7300"
out="$(hook)"; rc=$?
chk "종료 코드 0"                   '[[ "${rc}" = 0 ]]'
chk "출력 없음"                     '[[ -z "${out}" ]]'

echo "== 2. 행이 옛 버전이면 알림 한 줄"
table "v0.14.0-57-g988e096"
out="$(hook)"; rc=$?
chk "종료 코드 0(세션 시작을 막지 않음)" '[[ "${rc}" = 0 ]]'
chk "알림이 나옴"                   'grep -q "^\[progress-check\] " <<<"${out}"'
chk "설치 버전이 알림에 들어감"       'grep -q "v0.14.0-64-gd8d7300" <<<"${out}"'
chk "알림은 한 줄"                  '[[ "$(printf "%s\n" "${out}" | wc -l | tr -d " ")" = 1 ]]'

echo "== 3. 비교할 수 없으면 조용히 끝남"
rm -f "${T}/home/.claude-config-version"
out="$(hook)"; rc=$?
chk "설치 버전 파일 없음: 출력 없음"   '[[ "${rc}" = 0 && -z "${out}" ]]'
printf '%s\n%s\n' "/x/AI" "v0.14.0-64-gd8d7300" >"${T}/home/.claude-config-version"
out="$(CLAUDE_CONFIG_DIR="${T}/home" PROGRESS_FILE="${T}/없는파일.md" bash .claude/hooks/progress-stale-check.sh 2>&1)"; rc=$?
chk "표 파일 없음: 출력 없음"          '[[ "${rc}" = 0 && -z "${out}" ]]'
printf '| 표면 | 설치된 것 |\n| --- | --- |\n| 웹 | x |\n' >"${T}/progress.md"
out="$(hook)"; rc=$?
chk "이 기기 행 없음: 출력 없음"       '[[ "${rc}" = 0 && -z "${out}" ]]'

echo "== 4. CRLF 설치 버전 파일(Windows)도 같은 판정"
table "v0.14.0-64-gd8d7300"
printf '/x/AI\r\nv0.14.0-64-gd8d7300\r\nabc\r\n' >"${T}/home/.claude-config-version"
out="$(hook)"
chk "CR이 붙어도 출력 없음"            '[[ -z "${out}" ]]'

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
