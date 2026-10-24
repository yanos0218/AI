#!/usr/bin/env bash
# 설치본(~/.claude)이 기본 영역(base/)과 어긋났는지, 그리고 프로젝트마다 쌓인 로컬 설정이
# 무엇인지 보여준다. 월 점검(C-21) 때와 "설정이 이상하다" 싶을 때 실행한다. 아무것도 고치지 않는다.
#   bash tools/check-install.sh [--summary] [프로젝트 루트=이 저장소의 상위 폴더]
# --summary: 각 섹션 상세를 다 보여주지 않고 마지막 판정 줄만 출력(릴리즈 컷 등에서 사용,
# Issue #123 — grep으로 걸러도 "설정 변경 이력" 섹션이 새서 컨텍스트를 불필요하게 채웠음)
set -u
cd "$(dirname "${0}")/.." || exit 1

QUIET=0
if [[ "${1:-}" == "--summary" ]]; then QUIET=1; shift; fi

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
# 기본값은 이 저장소를 담은 상위 폴더(Windows C:\Git, Mac /Library/Git). 예전 /c/Git 고정은 Mac·Linux에서 조용히 "(없음)"이었다(Issue #157)
PROJECTS_ROOT="${1:-$(cd .. && pwd)}"
PY="$(command -v python3 || command -v python)"
drift=0

section() { printf '\n== %s\n' "${1}"; }
same_or_diff() { # $1=base 파일, $2=설치본
  if [[ ! -e "${2}" ]]; then echo "  MISSING  ${2}"; drift=1
  elif diff -q "${1}" "${2}" >/dev/null; then echo "  same     ${2}"
  else echo "  DIFF     ${2}  (diff ${1} ${2})"; drift=1; fi
}

