#!/usr/bin/env bash
# 문서 상한·필수 파일 검사. CI(lint.yml)와 로컬에서 같은 스크립트를 쓴다.
# 상한을 넘으면 "줄여라"가 아니라 "docs/로 분리하거나 항목을 파일로 빼라"는 신호다(CLAUDE.md "문서 규칙").
set -u
cd "$(dirname "$0")/../.." || exit 1
fail=0

limit() { # 파일 상한
  local f="$1" max="$2"
  [ -f "$f" ] || { echo "MISSING $f"; fail=1; return; }
  local n; n=$(wc -l < "$f")
  if [ "$n" -gt "$max" ]; then echo "TOO LONG $f: $n > $max"; fail=1; else echo "ok  $f ($n/$max)"; fi
}

limit README.md 120
limit CLAUDE.md 60
limit claude-md/CLAUDE.md 200
limit docs/HANDOFF.md 60
limit docs/PROGRESS.md 300
limit CHANGELOG.md 400
for s in skills/*/SKILL.md drafts/skills/*/SKILL.md; do [ -f "$s" ] && limit "$s" 80; done

# README 구조 목록에 적힌 경로가 실제로 있는지
while read -r p; do
  [ -e "$p" ] || { echo "README lists missing path: $p"; fail=1; }
done < <(grep -oE '^(claude-md|skills|scripts|vscode|drafts|docs|\.claude|\.github)/[^ ]*|^(CHANGELOG|CLAUDE)\.md' README.md | sort -u)

exit $fail
