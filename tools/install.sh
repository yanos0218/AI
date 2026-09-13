#!/usr/bin/env bash
# base/ → ~/.claude 설치 (Windows Git Bash · Mac · Linux 공통, 멱등).
#   bash tools/install.sh            설치 후 check-install.sh로 대조
#   bash tools/install.sh --dry-run  무엇이 바뀔지만 보여주고 손대지 않음
# 하는 일: CLAUDE.md·hooks·skills 복사, settings.json에 permissions·hooks·statusLine·env 키 병합(기기별 키는 유지).
# 하지 않는 일: 기존 CLAUDE.md를 묻지 않고 덮어쓰지 않는다(다르면 백업 후 교체하고 diff 경로를 알린다).
set -u
cd "$(dirname "${0}")/.." || exit 1
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
PY="$(command -v python3 || command -v python)"
DRY=0; [[ "${1:-}" = "--dry-run" ]] && DRY=1
say() { printf '%s\n' "$*"; }
run() { if [[ "${DRY}" = 1 ]]; then say "  (dry) $*"; else "$@"; fi; }

BASE_VER="$(git describe --tags --always 2>/dev/null)"
SRC_ABS="$(pwd)"
say "== 대상: ${CLAUDE_HOME}  (base 버전: ${BASE_VER})"
run mkdir -p "${CLAUDE_HOME}/hooks" "${CLAUDE_HOME}/skills"

# 1. CLAUDE.md — 다르면 백업 후 교체
src=base/claude-md/CLAUDE.md; dst="${CLAUDE_HOME}/CLAUDE.md"
if [[ -f "${dst}" ]] && ! diff -q "${src}" "${dst}" >/dev/null; then
  bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
  say "  CLAUDE.md 다름 → 기존 파일을 ${bak} 로 백업하고 교체 (diff: diff ${bak} ${dst})"
  run cp "${dst}" "${bak}"
fi
run cp "${src}" "${dst}"; say "  CLAUDE.md 설치"

# 2. hooks
for f in base/hooks/*.sh; do run cp "${f}" "${CLAUDE_HOME}/hooks/"; done
run chmod +x "${CLAUDE_HOME}"/hooks/*.sh 2>/dev/null
say "  hooks 설치: $(ls base/hooks | tr '\n' ' ')"

# 3. skills (_로 시작하는 틀은 제외, 기존 폴더는 교체)
for d in base/skills/*/; do
  n="$(basename "${d}")"; [[ "${n}" == _* ]] && continue
  run rm -rf "${CLAUDE_HOME}/skills/${n}"; run cp -r "${d}" "${CLAUDE_HOME}/skills/${n}"; say "  skill 설치: ${n}"
done

# 3b. rules (모듈 규칙) — base/rules/*.md → ~/.claude/rules/
if ls base/rules/*.md >/dev/null 2>&1; then
  run mkdir -p "${CLAUDE_HOME}/rules"
  for f in base/rules/*.md; do run cp "${f}" "${CLAUDE_HOME}/rules/"; done
  say "  rules 설치: $(ls base/rules | tr '\n' ' ')"
fi

# 4. settings.json 병합 — permissions·hooks·statusLine·env 은 base 값으로, 나머지 키(model 등)는 유지
if [[ "${DRY}" = 1 ]]; then say "  (dry) settings.json 병합: permissions·hooks·statusLine·env"; else
"${PY}" - "${CLAUDE_HOME}/settings.json" base/settings.example.json <<'PY'
import json, sys, io, os, collections
dst, src = sys.argv[1], sys.argv[2]
base = json.load(io.open(src, encoding='utf-8'), object_pairs_hook=collections.OrderedDict)
cur = collections.OrderedDict()
if os.path.exists(dst):
    cur = json.load(io.open(dst, encoding='utf-8'), object_pairs_hook=collections.OrderedDict)
changed = []
for k in ('$schema', 'permissions', 'hooks', 'statusLine', 'env'):
    if k in base and cur.get(k) != base[k]:
        cur[k] = base[k]; changed.append(k)
io.open(dst, 'w', encoding='utf-8', newline='\n').write(json.dumps(cur, ensure_ascii=False, indent=2) + '\n')
print('  settings.json 병합: ' + (', '.join(changed) + ' 갱신' if changed else '변경 없음'))
PY
fi

# 5. 버전 표시 파일 — SessionStart 훅(session-start-check.sh)이 최신 여부를 조용히 확인하는 데 씀
if [[ "${DRY}" = 1 ]]; then say "  (dry) 버전 표시 파일 기록: ${SRC_ABS} / ${BASE_VER}"; else
  printf '%s\n%s\n' "${SRC_ABS}" "${BASE_VER}" > "${CLAUDE_HOME}/.claude-config-version"
  say "  버전 표시 기록: ${BASE_VER}"
fi

say "== 설치 끝. 스킬·훅은 새 세션부터 적용. 웹(Claude.ai)은 dist/*.zip 업로드와 Project instructions 갱신이 별도."
[[ "${DRY}" = 1 ]] || bash tools/check-install.sh | tail -1