run_checks() {
  section "기본 영역 ↔ 설치본"
  same_or_diff base/claude-md/CLAUDE.md "${CLAUDE_HOME}/CLAUDE.md"
  for f in base/hooks/*.sh base/hooks/*.py; do same_or_diff "${f}" "${CLAUDE_HOME}/hooks/$(basename "${f}")"; done
  for f in base/agents/*.md; do same_or_diff "${f}" "${CLAUDE_HOME}/agents/$(basename "${f}")"; done
  for d in base/skills/*/; do
    n="$(basename "${d}")"; [[ "${n}" == _* ]] && continue
    # 파이썬 캐시(__pycache__)는 비교하지 않는다. 시험하다 생긴 캐시로 거짓 DIFF가 났다(Issue #160)
    if [[ ! -d "${CLAUDE_HOME}/skills/${n}" ]]; then echo "  MISSING  ${CLAUDE_HOME}/skills/${n}"; drift=1
    elif diff -rq -x __pycache__ "${d}" "${CLAUDE_HOME}/skills/${n}" >/dev/null; then echo "  same     ${CLAUDE_HOME}/skills/${n}"
    else echo "  DIFF     ${CLAUDE_HOME}/skills/${n}"; drift=1; fi
  done

  section "settings.json ↔ base/settings.example.json (설치하면 바뀔 항목이 없는가. 사용자 추가 항목은 어긋남이 아님, tools/settings_merge.py)"
  "${PY}" tools/settings_merge.py check "${CLAUDE_HOME}/settings.json" base/settings.example.json || drift=1

  section "사용자 모듈 규칙 ${CLAUDE_HOME}/rules/ (base/rules/에 없는 것은 승격 후보)"
  if [[ -d "${CLAUDE_HOME}/rules" ]] && ls "${CLAUDE_HOME}/rules"/*.md >/dev/null 2>&1; then
    for f in "${CLAUDE_HOME}/rules"/*.md; do
      n="$(basename "${f}")"
      if [[ -e "base/rules/${n}" ]]; then same_or_diff "base/rules/${n}" "${f}"; else echo "  NEW      ${f}"; fi
    done
  else echo "  (없음)"; fi

  section "VS Code 확장 ↔ base/vscode/extensions.txt (목록은 최소 보장. 밖에 더 있는 것은 정상)"
  CODE="$(command -v code || true)"
  [[ -z "${CODE}" ]] && [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]] && CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  # WSL에서 /mnt 아래 code는 Windows VS Code라 WSL 쪽 확장 목록(비어 있음)을 읽어 전부 MISSING이 된다(Issue #201). 마운트 위치를 바꿨으면 WIN_MOUNT_ROOT로 지정
  win_code=0
  if [[ -n "${CODE}" ]] && [[ "${CODE}" == "${WIN_MOUNT_ROOT:-/mnt/}"* ]] \
    && { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; }; then win_code=1; fi
  if [[ -z "${CODE}" ]]; then echo "  (code 명령 없음 — VS Code에서 'Shell Command: Install code command')"
  else
    installed="$("${CODE}" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    missing=0; total=0
    while read -r ext; do
      ext="${ext%%#*}"; ext="$(echo "${ext}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"; [[ -z "${ext}" ]] && continue
      total=$((total+1))
      if ! grep -qx "${ext}" <<<"${installed}"; then echo "  MISSING  ${ext}"; missing=$((missing+1)); fi
    done < base/vscode/extensions.txt
    extra=$(( $(grep -c . <<<"${installed}") - total + missing ))
    if [[ "${missing}" = 0 ]]; then echo "  same     기본 목록 ${total}개 전부 설치됨 (목록 밖 ${extra}개는 그대로 둔다)"
    elif [[ "${win_code}" = 1 ]]; then echo "  (WSL — 위 code는 Windows VS Code라 빠진 ${missing}개를 판정에 넣지 않음. Windows VS Code는 Windows에서 base/vscode/install.ps1, WSL 안 VS Code(Remote - WSL)는 WSL 쪽 code가 PATH에 먼저 오게 한 뒤 bash base/vscode/install.sh)"
    else drift=1; echo "  → 빠진 ${missing}개는 bash base/vscode/install.sh 로 채운다"; fi
  fi

  section "프로젝트별 로컬 설정 — '항상 허용' 클릭이 쌓이는 곳. 여러 저장소에 반복되면 base/settings.example.json 승격 후보"
  found=0
  [[ -d "${PROJECTS_ROOT}" ]] || echo "  프로젝트 루트 ${PROJECTS_ROOT} 가 없음 — 인자로 지정(bash tools/check-install.sh <루트>)"
  for f in "${PROJECTS_ROOT}"/*/.claude/settings.local.json; do
    [[ -e "${f}" ]] || continue; found=1
    echo "  ${f}"
    "${PY}" - "${f}" <<'PY'
import json, sys, io
d = json.load(io.open(sys.argv[1], encoding='utf-8'))
for k, v in (d.get('permissions') or {}).items():
    for r in v: print(f'    {k}: {r}')
PY
  done
  [[ "${found}" = 1 ]] || echo "  (없음, ${PROJECTS_ROOT}/*/.claude/settings.local.json 기준)"

  section "설정 변경 이력 ${CLAUDE_HOME}/config-changelog.md (config-changelog 훅이 쓰는 파일)"
  if [[ -f "${CLAUDE_HOME}/config-changelog.md" ]]; then tail -n 20 "${CLAUDE_HOME}/config-changelog.md" | sed 's/^/  /'; else echo "  (아직 없음 — 훅 미설치)"; fi
}

if [[ "${QUIET}" = 1 ]]; then run_checks >/dev/null; else run_checks; fi

# PROGRESS §0 표면별 설치 버전 행에 이 기기 설치 버전(git describe, 설치 버전 파일 2행)이 적혔는지(Issue #180).
# 설치 어긋남과는 별개라 판정(drift)에 넣지 않고, --summary에서도 보이게 판정 줄 바로 위에 한 줄로 낸다
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) surface="Windows";; Darwin) surface="Mac mini";; Linux) surface="Linux";; *) surface="";; esac
installed_ver="$(sed -n 2p "${CLAUDE_HOME}/.claude-config-version" 2>/dev/null)"
row="$(grep -m1 "^| ${surface}" docs/PROGRESS.md 2>/dev/null)"
if [[ -z "${surface}" || -z "${installed_ver}" || -z "${row}" ]]; then echo "기록: PROGRESS §0 설치 버전 확인 못함(표면 ${surface:-?}, 설치 버전 ${installed_ver:-없음})"
elif [[ "${row}" == *"${installed_ver}"* ]]; then echo "기록: PROGRESS §0 ${surface} 행에 설치 버전 ${installed_ver} 있음"
else echo "기록: PROGRESS §0 ${surface} 행에 설치 버전 ${installed_ver} 없음 — claude-config 세션에서 그 행을 갱신"; fi

echo
[[ "${drift}" = 0 ]] && echo "결과: 설치본이 기본 영역과 같다." || echo "결과: 어긋난 항목이 있다(DIFF/MISSING). 의도한 변경이면 base/에 반영, 아니면 재설치(docs/install.md)."
exit "${drift}"
