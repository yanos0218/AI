#!/usr/bin/env bash
# install.sh가 사용자 값을 지우지 않는지 임시 폴더에서 시험한다(Issue #194).
#   bash tools/test-install-merge.sh
# 실제 ~/.claude는 건드리지 않는다(CLAUDE_CONFIG_DIR을 임시 폴더로 지정).
# shellcheck disable=SC2034  # nbak·out·rc는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
PY="$(command -v python3 || command -v python)"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
export CLAUDE_CONFIG_DIR="${T}/home"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

mkdir -p "${CLAUDE_CONFIG_DIR}/skills/self-audit" "${CLAUDE_CONFIG_DIR}/skills/my-own"
echo "내가 고친 스킬" > "${CLAUDE_CONFIG_DIR}/skills/self-audit/SKILL.md"
echo "내 스킬" > "${CLAUDE_CONFIG_DIR}/skills/my-own/SKILL.md"
"${PY}" - "${CLAUDE_CONFIG_DIR}/settings.json" <<'PYEOF'
import io, json, sys
d = {
  "permissions": {"allow": ["Bash(my-user-cmd *)"], "deny": ["Read(./secret.txt)"]},
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /opt/my-hook.sh"}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "bash /opt/stop.sh"}]}]
  },
  "env": {"MY_VAR": "1"},
  "myDeviceKey": True
}
io.open(sys.argv[1], 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False))
PYEOF

echo "== 1. 사용자 값이 있는 상태에서 설치"
bash tools/install.sh >"${T}/out1.txt" 2>&1
S="${CLAUDE_CONFIG_DIR}/settings.json"
q() { "${PY}" - "$S" "$1" <<'PYEOF'
import io, json, sys
d = json.load(io.open(sys.argv[1], encoding='utf-8'))
sys.exit(0 if eval(sys.argv[2]) else 1)
PYEOF
}
chk "사용자 allow 항목 유지"       'q "\"Bash(my-user-cmd *)\" in d[\"permissions\"][\"allow\"]"'
chk "사용자 deny 항목 유지"        'q "\"Read(./secret.txt)\" in d[\"permissions\"][\"deny\"]"'
chk "base allow 항목 추가됨"       'q "len(d[\"permissions\"][\"allow\"]) > 1"'
chk "사용자 훅(기존 이벤트) 유지"  'q "any(h[\"command\"]==\"bash /opt/my-hook.sh\" for g in d[\"hooks\"][\"PreToolUse\"] for h in g[\"hooks\"])"'
chk "사용자 훅(새 이벤트) 유지"    'q "\"Stop\" in d[\"hooks\"]"'
chk "base 훅 설치됨"               'q "any(\"git-guardrails\" in h[\"command\"] for g in d[\"hooks\"][\"PreToolUse\"] for h in g[\"hooks\"])"'
chk "사용자 env 키 유지"           'q "d[\"env\"].get(\"MY_VAR\")==\"1\""'
chk "기기별 키 유지"               'q "d.get(\"myDeviceKey\") is True"'
chk "settings.json 백업 생성"      'ls "${CLAUDE_CONFIG_DIR}"/settings.json.bak.* >/dev/null 2>&1'
chk "고친 스킬 보관됨"             'grep -rq "내가 고친 스킬" "${CLAUDE_CONFIG_DIR}/backups/claude-config/"'
chk "스킬은 base로 교체됨"         'diff -rq -x __pycache__ base/skills/self-audit "${CLAUDE_CONFIG_DIR}/skills/self-audit" >/dev/null'
chk "사용자 전용 스킬 유지"        '[[ -f "${CLAUDE_CONFIG_DIR}/skills/my-own/SKILL.md" ]]'
chk "설치본 대조에서 settings 일치" '"${PY}" tools/settings_merge.py check "$S" base/settings.example.json >/dev/null'

echo "== 2. 두 번째 설치는 결과가 같다"
nbak="$(ls "${CLAUDE_CONFIG_DIR}"/settings.json.bak.* | wc -l | tr -d ' ')"
cp "$S" "${T}/before.json"
sleep 1
bash tools/install.sh >"${T}/out2.txt" 2>&1
chk "settings.json 변경 없음 표시"  'grep -q "변경 없음" "${T}/out2.txt"'
chk "settings.json 내용 동일"       'cmp -s "${T}/before.json" "$S"'
chk "백업이 더 늘지 않음"           '[[ "$(ls "${CLAUDE_CONFIG_DIR}"/settings.json.bak.* | wc -l | tr -d " ")" = "${nbak}" ]]'

