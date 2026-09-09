#!/usr/bin/env bash
# base/skills/* 폴더를 dist/<이름>.zip 으로 압축한다 (Claude.ai Customize → Skills 업로드용).
# 이름이 _로 시작하는 폴더(예: _template)와 숨김 파일은 제외한다.
# zip 명령이 없는 환경(Windows Git Bash)에서는 python zipfile로 같은 규칙을 적용한다(C-29).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/base/skills"
DIST_DIR="$ROOT_DIR/dist"
PY="$(command -v python3 || command -v python || true)"
mkdir -p "$DIST_DIR"

for skill_path in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_path")"
  [[ "$skill_name" == _* ]] && continue
  zip_path="$DIST_DIR/$skill_name.zip"
  rm -f "$zip_path"
  if command -v zip >/dev/null 2>&1; then
    (cd "$SKILLS_DIR" && zip -qr "$zip_path" "$skill_name" -x '.*' '*/.*')
  else
    "$PY" - "$SKILLS_DIR" "$skill_name" "$zip_path" <<'PY'
import sys, zipfile, pathlib
root, name, out = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in sorted((root / name).rglob('*')):
        rel = f.relative_to(root)
        if f.is_file() and not any(p.startswith('.') for p in rel.parts):
            z.write(f, rel.as_posix())
PY
  fi
  echo "packed: $zip_path"
done
