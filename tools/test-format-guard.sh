#!/usr/bin/env bash
# format-guard.sh·md-format-check.sh 시험(Issue #141). 명령 형태별로 훅 입력 JSON을 만들어 넣고 종료 코드를 대조한다.
#   bash tools/test-format-guard.sh
set -u
here="$(cd "$(dirname "${0}")/../base/hooks" && pwd)"   # 시험 대상 훅 폴더
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
export CLAUDE_CONFIG_DIR="${tmp}/home"   # 통과 기록(format-guard.log)을 시험 폴더에 쓴다
mkdir -p "${CLAUDE_CONFIG_DIR}"
printf '%s\n' '## 결과' '' '- 수정 완료' '  - 시험 3건 통과함' > "${tmp}/good.md"
printf '%s\n' '## 결과' '' '- `a.sh`: 설명이 한 줄에 길게 붙어 있어 목록 줄바꿈 규칙을 어긴 경우' > "${tmp}/bad.md"
printf '%s\n' '## 결과' '' '- 버그를 수정했습니다' > "${tmp}/formal.md"
# 훅과 같은 순서로 파이썬을 고른다. Mac은 python 없이 python3만 있는 경우가 많다
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
pass=0; fail=0

run() { # $1=기대 종료 코드 $2=설명 $3=훅(pre|post) $4=도구 이름 $5=명령 또는 파일 JSON 조각
  local want="${1}" name="${2}" hook="${3}" tool="${4}" payload="${5}" got
  local script="${here}/format-guard.sh"; [[ "${hook}" == post ]] && script="${here}/md-format-check.sh"
  got="$(PAYLOAD="${payload}" TOOL="${tool}" CWD="${RUN_CWD:-${tmp}}" HOOK="${hook}" "${PY}" - <<'PY' | bash "${script}" 2>/dev/null; echo "${PIPESTATUS[1]}"
import json, os
p = os.environ['PAYLOAD']
ti = json.loads(p) if os.environ['HOOK'] == 'post' else {'command': p}
print(json.dumps({'tool_name': os.environ['TOOL'], 'tool_input': ti, 'cwd': os.environ['CWD']}), end='')
PY
)"
  if [[ "${got}" == "${want}" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "실패: ${name} (기대 ${want}, 실제 ${got})"; fi
}

D="${tmp}"
run 0 '본문 파일 통과' pre Bash "gh issue comment 1 --body-file ${D}/good.md"
run 2 '본문 파일 목록 위반' pre Bash "gh issue comment 1 --body-file ${D}/bad.md"
run 2 '인라인 본문 위반' pre Bash 'gh issue create --title t --body "- x.sh 파일: 설명이 한 줄에 길게 이어 붙은 목록 항목 문장"'
run 2 '변수+cat 위반' pre Bash "D=\"${D}\"; gh issue close 1 --comment \"\$(cat \"\$D/bad.md\")\""
run 0 '변수+cat 통과' pre Bash "D=\"${D}\"; gh issue close 1 --comment \"\$(cat \"\$D/good.md\")\""
run 2 'pr -F 위반' pre Bash "gh pr create --title t -F ${D}/bad.md"
run 2 '릴리즈 노트 파일 위반' pre Bash "gh release create v1 --notes-file ${D}/bad.md"
run 2 '릴리즈 노트 문장형' pre Bash 'gh release create v1 --notes "- 버그를 수정했습니다"'
run 0 '릴리즈 노트 음슴체' pre Bash 'gh release create v1 --notes "- 버그 수정함"'
run 2 '이슈 본문 문장형' pre Bash "gh issue comment 1 --body-file ${D}/formal.md"
run 2 'env 접두 명령 위반(Issue #164 합친 뒤 검사 대상)' pre Bash 'env A=1 gh issue create --title t --body "- x.sh 파일: 설명이 한 줄에 길게 이어 붙은 목록 항목 문장"'
run 0 'echo 안의 gh 글은 통과' pre Bash 'echo "gh issue create --body - x.sh 파일: 설명이 한 줄에 길게 이어 붙은 목록"'
run 2 '커밋 -m 여러 개 위반' pre Bash 'git commit -m "feat: x" -m "- a.sh 파일: 설명이 한 줄에 길게 붙어 있는 경우를 막는다"'
run 0 '커밋 heredoc 통과' pre Bash "$(printf '%s\n' "git commit -q -F - <<'EOF'" 'feat(x): 제목' '' '- 수정' '  - 설명(괄호)과 "따옴표"' '' 'Refs #1' '' 'Co-Authored-By: A <a@b>' 'EOF')"
run 2 '커밋 heredoc 위반' pre Bash "$(printf '%s\n' "git commit -q -F - <<'EOF'" 'feat(x): 제목' '' '- `b.sh`: 설명이 한 줄에 길게 붙어 있는 경우를 막는다' 'EOF')"
run 2 '커밋 $(cat <<EOF) 위반' pre Bash "$(printf '%s\n' "git commit -m \"\$(cat <<'EOF'" 'feat(x): 제목' '' '- `c.sh`: 설명(괄호 포함)과 "따옴표"가 한 줄에 길게 붙음' 'EOF' ')"')"
run 0 '커밋 제목만' pre Bash 'git commit -m "fix: 제목만 있음"'
run 0 '커밋 문장형은 대상 아님' pre Bash 'git commit -m "fix: 제목" -m "설명 문장을 한다체로 썼다."'
run 0 '사용자 승인 통과' pre Bash "FORMAT_GUARD_SKIP=1 gh issue comment 1 --body-file ${D}/bad.md"
run 2 '본문 글 안의 SKIP 문구는 무시' pre Bash 'git commit -m "fix: x" -m "- a.sh 파일: FORMAT_GUARD_SKIP=1을 붙이면 통과한다는 설명이 길게 붙음"'
run 2 '같은 명령에서 만든 본문 파일 위반' pre Bash "$(printf '%s\n' "D=\"${D}/new\"; mkdir -p \"\$D\"; cat > \"\$D/n.md\" <<'EOF'" '- `n.sh`: 설명이 한 줄에 길게 붙어 있어 목록 줄바꿈 규칙을 어긴 경우' 'EOF' 'gh issue create --title t --body-file "$D/n.md"')"
run 0 '같은 명령에서 만든 본문 파일 통과' pre Bash "$(printf '%s\n' "D=\"${D}/new2\"; cat > \"\$D/n.md\" <<'EOF'" '- 수정함' '  - 설명' 'EOF' 'gh issue create --title t --body-file "$D/n.md"')"
run 0 'heredoc 데이터 안의 명령 글' pre Bash "$(printf '%s\n' "python - <<'EOF'" 'print("git commit -m \"x\" -m \"- a.sh 파일: 설명이 한 줄에 길게 붙어 있는 경우\"")' 'EOF')"
run 0 '문자열 안의 명령 글' pre Bash 'echo "gh issue comment 1 --body \"- a.sh 파일: 설명이 한 줄에 길게 붙어 있는 경우\""'
run 0 '꺼내지 못하면 통과' pre Bash 'gh issue comment 1 --body "$(make_body)"'
run 0 '대상 아닌 명령' pre Bash 'ls -la'
run 0 'gh 조회' pre Bash 'gh issue view 1 --comments'
run 0 '코드 블록 안은 제외' pre Bash "$(printf '%s\n' "git commit -q -F - <<'EOF'" 'feat: x' '' '```' '- a.sh: 코드 블록 안의 예시 줄이라 검사하지 않는다' '```' 'EOF')"
run 0 '인용 안 문장형은 제외' pre Bash 'gh issue comment 1 --body "- \"합니다\"라고 쓰지 않음"'
run 2 'PowerShell 본문 파일' pre PowerShell "gh issue comment 1 --body-file ${D}/bad.md"
run 2 '.md 편집 위반' post Edit "{\"file_path\": \"${D}/x.md\", \"old_string\": \"a\", \"new_string\": \"- \`a.sh\`: 설명이 한 줄에 길게 붙어 있는 목록 항목\"}"
run 0 '.md 쓰기 통과' post Write "{\"file_path\": \"${D}/x.md\", \"content\": \"# 제목\\n\\n- 항목\\n  - 설명\\n\"}"
run 0 '.md 아닌 파일' post Edit "{\"file_path\": \"${D}/x.txt\", \"old_string\": \"a\", \"new_string\": \"- \`a.sh\`: 설명이 한 줄에 길게 붙어 있는 목록 항목\"}"
run 0 '.md 문단은 줄바꿈 규칙 대상 아님' post Write "{\"file_path\": \"${D}/x.md\", \"content\": \"질문: 목록이 아닌 일반 문단은 줄바꿈 규칙 대상이 아니므로 검사하지 않음\\n\"}"
run 2 '.md 문단 문장형 위반(Issue #188)' post Write "{\"file_path\": \"${D}/x.md\", \"content\": \"# 제목\\n\\n이 문단은 문장형으로 끝난다.\\n\"}"
run 2 '.md 목록 문장형 위반' post Edit "{\"file_path\": \"${D}/x.md\", \"old_string\": \"a\", \"new_string\": \"- 설정을 고친다\"}"
run 0 '.md 음슴체 문단 통과' post Write "{\"file_path\": \"${D}/x.md\", \"content\": \"# 제목\\n\\n이 문단은 음슴체로 끝남\\n\"}"
run 0 '.md 코드 블록·백틱 안 문장형은 제외' post Write "{\"file_path\": \"${D}/x.md\", \"content\": \"예시는 \`했다\`처럼 씀\\n\\n\`\`\`\\n이 줄은 예시이다.\\n\`\`\`\\n\"}"
run 0 'rules 아래 지침 문서는 제외' post Write "{\"file_path\": \"${D}/rules/x.md\", \"content\": \"이 규칙은 명령형으로 쓴다.\\n\"}"
run 0 'CLAUDE.md는 제외' post Write "{\"file_path\": \"${D}/CLAUDE.md\", \"content\": \"이 지침은 명령형으로 쓴다.\\n\"}"
mkdir -p "${tmp}/off/.claude" && : > "${tmp}/off/.claude/no-eumseum-check"
RUN_CWD="${tmp}/off" run 0 '.claude/no-eumseum-check가 있으면 문장형 검사 끔' post Write "{\"file_path\": \"${tmp}/off/x.md\", \"content\": \"이 문단은 문장형으로 끝난다.\\n\"}"

echo "통과 ${pass} / 실패 ${fail}"
[[ -f "${CLAUDE_CONFIG_DIR}/format-guard.log" ]] && { echo "통과 기록:"; cut -f2 "${CLAUDE_CONFIG_DIR}/format-guard.log"; }
[[ "${fail}" -eq 0 ]]
