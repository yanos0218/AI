#!/usr/bin/env bash
# tools/ci-wait.sh 시험(Issue #229). 가짜 gh를 PATH 앞에 두어 GitHub 없이 판정 규칙을 확인한다.
# 가짜 gh는 jq 적용 뒤의 출력을 그대로 돌려주므로 실제 --jq 식은 시험하지 못한다. 그건 실제 커밋에 직접 돌려 확인한다.
#   bash tools/test-ci-wait.sh
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
SCRIPT="$(pwd)/tools/ci-wait.sh"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
BIN="${T}/bin"; mkdir -p "${BIN}"
FAKE="${T}/fake"; mkdir -p "${FAKE}"
CALLS="${T}/calls.log"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# 시험용 git 저장소(커밋 하나)
REPO="${T}/repo"; mkdir -p "${REPO}"
git -C "${REPO}" init -q
git -C "${REPO}" -c user.name=t -c user.email=t@t commit -q --allow-empty -m 시험
SHA="$(git -C "${REPO}" rev-parse HEAD)"

# 가짜 gh. run list는 FAKE/list.<호출순번>이 있으면 그 내용, 없으면 FAKE/list를 돌려준다(등록 지연 시험).
# run watch는 FAKE/<ID>.watchrc 값으로 끝나고, run view는 FAKE/<ID>.view를 그대로 출력한다.
cat > "${BIN}/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "${CALLS}"
case "$1 $2" in
  "run list")
    n=$(( $(cat "${FAKE}/listcount" 2>/dev/null || echo 0) + 1 )); echo "${n}" > "${FAKE}/listcount"
    if [[ -f "${FAKE}/list.${n}" ]]; then cat "${FAKE}/list.${n}"; elif [[ -f "${FAKE}/list" ]]; then cat "${FAKE}/list"; fi ;;
  "run watch") exit "$(cat "${FAKE}/$3.watchrc" 2>/dev/null || echo 0)" ;;
  "run view")
    if [[ "$*" == *"--json status"* ]]; then
      n=$(( $(cat "${FAKE}/$3.stcount" 2>/dev/null || echo 0) + 1 )); echo "${n}" > "${FAKE}/$3.stcount"
      if [[ -f "${FAKE}/$3.status.${n}" ]]; then cat "${FAKE}/$3.status.${n}"; else echo completed; fi
    else cat "${FAKE}/$3.view"; fi ;;
esac
EOF
chmod +x "${BIN}/gh"
export CALLS FAKE CI_WAIT_SLEEP=0

