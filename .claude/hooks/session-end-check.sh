#!/usr/bin/env bash
# Stop 훅 — 이 저장소 전용. Claude가 답변을 마칠 때, 이번 세션에서 파일이 바뀌었는데
# docs/PROGRESS.md·docs/HANDOFF.md 가 한 번도 안 바뀌었으면 한 줄 알린다(막지 않음).
# 소음이 되면 .claude/settings.json 에서 뺀다 (C-48).
set -u
cd "$(dirname "$0")/../.." || exit 0
changed="$(git status --porcelain 2>/dev/null | awk '{print $2}')"
[ -n "$changed" ] || exit 0                                  # 바뀐 게 없으면 조용히
docs_changed=0
printf '%s\n' "$changed" | grep -qE '^docs/(PROGRESS|HANDOFF)\.md$' && docs_changed=1
if [ "$docs_changed" = 0 ]; then
  n="$(printf '%s\n' "$changed" | grep -c .)"
  cat <<JSON
{"systemMessage":"session-end-check: 미커밋 변경 ${n}개가 있는데 docs/PROGRESS.md·HANDOFF.md 는 갱신되지 않았습니다. 작업 단위가 끝났으면 보드와 현재 상태를 갱신하세요."}
JSON
fi
exit 0
