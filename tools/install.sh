#!/usr/bin/env bash
# base/ → ~/.claude 설치 (Windows Git Bash · Mac · Linux 공통, 멱등).
#   bash tools/install.sh            설치 후 check-install.sh로 대조
#   bash tools/install.sh --dry-run  무엇이 바뀔지만 보여주고 손대지 않음
# 하는 일: CLAUDE.md·hooks·skills·agents 복사, settings.json에 base 값을 병합(규칙은 tools/settings_merge.py, 그 밖의 기기별 키는 유지).
# 하지 않는 일: 사용자 값을 백업 없이 지우지 않는다(Issue #194).
#   CLAUDE.md·settings.json은 다르면 .bak.<시각>으로 백업, 내용이 다른 스킬은 ~/.claude/backups/claude-config/<시각>/에 보관한 뒤 교체.
#   settings.json의 permissions 목록은 합집합, 사용자가 직접 넣은 훅은 남긴다.
#   이 도구가 만든 백업(.bak.<14자리>, backups/claude-config/<14자리>)은 종류별 최근 3개만 남기고 자동 정리(직접 만든 이름은 그대로, Issue #196).
set -u
cd "$(dirname "${0}")/.." || exit 1
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
PY="$(command -v python3 || command -v python)"
DRY=0; [[ "${1:-}" = "--dry-run" ]] && DRY=1
say() { printf '%s\n' "$*"; }
run() { if [[ "${DRY}" = 1 ]]; then say "  (dry) $*"; else "$@"; fi; }

TS="$(date +%Y%m%d%H%M%S)"
BASE_VER="$(git describe --tags --always 2>/dev/null)"
BASE_TREE="$(git rev-parse HEAD:base 2>/dev/null)"   # base/ 내용 지문. 문서만 바뀐 커밋과 구별하는 데 씀(Issue #150)
SRC_ABS="$(pwd)"
say "== 대상: ${CLAUDE_HOME}  (base 버전: ${BASE_VER})"
run mkdir -p "${CLAUDE_HOME}/hooks" "${CLAUDE_HOME}/skills" "${CLAUDE_HOME}/agents"

# 1. CLAUDE.md — 다르면 백업 후 교체
src=base/claude-md/CLAUDE.md; dst="${CLAUDE_HOME}/CLAUDE.md"
if [[ -f "${dst}" ]] && ! diff -q "${src}" "${dst}" >/dev/null; then
  bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
  say "  CLAUDE.md 다름 → 기존 파일을 ${bak} 로 백업하고 교체 (diff: diff ${bak} ${dst})"
  run cp "${dst}" "${bak}"
fi
run cp "${src}" "${dst}"; say "  CLAUDE.md 설치"

# 2. hooks
# 셸 입구(*.sh)와 파이썬 본체·공통 모듈(*.py, Issue #144)을 같은 폴더에 둔다
for f in base/hooks/*.sh base/hooks/*.py; do run cp "${f}" "${CLAUDE_HOME}/hooks/"; done
run chmod +x "${CLAUDE_HOME}"/hooks/*.sh 2>/dev/null
say "  hooks 설치: $(cd base/hooks && echo *.sh *.py)"

# 3. skills (_로 시작하는 틀은 제외, 기존 폴더는 교체. 내용이 다르면 교체 전에 backups/로 보관 — 스킬 폴더 안에 두면 스킬로 읽힐 수 있다)
for d in base/skills/*/; do
  n="$(basename "${d}")"; [[ "${n}" == _* ]] && continue
  if [[ -d "${CLAUDE_HOME}/skills/${n}" ]] && ! diff -rq -x __pycache__ "${d}" "${CLAUDE_HOME}/skills/${n}" >/dev/null; then
    bdir="${CLAUDE_HOME}/backups/claude-config/${TS}"
    say "  skill ${n} 다름 → 기존 폴더를 ${bdir}/${n} 로 보관하고 교체"
    run mkdir -p "${bdir}"; run cp -r "${CLAUDE_HOME}/skills/${n}" "${bdir}/${n}"
  fi
  run rm -rf "${CLAUDE_HOME}/skills/${n}"; run cp -r "${d}" "${CLAUDE_HOME}/skills/${n}"; say "  skill 설치: ${n}"
  # 원본에서 시험하다 생긴 파이썬 캐시는 설치본에 남기지 않는다(Issue #160)
  run find "${CLAUDE_HOME}/skills/${n}" -type d -name __pycache__ -prune -exec rm -rf {} +
done

