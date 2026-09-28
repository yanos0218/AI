#!/usr/bin/env bash
# config-changelog 셸 입구(Issue #144). ~/.claude 경로가 나오는 입력만 파이썬 본체(config_changelog.py)로 넘기고 나머지는 하위 프로세스 없이 바로 끝낸다.
# 기록 훅이라 파이썬이 없거나 실패하면 조용히 통과한다(오류는 본체가 ~/.claude/hook-errors.log에 남김).
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *.claude*) ;;
  *) exit 0 ;;
esac
if hash python 2>/dev/null; then PY=python; elif hash python3 2>/dev/null; then PY=python3; else exit 0; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/config_changelog.py"
exit 0
