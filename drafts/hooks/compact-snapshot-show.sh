#!/usr/bin/env bash
# SessionStart 훅(전역, matcher: compact) — 컴팩션 직후 compact-snapshot.sh(PreCompact)가
# 저장한 스냅샷을 보여주고 파일을 지운다(다음 컴팩션 때 새로 써서 쌓이지 않게). (Issue #104)
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

SNAP_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/compact-snapshots"
SLUG="$(printf '%s' "${CWD}" | tr -c 'A-Za-z0-9' '_')"
SNAP_FILE="${SNAP_DIR}/${SLUG}.md"

if [[ -f "${SNAP_FILE}" ]]; then
  echo "[claude-config] 컴팩션 직전 스냅샷(요약에서 빠졌을 수 있는 정보 — 대조해서 필요하면 보완):"
  cat "${SNAP_FILE}"
  rm -f "${SNAP_FILE}"
fi

exit 0
