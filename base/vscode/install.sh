#!/usr/bin/env bash
# 새 Mac/Linux 기기에서 VS Code 확장·설정을 한 번에 맞추는 스크립트.
# 평소 동기화는 VS Code Settings Sync가 담당하고, 이 스크립트는 "처음 세팅"과 "Sync가 꺼진 기기" 용도다.
# 실행: bash base/vscode/install.sh
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MAC_APP_CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if command -v code >/dev/null; then
  CODE=code
  # WSL에서 PATH의 code가 /mnt 아래(Windows VS Code)면 확장은 Windows 쪽에 들어가고 settings.json은 Windows가 읽지 않는 WSL 홈에 복사된다(Issue #204). 마운트 위치를 바꿨으면 WIN_MOUNT_ROOT로 지정
  code_path="$(command -v code)"
  if [[ "${code_path}" == "${WIN_MOUNT_ROOT:-/mnt/}"* ]] \
    && { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; }; then
    {
      echo "WSL에서 PATH의 code가 Windows VS Code입니다: ${code_path}"
      echo "여기서 실행하면 확장이 Windows 쪽에 들어가고 settings.json은 Windows가 읽지 않는 WSL 홈에 복사되므로 멈춥니다."
      echo "  - Windows VS Code를 맞추려면 Windows에서 base/vscode/install.ps1을 실행하세요."
      echo "  - WSL 안 VS Code(Remote - WSL)를 맞추려면 WSL 쪽 code가 PATH에 먼저 오게 한 뒤 다시 실행하세요."
    } >&2
    exit 1
  fi
elif [[ "$(uname -s)" == "Darwin" ]] && [[ -x "${MAC_APP_CODE}" ]]; then
  CODE="${MAC_APP_CODE}"
  echo "== code가 PATH에 없어 Mac 앱 내장 경로를 씀: ${CODE}"
else
  echo "VS Code CLI(code)가 PATH에 없습니다. VS Code에서 'Shell Command: Install code command' 실행 후 다시 시도하세요." >&2
  exit 1
fi

echo "== 확장 설치"
grep -v -E '^\s*(#|$)' "${here}/extensions.txt" | while read -r ext; do
  "${CODE}" --install-extension "${ext}" --force >/dev/null
  echo "  ${ext}"
done

case "$(uname -s)" in
  Darwin) target="${HOME}/Library/Application Support/Code/User/settings.json" ;;
  *)      target="${HOME}/.config/Code/User/settings.json" ;;
esac

if [[ -f "${target}" ]]; then
  echo "== settings.json 이미 있음 → 덮어쓰지 않음. 필요한 키는 base/vscode/settings.json에서 직접 옮기세요: ${target}"
else
  mkdir -p "$(dirname "${target}")"
  cp "${here}/settings.json" "${target}"
  echo "== settings.json 복사 완료: ${target}"
fi

echo "== 끝. VS Code를 다시 열고 Settings Sync(계정 메뉴 → Backup and Sync Settings)를 켜세요."