echo "== 3. --dry-run은 아무것도 바꾸지 않는다"
export CLAUDE_CONFIG_DIR="${T}/home2"; mkdir -p "${CLAUDE_CONFIG_DIR}/skills/self-audit"
echo '{"permissions":{"allow":["Bash(x)"]}}' > "${CLAUDE_CONFIG_DIR}/settings.json"
echo "고친" > "${CLAUDE_CONFIG_DIR}/skills/self-audit/SKILL.md"
cp "${CLAUDE_CONFIG_DIR}/settings.json" "${T}/dry-before.json"
bash tools/install.sh --dry-run >"${T}/out3.txt" 2>&1
chk "settings.json 그대로"          'cmp -s "${T}/dry-before.json" "${CLAUDE_CONFIG_DIR}/settings.json"'
chk "백업 폴더 안 만들어짐"         '[[ ! -d "${CLAUDE_CONFIG_DIR}/backups" ]]'
chk "스킬 그대로"                   'grep -q "^고친$" "${CLAUDE_CONFIG_DIR}/skills/self-audit/SKILL.md"'

echo "== 4. 깨진 settings.json은 건드리지 않고 실패를 알린다"
export CLAUDE_CONFIG_DIR="${T}/home3"; mkdir -p "${CLAUDE_CONFIG_DIR}"
printf '{ "permissions": { "allow": [ // 주석\n ] } }\n' > "${CLAUDE_CONFIG_DIR}/settings.json"
cp "${CLAUDE_CONFIG_DIR}/settings.json" "${T}/broken-before.json"
bash tools/install.sh >"${T}/out4.txt" 2>&1; rc=$?
chk "설치 종료 코드가 실패"          '[[ "${rc}" != 0 ]]'
chk "병합 실패 안내가 나옴"          'grep -q "병합 실패" "${T}/out4.txt"'
chk "트레이스백이 나오지 않음"       '! grep -q Traceback "${T}/out4.txt"'
chk "마지막 줄이 성공으로 오해되지 않음" '! grep -q "^== 설치 끝\. 스킬" "${T}/out4.txt"'
chk "깨진 파일 그대로"               'cmp -s "${T}/broken-before.json" "${CLAUDE_CONFIG_DIR}/settings.json"'
chk "나머지 파일은 설치됨"           '[[ -f "${CLAUDE_CONFIG_DIR}/CLAUDE.md" ]]'

echo "== 5. 모양이 이상한 settings.json도 같은 방식으로 처리한다"
for body in '{"hooks":{"Stop":"oops"}}' '{"permissions":null}' '{"env":[]}' '[]'; do
  printf '%s\n' "${body}" > "${T}/odd.json"
  out="$("${PY}" tools/settings_merge.py install "${T}/odd.json" base/settings.example.json 2>&1)"; rc=$?
  chk "건너뜀: ${body}" '[[ "${rc}" = 3 ]] && ! grep -q Traceback <<<"${out}" && [[ "$(cat "${T}/odd.json")" = "${body}" ]]'
done

echo "== 6. 출력 인코딩이 cp1252여도 한글 안내가 깨지지 않는다(Windows 파이프 흉내, CI windows-latest에서 발견)"
echo '{}' > "${T}/enc.json"
out="$(PYTHONIOENCODING=cp1252 "${PY}" tools/settings_merge.py install "${T}/enc.json" base/settings.example.json 2>&1)"; rc=$?
chk "종료 코드 0"                    '[[ "${rc}" = 0 ]]'
chk "트레이스백 없음"                '! grep -q Traceback <<<"${out}"'
chk "병합 결과가 파일에 쓰임"        'grep -q permissions "${T}/enc.json"'

