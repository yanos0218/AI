#!/usr/bin/env bash
# git-guardrails 훅의 판정과 오류 안전망, 설정의 onFailure 등록을 시험한다(Issue #211). 실제 설정은 건드리지 않는다.
#   bash tools/test-git-guardrails.sh
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
PY="$(command -v python3 || command -v python)"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
HOOK="base/hooks/git-guardrails.sh"
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

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
