#!/usr/bin/env bash
# 알림 훅 초안(Issue #5, 조사는 Issue #209). 승인 대기와 긴 작업 끝을 OS 알림으로 알린다. 항상 종료 코드 0, 출력 없음.
# 등록(async로 단다. Notification은 permission_prompt만, Stop·UserPromptSubmit은 같은 스크립트):
#   Notification  matcher permission_prompt  → 승인 요청 약 6초 뒤 "승인 대기" 알림
#   UserPromptSubmit                         → 응답 시작 시각만 기록(알림 없음)
#   Stop                                     → 백그라운드 작업이 없고 시작 뒤 60초 넘게 걸렸으면 "작업 끝" 알림
# 알림 본문은 폴더 이름과 session_id 앞 8자뿐이다. 훅 입력의 message는 쓰지 않고, 모든 문자열은 인자나 환경변수로만
# 넘겨(명령 문자열에 끼워 넣지 않음) 폴더 이름의 따옴표·$() 같은 문자가 실행되지 않게 한다.
# macOS는 osascript, Linux는 notify-send(없으면 조용히 끝남), Windows는 PowerShell 풍선 알림이다. Windows 분기는 미검증.
set -u
PY="$(command -v python3 || command -v python)" || exit 0
IFS= read -r -d '' input || true
fields="$(printf '%s' "${input}" | "${PY}" -I -c '
import sys, json, os, re
# Windows는 표준 입출력이 cp1252·cp949라 한글 폴더 이름이 깨지거나 UnicodeEncodeError가 난다. -I는 PYTHONIOENCODING을 무시하므로 바이트로 직접 읽고 쓴다
try:
    d = json.loads(sys.stdin.buffer.read().decode("utf-8"))
except Exception:
    sys.exit(1)
bg = d.get("background_tasks")
n = len(bg) if isinstance(bg, list) else 0
sid = re.sub(r"[^A-Za-z0-9]", "", d.get("session_id") or "")[:8]
folder = re.split(r"[\\/]+", (d.get("cwd") or "").rstrip("/\\"))[-1].replace("\t", " ").replace("\n", " ")
line = "\t".join([d.get("hook_event_name") or "-", d.get("notification_type") or "-", sid or "-", folder or "-", str(n)])
sys.stdout.buffer.write((line + "\n").encode("utf-8"))
' 2>/dev/null)" || exit 0
IFS=$'\t' read -r event ntype sid folder bgn <<<"${fields}"

send() { # $1=제목 $2=본문
  case "$(uname -s)" in
    Darwin)
      osascript -e 'on run argv' -e 'display notification (item 2 of argv) with title (item 1 of argv)' -e 'end run' "$1" "$2" >/dev/null 2>&1 ;;
    Linux)
      command -v notify-send >/dev/null 2>&1 && notify-send "$1" "$2" >/dev/null 2>&1 ;;
    MINGW*|MSYS*|CYGWIN*)
      command -v powershell.exe >/dev/null 2>&1 && CLAUDE_NOTIFY_TITLE="$1" CLAUDE_NOTIFY_BODY="$2" powershell.exe -NoProfile -Command \
        'Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $n = New-Object System.Windows.Forms.NotifyIcon; $n.Icon = [System.Drawing.SystemIcons]::Information; $n.Visible = $true; $n.ShowBalloonTip(5000, $env:CLAUDE_NOTIFY_TITLE, $env:CLAUDE_NOTIFY_BODY, "Info"); Start-Sleep -Seconds 6; $n.Dispose()' >/dev/null 2>&1 ;;
  esac
  return 0
}

state="${TMPDIR:-/tmp}/claude-notify-${sid}.start"
case "${event}" in
  UserPromptSubmit)
    date +%s > "${state}" 2>/dev/null
    exit 0 ;;
  Notification)
    [[ "${ntype}" = permission_prompt ]] || exit 0
    title="승인 대기" ;;
  Stop)
    [[ "${bgn}" = 0 ]] || exit 0                 # 백그라운드 작업이 남았으면 아직 끝이 아님
    [[ -f "${state}" ]] || exit 0
    start="$(<"${state}")"; rm -f "${state}"
    [[ "${start}" =~ ^[0-9]+$ ]] || exit 0
    (( $(date +%s) - start >= 60 )) || exit 0
    title="작업 끝" ;;
  *) exit 0 ;;
esac
send "${title}" "${folder} · ${sid}"
exit 0