echo "== 6b. 출력이 ASCII(locale C)여도 install·fingerprint·check-install·check-doc-sync의 한글 출력이 깨지지 않는다(파이썬 3.6 기기에서 발견, Issue #202)"
# 3.6에는 reconfigure가 없어 감싸기 경로를 탄다. CI 러너(3.7 이상)는 reconfigure 경로만 시험하고, 감싸기 경로는 3.6 기기(RHEL 8 계열)에서만 시험된다
ascii_env=(env -u LANG -u LC_ALL -u LC_CTYPE LC_ALL=C PYTHONIOENCODING=ascii CLAUDE_CONFIG_DIR="${T}/home6b")
echo '{"theme":"dark"}' > "${T}/seed6b.json"; mkdir -p "${T}/home6b"; cp "${T}/seed6b.json" "${T}/home6b/settings.json"
out="$("${ascii_env[@]}" bash tools/install.sh 2>&1)"; rc=$?
chk "install 종료 코드 0"            '[[ "${rc}" = 0 ]]'
chk "install 트레이스백 없음"        '! grep -q Traceback <<<"${out}"'
chk "install 뒤 사용자 키 유지"      'grep -q "\"theme\"" "${T}/home6b/settings.json"'
out="$("${ascii_env[@]}" bash tools/check-install.sh 2>&1)"; rc=$?
chk "check-install 종료 코드 0"      '[[ "${rc}" = 0 ]]'
chk "check-install 트레이스백 없음"  '! grep -q Traceback <<<"${out}"'
out="$("${ascii_env[@]}" bash tools/fingerprint.sh 2>&1)"; rc=$?
chk "fingerprint 종료 코드 0"        '[[ "${rc}" = 0 ]]'
chk "fingerprint 트레이스백 없음"    '! grep -q Traceback <<<"${out}"'
out="$("${ascii_env[@]}" "${PY}" tools/check-doc-sync.py 2>&1)"; rc=$?
chk "check-doc-sync 종료 코드 0"     '[[ "${rc}" = 0 ]]'
chk "check-doc-sync 트레이스백 없음" '! grep -q Traceback <<<"${out}"'

echo "== 7. 설치 뒤 check-install.sh·fingerprint.sh도 한글 출력이 파이프에서 깨지지 않는다(Windows 러너에서 확인)"
export CLAUDE_CONFIG_DIR="${T}/home7"
bash tools/install.sh >"${T}/out7.txt" 2>&1
out="$(bash tools/check-install.sh 2>&1)"; rc=$?
chk "check-install 종료 코드 0"      '[[ "${rc}" = 0 ]]'
chk "check-install 트레이스백 없음"  '! grep -q Traceback <<<"${out}"'
chk "check-install 판정이 같음"      'grep -q "설치본이 기본 영역과 같다" <<<"${out}"'
out="$(bash tools/fingerprint.sh 2>&1)"; rc=$?
[[ "${rc}" = 0 ]] || { echo "  --- fingerprint 출력 끝 15줄(진단)"; printf '%s\n' "${out}" | tail -15; }
chk "fingerprint 종료 코드 0"        '[[ "${rc}" = 0 ]]'
chk "fingerprint 트레이스백 없음"    '! grep -q Traceback <<<"${out}"'
chk "fingerprint 한글 항목 출력"     'grep -q "기기 OS" <<<"${out}"'

