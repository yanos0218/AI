#!/usr/bin/env bash
# SessionStart 훅 — 이 저장소 전용(Issue #207). 이 기기 설치 버전(설치 버전 파일 2행)이 docs/PROGRESS.md §0 표의
# 이 기기 행에 적혀 있지 않으면 한 줄로 알린다(출력은 Claude의 컨텍스트로 들어감). 정상이면 아무것도 출력하지 않는다.
# 설치한 뒤 이 행을 갱신하는 일이 반복해서 빠졌다(2026-10-24, Mac mini 행이 -57로 남고 설치본은 -64).
# 판별 로직은 tools/check-install.sh 끝의 "기록" 줄과 같다. 비교할 수 없으면 조용히 끝난다(세션 시작을 막지 않는다).
# 시험용: CLAUDE_CONFIG_DIR(설치 폴더), PROGRESS_FILE(표 파일)
set -u
cd "$(dirname "${0}")/../.." || exit 0
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
f="${PROGRESS_FILE:-docs/PROGRESS.md}"
[[ -f "${f}" ]] || exit 0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) surface="Windows";; Darwin) surface="Mac mini";; Linux) surface="Linux";; *) exit 0;; esac
installed_ver="$(sed -n 2p "${CLAUDE_HOME}/.claude-config-version" 2>/dev/null | tr -d '\r')"
[[ -n "${installed_ver}" ]] || exit 0
# 같은 OS 기기가 여럿이면 "Windows", "Windows(패키지 설치 PC)"처럼 행이 여럿이라 모두 보고, "설치된 것" 칸의 첫 백틱 값과
# 정확히 비교한다. 부분 문자열 비교는 v0.18.4가 v0.18.4-11-g…에 일치했다(Issue #271)
rows="$(grep "^| ${surface}[ (]" "${f}" 2>/dev/null)"
[[ -n "${rows}" ]] || exit 0
names=""
while IFS= read -r r; do
  name="$(printf '%s' "${r}" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')"
  ver="$(printf '%s' "${r}" | awk -F'|' '{print $3}' | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')"
  [[ "${ver}" == "${installed_ver}" ]] && exit 0
  names="${names:+${names}, }${name}"
done <<< "${rows}"
echo "[progress-check] docs/PROGRESS.md §0 ${names} 행 어디에도 이 기기 설치 버전 ${installed_ver}이 없음. 이 내용을 믿지 말고 이 기기 행의 설치 버전·설치일을 확인한 뒤, 세션 끝에 그 행에서 고칠 것."
