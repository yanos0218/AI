#!/usr/bin/env bash
# SessionStart 훅(전역, matcher: startup) — 새 세션이 시작될 때마다 조용히 네 가지를 확인한다.
# 1) ~/.claude/ 설치본이 원본 저장소(claude-config)의 최신 base/보다 낡았는지
# 2) 지금 연 저장소에 최소 표준(CLAUDE.md)이 있는지
# 3) self-audit(base/skills/self-audit)을 안 돌린 지 세션이 많이 쌓였는지
# 4) 대량 조회(서브에이전트 위임 없이 직접 실행)가 얼마나 쌓였는지
# 읽기만 한다 — 파일을 쓰거나 지우지 않는다. 조건에 안 걸리면 아무 말도 안 한다(2026-09-12, Issue #62 / 2026-09-13, 3번 추가 / 2026-09-15, 4번 추가).
#
# 4번 배경: PreToolUse/PostToolUse 훅이 매 도구 호출마다 Claude에게 실시간으로
# 알려주는 게 기술적으로 안 됨을 실제 세션 3개로 확인함(systemMessage·평문 stdout
# 전부 트랜스크립트 로그에만 남고 모델 컨텍스트엔 주입 안 됨). 그래서 대량 조회를
# bulk-read-log.sh(PostToolUse)가 조용히 기록만 하고, 이 SessionStart 훅이 쌓인
# 개수를 세서(self-audit과 같은 방식) 다음 세션 시작 때 알려준다.
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

# 3. self-audit 오래됨 확인 — transcript_path(이 세션 트랜스크립트 파일)의 폴더에
# 감사 표시 파일(.self-audit-marker, self-audit 스킬이 씀)이 있으면 그때의 세션 개수와
# 지금 세션 개수를 비교한다. 15개쯤 쌓였으면 알려만 준다 — 실행(비용 발생)은 사용자 몫.
TRANSCRIPT_PATH="$(get_field transcript_path)"
if [[ -n "${TRANSCRIPT_PATH}" ]]; then
  PROJ_DIR="$(dirname "${TRANSCRIPT_PATH}")"
  if [[ -d "${PROJ_DIR}" ]]; then
    CUR_N="$(ls "${PROJ_DIR}"/*.jsonl 2>/dev/null | wc -l)"
    LAST_N=0
    MARKER="${PROJ_DIR}/.self-audit-marker"
    if [[ -f "${MARKER}" ]]; then
      READ_N="$(sed -n '1p' "${MARKER}" 2>/dev/null)"
      [[ "${READ_N}" =~ ^[0-9]+$ ]] && LAST_N="${READ_N}"
    fi
    if (( CUR_N - LAST_N >= 15 )); then
      echo "[claude-config] self-audit 안 돌린 지 세션 $((CUR_N - LAST_N))개 지났습니다. CLAUDE.md가 실제 작업 방식과 어긋났는지 보려면 \"self-audit 해줘\"라고 하세요."
    fi
  fi
fi

# 4. 대량 조회 로그 누적 확인 — bulk-read-log.sh가 조용히 기록한 표의 데이터 행 개수.
# 10건 넘으면 알려만 준다. 검토 후 표 내용만 지워 비우면(월 점검 3번과 같은 방식)
# 다음부터 다시 0부터 쌓인다 — 별도 마커 파일 없이 로그 자체의 남은 줄 수로 판단.
BULK_LOG="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/bulk-read-log.md"
if [[ -f "${BULK_LOG}" ]]; then
  CUR_BULK="$(grep -c '^| [0-9]' "${BULK_LOG}" 2>/dev/null)"
  [[ "${CUR_BULK}" =~ ^[0-9]+$ ]] || CUR_BULK=0
  if (( CUR_BULK >= 10 )); then
    echo "[claude-config] 대량 조회가 ${CUR_BULK}건 쌓였습니다(서브에이전트 위임 없이 직접 실행). \"${BULK_LOG}\"를 검토한 뒤 표 내용만 지워 비우세요."
  fi
fi

exit 0
