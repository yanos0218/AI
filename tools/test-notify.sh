#!/usr/bin/env bash
# 알림 훅 초안(drafts/hooks/notify.sh) 시험(Issue #5). 가짜 알림 도구와 가짜 uname을 PATH 앞에 두어 세 운영체제 분기를 한 기기에서 확인한다.
# 실제 OS 알림은 보내지 않는다. 실제 알림 도착은 사용자 기기에서 따로 확인한다.
#   bash tools/test-notify.sh
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
HOOK="$(pwd)/drafts/hooks/notify.sh"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
BIN="${T}/bin"; mkdir -p "${BIN}"
CALLS="${T}/calls.log"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# 가짜 알림 도구: 호출 인자를 한 줄에 하나씩 CALLS에 남긴다. 가짜 uname은 FAKE_OS 값을 돌려준다
for tool in osascript notify-send; do
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s" "$@" >> "${CALLS}"\n' "${tool}" > "${BIN}/${tool}"
done
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "powershell" "$CLAUDE_NOTIFY_TITLE" "$CLAUDE_NOTIFY_BODY" >> "${CALLS}"\n' > "${BIN}/powershell.exe"
printf '#!/usr/bin/env bash\necho "${FAKE_OS:-Darwin}"\n' > "${BIN}/uname"
chmod +x "${BIN}"/*
export TMPDIR="${T}/tmp"; mkdir -p "${TMPDIR}"
export CALLS

run() { # $1=입력 JSON $2=가짜 OS, 나머지는 PATH 앞에 둘 폴더(기본 가짜 bin)
  : > "${CALLS}"
  printf '%s' "$1" | env FAKE_OS="${2:-Darwin}" PATH="${BIN}:${PATH}" bash "${HOOK}" 2>&1
}
calls() { cat "${CALLS}"; }
last2() { tail -n 2 "${CALLS}" | tr '\n' '|'; }
old_start() { echo $(( $(date +%s) - 120 )) > "${TMPDIR}/claude-notify-$1.start"; }

echo "== 1. 승인 대기(Notification permission_prompt)"
out="$(run '{"hook_event_name":"Notification","notification_type":"permission_prompt","message":"Claude needs your permission to use Bash","session_id":"abcdef1234567","cwd":"/work/MyRepo"}' Darwin)"; rc=$?
chk "출력 없음, 종료 코드 0"                       '[[ -z "${out}" && "${rc}" = 0 ]]'
chk "macOS: osascript에 제목과 본문이 인자로 감"     '[[ "$(last2)" = "승인 대기|MyRepo · abcdef12|" ]] && head -n1 "${CALLS}" | grep -q osascript'
chk "훅 입력의 message는 본문에 쓰지 않음"          '! grep -q "permission to use" "${CALLS}"'
out="$(run '{"hook_event_name":"Notification","notification_type":"permission_prompt","session_id":"abcdef1234567","cwd":"/work/MyRepo"}' Linux)"
chk "Linux: notify-send로 감"                       '[[ "$(last2)" = "승인 대기|MyRepo · abcdef12|" ]] && head -n1 "${CALLS}" | grep -q notify-send'
out="$(run '{"hook_event_name":"Notification","notification_type":"permission_prompt","session_id":"abcdef1234567","cwd":"C:\\work\\MyRepo"}' MINGW64_NT)"
chk "Windows: powershell에 환경변수로 제목·본문이 감" '[[ "$(last2)" = "승인 대기|MyRepo · abcdef12|" ]] && head -n1 "${CALLS}" | grep -q powershell'

out="$(run '{"hook_event_name":"Notification","notification_type":"permission_prompt","session_id":"abcdef1234567","cwd":"/work/한글폴더"}' Darwin)"
chk "한글 폴더 이름이 깨지지 않고 본문으로 감"          '[[ "$(last2)" = "승인 대기|한글폴더 · abcdef12|" ]]'

echo "== 2. 다른 알림 유형은 무시"
run '{"hook_event_name":"Notification","notification_type":"idle_prompt","session_id":"abcdef1234567","cwd":"/work/MyRepo"}' Darwin >/dev/null
chk "idle_prompt: 알림 없음"                        '[[ ! -s "${CALLS}" ]]'
run '{"hook_event_name":"SubagentStop","session_id":"abcdef1234567","cwd":"/work/MyRepo"}' Darwin >/dev/null
chk "SubagentStop: 알림 없음"                       '[[ ! -s "${CALLS}" ]]'

echo "== 3. 작업 끝(Stop)은 오래 걸린 응답만"
run '{"hook_event_name":"UserPromptSubmit","session_id":"abcdef1234567","cwd":"/work/MyRepo"}' Darwin >/dev/null
chk "UserPromptSubmit: 시작 시각만 기록, 알림 없음"   '[[ ! -s "${CALLS}" && -f "${TMPDIR}/claude-notify-abcdef12.start" ]]'
run '{"hook_event_name":"Stop","session_id":"abcdef1234567","cwd":"/work/MyRepo","background_tasks":[]}' Darwin >/dev/null
chk "60초 미만: 알림 없음, 기록 파일 정리"            '[[ ! -s "${CALLS}" && ! -f "${TMPDIR}/claude-notify-abcdef12.start" ]]'
old_start abcdef12
run '{"hook_event_name":"Stop","session_id":"abcdef1234567","cwd":"/work/MyRepo","background_tasks":[]}' Darwin >/dev/null
chk "60초 이상: 작업 끝 알림"                        '[[ "$(last2)" = "작업 끝|MyRepo · abcdef12|" ]]'
old_start abcdef12
run '{"hook_event_name":"Stop","session_id":"abcdef1234567","cwd":"/work/MyRepo","background_tasks":[{"id":"t1","type":"subagent"}]}' Darwin >/dev/null
chk "백그라운드 작업이 남음: 알림 없음, 기록 유지"     '[[ ! -s "${CALLS}" && -f "${TMPDIR}/claude-notify-abcdef12.start" ]]'
rm -f "${TMPDIR}"/claude-notify-*.start
run '{"hook_event_name":"Stop","session_id":"abcdef1234567","cwd":"/work/MyRepo","background_tasks":[]}' Darwin >/dev/null
chk "시작 기록이 없음: 알림 없음"                     '[[ ! -s "${CALLS}" ]]'
echo "not-a-number" > "${TMPDIR}/claude-notify-abcdef12.start"
run '{"hook_event_name":"Stop","session_id":"abcdef1234567","cwd":"/work/MyRepo","background_tasks":[]}' Darwin >/dev/null
chk "시작 기록이 숫자가 아님: 알림 없음"              '[[ ! -s "${CALLS}" ]]'

echo "== 4. 주입 방지와 실패 안전"
evil='/work/x"; touch PWNED; echo "$(touch PWNED2)'
json="$(python3 -c 'import json,sys;print(json.dumps({"hook_event_name":"Notification","notification_type":"permission_prompt","session_id":"abcdef1234567","cwd":sys.argv[1]}))' "${evil}")"
out="$(cd "${T}" && run "${json}" Darwin)"; rc=$?
chk "특수문자 폴더 이름: 명령이 실행되지 않음"          '[[ ! -e "${T}/PWNED" && ! -e "${T}/PWNED2" && "${rc}" = 0 ]]'
chk "특수문자 폴더 이름: 본문으로 그대로 전달"          'grep -q "touch" "${CALLS}"'
out="$(printf 'not json' | env PATH="${BIN}:${PATH}" bash "${HOOK}" 2>&1)"; rc=$?
chk "깨진 입력: 출력 없음, 종료 코드 0"                '[[ -z "${out}" && "${rc}" = 0 ]]'
mkdir -p "${T}/bin2"; cp "${BIN}/uname" "${T}/bin2/"
: > "${CALLS}"; out="$(printf '%s' '{"hook_event_name":"Notification","notification_type":"permission_prompt","session_id":"abcdef1234567","cwd":"/work/MyRepo"}' | env FAKE_OS=Linux PATH="${T}/bin2:$(dirname "$(command -v python3)"):/usr/bin:/bin" bash "${HOOK}" 2>&1)"; rc=$?
chk "Linux에 notify-send 없음: 조용히 끝남"             '[[ -z "${out}" && "${rc}" = 0 && ! -s "${CALLS}" ]]'

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