echo "== 7b. WSL에서 Windows VS Code(/mnt 아래 code)가 잡혀도 확장 MISSING이 판정을 깨지 않는다(Issue #201, 가짜 code로 흉내)"
# 실제 /mnt를 건드리지 않으려고 WIN_MOUNT_ROOT를 임시 폴더로 바꿔 /mnt 역할을 맡긴다. 실제 WSL에서는 사용자가 따로 확인한다
mkdir -p "${T}/fakewin/bin" "${T}/fakenative"
printf '#!/usr/bin/env bash\nexit 0\n' > "${T}/fakewin/bin/code"; cp "${T}/fakewin/bin/code" "${T}/fakenative/code"
chmod +x "${T}/fakewin/bin/code" "${T}/fakenative/code"
wsl_env=(env CLAUDE_CONFIG_DIR="${T}/home7" WIN_MOUNT_ROOT="${T}/fakewin/" WSL_DISTRO_NAME=Ubuntu)
out="$(PATH="${T}/fakewin/bin:${PATH}" "${wsl_env[@]}" bash tools/check-install.sh 2>&1)"; rc=$?
chk "WSL+Windows code: 종료 코드 0"          '[[ "${rc}" = 0 ]]'
chk "WSL+Windows code: 판정이 같음"          'grep -q "설치본이 기본 영역과 같다" <<<"${out}"'
chk "WSL+Windows code: 안내가 나옴"          'grep -q "WSL" <<<"${out}"'
chk "WSL+Windows code: MISSING은 정보로 보임" 'grep -q "MISSING" <<<"${out}"'
out="$(PATH="${T}/fakenative:${PATH}" "${wsl_env[@]}" bash tools/check-install.sh 2>&1)"; rc=$?
chk "WSL+WSL 안 code: 진짜 MISSING은 실패로 셈" '[[ "${rc}" = 1 ]]'
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "  건너뜀  실제 WSL이라 WSL 아님 대조는 생략"
else
  out="$(PATH="${T}/fakewin/bin:${PATH}" env -u WSL_DISTRO_NAME CLAUDE_CONFIG_DIR="${T}/home7" WIN_MOUNT_ROOT="${T}/fakewin/" bash tools/check-install.sh 2>&1)"; rc=$?
  chk "WSL 아님: 같은 code여도 실패로 셈"      '[[ "${rc}" = 1 ]]'
fi

echo "== 8. fingerprint --common: 사용자 추가는 공통 구역에 안 나오고, 기기 간 어긋남만 나온다"
export CLAUDE_CONFIG_DIR="${T}/home8"
bash tools/install.sh >"${T}/out8.txt" 2>&1
bash tools/fingerprint.sh --common >"${T}/fp-base.txt" 2>&1
chk "--common은 [공통] 줄만 출력"     '! grep -v "^\[공통\]" "${T}/fp-base.txt" | grep -q .'
chk "설치 직후 base 대비 same"        'grep -q "settings base 대비 = same" "${T}/fp-base.txt"'
chk "전체 출력에는 [기기별]도 있음"   'bash tools/fingerprint.sh | grep -q "^\[기기별\]"'
edit() { "${PY}" - "${CLAUDE_CONFIG_DIR}/settings.json" "$1" <<'PYEOF'
import io, json, sys
p = sys.argv[1]
d = json.load(io.open(p, encoding='utf-8'))
exec(sys.argv[2])
io.open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
PYEOF
}
edit "d['permissions']['allow'].append('Bash(my-own *)')"
bash tools/fingerprint.sh --common >"${T}/fp-user.txt" 2>&1
chk "사용자 allow 추가는 공통 구역 불변" 'cmp -s "${T}/fp-base.txt" "${T}/fp-user.txt"'
chk "사용자 추가는 [기기별] 줄에 표시"   'bash tools/fingerprint.sh | grep "^\[기기별\] 사용자 추가 항목" | grep -q "1개"'
edit "d['permissions']['defaultMode'] = 'acceptEdits'"
bash tools/fingerprint.sh --common >"${T}/fp-key.txt" 2>&1
chk "권한 추가 키는 공통 구역에서 차이로 드러남" '! cmp -s "${T}/fp-base.txt" "${T}/fp-key.txt" && grep -q "defaultMode=" "${T}/fp-key.txt"'
edit "d['model'] = 'claude-opus-5-5'"
bash tools/fingerprint.sh --common >"${T}/fp-model.txt" 2>&1
chk "model 어긋남이 base 대비 DIFF로 보임" 'grep -q "settings base 대비 = DIFF model" "${T}/fp-model.txt"'

echo "== 9. 오래된 백업은 종류별 최근 3개만 남기고 자동 정리한다(직접 만든 이름은 그대로)"
H9="${T}/home9"; export CLAUDE_CONFIG_DIR="${H9}"
mkdir -p "${H9}/backups/claude-config" "${H9}/skills/self-audit"
for i in 1 2 3 4 5 6; do
  echo "old${i}" > "${H9}/CLAUDE.md.bak.2020010100000${i}"
done
for i in 1 2 3 4 5; do
  echo "{}" > "${H9}/settings.json.bak.2020010100000${i}"
  mkdir -p "${H9}/backups/claude-config/2020010100000${i}"
