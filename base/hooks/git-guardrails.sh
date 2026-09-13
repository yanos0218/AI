#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅.
# 되돌리기 어려운 명령은 auto 모드에서도 반드시 사용자 확인 프롬프트를 띄우게 한다.
# CLAUDE.md의 "확인 후 진행" 목록을 문장이 아니라 실행 시점에 강제하는 장치.
# 차단(deny)이 아니라 확인(ask)이므로, 사용자가 승인하면 그대로 실행된다.
#
# 명령을 스크립트 파일로 감싸면(bash x.sh) 문자열 매칭이 뚫리는 우회가 실제
# 사고(Issue #71)로 확인돼, 그런 형태면 스크립트 내용까지 같이 검사한다
# (Issue #73). 한 단계만 열어본다 — 스크립트가 또 다른 스크립트를 감싸는
# 경우까지는 다루지 않는다.
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

reason=""

if printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+push'; then
  reason="git push -- 원격 저장소에 반영됩니다. force push라면 히스토리를 덮어씁니다."
elif printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard'; then
  reason="git reset --hard -- 커밋 안 된 로컬 변경이 전부 사라집니다."
elif printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[A-Za-z]*f'; then
  reason="git clean -f -- untracked 파일이 복구 불가능하게 삭제됩니다."
elif printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D'; then
  reason="git branch -D -- 병합 안 된 커밋이 있어도 강제로 브랜치가 삭제됩니다."
elif printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+checkout[[:space:]]+--|git[[:space:]]+restore[[:space:]]+\.'; then
  reason="git checkout -- / restore . -- 커밋 안 된 로컬 변경이 되돌려집니다."
elif printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+tag[[:space:]]+-d'; then
  reason="git tag -d -- 로컬 태그가 삭제됩니다(원격 태그는 별도로 지워야 함)."
elif printf '%s' "${search_text}" | grep -Eq -- '--no-verify'; then
  reason="--no-verify -- 커밋/푸시 훅(검증)을 건너뜁니다."
elif printf '%s' "${search_text}" | grep -Eq 'npm[[:space:]]+publish'; then
  reason="npm publish -- 패키지가 공개 레지스트리에 배포됩니다(사실상 되돌리기 불가)."
elif printf '%s' "${search_text}" | grep -Eq 'gh[[:space:]]+release[[:space:]]+create'; then
  reason="gh release create -- GitHub Release가 공개로 생성됩니다."
elif printf '%s' "${search_text}" | grep -Eq 'gh[[:space:]]+repo[[:space:]]+delete'; then
  reason="gh repo delete -- 저장소가 영구 삭제됩니다."
elif printf '%s' "${search_text}" | grep -Eq 'rm[[:space:]]+-[A-Za-z]*r[A-Za-z]*f|Remove-Item[^|]*-Recurse'; then
  reason="rm -rf / Remove-Item -Recurse -- 파일이 복구 불가능하게 삭제됩니다."
fi

if [[ -n "${reason}" ]]; then
  via=""
  if [[ -n "${script_content}" ]]; then
    via="(스크립트 ${script_path} 안에서 발견) "
  fi
  reason_escaped=$(printf '%s' "되돌리기 어려운 명령입니다 (git-guardrails). ${via}${reason}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "${reason_escaped}"
fi

exit 0
