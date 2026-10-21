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

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
