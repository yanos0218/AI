#!/usr/bin/env bash
# 실시간 세션 현황 서버를 켜고 끈다(Issue #213). 사용법: bash live.sh start|stop|status|url|open
#   start   서버를 백그라운드로 띄운다(이미 떠 있으면 주소만 알린다)
#   stop    끈다
#   status  떠 있는지 알린다
#   url     주소를 알리고 클립보드에 복사한다(VS Code 통합 브라우저에 붙여넣기용)
#   open    기본 브라우저로 연다
# 서버는 127.0.0.1에만 묶인다. 기본 포트 8766, LIVE_PORT로 바꾼다. 기록 폴더는 ${CLAUDE_CONFIG_DIR:-~/.claude}/live-status.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${LIVE_PORT:-8766}"
URL="http://127.0.0.1:${PORT}/"
DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/live-status"
PIDFILE="${DIR}/server.pid"
PY="$(command -v python3 || command -v python)"
[[ -n "${PY}" ]] || { echo "python3 또는 python이 필요합니다."; exit 1; }
serving() { curl -s -o /dev/null -m 2 "${URL}"; }
running() { [[ -f "${PIDFILE}" ]] && kill -0 "$(cat "${PIDFILE}")" 2>/dev/null; }

case "${1:-}" in
  start)
    if running && serving; then echo "이미 켜져 있습니다: ${URL}"; exit 0; fi
    if serving; then echo "포트 ${PORT}을 다른 프로그램이 쓰고 있습니다. LIVE_PORT로 다른 번호를 지정하세요."; exit 1; fi
    mkdir -p "${DIR}"
    nohup "${PY}" "${here}/live.py" >"${DIR}/server.log" 2>&1 &
    echo "$!" > "${PIDFILE}"
    for _ in 1 2 3 4 5 6 7 8 9 10; do serving && break; sleep 0.5; done
    if serving; then echo "켜짐: ${URL}"; else echo "서버가 뜨지 않았습니다. 로그: ${DIR}/server.log"; exit 1; fi
    ;;
  stop)
    if running; then kill "$(cat "${PIDFILE}")" 2>/dev/null; rm -f "${PIDFILE}"; echo "꺼짐."; else rm -f "${PIDFILE}"; echo "켜져 있지 않습니다."; fi
    ;;
  status)
    if running && serving; then echo "켜져 있음: ${URL}"; else echo "꺼져 있음"; fi
    ;;
  url|open)
    serving || { echo "꺼져 있습니다. 먼저 bash live.sh start"; exit 1; }
    if [[ "$1" = url ]]; then
      case "$(uname -s)" in
        Darwin) printf '%s' "${URL}" | pbcopy ;;
        MINGW*|MSYS*|CYGWIN*) printf '%s' "${URL}" | clip.exe ;;
      esac
      echo "${URL} (복사됨). VS Code는 명령 팔레트에서 Open Integrated Browser를 열고 붙여넣으세요."
    else
      case "$(uname -s)" in
        Darwin) open "${URL}" ;;
        MINGW*|MSYS*|CYGWIN*) cmd.exe //c start "" "${URL}" ;;
        *) echo "브라우저로 여세요: ${URL}" ;;
      esac
    fi
    ;;
  *) echo "사용법: bash live.sh start|stop|status|url|open"; exit 2 ;;
esac
