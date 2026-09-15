#!/usr/bin/env bash
# 목록 줄바꿈 규칙(base/rules/docs-format.md) 위반 — "라벨: 흐르는 문장" /
# "라벨 — 흐르는 문장" 크램을 기계적으로 찾는다. 정규식 휴리스틱이라 오탐이
# 있을 수 있다 — 진짜 크램이면 고치고, 나열·필드-값 등 예외면
# `--add-exception`으로 예외 목록에 올린다(Issue #99).
#
# 사용법
#   tools/check-cram.sh --staged          # git 스테이징된 .md diff의 추가된 줄만 검사
#   tools/check-cram.sh <file...>         # 파일 전체를 검사(GitHub 댓글/이슈 본문 등
#                                          #   git이 관리하지 않는 텍스트를 커밋 전 확인할 때)
#   tools/check-cram.sh --add-exception <file> <line-number>
#                                          # 그 줄을 예외 목록에 등록(오탐 확정 시)
set -u
cd "$(dirname "${0}")/.." || exit 1

PY="$(command -v python3 || command -v python)"
EXCEPTIONS_FILE=".claude/cram-exceptions.txt"

if [[ "${1:-}" == "--add-exception" ]]; then
  file="${2:?파일 경로 필요}"
  lineno="${3:?줄 번호 필요}"
  line="$(sed -n "${lineno}p" "${file}")"
  trimmed="$(printf '%s' "${line}" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if [[ -z "${trimmed}" ]]; then
    echo "그 줄이 비어있거나 파일/줄 번호가 잘못됨" >&2
    exit 1
  fi
  printf '%s\n' "${trimmed}" >> "${EXCEPTIONS_FILE}"
  echo "예외 등록: ${file}:${lineno}"
  exit 0
fi

# 입력은 "경로<TAB>줄번호<TAB>내용" 한 줄씩. python -로 heredoc을 넘기면 그 heredoc
# 자체가 프로그램 소스로 stdin을 다 써버려 실제 데이터를 못 읽으므로, 별도 .py 파일로 둔다.
detect() {
  PYTHONIOENCODING=utf-8 "${PY}" tools/check-cram.py "${EXCEPTIONS_FILE}"
}

if [[ "${1:-}" == "--staged" ]]; then
  # test-fixtures는 검사 대상이 아니라 검사 스크립트 자체의 시험 데이터라 제외
  files="$(git diff --cached --name-only --diff-filter=ACM -- '*.md' ':!tools/test-fixtures/*' 2>/dev/null || true)"
  if [[ -z "${files}" ]]; then
    exit 0
  fi
  tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' EXIT
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    # 어떤 줄이 새로 추가됐는지(코드펜스 상태는 파일 전체를 봐야 정확하므로,
    # 스테이징된 전체 내용에 "추가됨" 표시만 얹어서 넘긴다)
    added_lines="$(git diff --cached --unified=0 -- "${f}" | awk '
      /^@@/ { match($0, /\+[0-9]+(,[0-9]+)?/); spec=substr($0, RSTART+1, RLENGTH-1); split(spec, a, ","); start=a[1]; count=(a[2]=="" ? 1 : a[2]); for (i=0;i<count;i++) print start+i }
    ')"
    git show ":${f}" 2>/dev/null | awk -v path="${f}" -v added="${added_lines}" '
      BEGIN { n=split(added, arr, "\n"); for (i=1;i<=n;i++) is_added[arr[i]]=1 }
      { line=$0; gsub(/\t/, "    ", line); print path "\t" FNR "\t" (FNR in is_added ? 1 : 0) "\t" line }
    ' >> "${tmp}"
  done <<< "${files}"
  detect < "${tmp}"
  exit $?
fi

if [[ $# -eq 0 ]]; then
  echo "사용법: tools/check-cram.sh --staged | <file...> | --add-exception <file> <line>" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
for f in "$@"; do
  awk -v path="${f}" '{ line=$0; gsub(/\t/, "    ", line); print path "\t" FNR "\t1\t" line }' "${f}" >> "${tmp}"
done
detect < "${tmp}"
exit $?
