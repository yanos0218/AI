#!/usr/bin/env bash
# 설치본(~/.claude)이 기본 영역(base/)과 어긋났는지, 그리고 프로젝트마다 쌓인 로컬 설정이
# 무엇인지 보여준다. 월 점검(C-21) 때와 "설정이 이상하다" 싶을 때 실행한다. 아무것도 고치지 않는다.
#   bash tools/check-install.sh [프로젝트 루트=/c/Git]
set -u
cd "$(dirname "$0")/.." || exit 1
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PROJECTS_ROOT="${1:-/c/Git}"
PY="$(command -v python3 || command -v python)"
drift=0

section() { printf '\n== %s\n' "$1"; }
same_or_diff() { # $1=base 파일, $2=설치본
  if [ ! -e "$2" ]; then echo "  MISSING  $2"; drift=1
  elif diff -q "$1" "$2" >/dev/null; then echo "  same     $2"
  else echo "  DIFF     $2  (diff $1 $2)"; drift=1; fi
}

section "기본 영역 ↔ 설치본"
same_or_diff base/claude-md/CLAUDE.md "$CLAUDE_HOME/CLAUDE.md"
for f in base/hooks/*.sh; do same_or_diff "$f" "$CLAUDE_HOME/hooks/$(basename "$f")"; done
for d in base/skills/*/; do
  n="$(basename "$d")"; [[ "$n" == _* ]] && continue
  if [ ! -d "$CLAUDE_HOME/skills/$n" ]; then echo "  MISSING  $CLAUDE_HOME/skills/$n"; drift=1
  elif diff -rq "$d" "$CLAUDE_HOME/skills/$n" >/dev/null; then echo "  same     $CLAUDE_HOME/skills/$n"
  else echo "  DIFF     $CLAUDE_HOME/skills/$n"; drift=1; fi
done

section "settings.json ↔ base/settings.example.json (permissions·hooks·statusLine 키)"
"$PY" - "$CLAUDE_HOME/settings.json" base/settings.example.json <<'PY' || drift=1
import json, sys, io
a = json.load(io.open(sys.argv[1], encoding='utf-8')); b = json.load(io.open(sys.argv[2], encoding='utf-8'))
rc = 0
for k in ('permissions', 'hooks', 'statusLine'):
    if a.get(k) == b.get(k): print(f'  same     {k}')
    else: print(f'  DIFF     {k}'); rc = 1
extra = sorted(set(a) - set(b))
print(f'  설치본에만 있는 키(기기별, 정상): {extra}')
sys.exit(rc)
PY

section "사용자 모듈 규칙 $CLAUDE_HOME/rules/ (base/rules/에 없는 것은 승격 후보)"
if [ -d "$CLAUDE_HOME/rules" ] && ls "$CLAUDE_HOME/rules"/*.md >/dev/null 2>&1; then
  for f in "$CLAUDE_HOME/rules"/*.md; do
    n="$(basename "$f")"
    if [ -e "base/rules/$n" ]; then same_or_diff "base/rules/$n" "$f"; else echo "  NEW      $f"; fi
  done
else echo "  (없음)"; fi

section "VS Code 확장 ↔ base/vscode/extensions.txt (목록은 최소 보장. 밖에 더 있는 것은 정상)"
CODE="$(command -v code || true)"
[ -z "$CODE" ] && [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ] && CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [ -z "$CODE" ]; then echo "  (code 명령 없음 — VS Code에서 'Shell Command: Install code command')"
else
  installed="$("$CODE" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  missing=0; total=0
  while read -r ext; do
    ext="${ext%%#*}"; ext="$(echo "$ext" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"; [ -z "$ext" ] && continue
    total=$((total+1))
    if ! grep -qx "$ext" <<<"$installed"; then echo "  MISSING  $ext"; missing=$((missing+1)); fi
  done < base/vscode/extensions.txt
  extra=$(( $(grep -c . <<<"$installed") - total + missing ))
  if [ "$missing" = 0 ]; then echo "  same     기본 목록 ${total}개 전부 설치됨 (목록 밖 ${extra}개는 그대로 둔다)"
  else drift=1; echo "  → 빠진 ${missing}개는 bash base/vscode/install.sh 로 채운다"; fi
fi

section "프로젝트별 로컬 설정 — '항상 허용' 클릭이 쌓이는 곳. 여러 저장소에 반복되면 base/settings.example.json 승격 후보"
found=0
for f in "$PROJECTS_ROOT"/*/.claude/settings.local.json; do
  [ -e "$f" ] || continue; found=1
  echo "  $f"
  "$PY" - "$f" <<'PY'
import json, sys, io
d = json.load(io.open(sys.argv[1], encoding='utf-8'))
for k, v in (d.get('permissions') or {}).items():
    for r in v: print(f'    {k}: {r}')
PY
done
[ "$found" = 1 ] || echo "  (없음)"

section "설정 변경 이력 $CLAUDE_HOME/config-changelog.md (config-changelog 훅이 쓰는 파일)"
if [ -f "$CLAUDE_HOME/config-changelog.md" ]; then tail -n 20 "$CLAUDE_HOME/config-changelog.md" | sed 's/^/  /'; else echo "  (아직 없음 — 훅 미설치)"; fi

echo
[ "$drift" = 0 ] && echo "결과: 설치본이 기본 영역과 같다." || echo "결과: 어긋난 항목이 있다(DIFF/MISSING). 의도한 변경이면 base/에 반영, 아니면 재설치(docs/install.md)."
exit "$drift"
