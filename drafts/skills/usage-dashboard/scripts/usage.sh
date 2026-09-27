#!/usr/bin/env bash
# 토큰 사용 기록·대시보드(Issue #136). usage-dashboard 스킬이 사용자 요청으로 부른다.
# 훅은 설정에 항상 등록돼 있어도 켜짐 표시 파일(usage-log/enabled)이 없으면 바로 끝난다.
# 설정 업데이트(install.sh)는 usage-log/를 건드리지 않으므로 기록이 유지된다.
# API를 부르지 않으므로 기록·조회에 토큰이 들지 않는다. 집계는 usage.py, 화면 틀은 dashboard.html.
#
# 사용법: bash usage.sh <명령>
#   hook      Stop 훅(async 등록). 메인 기록과 그 세션의 서브에이전트 기록에서 새 줄만 읽는다
#   enable    켜기 — 남아 있는 대화 기록(기본 30일 보관)을 훑어 채우고 대시보드를 만든다(다시 실행하면 새 부분만)
#   disable   끄기 — 표시 파일만 지운다(쌓인 기록은 남김)
#   open      대시보드를 다시 만들고 브라우저로 연다
#   render    대시보드만 다시 만든다
#   status    켜짐 여부와 기록 기간
#   check     세션 시작 크기가 중앙값보다 20% 넘게 늘었으면 한 줄 출력
# 저장: ${CLAUDE_CONFIG_DIR:-~/.claude}/usage-log/ (시험할 때는 USAGE_LOG_DIR, USAGE_PROJECTS_DIR로 바꾼다)
# 대상은 Windows·Mac(브라우저로 보는 화면). UI 없는 Linux 서버는 켜지 않는다(2026-09-27 결정).
set -u

HOME_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
LOG="${USAGE_LOG_DIR:-${HOME_DIR}/usage-log}"
MODE="${1:-hook}"
HERE="$(cd "$(dirname "${0}")" && pwd)"

if [[ "${MODE}" == "hook" ]] && [[ ! -f "${LOG}/enabled" ]]; then
  cat >/dev/null
  exit 0
fi

# Windows는 python3가 스토어 별칭이라 느려(0.6초+) python을 먼저 쓴다. Mac·Linux는 python3만 있는 경우가 많다
PY="$(command -v python || command -v python3 || true)"
[[ -n "${PY}" ]] || { echo "python이 없습니다"; exit 1; }
run_py() { PYTHONIOENCODING=utf-8 "${PY}" "${HERE}/usage.py" "$@"; }

# 세션 여러 개가 동시에 끝나면 훅도 동시에 돈다. 합계 파일을 읽고-고치고-쓰는 사이에 서로 덮어쓰지 않게
# mkdir 잠금으로 한 번에 하나만 쓰게 한다(gh-throttle.sh와 같은 방식). 1분 넘은 잠금은 죽은 것으로 보고 치운다.
LOCK="${LOG}/.lock"
lock() {
  mkdir -p "${LOG}"
  local i=0
  until mkdir "${LOCK}" 2>/dev/null; do
    if [[ -n "$(find "${LOCK}" -maxdepth 0 -mmin +1 2>/dev/null)" ]]; then rmdir "${LOCK}" 2>/dev/null; continue; fi
    i=$((i + 1))
    [[ "${i}" -gt 150 ]] && return 1
    sleep 0.2
  done
  trap 'rmdir "${LOCK}" 2>/dev/null' EXIT
}

case "${MODE}" in
  hook)
    input="$(cat)"
    lock || exit 0
    printf '%s' "${input}" | run_py hook
    ;;
  enable)
    if [[ "$(uname -s)" == "Linux" ]]; then
      echo "Linux 서버는 대상이 아닙니다(화면 없이 쓰는 환경, 2026-09-27 결정). /usage로 확인하세요."
      exit 1
    fi
    mkdir -p "${LOG}" && : > "${LOG}/enabled"
    lock || { echo "다른 기록 작업이 끝나지 않았습니다. 잠시 뒤 다시 실행하세요."; exit 1; }
    echo "켜짐. 남아 있는 대화 기록을 훑는 중(처음 한 번은 수십 초 걸릴 수 있음)..."
    run_py backfill
    echo "대시보드: ${LOG}/dashboard.html"
    ;;
  disable) rm -f "${LOG}/enabled"; run_py render; echo "꺼짐. 쌓인 기록은 ${LOG}에 그대로 있습니다." ;;
  open)
    run_py render
    page="${LOG}/dashboard.html"
    case "$(uname -s)" in
      Darwin) open "${page}" ;;
      MINGW*|MSYS*|CYGWIN*) cmd.exe //c start "" "$(cygpath -w "${page}")" ;;
      *) echo "브라우저로 여세요: ${page}" ;;
    esac
    ;;
  render|check|status) run_py "${MODE}" ;;
  *) echo "사용법: bash usage.sh hook|enable|disable|open|render|status|check"; exit 2 ;;
esac
exit 0
