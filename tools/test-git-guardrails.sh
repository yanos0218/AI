#!/usr/bin/env bash
# git-guardrails 훅의 판정과 오류 안전망, 설정의 onFailure 등록을 시험한다(Issue #211). 실제 설정은 건드리지 않는다.
#   bash tools/test-git-guardrails.sh
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
# python3·python 중 실제로 실행되는 것을 고른다(Windows 스토어 별칭 python3는 이름만 있고 실행하면 실패, Issue #255)
PY=""; for c in python3 python; do p="$(command -v "${c}" 2>/dev/null)" && "${p}" -c 'import sys' >/dev/null 2>&1 && { PY="${p}"; break; }; done
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
HOOK="${GG_HOOK:-base/hooks/git-guardrails.sh}"  # 다른 훅 파일 시험은 GG_HOOK=<경로>
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

echo "== 1. 판정은 그대로"
out="$(printf '%s' '{"tool_input":{"command":"ls"}}' | bash "${HOOK}")"; rc=$?
chk "평범한 명령: 출력 없음, 종료 코드 0"      '[[ -z "${out}" && "${rc}" = 0 ]]'
out="$(printf '%s' '{"tool_input":{"command":"git push origin main"}}' | bash "${HOOK}")"; rc=$?
chk "git push: 확인(ask) 한 줄, 종료 코드 0"   '[[ "${rc}" = 0 && "$(printf "%s\n" "${out}" | wc -l | tr -d " ")" = 1 ]] && grep -q "\"permissionDecision\":\"ask\"" <<<"${out}"'
chk "git push: 안전망 문구가 섞이지 않음"       '! grep -q "예상 밖 오류" <<<"${out}"'

echo "== 2. 오류 안전망: 스크립트가 예상 밖으로 죽으면 전체 차단 대신 확인(ask)"
# 미정의 변수 참조를 심은 사본으로 set -u 오류(종료 코드 1)를 일으킨다
awk '{print} /^trap on_exit EXIT$/{print ": \"${GG_UNDEFINED_VAR}\""}' "${HOOK}" > "${T}/inject.sh"
out="$(printf '%s' '{"tool_input":{"command":"ls"}}' | bash "${T}/inject.sh" 2>/dev/null)"; rc=$?
chk "오류 주입: 종료 코드 0"                    '[[ "${rc}" = 0 ]]'
chk "오류 주입: 확인(ask)과 안전망 문구"         'grep -q "\"permissionDecision\":\"ask\"" <<<"${out}" && grep -q "예상 밖 오류" <<<"${out}"'
chk "오류 주입: 출력은 JSON 한 줄"               '[[ "$(printf "%s\n" "${out}" | wc -l | tr -d " ")" = 1 ]] && "${PY}" -c "import json,sys;json.loads(sys.argv[1])" "${out}"'
# 대조: 안전망(트랩)을 뺀 사본은 같은 오류로 종료 코드 1이 되어 onFailure block이면 모든 명령이 막힘
awk '/^trap on_exit EXIT$/{next} {print} /^set -u$/{print ": \"${GG_UNDEFINED_VAR}\""}' "${HOOK}" > "${T}/control.sh"
printf '%s' '{"tool_input":{"command":"ls"}}' | bash "${T}/control.sh" >/dev/null 2>&1; rc=$?
chk "대조(안전망 없음): 같은 오류가 종료 코드 1"   '[[ "${rc}" = 1 ]]'

echo "== 3. 설정 등록"
"${PY}" - base/settings.example.json <<'PYEOF' ; rc=$?
import io, json, sys
d = json.load(io.open(sys.argv[1], encoding='utf-8'))
with_block, without = [], []
for groups in d['hooks'].values():
    for g in groups:
        for h in g.get('hooks', []):
            (with_block if h.get('onFailure') == 'block' else without).append(h['command'])
ok = len(with_block) == 1 and 'git-guardrails.sh' in with_block[0]
print('onFailure block entries: %s' % with_block)  # 한글을 쓰면 Windows 파이프(cp1252)에서 UnicodeEncodeError가 난다
sys.exit(0 if ok else 1)
PYEOF
chk "onFailure block은 git-guardrails 하나에만"  '[[ "${rc}" = 0 ]]'

echo "== 4. git과 하위 명령 사이에 옵션이 낀 형태도 판정(Issue #268)"
# 인자는 JSON 문자열 안에 들어갈 명령 원문(큰따옴표는 JSON처럼 \" 로 적어 넘긴다)
run_hook() { printf '{"tool_input":{"command":"%s"}}' "$1" | bash "${HOOK}"; }
n_ask=0; n_pass=0
for c in \
  'git push origin main' \
  'git -C /tmp/x push origin main' \
  'git -C /tmp/x push --force origin main' \
  'git -c user.name=a push' \
  'git --no-pager push' \
  'git --git-dir=/tmp/x/.git push' \
  'git --git-dir /tmp/x/.git --work-tree /tmp/x push' \
  'git -C /tmp/x reset --hard' \
  'git -C /tmp/x clean -fd' \
  'git -C /tmp/x branch -D x' \
  'git -C /tmp/x checkout -- .' \
  'git -C /tmp/x restore .' \
  'git -C /tmp/x tag -d v1' \
  'git -C \"C:/my dir/x\" push origin main' \
  "git -C 'C:/my dir/x' push origin main" \
  'git -C /tmp/x -c a=b --no-pager push' \
  'cd /tmp/x && git -C . push'
do
  out="$(run_hook "${c}")"
  n_ask=$((n_ask + 1))
  chk "ask: ${c}" 'grep -q "\"permissionDecision\":\"ask\"" <<<"${out}" && ! grep -q "예상 밖 오류" <<<"${out}"'
done
for c in \
  'git -C /tmp/x status' \
  'git --no-pager log -5' \
  'git -c a=b commit -m x' \
  'git -C /tmp/x diff' \
  'git -C \"C:/my dir/x\" status' \
  'git fetch origin'
do
  out="$(run_hook "${c}")"
  n_pass=$((n_pass + 1))
  chk "통과(출력 없음): ${c}" '[[ -z "${out}" ]]'
done
printf '  시험 건수: ask %s건, 통과 %s건\n' "${n_ask}" "${n_pass}"
# 느린 판정 방지: 긴 옵션 나열도 제한 시간(5초) 안에 끝나야 함
long="git"; for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do long="${long} -c a=b --no-pager"; done
t0=$SECONDS; out="$(run_hook "${long} push")"; dt=$((SECONDS - t0))
chk "옵션 20쌍이 낀 push: ask, ${dt}초(2초 미만)" 'grep -q "\"permissionDecision\":\"ask\"" <<<"${out}" && [[ "${dt}" -lt 2 ]]'
long="git"; for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do long="${long} -c a=b --no-pager"; done
t0=$SECONDS; out="$(run_hook "${long} status")"; dt=$((SECONDS - t0))
chk "옵션 20쌍이 낀 status: 통과, ${dt}초(2초 미만)" '[[ -z "${out}" && "${dt}" -lt 2 ]]'

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
