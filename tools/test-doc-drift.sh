#!/usr/bin/env bash
# 문서 낡음 알림 훅 초안(drafts/hooks/doc-drift-check.sh) 시험(Issue #219). 임시 git 저장소에서 사례별로 경고가 나오고 안 나오는지 확인한다.
# 훅 입력은 JSON을 파이프로 넣는다. 실제 Claude 세션 동작은 승격 때 따로 확인한다.
#   bash tools/test-doc-drift.sh
# shellcheck disable=SC2034  # out·rc는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
HOOK="$(pwd)/drafts/hooks/doc-drift-check.sh"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
export CLAUDE_CONFIG_DIR="${T}/cfg"; mkdir -p "${CLAUDE_CONFIG_DIR}"
if hash python 2>/dev/null; then PY=python; else PY=python3; fi
fail=0; total=0
ok()  { printf '  ok    %s\n' "$1"; total=$((total + 1)); }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; total=$((total + 1)); }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# Windows(Git Bash)에서 파이썬이 읽을 수 있는 경로로 바꾼다
winpath() { if hash cygpath 2>/dev/null; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
n=0
mk() { # 새 저장소를 만들고 R에 경로를 둔다
  n=$((n + 1)); R="${T}/r${n}"; mkdir -p "${R}"
  git -C "${R}" init -q
  git -C "${R}" config user.email t@t; git -C "${R}" config user.name t; git -C "${R}" config core.autocrlf false
}
put() { mkdir -p "$(dirname "${R}/$1")"; printf '%s\n' "$2" > "${R}/$1"; }
base() { git -C "${R}" add -A; git -C "${R}" commit -q -m base; }
run() { # $1=명령(큰따옴표 없음) $2=cwd(기본 R)
  printf '{"tool_input":{"command":"%s"},"cwd":"%s"}' "$1" "$(winpath "${2:-${R}}")" | bash "${HOOK}"
}
isjson() { printf '%s' "$1" | "${PY}" -c 'import json,sys; d=json.load(sys.stdin); assert d["hookSpecificOutput"]["additionalContext"] and d["systemMessage"]'; }

echo "== 1. 사라진 경로가 문서에 남음"
mk; put drafts/skills/foo/SKILL.md x; put README.md '안내 `drafts/skills/foo` 참고'; put docs/a.md '[스킬](../drafts/skills/foo/SKILL.md)'; base
mkdir -p "${R}/base/skills"; git -C "${R}" mv drafts/skills/foo base/skills/foo
out="$(run 'git commit -m x')"; rc=$?
chk "폴더 이동: 백틱 참조 README.md:1 경고"        'grep -q "README.md:1 → drafts/skills/foo" <<<"${out}"'
chk "폴더 이동: 상대 링크 docs/a.md:1 경고"        'grep -q "docs/a.md:1" <<<"${out}"'
chk "경고 JSON이 올바르고 종료 코드 0"              'isjson "${out}" && [[ "${rc}" = 0 ]]'
mk; put tools/old.sh x; put docs/b.md '먼저 `tools/old.sh`를 실행'; base
git -C "${R}" rm -q tools/old.sh
out="$(run 'git commit -m x')"
chk "파일 삭제: docs/b.md:1 경고"                  'grep -q "docs/b.md:1 → tools/old.sh" <<<"${out}"'
mk; put tools/old3.sh x; put docs/c.md '[삭제됨](../tools/old3.sh)'; base
git -C "${R}" rm -q tools/old3.sh
out="$(run 'git commit -m x')"
chk "파일 삭제: 하위 폴더 문서의 상대 링크 경고"      'grep -q "docs/c.md:1" <<<"${out}"'

echo "== 2. 경고가 나오면 안 되는 사례"
mk; put tools/x.sh x; base; git -C "${R}" mv tools/x.sh tools/y.sh
out="$(run 'git commit -m x')"
chk "참조하는 문서가 없으면 조용함"                 '[[ -z "${out}" ]]'
mk; put tools/old2.sh x; put CHANGELOG.md '- 옛 `tools/old2.sh`를 추가'; base; git -C "${R}" rm -q tools/old2.sh
out="$(run 'git commit -m x')"
chk "CHANGELOG에 남은 옛 경로는 조용함"            '[[ -z "${out}" ]]'
mk; put docs/a/x.md x; put docs/ab/x.md x; put docs/a.md x; put README.md '`docs/ab/x.md` `docs/a.md`'; base; git -C "${R}" rm -rq docs/a
out="$(run 'git commit -m x')"
chk "이름이 비슷한 다른 경로는 조용함(경계 검사)"     '[[ -z "${out}" ]]'
mk; put old-note.md x; put README.md '참고 old-note.md'; base; git -C "${R}" rm -q old-note.md
out="$(run 'git commit -m x')"
chk "슬래시 없는 단순 이름은 보지 않음"             '[[ -z "${out}" ]]'
mk; put tools/keep.sh x; put README.md '`tools/keep.sh`'; base; git -C "${R}" rm -q --cached tools/keep.sh
out="$(run 'git commit -m x')"
chk "git rm --cached처럼 파일이 남아 있으면 조용함"   '[[ -z "${out}" ]]'

echo "== 3. 이번에 올리는 .md의 링크"
mk; put README.md x; base
put docs/d.md '[없음](missing.md) [있음](../README.md) [외부](https://e.com/x.md) [앵커](#sec) [메일](mailto:a@b.c) `[코드](nocode.md)`'
put docs/e.md '```'; printf '%s\n' '[펜스](nope.md)' '```' >> "${R}/docs/e.md"
git -C "${R}" add -A
out="$(run 'git commit -m x')"
chk "없는 상대 링크 docs/d.md:1 → missing.md 경고"    'grep -q "docs/d.md:1 → missing.md" <<<"${out}"'
chk "있는 링크·외부·앵커·메일은 경고하지 않음"          '! grep -Eq "README.md|e.com|#sec|mailto" <<<"${out}"'
chk "코드 조각·코드 블록 안 링크는 보지 않음"           '! grep -Eq "nocode|nope" <<<"${out}"'

echo "== 4. CHANGELOG 릴리즈 섹션의 다음 컷"
mk; put CHANGELOG.md "$(printf '## [Unreleased]\n- 다음 컷에 넣을 것\n## [1.0.0] - 2026-01-01\n- 다음 컷 후보')"; git -C "${R}" add -A
out="$(run 'git commit -m x')"
chk "릴리즈된 섹션 CHANGELOG.md:4 경고"            'grep -q "CHANGELOG.md:4" <<<"${out}"'
chk "[Unreleased] 아래 2행은 경고하지 않음"         '! grep -q "CHANGELOG.md:2" <<<"${out}"'

echo "== 5. 커밋 명령 판별"
mk; put tools/old5.sh x; put docs/f.md '`tools/old5.sh`'; base; rm "${R}/tools/old5.sh"
out="$(run 'git commit -m x')"
chk "스테이징 없이 commit만: 조용함"               '[[ -z "${out}" ]]'
out="$(run 'git commit -m \"fix a thing\"')"
chk "메시지 속 단어 a는 -a 옵션으로 보지 않음"       '[[ -z "${out}" ]]'
out="$(run 'git add -A && git commit -m x')"
chk "git add -A && git commit: 작업 트리 삭제도 경고" 'grep -q "docs/f.md:1" <<<"${out}"'
git -C "${R}" checkout -q -- tools/old5.sh; rm "${R}/tools/old5.sh"
out="$(run 'git commit -am x')"
chk "commit -am: 수정된 추적 파일 삭제도 경고"        'grep -q "docs/f.md:1" <<<"${out}"'
out="$(run 'git status')"
chk "commit이 아닌 명령: 조용함"                   '[[ -z "${out}" ]]'
out="$(printf '{"tool_input":{"command":"echo \\"git commit\\""},"cwd":"%s"}' "$(winpath "${R}")" | bash "${HOOK}")"
chk "따옴표 안의 git commit 글자는 무시"             '[[ -z "${out}" ]]'
mk; put tools/old6.sh x; put docs/g.md '`tools/old6.sh`'; base; git -C "${R}" rm -q tools/old6.sh
out="$(run "git -C $(winpath "${R}") commit -m x" "${T}")"
chk "git -C <경로> commit: 다른 폴더에서도 그 저장소 검사" 'grep -q "docs/g.md:1" <<<"${out}"'
mkdir -p "${T}/plain"
out="$(run 'git commit -m x' "${T}/plain")"
chk "git 저장소가 아닌 폴더: 조용함"               '[[ -z "${out}" ]]'

echo "== 6. 오류는 조용히 통과"
out="$(printf 'git commit not json' | bash "${HOOK}")"; rc=$?
chk "깨진 입력: 출력 없음, 종료 코드 0"             '[[ -z "${out}" && "${rc}" = 0 ]]'
chk "오류는 hook-errors.log에만 남김"              'grep -q doc-drift-check "${CLAUDE_CONFIG_DIR}/hook-errors.log"'

echo
if [[ "${fail}" = 0 ]]; then echo "통과 ${total}건"; else echo "실패 있음 (확인 ${total}건)"; exit 1; fi
