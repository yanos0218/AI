#!/usr/bin/env bash
# SessionStart 훅 — 이 저장소 전용(Issue #192). docs/HANDOFF.md "지금" 절의 목록에서 가리키는 이슈 중
# 이미 닫힌 것이 있으면 한 줄로 알린다(출력은 Claude의 컨텍스트로 들어감). 정상이면 아무것도 출력하지 않는다.
# HANDOFF가 이슈 상태의 사본이라 낡기 쉬웠다(2026-10-21, 기각해 닫은 이슈를 다음 할 일로 추천한 사례).
# 네트워크·gh가 없거나 실패하면 조용히 끝낸다(세션 시작을 막지 않는다).
set -u
cd "$(dirname "${0}")/../.." || exit 0
f="docs/HANDOFF.md"
[[ -f "${f}" ]] || exit 0
command -v gh >/dev/null 2>&1 || exit 0
# "## 지금" 절의 목록 줄(- 로 시작)에서 이슈 번호를 모은다. 제목 줄의 번호(마지막 월 점검 등)는 닫혀 있어도 정상이라 뺀다
nums="$(awk '/^## 지금/{on=1; next} /^## /{on=0} on && /^- / && !/닫음|닫았/' "${f}" | grep -oE '#[0-9]+' | tr -d '#' | sort -un)"
[[ -n "${nums}" ]] || exit 0
# 이슈 번호 하나마다 gh를 부르면 느리므로 한 번에 받는다. 기본 --limit은 30이라 넉넉히 받는다
closed="$(gh issue list --state closed --limit 300 --json number --jq '.[].number' 2>/dev/null)" || exit 0
stale=""
for n in ${nums}; do
  if printf '%s\n' "${closed}" | grep -qx "${n}"; then stale="${stale} #${n}"; fi
done
[[ -n "${stale}" ]] || exit 0
echo "[handoff-check] docs/HANDOFF.md \"지금\" 절이 이미 닫힌 이슈를 가리킴:${stale}. 이 내용을 믿지 말고 gh issue list --state open으로 확인한 뒤, 세션 끝에 HANDOFF에서 고칠 것."
