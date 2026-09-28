#!/usr/bin/env bash
# PreToolUse(Bash|PowerShell) 훅 초안 — 전역용(Issue #141). gh issue·pr·release 작성·댓글·수정과
# git commit의 본문을 게시 직전에 검사해 목록 줄바꿈·음슴체 위반이면 exit 2로 막고 사유를 Claude에게 돌려준다.
# CLAUDE.md 규칙은 지시일 뿐 강제가 아니라 계속 빠져서(2026-09-27 커밋 본문 21% 위반, Issue #140) 훅으로 막는다.
# 모든 Bash 호출마다 돌기 때문에 대상 명령이 아니면 하위 프로세스 없이 바로 끝낸다(Windows는 프로세스 하나에 0.3초 안팎).
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *'gh '*issue*|*'gh '*pr*|*'gh '*release*|*git*commit*) ;;
  *) exit 0 ;;
esac
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/format_check.py" pre
