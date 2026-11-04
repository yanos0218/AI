#!/usr/bin/env bash
# 도구·스킬 스크립트의 파이썬 선택 시험(Issue #255). Windows의 python3는 실행하면 "Python"만 찍고 종료 코드 49로 끝나는
# Microsoft Store 별칭일 수 있어, 이름만 보고 고르면 도구가 실패한다.
#   bash tools/test-python-pick.sh
# 1) 이름만 보고 python3를 고르는 줄이 남아 있지 않은지 정적으로 확인한다.
# 2) 가짜 별칭 python3(종료 코드 49)을 PATH 앞에 두고 도구를 실제로 돌려 진짜 python으로 넘어가는지 확인한다.
set -u
cd "$(dirname "${0}")/.." || exit 1
tmp="$(mktemp -d)"; trap 'rm -rf "${tmp}"' EXIT
pass=0; fail=0
ok() { pass=$((pass + 1)); }
ng() { fail=$((fail + 1)); echo "실패: ${1}"; }

# 1) 정적 확인: 이름 순서만 믿는 선택을 금지한다(이 파일은 패턴을 조각으로 만들어 스스로 걸리지 않게 한다)
bare="command -v python3 |""| command -v python"
hits="$(grep -rIn --exclude=test-python-pick.sh --exclude-dir=.git --exclude-dir=node_modules -F -e "${bare}" tools base drafts .claude 2>/dev/null)"
if [[ -z "${hits}" ]]; then ok; else ng "이름만 보고 python3를 고르는 줄이 남음"; echo "${hits}"; fi

# 2) 동작 확인: 진짜 python을 찾고, 가짜 별칭을 앞에 둔다
real=""
for c in python3 python; do
  p="$(command -v "${c}" 2>/dev/null)" && "${p}" -c 'import sys' >/dev/null 2>&1 && { real="${p}"; break; }
done
if [[ -z "${real}" ]]; then echo "미검증: 실행되는 python이 없음"; exit 0; fi
mkdir -p "${tmp}/alias"
printf '#!/usr/bin/env bash\necho -n Python\nexit 49\n' > "${tmp}/alias/python3"
printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "${real}" > "${tmp}/alias/python"
chmod +x "${tmp}/alias/python3" "${tmp}/alias/python"
[[ "$(PATH="${tmp}/alias:${PATH}" command -v python3)" == "${tmp}/alias/python3" ]] || { echo "미검증: 가짜 별칭이 PATH 앞에 오지 않음"; exit 0; }

printf '## 제목\n\n- 항목\n  - 설명\n' > "${tmp}/clean.md"
out="$(PATH="${tmp}/alias:${PATH}" bash tools/check-cram.sh "${tmp}/clean.md" 2>&1)"; rc=$?
if [[ "${rc}" -eq 0 && "${out}" != *"Python"* ]]; then ok; else ng "check-cram.sh가 가짜 별칭 python3에 걸림(종료 코드 ${rc}) ${out}"; fi

out="$(PATH="${tmp}/alias:${PATH}" bash tools/check-docs.sh 2>&1)"
if [[ "${out}" != *"skip doc-sync"* && "${out}" == *"doc-sync"* ]]; then ok; else ng "check-docs.sh가 doc-sync 검사를 건너뜀(가짜 별칭 python3에 걸림) $(printf '%s' "${out}" | tail -3)"; fi

echo "통과 ${pass} / 실패 ${fail}"
[[ "${fail}" -eq 0 ]]