done
echo manual > "${H9}/settings.json.bak.pre-blockreads"; echo manual > "${H9}/CLAUDE.md.bak.manual"
echo "고친" > "${H9}/skills/self-audit/SKILL.md"; echo old > "${H9}/CLAUDE.md"
bash tools/install.sh --dry-run >"${T}/out9d.txt" 2>&1
chk "--dry-run은 아무것도 안 지움"        '[[ "$(ls "${H9}"/CLAUDE.md.bak.2020* | wc -l | tr -d " ")" = 6 ]]'
chk "--dry-run이 정리 대상을 알림"         'grep -q "오래된 백업 정리" "${T}/out9d.txt"'
bash tools/install.sh >"${T}/out9.txt" 2>&1
chk "CLAUDE.md 백업은 최근 3개만"         '[[ "$(find "${H9}" -maxdepth 1 -name "CLAUDE.md.bak.[0-9]*" | wc -l | tr -d " ")" = 3 ]]'
chk "이번 설치가 만든 백업은 남음"        'find "${H9}" -maxdepth 1 -name "CLAUDE.md.bak.2026*" | grep -q .'
chk "가장 오래된 것부터 지워짐"           '[[ ! -e "${H9}/CLAUDE.md.bak.20200101000001" && -e "${H9}/CLAUDE.md.bak.20200101000006" ]]'
chk "settings 백업도 3개 이하"            '[[ "$(find "${H9}" -maxdepth 1 -name "settings.json.bak.[0-9]*" | wc -l | tr -d " ")" -le 3 ]]'
chk "보관 폴더도 3개 이하"                '[[ "$(find "${H9}/backups/claude-config" -maxdepth 1 -type d -name "[0-9]*" | wc -l | tr -d " ")" -le 3 ]]'
chk "직접 만든 이름은 그대로"             '[[ -f "${H9}/settings.json.bak.pre-blockreads" && -f "${H9}/CLAUDE.md.bak.manual" ]]'
# 병합 실패 시에는 정리하지 않는다
for i in 7 8 9; do echo "old${i}" > "${H9}/CLAUDE.md.bak.2020010100000${i}"; done
printf '{ broken // json\n' > "${H9}/settings.json"
bash tools/install.sh >"${T}/out9f.txt" 2>&1
chk "병합 실패 때는 정리하지 않음"        '[[ "$(find "${H9}" -maxdepth 1 -name "CLAUDE.md.bak.[0-9]*" | wc -l | tr -d " ")" -ge 4 ]]'

