#!/usr/bin/env bash
# PreToolUse(Bash|PowerShell) 훅 — 전역(Issue #141, 2026-09-29 기본 반영). gh issue·pr·release 작성·댓글·수정과
# git commit의 본문을 게시 직전에 검사해 목록 줄바꿈·음슴체 위반이면 exit 2로 막고 사유를 Claude에게 돌려준다.
# CLAUDE.md 규칙은 지시일 뿐 강제가 아니라 계속 빠져서(2026-09-27 커밋 본문 21% 위반, Issue #140) 훅으로 막는다.
# settings.example.json에서 git·gh 명령일 때만 뜨게 등록하고(if 조건), 그래도 대상이 아니면 하위 프로세스 없이 바로 끝낸다.
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *'gh '*issue*|*'gh '*pr*|*'gh '*release*|*git*commit*) ;;
  *) exit 0 ;;
esac
# if 조건 두 개(git·gh)가 같은 명령에 함께 걸리면(heredoc 등 조건을 판정 못 하는 명령) 이 훅이 동시에 두 번 뜬다.
# 같은 도구 호출(tool_use_id)은 먼저 뜬 하나만 검사한다(pre-commit-check.sh와 같은 방식, Issue #148)
if [[ "${input}" =~ \"tool_use_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  once="${TMPDIR:-/tmp}/format-guard.${BASH_REMATCH[1]}"
  mkdir "${once}" 2>/dev/null || exit 0
  trap 'rmdir "${once}" 2>/dev/null' EXIT
fi
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/format_check.py" pre
