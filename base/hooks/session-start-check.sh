#!/usr/bin/env bash
# SessionStart 훅(전역, matcher: startup) — 새 세션이 시작될 때마다 조용히 두 가지를 확인한다.
# 1) ~/.claude/ 설치본이 원본 저장소(claude-config)의 최신 base/보다 낡았는지
# 2) 지금 연 저장소에 최소 표준(CLAUDE.md)이 있는지
# 읽기만 한다 — 파일을 쓰거나 지우지 않는다. 조건에 안 걸리면 아무 말도 안 한다(2026-09-12, Issue #62).
set -u
input="$(cat)"
PY="$(command -v python3 || command -v python || true)"

get_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${input}" | jq -r ".${1} // empty" 2>/dev/null
  elif [[ -n "${PY}" ]]; then
    printf '%s' "${input}" | "${PY}" -c "import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('${1}') or '')
except Exception:
    print('')" 2>/dev/null
  fi
}

CWD="$(get_field cwd)"
[[ -n "${CWD}" ]] || exit 0

# 1. 전역 설정 버전 확인
VER_FILE="${HOME}/.claude/.claude-config-version"
if [[ -f "${VER_FILE}" ]]; then
  SRC_PATH="$(sed -n '1p' "${VER_FILE}" 2>/dev/null)"
  INSTALLED_VER="$(sed -n '2p' "${VER_FILE}" 2>/dev/null)"
  if [[ -n "${SRC_PATH}" ]] && [[ -d "${SRC_PATH}/.git" ]]; then
    CURRENT_VER="$(git -C "${SRC_PATH}" describe --tags --always 2>/dev/null || true)"
    if [[ -n "${CURRENT_VER}" ]] && [[ -n "${INSTALLED_VER}" ]] && [[ "${CURRENT_VER}" != "${INSTALLED_VER}" ]]; then
      echo "[claude-config] 전역 설정이 낡았습니다(설치됨 ${INSTALLED_VER} → 최신 ${CURRENT_VER}). \"${SRC_PATH}\"에서 bash tools/install.sh 로 갱신하세요."
    fi
  fi
fi

# 2. 저장소 최소 표준 확인
if REPO_ROOT="$(git -C "${CWD}" rev-parse --show-toplevel 2>/dev/null)"; then
  if [[ ! -f "${REPO_ROOT}/CLAUDE.md" ]] && [[ ! -f "${REPO_ROOT}/.claude/.no-repo-setup-suggest" ]]; then
    echo "[claude-config] 이 저장소엔 CLAUDE.md가 없습니다. repo-setup 스킬로 최소 표준 확인을 이 세션에서 한 번 제안하세요. 사용자가 원치 않으면 \"${REPO_ROOT}/.claude/.no-repo-setup-suggest\"를 만들어 다음부턴 묻지 마세요."
  fi
fi

exit 0
