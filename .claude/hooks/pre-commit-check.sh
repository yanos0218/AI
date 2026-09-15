#!/usr/bin/env bash
# PreToolUse(Bash/PowerShell) 훅 — 이 저장소 전용.
# `git commit`을 실행하려 할 때 문서 상한·markdownlint·shellcheck를 먼저 돌리고,
# 실패하면 커밋 자체를 막는다(permissionDecision: deny). 지금까지는 "커밋 전에
# 검사를 돌린다"가 제 습관이었을 뿐 강제 장치가 없었다 — "강제할 건 CLAUDE.md
# 문장이 아니라 훅으로"라는 이 저장소 원칙을 검증에도 적용한 것(2026-09-13).
#
# base/·docs 규칙 문서를 건드리는 커밋에 이슈 번호가 없으면 확인을 띄운다
# (permissionDecision: ask). "착수 시점에 먼저 Issue부터 연다"는 CLAUDE.md
# 문장만으로는 두 번(Issue #64, #66) 안 지켜져서 훅으로 옮김(2026-09-13).
# 릴리즈 컷(`chore(release): vX.Y.Z`)은 예외 — 매번 이슈를 만들 가치가 없다고
# 판단해 제외함(2026-09-13, Issue #77 삭제로 정리).
#
# 명령을 스크립트 파일로 감싸면(bash x.sh) 문자열 매칭이 뚫리는 우회가 실제
# 사고로 확인돼, 그런 형태면 스크립트 내용까지 같이 검사한다(Issue #73).
#
# 목록 줄바꿈 규칙(라벨: 흐르는 문장 / 라벨 — 흐르는 문장 크램)도 수동 재검색만으로는
# 매번 뭔가 놓쳐서(2026-09-15, 4라운드 동안 계속 새 미비 발견) tools/check-cram.sh로
# 커밋 단계에서 기계적으로 잡는다. 정규식 휴리스틱이라 오탐 시 --add-exception으로
# 예외 등록(Issue #99).
set -u
cd "$(dirname "${0}")/../.." || exit 0

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

search_text="${cmd}
${script_content}"

# git commit이 아니면 조용히 통과
printf '%s' "${search_text}" | grep -Eq 'git[[:space:]]+commit' || exit 0

fail=0
msg=""

# 1. 문서 상한·필수 파일 — 항상 실행(가볍다)
if ! out=$(bash tools/check-docs.sh 2>&1); then
  fail=1
  msg="${msg}\\ncheck-docs.sh 실패:\\n$(printf '%s' "${out}" | tail -5)"
fi

# 2. markdownlint — 스테이징된 .md가 있을 때만
if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q '\.md$'; then
  if ! out=$(npx --yes markdownlint-cli2 "**/*.md" 2>&1); then
    fail=1
    msg="${msg}\\nmarkdownlint 실패:\\n$(printf '%s' "${out}" | tail -8)"
  fi
fi

# 3. shellcheck — 스테이징된 .sh가 있을 때만
sh_files="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.sh$' || true)"
if [[ -n "${sh_files}" ]]; then
  if ! out=$(printf '%s\n' "${sh_files}" | xargs npx --yes shellcheck -S warning 2>&1); then
    fail=1
    msg="${msg}\\nshellcheck 실패:\\n$(printf '%s' "${out}" | tail -8)"
  fi
fi

# 3.5. 목록 줄바꿈 규칙(콜론·em-dash 크램) — 스테이징된 .md diff의 추가된 줄만(Issue #99)
if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q '\.md$'; then
  if ! out=$(bash tools/check-cram.sh --staged 2>&1); then
    fail=1
    msg="${msg}\\n목록 줄바꿈 규칙 위반(크램):\\n$(printf '%s' "${out}" | head -10)\\n오탐이면 tools/check-cram.sh --add-exception <file> <line>"
  fi
fi

if [[ "${fail}" = 1 ]]; then
  reason="$(printf '%s' "${msg}" | tr '\n' ' ' | sed 's/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"pre-commit-check 실패, 커밋 차단: %s"}}\n' "${reason}"
  exit 0
fi

# 4. base/·docs 규칙 변경인데 커밋 메시지에 이슈 번호(#숫자)가 없으면 확인
# (릴리즈 컷 커밋은 예외 — 항상 PROGRESS·HANDOFF를 건드리지만 이슈를 만들지 않는다)
if ! printf '%s' "${search_text}" | grep -Eq 'chore\(release\):'; then
  touched="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)"
  if printf '%s\n' "${touched}" | grep -Eq '^base/|^docs/.*\.md$|^CLAUDE\.md$'; then
    if ! printf '%s' "${search_text}" | grep -Eq '#[0-9]+'; then
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"base/ 또는 docs 규칙 문서를 바꾸는 커밋인데 메시지에 이슈 번호(#숫자)가 없습니다. 이슈 없이 진행할까요?"}}\n'
    fi
  fi
fi
exit 0
