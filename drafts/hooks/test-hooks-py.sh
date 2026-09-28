#!/usr/bin/env bash
# 셸 입구 + 파이썬 본체 훅 시험(Issue #144): 판정 사례, 실패 시 동작(fail-closed/open), 출력 JSON 유효성.
#   bash drafts/hooks/test-hooks-py.sh
set -u
here="$(cd "$(dirname "${0}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
export CLAUDE_CONFIG_DIR="${tmp}"
pass=0; fail=0
ok() { pass=$((pass + 1)); }
ng() { fail=$((fail + 1)); echo "실패: ${1}"; }

mk() { # $1=도구 $2=명령 또는 경로 → 입력 JSON
  TOOL="${1}" VAL="${2}" python -c "
import json, os
t, v = os.environ['TOOL'], os.environ['VAL']
ti = {'command': v, 'description': 'git push 전에 rm -rf 설명 글'} if t in ('Bash', 'PowerShell') else {'file_path': v}
print(json.dumps({'tool_name': t, 'tool_input': ti, 'cwd': 'C:/Git/AI'}), end='')"
}
decide() { # $1=훅 $2=도구 $3=값 → 출력의 결정(allow/ask/deny)
  local out
  out="$(mk "${2}" "${3}" | bash "${here}/${1}" 2>/dev/null)"
  if [[ -z "${out}" ]]; then echo allow; return; fi
  printf '%s' "${out}" | python -c "import json,sys; print(json.load(sys.stdin)['hookSpecificOutput']['permissionDecision'])" 2>/dev/null || echo bad-json
}
expect() { local got; got="$(decide "${2}" "${3}" "${4}")"; if [[ "${got}" == "${1}" ]]; then ok; else ng "${5} (기대 ${1}, 실제 ${got})"; fi; }

# verifier-guard: 설명 글의 위험 단어는 무시, 여러 줄 명령 안의 git add는 차단, 따옴표 안 > 는 쓰기 아님
expect allow verifier-guard.sh Bash 'bash check.sh' '검사 명령 통과'
expect deny  verifier-guard.sh Bash "$(printf 'cd x\ngit add a.txt')" '여러 줄 안의 git add 차단'
expect allow verifier-guard.sh Bash 'python -c "print(1 > 0)"' '따옴표 안 > 는 쓰기 아님'
expect deny  verifier-guard.sh Bash 'echo hi > out.txt' '리다이렉션 차단'
expect allow verifier-guard.sh Bash 'npm test 2>&1 | tail -5' '출력 합치기는 쓰기 아님'
expect deny  verifier-guard.sh Bash 'x=$(rm -rf build)' '명령 치환 안의 rm 차단'
# baseline-guard: 읽기 명령과 _template 예외는 통과, 쓰기는 확인
expect allow baseline-guard.sh Bash 'npx markdownlint-cli2 base/rules/docs-format.md 2>&1 | tail -5' '읽기 명령 통과'
expect ask   baseline-guard.sh Bash 'cp x.sh base/hooks/' 'base 쓰기 확인'
expect ask   baseline-guard.sh Edit 'C:\Git\AI\base\hooks\x.sh' 'Windows 경로 편집 확인'
expect allow baseline-guard.sh Edit 'C:\Git\AI\base\skills\_template\SKILL.md' '_template 예외'
expect allow baseline-guard.sh Edit 'C:\Git\AI\drafts\hooks\x.sh' 'drafts는 대상 아님'

# 실패 시 동작: 깨진 입력 → 막는 훅은 막거나 확인, 기록 훅은 조용히 통과
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"base/ x' | bash "${here}/baseline-guard.sh" 2>/dev/null)"
[[ "${out}" == *'"ask"'* ]] && ok || ng '깨진 입력이면 baseline-guard는 확인'
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"x' | bash "${here}/verifier-guard.sh" 2>/dev/null)"
[[ "${out}" == *'"deny"'* ]] && ok || ng '깨진 입력이면 verifier-guard는 차단'
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"gh --limit 50' | bash "${here}/bulk-read-log.sh" 2>&1)"
[[ -z "${out}" ]] && ok || ng '깨진 입력이면 bulk-read-log는 조용히 통과'
[[ -s "${tmp}/hook-errors.log" ]] && ok || ng '오류는 hook-errors.log에 기록'
# 파이썬이 없는 환경: PATH에서 파이썬을 빼고 실행
nopy="$(mk Bash 'bash check.sh' | PATH=/usr/bin:/bin bash "${here}/verifier-guard.sh" 2>/dev/null)"
if PATH=/usr/bin:/bin bash -c 'hash python 2>/dev/null || hash python3 2>/dev/null'; then echo "건너뜀: /usr/bin에도 파이썬이 있어 파이썬 없는 환경 시험 불가"; else
  [[ "${nopy}" == *'"deny"'* ]] && ok || ng '파이썬 없으면 verifier-guard는 차단'; fi

# 기록 훅: 한글 명령이 깨지지 않게 기록
mk Bash 'gh issue list --limit 50 --json body --search "한글 검색어"' | bash "${here}/bulk-read-log.sh"
python -c "import io,sys; t=io.open(sys.argv[1],encoding='utf-8').read(); sys.exit(0 if '한글 검색어' in t else 1)" "${tmp}/bulk-read-log.md" && ok || ng '한글 기록이 UTF-8로 남음'
mk Write 'C:\Users\me\.claude\settings.json' | bash "${here}/config-changelog.sh"
grep -q 'settings.json' "${tmp}/config-changelog.md" 2>/dev/null && ok || ng 'Windows 경로 설정 파일 수정 기록'

echo "통과 ${pass} / 실패 ${fail}"
[[ "${fail}" -eq 0 ]]
