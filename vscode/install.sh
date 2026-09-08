#!/usr/bin/env bash
# 새 Mac/Linux 기기에서 VS Code 확장·설정을 한 번에 맞추는 스크립트.
# 평소 동기화는 VS Code Settings Sync가 담당하고, 이 스크립트는 "처음 세팅"과 "Sync가 꺼진 기기" 용도다.
# 실행: bash vscode/install.sh
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v code >/dev/null || { echo "VS Code CLI(code)가 PATH에 없습니다. VS Code에서 'Shell Command: Install code command' 실행 후 다시 시도하세요." >&2; exit 1; }

echo "== 확장 설치"
grep -v -E '^\s*(#|$)' "$here/extensions.txt" | while read -r ext; do
  code --install-extension "$ext" --force >/dev/null
  echo "  $ext"
done

case "$(uname -s)" in
  Darwin) target="$HOME/Library/Application Support/Code/User/settings.json" ;;
  *)      target="$HOME/.config/Code/User/settings.json" ;;
esac

if [[ -f "$target" ]]; then
  echo "== settings.json 이미 있음 → 덮어쓰지 않음. 필요한 키는 vscode/settings.json에서 직접 옮기세요: $target"
else
  mkdir -p "$(dirname "$target")"
  cp "$here/settings.json" "$target"
  echo "== settings.json 복사 완료: $target"
fi

echo "== 끝. VS Code를 다시 열고 Settings Sync(계정 메뉴 → Backup and Sync Settings)를 켜세요."
