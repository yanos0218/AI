#!/usr/bin/env bash
# easy-explain-hint 훅 초안 시험(Issue #222). 사용법: bash tools/test-easy-explain.sh
set -u
here="$(cd "$(dirname "${0}")/.." && pwd)"
hook="${here}/drafts/hooks/easy-explain-hint.sh"
pass=0; fail=0
check() { # 이름 입력 기대(hit|none)
  local out; out="$(printf '%s' "${2}" | bash "${hook}")"
  local got=none; case "${out}" in *additionalContext*) got=hit;; esac
  if [ "${got}" = "${3}" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "실패: ${1} (기대 ${3}, 결과 ${got})"; fi
}
check 쉽게다시설명 '{"prompt":"쉽게 다시 설명해줘"}' hit
check 쉬운말로 '{"prompt":"쉬운 말로 설명해줘"}' hit
check 이해안돼 '{"prompt":"이게 이해가 안 돼"}' hit
check 무슨말 '{"prompt":"그게 무슨 말이야"}' hit
check 쉽게알려줘 '{"prompt":"어떤 내용인지 쉽게 알려줘"}' hit
check 일상표현 '{"prompt":"이거 쉽게 고칠 수 있나?"}' none
check 무관 '{"prompt":"커밋해줘"}' none
check 깨진JSON '{"prompt":"쉽게 설명' none
check 빈입력 '' none
echo "통과 ${pass}건, 실패 ${fail}건"
[ "${fail}" -eq 0 ]
