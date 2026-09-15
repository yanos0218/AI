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
#
# git push는 이미 사용자 확인(ask)을 띄우던 지점이라, 그 확인 전에 문서
# 갱신도 같이 상기시킨다(Issue #102). "HANDOFF/PROGRESS/CHANGELOG만"처럼
# 특정 파일을 못 박지 않는다 — 이번 세션에서 config-lifecycle.md·README.md처럼
# 나열에 없던 문서도 실제로 갱신이 필요했던 사례가 나와서, 대신 이번 push에
# 실제로 포함된 `.md` 파일 목록을 사실 그대로 보여주고 "이 밖에도 있을 수
# 있다"고만 알린다. 판단(그 밖에 뭘 더 봐야 하는지)은 훅이 못 하므로 여전히
# Claude가 그 순간 직접 한다.
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
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  if [[ -n "${upstream}" ]]; then
    changed="$(git diff "${upstream}..HEAD" --name-only 2>/dev/null || true)"
    md_files="$(printf '%s\n' "${changed}" | grep -E '\.md$' || true)"
    base_changed="$(printf '%s\n' "${changed}" | grep -Eq '^base/' && echo 1 || true)"
    if [[ -n "${md_files}" || -n "${base_changed}" ]]; then
      md_list="$(printf '%s' "${md_files}" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
      [[ -n "${md_list}" ]] || md_list="(.md 없음, base/만 변경)"
      reason="${reason} 확정된 사실이 관련 문서 전반에 반영됐는지 확인하세요(이번 push에 포함된 .md: ${md_list} -- 나열 안 된 다른 주제 문서에도 걸쳐 있을 수 있습니다)."
    fi
  fi
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
