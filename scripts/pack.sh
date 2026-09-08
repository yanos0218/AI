#!/usr/bin/env bash
# skills/* 폴더를 dist/<이름>.zip 으로 압축한다.
# 이름이 _로 시작하는 폴더(예: _template)는 제외한다.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"
DIST_DIR="$ROOT_DIR/dist"

mkdir -p "$DIST_DIR"

for skill_path in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_path")"

  if [[ "$skill_name" == _* ]]; then
    continue
  fi

  zip_path="$DIST_DIR/$skill_name.zip"
  rm -f "$zip_path"

  (cd "$SKILLS_DIR" && zip -r "$zip_path" "$skill_name" -x '.*')

  echo "packed: $zip_path"
done
