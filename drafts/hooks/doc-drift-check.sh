#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅 초안 — 전역 후보(Issue #219). `git commit`을 실행하려 할 때 이번 커밋 때문에 문서가 낡았는지만 알린다(경고만, 막지 않음).
# 삭제·이름변경된 경로가 다른 .md에 남았는지, 스테이징한 .md의 상대 링크 대상이 있는지, CHANGELOG 릴리즈 섹션에 "다음 컷"이 남았는지 본다.
# 모든 Bash 호출마다 돌므로 commit 글자가 없으면 하위 프로세스 없이 바로 끝낸다(Issue #143).
set -u
IFS= read -r -d '' input || true
case "${input}" in
  *commit*) ;;
  *) exit 0 ;;
esac
# if 조건이 겹쳐 같은 호출에 훅이 두 번 뜨면 먼저 뜬 하나만 검사한다(Issue #148)
if [[ "${input}" =~ \"tool_use_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  once="${TMPDIR:-/tmp}/doc-drift-check.${BASH_REMATCH[1]}"
  mkdir "${once}" 2>/dev/null || exit 0
  trap 'rmdir "${once}" 2>/dev/null' EXIT
fi
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
[[ "${0}" == */* ]] && here="${0%/*}" || here=.
printf '%s' "${input}" | PYTHONIOENCODING=utf-8 "${PY}" "${here}/doc_drift.py"
exit 0
