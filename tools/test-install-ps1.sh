#!/usr/bin/env bash
# tools/install.ps1 시험 (Issue #247, #249). 임시 폴더와 현재 HEAD의 zip으로 실행하고 ~/.claude는 건드리지 않는다.
#   bash tools/test-install-ps1.sh
# pwsh가 없으면 미검증으로 끝낸다(종료 코드 0). PowerShell 7로 도는 시험이라 Windows PowerShell 5.1 동작은 보증하지 않는다.
set -u
cd "$(dirname "${0}")/.." || exit 1
PY="$(command -v python3 || command -v python)"
if ! command -v pwsh >/dev/null 2>&1; then echo "미검증: pwsh가 없음"; exit 0; fi

T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

git archive --format=zip --prefix=AI-test/ HEAD -o "${T}/pkg.zip" || exit 1
C="${T}/home/.claude"
mkdir -p "${T}/home" "${T}/pf/Git/bin"
run() { env -i HOME="${T}/home" PATH=/usr/bin:/bin:/opt/homebrew/bin USERPROFILE="${T}/home" ProgramFiles="${T}/pf" LOCALAPPDATA="${T}/lad" \
  CLAUDE_CONFIG_DIR="${C}" CLAUDE_CONFIG_ZIP="${T}/pkg.zip" CLAUDE_CONFIG_ASSUME="${ASSUME:-no}" pwsh -NoProfile -File tools/install.ps1 2>&1; }

echo "== 문법"
"$(command -v pwsh)" -NoProfile -Command '$e=$null;$t=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("tools/install.ps1",[ref]$t,[ref]$e);exit $e.Count' \
  && ok "문법 오류 0건" || bad "문법 오류"

echo "== 1단계: bash 없음 (Git 위치에 bash.exe 없음)"
out="$(run)"
echo "${out}" | grep -q '1단계만 끝남' && ok "1단계만 끝났다고 안내" || bad "1단계 안내 없음: ${out}"
[[ -f "${C}/CLAUDE.md" && -d "${C}/skills/config-update" && -f "${C}/hooks/git-guardrails.sh" ]] && ok "CLAUDE.md·skills·hooks 파일 복사" || bad "파일 복사"
"${PY}" - "${C}/settings.json" <<'EOF' && ok "settings.json: BOM 없음, hooks·statusLine 없음, permissions 있음" || bad "settings.json 내용"
import json, sys
raw = open(sys.argv[1], 'rb').read()
assert raw[:3] != b'\xef\xbb\xbf'
d = json.loads(raw.decode('utf-8'))
assert 'hooks' not in d and 'statusLine' not in d and d['permissions']['allow']
EOF

echo "== 기존 settings.json 보존"
echo '{"x":1}' > "${C}/settings.json"
run >/dev/null
[[ "$(cat "${C}/settings.json")" = '{"x":1}' ]] && ok "기존 settings.json을 바꾸지 않음" || bad "기존 settings.json이 바뀜"

echo "== 설치 동의했지만 winget도 직접 설치도 못 하는 환경(x64 Windows가 아님)"
out="$(ASSUME=yes run)"
echo "${out}" | grep -q '64비트(x64) Windows만 지원' && echo "${out}" | grep -q 'git-scm.com/download/win' && ok "직접 설치 불가 사유와 수동 설치 주소 안내" || bad "폴백 안내 없음: ${out}"

echo "== 2단계: 가짜 Git Bash (bash.exe)"
printf '#!/bin/bash\nexec /bin/bash "$@"\n' > "${T}/pf/Git/bin/bash.exe"; chmod +x "${T}/pf/Git/bin/bash.exe"
rm -f "${C}/settings.json"
out="$(run)"
echo "${out}" | grep -q '훅까지 설치됨' && ok "훅까지 설치됨 안내" || bad "2단계 안내 없음"
"${PY}" -c "import json,sys; d=json.load(open(sys.argv[1])); assert 'hooks' in d and 'statusLine' in d" "${C}/settings.json" && ok "settings.json에 hooks·statusLine 병합" || bad "훅 병합 안 됨"
[[ "$(sed -n 2p "${C}/.claude-config-version")" = "local" ]] && ok "버전 표시 파일에 태그 복원(임시, Issue #248)" || bad "버전 표시 파일 태그 없음"

echo "결과: ${pass}건 통과, ${fail}건 실패"
[[ "${fail}" = 0 ]]