echo "== 10. 읽기 차단을 켜면 허용 폴더(설치본 폴더·원본 저장소)를 설치가 계산해 넣는다(Issue #205)"
H10="${T}/home10"; export CLAUDE_CONFIG_DIR="${H10}"; mkdir -p "${H10}"
echo '{"permissions":{"additionalDirectories":["user-extra/dir"]}}' > "${H10}/settings.json"
bash tools/install.sh >"${T}/out10.txt" 2>&1
# q10 <확인식>: d=설치본 settings, home·repo=기대 경로. 슬래시·대소문자 차이나 짧은 이름은 같은 경로로 본다
q10() { "${PY}" - "${H10}/settings.json" "${H10}" "$(pwd)" "$1" <<'PYEOF'
import io, json, os, sys
d = json.load(io.open(sys.argv[1], encoding='utf-8'))
home, repo = sys.argv[2], sys.argv[3]
def same(a, b):
    if os.path.normcase(os.path.normpath(a)) == os.path.normcase(os.path.normpath(b)):
        return True
    return os.path.exists(a) and os.path.exists(b) and os.path.samefile(a, b)
def has(p):
    return any(same(x, p) for x in d.get('permissions', {}).get('additionalDirectories', []))
sys.exit(0 if eval(sys.argv[4]) else 1)
PYEOF
}
chk "읽기 차단 값이 들어감"               'q10 "d[\"permissions\"].get(\"blockReadsOutsideWorkingDirectories\") is True"'
chk "설치본 폴더(.claude) 경로가 허용 폴더에 들어감" 'q10 "has(home)"'
chk "원본 저장소 경로가 들어감"           'q10 "has(repo)"'
chk "사용자 허용 폴더는 유지"             'q10 "has(\"user-extra/dir\")"'
nbak10="$(ls "${H10}"/settings.json.bak.* 2>/dev/null | wc -l | tr -d ' ')"
bash tools/install.sh >"${T}/out10b.txt" 2>&1
chk "두 번째 설치는 변경 없음"            'grep -q "settings.json 병합: 변경 없음" "${T}/out10b.txt"'
chk "백업이 더 늘지 않음"                 '[[ "$(ls "${H10}"/settings.json.bak.* 2>/dev/null | wc -l | tr -d " ")" = "${nbak10}" ]]'
edit10() { "${PY}" - "${H10}/settings.json" "$1" <<'PYEOF'
import io, json, sys
p = sys.argv[1]
d = json.load(io.open(p, encoding='utf-8'))
exec(sys.argv[2])
io.open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
PYEOF
}
edit10 "a = d['permissions']['additionalDirectories']; a[:] = [x + '/' if x != 'user-extra/dir' else x for x in a]"
bash tools/install.sh >"${T}/out10c.txt" 2>&1
chk "끝 슬래시만 다른 경로는 중복으로 안 늘림" 'grep -q "settings.json 병합: 변경 없음" "${T}/out10c.txt"'
"${PY}" tools/settings_merge.py check "${H10}/settings.json" base/settings.example.json >"${T}/check10.txt" 2>&1; rc=$?
chk "설치 직후 check는 어긋남 없음"       '[[ "${rc}" = 0 ]]'
chk "설치가 넣은 허용 폴더는 사용자 추가로 안 셈(사용자 것 1개만)" 'grep -q "additionalDirectories 설치본에만 있음 1개" "${T}/check10.txt"'
bash tools/fingerprint.sh --common >"${T}/fp10.txt" 2>&1
chk "지문 추가 키에 기기별 경로가 안 나옴" 'grep -q "permissions 추가 키 = 없음" "${T}/fp10.txt"'
chk "지문 base 대비 same"                 'grep -q "settings base 대비 = same" "${T}/fp10.txt"'
edit10 "d['permissions']['additionalDirectories'] = ['user-extra/dir']"
"${PY}" tools/settings_merge.py check "${H10}/settings.json" base/settings.example.json >/dev/null 2>&1; rc=$?
chk "허용 폴더가 빠지면 check가 어긋남으로 봄" '[[ "${rc}" = 1 ]]'

echo "== 11. fingerprint 설치본 줄: 설치 직후 최신, 해시가 다르면 낡음, 해시가 없으면 비교 못 함(Issue #203)"
H11="${T}/home11"
CLAUDE_CONFIG_DIR="${H11}" bash tools/install.sh >"${T}/out11.txt" 2>&1
CLAUDE_CONFIG_DIR="${H11}" bash tools/fingerprint.sh >"${T}/fp11a.txt" 2>&1
chk "설치 직후는 최신"                    'grep -q "^\[기기별\] 설치본 = 최신$" "${T}/fp11a.txt"'
chk "설치본 줄은 --common에 안 나옴"      '! CLAUDE_CONFIG_DIR="${H11}" bash tools/fingerprint.sh --common | grep -q "설치본 ="'
"${PY}" - "${H11}/.claude-config-version" <<'PYEOF'
import io, sys
p = sys.argv[1]
l = io.open(p, encoding='utf-8').read().split('\n')
l[2] = '0' * 40
io.open(p, 'w', encoding='utf-8', newline='\n').write('\n'.join(l))
PYEOF
CLAUDE_CONFIG_DIR="${H11}" bash tools/fingerprint.sh >"${T}/fp11b.txt" 2>&1
chk "해시가 다르면 낡음과 저장소 해시"    'grep -q "^\[기기별\] 설치본 = 낡음(저장소 $(git rev-parse HEAD:base | cut -c1-8))$" "${T}/fp11b.txt"'
head -n 2 "${H11}/.claude-config-version" >"${H11}/v2" && mv "${H11}/v2" "${H11}/.claude-config-version"
CLAUDE_CONFIG_DIR="${H11}" bash tools/fingerprint.sh >"${T}/fp11c.txt" 2>&1
chk "3행이 없으면 비교 못 함"             'grep -q "^\[기기별\] 설치본 = 비교 못 함" "${T}/fp11c.txt"'