reset() { rm -f "${FAKE}"/* "${CALLS}"; : > "${CALLS}"; }
run() { PATH="${BIN}:${PATH}" bash "${SCRIPT}" "${REPO}" 2>&1; }
view() { # $1=ID $2=run 결론, 나머지는 "결론:이름" job들
  local id="$1" c="$2"; shift 2
  { printf 'run|워크플로%s|%s\n' "${id}" "${c}"; for j in "$@"; do printf 'job|%s|%s\n' "${j%%:*}" "${j#*:}"; done; } > "${FAKE}/${id}.view"
}

echo "== 1. 전부 성공"
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success success:lint success:test
out="$(run)"; rc=$?
chk "종료 코드 0"                                  '[[ "${rc}" = 0 ]]'
chk "마지막 줄: CI 통과 — 실행 1건, job 2개"        '[[ "$(tail -n1 <<< "${out}")" = "CI 통과 — 실행 1건, job 2개 (커밋 ${SHA:0:7})" ]]'
chk "목록 조회에 전체 SHA 40자를 넘김"              'grep -q -- "--commit ${SHA} " "${CALLS}" && [[ ${#SHA} = 40 ]]'
chk "watch를 --exit-status로 호출"                 'grep -q "^run watch 100 --exit-status" "${CALLS}"'

echo "== 2. job 하나 실패"
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 failure success:lint failure:test; echo 1 > "${FAKE}/100.watchrc"
out="$(run)"; rc=$?
chk "종료 코드 1"                                  '[[ "${rc}" = 1 ]]'
chk "실패 job 이름이 출력됨"                        'grep -q "성공·건너뜀 아님 test" <<< "${out}"'
chk "로그 안내에 실행 ID가 들어감"                  'grep -q "gh run view 100 --log-failed" <<< "${out}"'

echo "== 3. 실행 0건"
reset
out="$(run)"; rc=$?
chk "종료 코드 2"                                  '[[ "${rc}" = 2 ]]'
chk "미검증이라고 보고, 통과라고 쓰지 않음"          'grep -q "CI 미검증" <<< "${out}" && ! grep -q "CI 통과" <<< "${out}"'
chk "목록 조회를 처음 1번 + 다시 3번 = 4번 함"        '[[ "$(grep -c "^run list" "${CALLS}")" = 4 ]]'

echo "== 4. 등록 지연(처음엔 비었다가 다시 조회하면 생김)"
reset; view 100 success success:lint; printf '100\tpush\n' > "${FAKE}/list.3"
out="$(run)"; rc=$?
chk "다시 조회해서 통과로 끝남"                      '[[ "${rc}" = 0 ]] && grep -q "CI 통과" <<< "${out}"'
chk "목록 조회는 3번에서 멈춤"                       '[[ "$(grep -c "^run list" "${CALLS}")" = 3 ]]'

echo "== 5. 워크플로 둘 이상"
reset; printf '100\tpush\n200\tpull_request\n' > "${FAKE}/list"; view 100 success success:lint; view 200 success success:a success:b
out="$(run)"; rc=$?
chk "둘 다 watch함"                                 'grep -q "^run watch 100 " "${CALLS}" && grep -q "^run watch 200 " "${CALLS}"'
chk "합산: 실행 2건, job 3개"                        '[[ "${rc}" = 0 ]] && grep -q "실행 2건, job 3개" <<< "${out}"'
reset; printf '100\tpush\n200\tpull_request\n' > "${FAKE}/list"; view 100 success success:lint; view 200 failure success:a failure:b
out="$(run)"; rc=$?
chk "하나라도 실패하면 종료 코드 1, 첫 실패 실행 ID 안내" '[[ "${rc}" = 1 ]] && grep -q "gh run view 200 --log-failed" <<< "${out}"'

echo "== 6. 실행 단위 skipped·cancelled는 통과로 세지 않음"
for c in skipped cancelled; do
  reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 "${c}" "${c}:lint"
  out="$(run)"; rc=$?
  chk "${c}: 종료 코드 1, CI 통과 문구 없음"           '[[ "${rc}" = 1 ]] && ! grep -q "CI 통과" <<< "${out}"'
done
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success success:lint skipped:comment-check
out="$(run)"; rc=$?
chk "실행이 success면 안의 skipped job은 정상, 건너뜀 개수를 알림" '[[ "${rc}" = 0 ]] && grep -q "job 2개, 건너뜀 1개" <<< "${out}"'
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success success:lint failure:test
out="$(run)"; rc=$?
chk "실행이 success로 읽혀도 failure job이 있으면 통과 아님"   '[[ "${rc}" = 1 ]] && ! grep -q "CI 통과" <<< "${out}"'

echo "== 6-2. 이슈 이벤트 실행은 세지 않음"
reset; printf '300\tissues\n100\tpush\n400\tissue_comment\n' > "${FAKE}/list"; view 100 success success:lint
out="$(run)"; rc=$?
chk "push 실행만 watch함, 통과"                       '[[ "${rc}" = 0 ]] && grep -q "^run watch 100 " "${CALLS}" && ! grep -q "^run watch 300 \|^run watch 400 " "${CALLS}"'
reset; printf '300\tissues\n' > "${FAKE}/list"
out="$(run)"; rc=$?
chk "이슈 이벤트 실행뿐이면 0건과 같이 미검증(종료 코드 2)" '[[ "${rc}" = 2 ]] && grep -q "CI 미검증" <<< "${out}"'

echo "== 6-3. 결론이 빈 job(끝나지 않음)은 통과로 세지 않음 (Issue #232)"
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success success:lint :test
out="$(run)"; rc=$?
chk "run이 success여도 빈 결론 job이 있으면 종료 코드 1, CI 통과 문구 없음" '[[ "${rc}" = 1 ]] && ! grep -q "CI 통과" <<< "${out}"'
chk "미완료 job 이름이 실패 목록에 들어감"           'grep -q "성공·건너뜀 아님 test" <<< "${out}"'

echo "== 6-4. watch가 끝나기 전에 돌아오면 다시 기다림 (Issue #232)"
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success success:lint success:test; echo in_progress > "${FAKE}/100.status.1"
out="$(run)"; rc=$?
chk "처음 상태가 in_progress면 watch를 다시 함, 통과"   '[[ "${rc}" = 0 ]] && [[ "$(grep -c "^run watch 100 " "${CALLS}")" = 2 ]]'
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success success:lint; for i in 1 2 3 4 5 6 7 8; do echo in_progress > "${FAKE}/100.status.${i}"; done
out="$(run)"; rc=$?
chk "끝내 안 끝나면 다시 하는 횟수에서 멈추고 통과 아님"  '[[ "${rc}" = 1 ]] && ! grep -q "CI 통과" <<< "${out}" && [[ "$(grep -c "^run watch 100 " "${CALLS}")" -le 5 ]]'

echo "== 7. 결과를 읽지 못함 / job 0개"
reset; printf '100\tpush\n' > "${FAKE}/list"; : > "${FAKE}/100.view"
out="$(run)"; rc=$?
chk "view가 비면 종료 코드 1"                        '[[ "${rc}" = 1 ]] && grep -q "결과를 읽지 못함" <<< "${out}"'
reset; printf '100\tpush\n' > "${FAKE}/list"; view 100 success
out="$(run)"; rc=$?
chk "run은 성공이어도 job 0개면 통과로 세지 않음"      '[[ "${rc}" = 1 ]] && ! grep -q "CI 통과" <<< "${out}"'

echo "== 8. 저장소가 아닌 경로"
out="$(PATH="${BIN}:${PATH}" bash "${SCRIPT}" "${T}/없는폴더" 2>&1)"; rc=$?
chk "종료 코드 2"                                  '[[ "${rc}" = 2 ]]'

echo
if [[ "${fail}" = 0 ]]; then echo "전체 통과"; else echo "실패 있음"; exit 1; fi
