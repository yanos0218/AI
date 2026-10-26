#!/usr/bin/env bash
# UserPromptSubmit 훅 초안(Issue #222 조사, #220 후보 "쉬운 설명 요청 반복"). 사용자가 쉬운 설명을 다시 요청한 말이면
# 전역 §2의 "결론 한 줄 + 비유나 예시 하나" 지침을 additionalContext로 붙인다. 막지 않고 알림만 하며, 오류는 조용히 지나간다.
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *쉽게*|*쉬운*|*이해*|*무슨\ 말*) ;;
  *) exit 0 ;;
esac
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/easy_explain.py"
exit 0