# 3a. agents (서브에이전트 정의) — base/agents/*.md → ~/.claude/agents/. 폴더를 처음 만든 뒤에는 새 세션부터 인식됨
for f in base/agents/*.md; do run cp "${f}" "${CLAUDE_HOME}/agents/"; done
say "  agents 설치: $(ls base/agents | tr '
' ' ')"

# 3b. rules (모듈 규칙) — base/rules/*.md → ~/.claude/rules/
if ls base/rules/*.md >/dev/null 2>&1; then
  run mkdir -p "${CLAUDE_HOME}/rules"
  for f in base/rules/*.md; do run cp "${f}" "${CLAUDE_HOME}/rules/"; done
  say "  rules 설치: $(ls base/rules | tr '\n' ' ')"
fi

# 3c. claude-md-details (CLAUDE.md가 경로로 가리키는 세부 규칙, 필요할 때만 읽힘) — base/claude-md-details/*.md → ~/.claude/claude-md-details/
if ls base/claude-md-details/*.md >/dev/null 2>&1; then
  run mkdir -p "${CLAUDE_HOME}/claude-md-details"
  for f in base/claude-md-details/*.md; do run cp "${f}" "${CLAUDE_HOME}/claude-md-details/"; done
  say "  claude-md-details 설치: $(ls base/claude-md-details | tr '\n' ' ')"
fi

# 4. settings.json 병합 — 규칙은 tools/settings_merge.py(permissions 목록 합집합, base 훅만 교체, 변경 시 .bak 백업)
SETTINGS_OK=1
if [[ "${DRY}" = 1 ]]; then "${PY}" tools/settings_merge.py install "${CLAUDE_HOME}/settings.json" base/settings.example.json --dry-run || SETTINGS_OK=0
else "${PY}" tools/settings_merge.py install "${CLAUDE_HOME}/settings.json" base/settings.example.json || SETTINGS_OK=0; fi

# 4a. 이 도구가 만든 백업 정리 — 종류별로 최근 KEEP개만 남긴다(Issue #196, 사용자 결정 2026-10-21: 수동 정리는 잊으므로 자동, 3개).
#     이름이 .bak.<숫자 14자리>인 것만 대상이라 직접 만든 백업(예: settings.json.bak.pre-blockreads)은 건드리지 않는다.
#     settings.json 병합이 실패했으면 복구에 쓸 수 있으므로 정리하지 않는다.
KEEP=3
D14='[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
prune_old() { # $1=find 대상 폴더 $2=이름 패턴 $3=종류(f|d)
  [[ -d "$1" ]] || return 0
  local old
  old="$(find "$1" -maxdepth 1 -type "$3" -name "$2" 2>/dev/null | sort | awk -v n="${KEEP}" '{a[NR]=$0} END{for(i=1;i<=NR-n;i++)print a[i]}')"
  [[ -n "${old}" ]] || return 0
  while IFS= read -r f; do
    say "  오래된 백업 정리: ${f}"
    if [[ "$3" = d ]]; then run rm -rf "${f}"; else run rm -f "${f}"; fi
  done <<< "${old}"
}
if [[ "${SETTINGS_OK}" = 1 ]]; then
  prune_old "${CLAUDE_HOME}" "CLAUDE.md.bak.${D14}" f
  prune_old "${CLAUDE_HOME}" "settings.json.bak.${D14}" f
  prune_old "${CLAUDE_HOME}/backups/claude-config" "${D14}" d
fi

# 5. 버전 표시 파일 — SessionStart 훅(session-start-check.sh)이 최신 여부를 조용히 확인하는 데 씀
#    1행 원본 경로, 2행 버전(표시용), 3행 base/ 트리 해시(비교용)
if [[ "${DRY}" = 1 ]]; then say "  (dry) 버전 표시 파일 기록: ${SRC_ABS} / ${BASE_VER}"; else
  printf '%s\n%s\n%s\n' "${SRC_ABS}" "${BASE_VER}" "${BASE_TREE}" > "${CLAUDE_HOME}/.claude-config-version"
  say "  버전 표시 기록: ${BASE_VER}"
fi

if [[ "${SETTINGS_OK}" = 1 ]]; then say "== 설치 끝. 스킬·훅은 새 세션부터 적용. 웹(Claude.ai)은 dist/*.zip 업로드와 Project instructions 갱신이 별도."
else say "== 설치 끝, 단 settings.json 병합은 실패했음(위 메시지 확인). 나머지 파일만 설치됨."; fi
# 설치 직후엔 PROGRESS를 아직 못 고쳤으므로 비교하지 않고 적을 값만 알린다. 대조는 check-install.sh가 한다(Issue #180)
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) surface="Windows";; Darwin) surface="Mac mini";; Linux) surface="Linux";; *) surface="?";; esac
say "== 기록: docs/PROGRESS.md §0 표면별 설치 버전 '${surface}' 행 → ${BASE_VER} / $(date +%Y-%m-%d) (claude-config 세션에서 갱신)"
[[ "${DRY}" = 1 ]] || bash tools/check-install.sh | tail -1
[[ "${SETTINGS_OK}" = 1 ]] || exit 1
