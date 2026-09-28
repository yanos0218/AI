#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit) 훅 초안 — 전역용(Issue #141). .md에 새로 쓴 내용만 목록 줄바꿈 규칙으로 검사해
# 위반이면 exit 2로 사유를 Claude에게 돌려준다(파일은 이미 저장됨, Claude가 이어서 고침).
# 기존 문서의 옛 위반까지 보면 편집마다 같은 사유가 되풀이돼 토큰이 새므로 이번에 쓴 부분만 본다.
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *'.md"'*|*'.MD"'*) ;;
  *) exit 0 ;;
esac
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/format_check.py" post
