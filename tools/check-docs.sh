#!/usr/bin/env bash
# 문서 상한·필수 파일 검사. CI(lint.yml)와 로컬에서 같은 스크립트를 쓴다.
# 상한을 넘으면 "줄여라"가 아니라 "docs/로 분리하거나 항목을 파일로 빼라"는 신호다(CLAUDE.md "문서 규칙").
set -u
cd "$(dirname "${0}")/.." || exit 1
fail=0
checked=0   # 줄 수를 실제로 센 파일 수. 0이면 아무것도 검사하지 못한 것이라 통과로 치지 않는다(2026-09-29 0줄 오독 사례)

limit() { # 파일 상한
  local f="${1}" max="${2}"
  checked=$((checked + 1))
  [[ -f "${f}" ]] || { echo "MISSING ${f}"; fail=1; return; }
  # 줄 수는 bash 내장 read로 센다. 파일마다 wc를 띄우면 Windows 느린 시각에 24초가 걸려 커밋 검사 훅이 제한 시간을 넘겼다(Issue #148)
  # mapfile은 Mac 기본 bash 3.2에 없어 모든 파일을 0줄로 세고 통과시켰다(2026-09-28)
  local n=0 _l; while IFS= read -r _l || [[ -n "${_l}" ]]; do n=$((n + 1)); done < "${f}"
  if [[ "${n}" -gt "${max}" ]]; then echo "TOO LONG ${f}: ${n} > ${max}"; fail=1; else echo "ok  ${f} (${n}/${max})"; fi
}

limit README.md 120
limit CLAUDE.md 60
limit base/claude-md/CLAUDE.md 200
limit docs/HANDOFF.md 40
limit docs/PROGRESS.md 300
limit CHANGELOG.md 400
for s in base/skills/*/SKILL.md drafts/skills/*/SKILL.md; do [[ -f "${s}" ]] && limit "${s}" 80; done

# README 구조 목록에 적힌 경로가 실제로 있는지
while read -r p; do
  [[ -e "${p}" ]] || { echo "README lists missing path: ${p}"; fail=1; }
done < <(grep -oE '^(claude-md|skills|scripts|vscode|drafts|docs|\.claude|\.github)/[^ ]*|^(CHANGELOG|CLAUDE)\.md' README.md | sort -u)

# 문서 갱신 누락 검사(Issue #192): 존재·참조·개수 대조. 파이썬 한 번 호출이라 느린 시각에도 가볍다(Issue #148)
# python3·python 중 실제로 실행되는 것을 고른다(Windows 스토어 별칭 python3는 이름만 있고 실행하면 실패, Issue #255)
PY=""; for c in python3 python; do p="$(command -v "${c}" 2>/dev/null)" && "${p}" -c 'import sys' >/dev/null 2>&1 && { PY="${p}"; break; }; done
if [[ -n "${PY}" ]]; then "${PY}" tools/check-doc-sync.py || fail=1; else echo "skip doc-sync: python 없음"; fi

# 문서 형식 검사(Issue #274): 목록 줄바꿈·번호 인접·음슴체. 저장 훅(md-format-check)은 Edit·Write만 보므로 Bash로 쓴 수정과 기존 위반을 여기서 잡는다(Issue #261)
# 훅과 같은 판정 코드를 쓴다. 음슴체 규칙이 적용되는 문서만 보고, 지침 문서(skills·rules)와 시험 파일(test-fixtures)은 범위 밖이다. 대상 목록은 이 스크립트가 유일한 정의다(lint.yml은 이 스크립트를 부름)
fmt_files=()
while IFS= read -r f; do [[ -n "${f}" ]] && fmt_files+=("${f}"); done < <(git ls-files 'docs/*.md' README.md CHANGELOG.md 'drafts/*.md')
echo "형식 검사 대상 .md ${#fmt_files[@]}개"
if [[ "${#fmt_files[@]}" -eq 0 ]]; then
  echo "형식 검사 대상 0개: 통과가 아니라 미검증"; fail=1
elif [[ -n "${PY}" ]]; then
  PYTHONPATH=base/hooks "${PY}" base/hooks/format_check.py scan md "${fmt_files[@]}" || fail=1
else
  echo "형식 검사 불가: python 없음"; fail=1
fi

echo "검사한 줄 수 상한 파일: ${checked}개"
[[ "${checked}" -gt 0 ]] || { echo "검사 대상 0개: 통과가 아니라 미검증"; fail=1; }

exit "${fail}"
