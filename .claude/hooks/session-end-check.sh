#!/usr/bin/env bash
# Stop 훅 — 이 저장소 전용. Claude가 답변을 마칠 때, 이번 세션에서 파일이 바뀌었는데
# 관련 문서가 한 번도 안 바뀌었으면 한 줄 알린다(막지 않음).
# base/ 변경(기기별 배포에 영향)은 PROGRESS.md §0 표 갱신을 확인한다.
# 그 외 변경은 로컬 git만으로는 관련 Issue를 확인할 수 없어(C-54, 2026-09-12,
# 할 일·문제를 GitHub Issues로 관리) 댓글·닫기 여부를 스스로 점검하라는 안내만 한다.
# 소음이 되면 .claude/settings.json 에서 뺀다 (C-48).
set -u
cd "$(dirname "${0}")/../.." || exit 0
changed="$(git status --porcelain 2>/dev/null | awk '{print $2}')"
[[ -n "${changed}" ]] || exit 0                               # 바뀐 게 없으면 조용히

base_changed=0
printf '%s\n' "${changed}" | grep -qE '^base/' && base_changed=1
progress_changed=0
printf '%s\n' "${changed}" | grep -qE '^docs/PROGRESS\.md$' && progress_changed=1

if [[ "${base_changed}" = 1 ]] && [[ "${progress_changed}" = 0 ]]; then
  cat <<JSON
{"systemMessage":"session-end-check: base/ 변경이 있는데 docs/PROGRESS.md §0(자산 현황·기기별 배포 표)는 갱신되지 않았습니다. 확인하세요."}
JSON
  exit 0
fi

n="$(printf '%s\n' "${changed}" | grep -c .)"
cat <<JSON
{"systemMessage":"session-end-check: 미커밋 변경 ${n}개. 관련 GitHub Issue가 있으면 댓글이나 닫기(Closes #N)를 했는지 확인하세요. PROGRESS·HANDOFF는 §0 표나 결정 사항이 바뀌었을 때만 갱신하면 됩니다."}
JSON
exit 0
