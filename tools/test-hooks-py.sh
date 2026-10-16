#!/usr/bin/env bash
# 셸 입구 + 파이썬 본체 훅 시험(Issue #144): 판정 사례, 실패 시 동작(fail-closed/open), 출력 JSON 유효성.
#   bash tools/test-hooks-py.sh
set -u
root="$(cd "$(dirname "${0}")/.." && pwd)"
hook() { [[ "${1}" == baseline-guard.sh ]] && echo "${root}/.claude/hooks/${1}" || echo "${root}/base/hooks/${1}"; }
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
export CLAUDE_CONFIG_DIR="${tmp}"
# 훅과 같은 순서로 파이썬을 고른다. Mac은 python 없이 python3만 있는 경우가 많다
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
pass=0; fail=0
ok() { pass=$((pass + 1)); }
ng() { fail=$((fail + 1)); echo "실패: ${1}"; }

mk() { # $1=도구 $2=명령 또는 경로 → 입력 JSON
  TOOL="${1}" VAL="${2}" "${PY}" -c "
import json, os
t, v = os.environ['TOOL'], os.environ['VAL']
ti = {'command': v, 'description': 'git push 전에 rm -rf 설명 글'} if t in ('Bash', 'PowerShell') else {'file_path': v}
print(json.dumps({'tool_name': t, 'tool_input': ti, 'cwd': 'C:/Git/AI'}), end='')"
}
decide() { # $1=훅 $2=도구 $3=값 → 출력의 결정(allow/ask/deny)
  local out
  out="$(mk "${2}" "${3}" | bash "$(hook "${1}")" 2>/dev/null)"
  if [[ -z "${out}" ]]; then echo allow; return; fi
  printf '%s' "${out}" | "${PY}" -c "import json,sys; print(json.load(sys.stdin)['hookSpecificOutput']['permissionDecision'])" 2>/dev/null || echo bad-json
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
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"base/ x' | bash "$(hook baseline-guard.sh)" 2>/dev/null)"
[[ "${out}" == *'"ask"'* ]] && ok || ng '깨진 입력이면 baseline-guard는 확인'
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"x' | bash "$(hook verifier-guard.sh)" 2>/dev/null)"
[[ "${out}" == *'"deny"'* ]] && ok || ng '깨진 입력이면 verifier-guard는 차단'
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"gh --limit 50' | bash "$(hook bulk-read-log.sh)" 2>&1)"
[[ -z "${out}" ]] && ok || ng '깨진 입력이면 bulk-read-log는 조용히 통과'
[[ -s "${tmp}/hook-errors.log" ]] && ok || ng '오류는 hook-errors.log에 기록'
# 파이썬이 없는 환경: PATH에서 파이썬을 빼고 실행
nopy="$(mk Bash 'bash check.sh' | PATH=/usr/bin:/bin bash "$(hook verifier-guard.sh)" 2>/dev/null)"
if PATH=/usr/bin:/bin bash -c 'hash python 2>/dev/null || hash python3 2>/dev/null'; then echo "건너뜀: /usr/bin에도 파이썬이 있어 파이썬 없는 환경 시험 불가"; else
  [[ "${nopy}" == *'"deny"'* ]] && ok || ng '파이썬 없으면 verifier-guard는 차단'; fi

# 기록 훅: 한글 명령이 깨지지 않게 기록
mk Bash 'gh issue list --limit 50 --json body --search "한글 검색어"' | bash "$(hook bulk-read-log.sh)"
"${PY}" -c "import io,sys; t=io.open(sys.argv[1],encoding='utf-8').read(); sys.exit(0 if '한글 검색어' in t else 1)" "${tmp}/bulk-read-log.md" && ok || ng '한글 기록이 UTF-8로 남음'
mk Write 'C:\Users\me\.claude\settings.json' | bash "$(hook config-changelog.sh)"
grep -q 'settings.json' "${tmp}/config-changelog.md" 2>/dev/null && ok || ng 'Windows 경로 설정 파일 수정 기록'

# config-changelog Bash 판정: 같은 명령 조각에서 쓰기 명령 뒤에 보호 경로가 있을 때만 기록(Issue #173)
cl() { # $1=기대(log|skip) $2=도구 $3=명령 $4=설명
  rm -f "${tmp}/config-changelog.md"
  mk "${2}" "${3}" | bash "$(hook config-changelog.sh)"
  if [[ -f "${tmp}/config-changelog.md" ]]; then got=log; else got=skip; fi
  [[ "${got}" == "${1}" ]] && ok || ng "config-changelog ${4} (기대 ${1}, 실제 ${got})"
}
cl log  Bash "sed -i 's/a/b/' ~/.claude/settings.json" 'sed -i로 설정 수정'
cl log  Bash 'cp base/claude-md/CLAUDE.md ~/.claude/CLAUDE.md' 'cp 목적지가 설정'
cl log  Bash 'echo x > ~/.claude/rules/a.md' '리디렉션 대상이 규칙'
cl log  Bash 'cd /c/Git/AI && cp x "$HOME/.claude/hooks/y.sh"' '$HOME 경로로 복사'
cl log  Bash 'rm ~/.claude/hooks/old.sh' '훅 삭제'
cl log  Bash 'cat a | tee ~/.claude/CLAUDE.md' 'tee로 덮어쓰기'
cl log  PowerShell 'Set-Content -Path C:\Users\me\.claude\settings.json -Value x' 'PowerShell Set-Content'
cl skip Bash 'grep model ~/.claude/settings.json > /tmp/out.txt' '설정 읽고 다른 곳에 저장'
cl skip Bash 'cp ~/.claude/settings.json /tmp/backup.json' '설정을 다른 곳으로 복사'
cl skip Bash 'bash tools/install.sh 2>&1 | tail -4; diff base/x ~/.claude/CLAUDE.md' '설치와 대조'
cl skip Bash 'sed -n 1,5p ~/.claude/settings.json' '설정 읽기'
cl skip Bash 'cat ~/.claude/CLAUDE.md; echo done > /tmp/x' '읽기와 무관한 쓰기가 다른 조각'
cl skip Bash 'git commit -m "cp 설명 ~/.claude/settings.json"' '따옴표 안 글'

echo "통과 ${pass} / 실패 ${fail}"
[[ "${fail}" -eq 0 ]]
