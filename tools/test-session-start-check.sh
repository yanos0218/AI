#!/usr/bin/env bash
# session-start-check.sh 1번(전역 설정 낡음 판정) 시험(Issue #150). 임시 원격·복제본·가짜 HOME으로
# 원격이 앞선 경우, 문서만 바뀐 경우, 옛 버전 파일 형식, fetch 주기와 기다리지 않음을 확인한다.
#   bash tools/test-session-start-check.sh [훅 경로]   (기본: base/hooks/session-start-check.sh)
set -u
root="$(cd "$(dirname "${0}")/.." && pwd)"
hook="${1:-${root}/base/hooks/session-start-check.sh}"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
pass=0; fail=0

git clone -q --bare "${root}" "${tmp}/remote.git"
git clone -q "${tmp}/remote.git" "${tmp}/src"
git -C "${tmp}/src" config user.email t@t; git -C "${tmp}/src" config user.name t
mkdir -p "${tmp}/home/.claude"
tree_of() { git -C "${tmp}/src" rev-parse "${1}:base"; }
OLD=v0.11.4; NEW=v0.12.0
OLD_TREE="$(tree_of "${OLD}")"; MAIN_TREE="$(tree_of origin/main)"

ver() { printf '%s\n' "${tmp}/src" "$@" > "${tmp}/home/.claude/.claude-config-version"; }
run() { printf '{"cwd":"%s","transcript_path":""}' "${tmp}" | HOME="${tmp}/home" CLAUDE_CONFIG_DIR='' bash "${hook}" 2>&1; }
expect() { # $1=기대(alert|behind|quiet) $2=설명
  local out; out="$(run)"
  local got=quiet
  [[ "${out}" == *"낡았습니다"* ]] && got=alert
  [[ "${out}" == *"뒤처져"* ]] && got=behind
  if [[ "${got}" == "${1}" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "실패: ${2} (기대 ${1}, 실제 ${got}) ${out}"; fi
}
at() { git -C "${tmp}/src" checkout -q -B main "${1}"; git -C "${tmp}/src" branch -q -u origin/main; }

# 원격보다 뒤처진 원본(이슈 증상)
at "${OLD}"
ver "${OLD}";                      expect behind '뒤처짐, 옛 형식(태그만)'
ver "${OLD}" "${OLD_TREE}";        expect behind '뒤처짐, 새 형식(트리)'

# 원격과 같은 원본, 태그 뒤에 base/ 밖 커밋만 있음(거짓 경보)
at origin/main
if [[ "$(tree_of "${NEW}")" == "${MAIN_TREE}" ]]; then
  ver "${NEW}";                    expect quiet '문서만 바뀜, 옛 형식 태그'
  ver "${NEW}-2-gdbd7429";         expect quiet '문서만 바뀜, 옛 형식 describe 꼬리'
else
  echo "건너뜀: ${NEW} 이후 base/가 바뀌어 거짓 경보 시험(옛 형식) 불가"
fi
ver "$(git -C "${tmp}/src" describe --tags --always)" "${MAIN_TREE}"; expect quiet '최신 설치, 새 형식'
ver "${OLD}" "${OLD_TREE}";        expect alert 'base 낡음, 새 형식'

# 로컬이 앞섬(push 전 base/ 변경) — 로컬 HEAD 기준
echo x > "${tmp}/src/base/.test-change"; git -C "${tmp}/src" add base/.test-change; git -C "${tmp}/src" commit -q -m t
ver "${NEW}" "${MAIN_TREE}";       expect alert '로컬 base 변경(push 전)'
ver "${NEW}" "$(tree_of HEAD)";    expect quiet '로컬 base 변경을 설치함'

# upstream 없음(분리된 HEAD)
git -C "${tmp}/src" checkout -q --detach origin/main
ver "${NEW}" "${MAIN_TREE}";       expect quiet 'upstream 없음, 최신'
ver "${OLD}" "${OLD_TREE}";        expect alert 'upstream 없음, 낡음'

# 원본 경로가 없음
printf '%s\n' "${tmp}/nowhere" "${OLD}" > "${tmp}/home/.claude/.claude-config-version"; expect quiet '원본 경로 없음'

# fetch 주기 — FETCH_HEAD가 없으면 백그라운드로 받고, 하루 안에는 다시 받지 않음
at origin/main; ver "${NEW}" "${MAIN_TREE}"
rm -f "${tmp}/src/.git/FETCH_HEAD"; run >/dev/null
for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -f "${tmp}/src/.git/FETCH_HEAD" ]] && break; sleep 0.5; done
if [[ -f "${tmp}/src/.git/FETCH_HEAD" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "실패: FETCH_HEAD 없을 때 fetch 안 함"; fi
: > "${tmp}/marker"; sleep 1; run >/dev/null; sleep 2
if [[ "${tmp}/src/.git/FETCH_HEAD" -nt "${tmp}/marker" ]]; then fail=$((fail + 1)); echo "실패: 하루 안에 다시 fetch함"; else pass=$((pass + 1)); fi

# 응답 없는 원격이어도 기다리지 않음(라우팅 안 되는 주소)
git -C "${tmp}/src" remote set-url origin https://10.255.255.1/none.git
rm -f "${tmp}/src/.git/FETCH_HEAD"
start="${SECONDS}"; run >/dev/null; took=$((SECONDS - start))
if [[ "${took}" -le 3 ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "실패: 응답 없는 원격에서 ${took}초 기다림"; fi
pkill -f '10.255.255.1/none.git' 2>/dev/null

echo "통과 ${pass} / 실패 ${fail}"
[[ "${fail}" -eq 0 ]]