echo "== 12. base/vscode/install.sh: WSL에서 /mnt 아래 code(Windows VS Code)면 안내하고 멈춘다(Issue #204, 가짜 code로 흉내)"
# 가짜 code는 호출되면 로그 파일을 남겨, 멈췄는지(호출 안 됨)와 진행했는지(호출됨)를 가른다. 실제 확장은 설치하지 않는다
mkdir -p "${T}/fakewin12/bin" "${T}/fakenative12" "${T}/h12a" "${T}/h12b" "${T}/h12c"
for d in "${T}/fakewin12/bin" "${T}/fakenative12"; do
  printf '#!/usr/bin/env bash\necho called >>"${CODE_LOG}"\nexit 0\n' > "${d}/code"; chmod +x "${d}/code"
done
out="$(PATH="${T}/fakewin12/bin:${PATH}" env HOME="${T}/h12a" CODE_LOG="${T}/log12a" WIN_MOUNT_ROOT="${T}/fakewin12/" WSL_DISTRO_NAME=Ubuntu bash base/vscode/install.sh 2>&1)"; rc=$?
chk "WSL+Windows code: 종료 코드 1"            '[[ "${rc}" = 1 ]]'
chk "WSL+Windows code: install.ps1 안내"       'grep -q "install.ps1" <<<"${out}"'
chk "WSL+Windows code: code를 호출하지 않음"   '[[ ! -e "${T}/log12a" ]]'
chk "WSL+Windows code: 설정 파일을 복사하지 않음" '[[ -z "$(find "${T}/h12a" -name settings.json 2>/dev/null)" ]]'
out="$(PATH="${T}/fakenative12:${PATH}" env HOME="${T}/h12b" CODE_LOG="${T}/log12b" WIN_MOUNT_ROOT="${T}/fakewin12/" WSL_DISTRO_NAME=Ubuntu bash base/vscode/install.sh 2>&1)"; rc=$?
chk "WSL+WSL 안 code: 진행(종료 코드 0)"        '[[ "${rc}" = 0 ]]'
chk "WSL+WSL 안 code: code를 호출함"           '[[ -e "${T}/log12b" ]]'
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "  건너뜀  실제 WSL이라 WSL 아님 대조는 생략"
else
  out="$(PATH="${T}/fakewin12/bin:${PATH}" env -u WSL_DISTRO_NAME HOME="${T}/h12c" CODE_LOG="${T}/log12c" WIN_MOUNT_ROOT="${T}/fakewin12/" bash base/vscode/install.sh 2>&1)"; rc=$?
  chk "WSL 아님: 같은 code여도 진행"            '[[ "${rc}" = 0 && -e "${T}/log12c" ]]'
fi

echo "== 13. base/vscode/install.sh: extensions.txt가 CRLF여도 확장 ID에 \r이 붙지 않는다(Issue #208)"
# 가짜 code는 받은 확장 ID를 줄마다 [ID]로 기록해, 끝에 CR이 붙었는지 가른다
mkdir -p "${T}/vs13/bin" "${T}/h13"
cp base/vscode/install.sh base/vscode/settings.json "${T}/vs13/"
printf 'usernamehw.errorlens\r\n# 주석\r\n\r\nredhat.vscode-yaml\r\n' > "${T}/vs13/extensions.txt"
printf '#!/usr/bin/env bash\nprintf "[%%s]\n" "$2" >>"${CODE_LOG}"\nexit 0\n' > "${T}/vs13/bin/code"; chmod +x "${T}/vs13/bin/code"
out="$(PATH="${T}/vs13/bin:${PATH}" env -u WSL_DISTRO_NAME HOME="${T}/h13" CODE_LOG="${T}/log13" bash "${T}/vs13/install.sh" 2>&1)"; rc=$?
chk "CRLF 목록: 종료 코드 0"                   '[[ "${rc}" = 0 ]]'
chk "CRLF 목록: 확장 ID 2개가 CR 없이 전달됨"   '[[ "$(tr "\n" " " < "${T}/log13")" = "[usernamehw.errorlens] [redhat.vscode-yaml] " ]]'

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
