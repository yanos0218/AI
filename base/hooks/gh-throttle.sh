#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅.
# gh의 콘텐츠 생성 명령(이슈·PR·릴리즈·라벨 생성/댓글/닫기/수정 등) 앞에 1.5초
# 지연을 강제해 GitHub 2차 속도 제한(secondary rate limit)을 예방한다. 병렬
# 서브에이전트가 간격 없이 gh를 여러 번 호출해 계정이 일시 차단된 사고
# (Issue #71, 2026-09-13)의 재발 방지. 공유 락 파일 없이 매번 무조건 지연하는
# 단순한 방식으로 간다 — 경쟁 조건까지 다루려면 flock 등 플랫폼 의존 코드가
# 필요해 Windows/Mac 공통 유지가 번거로워진다.
#
# 명령을 스크립트 파일로 감싸면(bash x.sh) 문자열 매칭이 뚫리는 우회가 실제
# 사고로 확인돼, 그런 형태면 스크립트 내용까지 같이 검사한다(Issue #73).
set -u

input="$(cat)"
cmd="$(printf '%s' "${input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"

script_path=""
if printf '%s' "${cmd}" | grep -Eq '^[[:space:]]*(bash|sh|source)[[:space:]]+[^&|;]+\.sh'; then
  script_path="$(printf '%s' "${cmd}" | sed -E 's/^[[:space:]]*(bash|sh|source)[[:space:]]+//' | awk '{print $1}')"
elif printf '%s' "${cmd}" | grep -Eq '^[[:space:]]*\.\/[^&|;[:space:]]+\.sh'; then
  script_path="$(printf '%s' "${cmd}" | awk '{print $1}')"
fi

script_content=""
if [[ -n "${script_path}" && -f "${script_path}" ]]; then
  script_content="$(cat "${script_path}" 2>/dev/null || true)"
fi

search_text="${input}
${script_content}"

pattern='gh[[:space:]]+(issue|pr|release|label)[[:space:]]+(create|comment|close|edit|reopen)|gh[[:space:]]+api[[:space:]].*(--method[[:space:]]+(POST|PATCH|PUT|DELETE)|-X[[:space:]]+(POST|PATCH|PUT|DELETE)|-[fF][[:space:]])'

if printf '%s' "${search_text}" | grep -Eq "${pattern}"; then
  sleep 1.5
fi

exit 0
