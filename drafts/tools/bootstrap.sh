#!/usr/bin/env bash
# 신규 기기에서 claude-config를 한 줄로 내려받아 설치한다.
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/yanos0218/AI/main/tools/bootstrap.sh)"
# 하는 일: 저장소를 ~/claude-config에 clone(이미 있으면 pull)한 뒤 tools/install.sh 실행.
set -u
REPO_URL="https://github.com/yanos0218/AI.git"
TARGET="${HOME}/claude-config"

if ! command -v git >/dev/null 2>&1; then
  echo "git이 없습니다. 먼저 git을 설치한 뒤 다시 실행하세요." >&2
  exit 1
fi

if [[ -d "${TARGET}/.git" ]]; then
  echo "== 기존 저장소 갱신: ${TARGET}"
  git -C "${TARGET}" pull --ff-only || { echo "git pull 실패 — 수동으로 ${TARGET}에서 확인하세요." >&2; exit 1; }
else
  echo "== 저장소 내려받기: ${TARGET}"
  git clone "${REPO_URL}" "${TARGET}" || exit 1
fi

bash "${TARGET}/tools/install.sh"
