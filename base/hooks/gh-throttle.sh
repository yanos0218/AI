#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅.
# gh의 콘텐츠 생성 명령(이슈·PR·릴리즈·라벨 생성/댓글/닫기/수정 등)을 실제로
# 직렬화해 GitHub 2차 속도 제한(secondary rate limit)을 예방한다. 병렬
# 서브에이전트가 간격 없이 gh를 여러 번 호출해 계정이 일시 차단된 사고
# (Issue #71, 2026-09-13)의 재발 방지.
#
# 첫 버전(무조건 1.5초 지연)은 서로 다른 프로세스 간에 공유 상태가 없어
# 병렬로 여러 개가 동시에 들어오면 다들 비슷한 시점에 풀려나가 원래 사고의
# 실제 방아쇠(병렬 서브에이전트 다수)를 못 막는다는 게 실측으로 확인됨
# (3개 병렬 실행 시 총 2.78초 만에 전부 종료 — 직렬이면 약 4.5초여야 함).
# mkdir 기반 락 + 공유 타임스탬프 파일로 실제 순차 처리하도록 바꿨다(락 파일
# 방식은 Windows/Mac/Linux 공통으로 별도 도구 없이 동작).
#
# 명령을 스크립트 파일로 감싸면(bash x.sh) 문자열 매칭이 뚫리는 우회가 실제
# 사고로 확인돼, 그런 형태면 스크립트 내용까지 같이 검사한다(Issue #73).
#
# 모든 Bash 호출마다 도므로 대상 판정은 bash 내장 기능만 쓴다. grep·sed를 여러 번 띄우던 예전 방식은
# Windows Git Bash가 느린 시각에 5.6초가 걸려 제한 시간을 넘긴 기록이 있다(Issue #142, 2026-09-28).
set -u

IFS= read -r -d '' input || true
cmd_re='"command"[[:space:]]*:[[:space:]]*"[[:space:]]*'

script_path=""
if [[ "${input}" =~ ${cmd_re}(bash|sh|source)[[:space:]]+([^\&\|\;\"[:space:]]+\.sh) ]]; then
  script_path="${BASH_REMATCH[2]}"
elif [[ "${input}" =~ ${cmd_re}(\./[^\&\|\;\"[:space:]]+\.sh) ]]; then
  script_path="${BASH_REMATCH[1]}"
fi

script_content=""
if [[ -n "${script_path}" && -f "${script_path}" ]]; then
  script_content="$(<"${script_path}")"
fi

search_text="${input}
${script_content}"

pattern='gh[[:space:]]+(issue|pr|release|label)[[:space:]]+(create|comment|close|edit|reopen)|gh[[:space:]]+api[[:space:]].*(--method[[:space:]]+(POST|PATCH|PUT|DELETE)|-X[[:space:]]+(POST|PATCH|PUT|DELETE)|-[fF][[:space:]])'

[[ "${search_text}" =~ ${pattern} ]] || exit 0

state_dir="${HOME}/.claude/state"
mkdir -p "${state_dir}" 2>/dev/null
ts_file="${state_dir}/gh-mutation-last-ts"
lock_dir="${state_dir}/gh-mutation.lock"
min_gap=2

# 5초 넘은 락은 죽은 프로세스가 남긴 것으로 보고 강제로 치운다
if [[ -d "${lock_dir}" ]]; then
  held_since="$(cat "${lock_dir}/ts" 2>/dev/null || echo 0)"
  now_probe="$(date +%s)"
  if (( now_probe - held_since > 5 )); then
    rm -rf "${lock_dir}" 2>/dev/null
  fi
fi

acquired=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if mkdir "${lock_dir}" 2>/dev/null; then
    date +%s > "${lock_dir}/ts" 2>/dev/null
    acquired=1
    break
  fi
  sleep 0.5
done

if [[ "${acquired}" = 1 ]]; then
  now="$(date +%s)"
  last="$(cat "${ts_file}" 2>/dev/null || echo 0)"
  elapsed=$(( now - last ))
  if (( elapsed < min_gap )); then
    sleep $(( min_gap - elapsed ))
  fi
  date +%s > "${ts_file}" 2>/dev/null
  rm -rf "${lock_dir}" 2>/dev/null
else
  # 락 경쟁이 심해 못 얻었으면(다른 프로세스가 계속 쓰는 중) 최소한의 지연은 보장
  sleep "${min_gap}"
fi

exit 0
