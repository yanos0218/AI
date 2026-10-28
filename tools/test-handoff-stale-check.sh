#!/usr/bin/env bash
# .claude/hooks/handoff-stale-check.sh 시험(Issue #238). 임시 폴더에 훅을 복사하고 가짜 gh를 PATH 앞에 둔다.
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
#   bash tools/test-handoff-stale-check.sh
set -u
cd "$(dirname "${0}")/.." || exit 1
SRC="$(pwd)/.claude/hooks/handoff-stale-check.sh"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

mkdir -p "${T}/.claude/hooks" "${T}/docs" "${T}/bin"
cp "${SRC}" "${T}/.claude/hooks/"
# 가짜 gh: 닫힌 이슈 번호를 GH_CLOSED(공백 구분)로 받아 한 줄에 하나씩 출력한다
printf '#!/bin/sh\nprintf "%%s\\n" ${GH_CLOSED:-}\n' >"${T}/bin/gh"; chmod +x "${T}/bin/gh"
# 가짜 gh가 실패하는 경우용
printf '#!/bin/sh\nexit 1\n' >"${T}/bin/gh-fail"; chmod +x "${T}/bin/gh-fail"
# $1=HANDOFF 본문, $2=닫힌 번호들
handoff() { printf '%s\n' "$1" >"${T}/docs/HANDOFF.md"; }
hook() { PATH="${T}/bin:${PATH}" GH_CLOSED="$1" bash "${T}/.claude/hooks/handoff-stale-check.sh" 2>&1; }

echo "== 1. 닫힌 이슈를 가리키면 알림 한 줄"
handoff $'# x\n\n## 지금\n\n- 다음은 [#195](https://x/issues/195)임'
out="$(hook "195")"; rc=$?
chk "종료 코드 0(세션 시작을 막지 않음)" '[[ "${rc}" = 0 ]]'
chk "알림에 #195가 들어감"             'grep -q "^\[handoff-check\] .*#195" <<<"${out}"'
chk "알림은 한 줄"                    '[[ "$(printf "%s\n" "${out}" | wc -l | tr -d " ")" = 1 ]]'

echo "== 2. 열린 이슈만 가리키면 출력 없음"
out="$(hook "999")"
chk "출력 없음"                       '[[ -z "${out}" ]]'

echo "== 3. 닫혔다고 밝힌 줄은 제외 (Issue #237)"
handoff $'# x\n\n## 지금\n\n- 근거는 닫힌 [#195](https://x/issues/195) 댓글, 남은 것 [#228](https://x/issues/228)임'
out="$(hook "195")"
chk "닫힌 [#N] 표기만 닫힘: 출력 없음"   '[[ -z "${out}" ]]'
out="$(hook "195 228")"
chk "같은 줄의 다른 번호가 닫히면 그것만 알림" 'grep -q "#228" <<<"${out}" && ! grep -q "#195" <<<"${out}"'
handoff $'# x\n\n## 지금\n\n- #195는 2026-10-24에 닫음, 이어서 해야 할 것은 없음'
out="$(hook "195")"
chk "\"닫음\"으로 적은 줄: 출력 없음"    '[[ -z "${out}" ]]'

echo "== 4. 판정 범위"
handoff $'# x\n\n## 지금 · 마지막 월 점검 ([#171](https://x/issues/171))\n\n- 지금 상태\n\n## 문서 지도\n\n- [#171](https://x/issues/171)'
out="$(hook "171")"
chk "\"지금\" 절 밖의 번호는 보지 않음"   '[[ -z "${out}" ]]'
handoff $'# x\n\n## 지금\n\n- 항목\n  - 하위 [#195](https://x/issues/195)'
out="$(hook "195")"
chk "하위 bullet은 보지 않음(최상위 줄만)" '[[ -z "${out}" ]]'

echo "== 5. 조용히 끝나는 경우"
handoff $'# x\n\n## 지금\n\n- 번호 없는 줄'
out="$(hook "195")"; rc=$?
chk "이슈 번호 없음: 출력 없음"          '[[ "${rc}" = 0 && -z "${out}" ]]'
handoff $'# x\n\n## 지금\n\n- 다음은 [#195](https://x/issues/195)임'
out="$(PATH="${T}/bin:${PATH}" bash -c 'cp "$1/bin/gh-fail" "$1/bin/gh"; exec bash "$1/.claude/hooks/handoff-stale-check.sh"' _ "${T}" 2>&1)"; rc=$?
chk "gh 실패: 출력 없음, 종료 코드 0"    '[[ "${rc}" = 0 && -z "${out}" ]]'
rm -f "${T}/docs/HANDOFF.md"
printf '#!/bin/sh\nprintf "%%s\\n" ${GH_CLOSED:-}\n' >"${T}/bin/gh"
out="$(hook "195")"; rc=$?
chk "HANDOFF 파일 없음: 출력 없음"        '[[ "${rc}" = 0 && -z "${out}" ]]'

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
