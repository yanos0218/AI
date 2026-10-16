#!/usr/bin/env bash
# 모델별 구독 한도 소모 즉시 측정(Issue #178) — 같은 읽기 전용 작업을 모델마다 claude -p로 반복하고,
# 실행 뒤마다 짧은 Haiku 질문(probe)으로 5시간·주간 한도 사용률을 읽어 실행 1회가 쓴 몫과 결과 품질을 비교한다.
#   bash tools/measure-model.sh [--models "claude-opus-5-5 claude-sonnet-5-5"] [--target 3] [--max-runs 6] [--turns 25]
#   사용률은 stream-json의 rate_limit_event.unifiedWindows(문서화 안 됨, anthropics/claude-code#91857)에서 읽는다.
#   모델은 전체 ID로 넘긴다 — 별칭(sonnet 등)이 가리키는 버전은 CLI 버전마다 다르다(2026-10-16, v2.1.283은 sonnet=Sonnet 5).
#   측정 중에는 claude.ai 채팅·다른 세션을 쓰지 않는다(한도는 계정 전체 기준이라 섞인다).
set -u
cd "$(dirname "${0}")/.." || exit 1
MODELS="claude-opus-5-5 claude-sonnet-5-5"; TARGET=3; MAXRUNS=6; TURNS=25
while [[ $# -gt 0 ]]; do case "${1}" in
  --models) MODELS="${2}"; shift 2;; --target) TARGET="${2}"; shift 2;; --max-runs) MAXRUNS="${2}"; shift 2;;
  --turns) TURNS="${2}"; shift 2;; *) echo "모르는 옵션 ${1}"; exit 2;; esac; done
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || echo "${HOME}/.local/bin/claude.exe")}"
PY="$(command -v python3 || command -v python)"
FIX="$(pwd)/tools/test-fixtures/model-compare"
OUT="${MEASURE_OUT:-$(mktemp -d)}"; mkdir -p "${OUT}"
PROMPT='rules.md의 규칙을 docs/ 아래 모든 문서에 적용해 위반을 빠짐없이 찾아라. 각 위반을 "파일명:줄번호:규칙번호" 형식으로 한 줄씩만 출력하고(예: doc01.md:5:2), 다른 말은 쓰지 마라. 위반이 없으면 아무것도 출력하지 마라.'

# 새 세션 하나를 띄워 stream-json을 파일로 남긴다. 신뢰 전 폴더에서 돌도록 매번 빈 작업 폴더를 쓴다.
run_session() { # $1=작업 폴더 $2=모델 $3=프롬프트 $4=출력 파일 $5=턴 수
  (cd "${1}" && unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT && "${CLAUDE_BIN}" -p "${3}" --model "${2}" \
    --output-format stream-json --verbose --max-turns "${5}" --allowedTools Read Glob Grep) > "${4}" 2>"${4}.err" < /dev/null
}

probe() { # $1=이름 — 사용률을 읽어 OUT/probe-<이름>.jsonl로 남긴다
  local d="${OUT}/probe-dir"; mkdir -p "${d}"
  run_session "${d}" haiku "1+1은? 숫자만" "${OUT}/probe-${1}.jsonl" 1
}

echo "== $("${CLAUDE_BIN}" --version 2>/dev/null) · 모델 ${MODELS} · 목표 ${TARGET}%p · 최대 ${MAXRUNS}회 · 결과 ${OUT}"
seq=0
probe "${seq}"
for model in ${MODELS}; do
  runs=0
  while (( runs < MAXRUNS )); do
    runs=$(( runs + 1 )); seq=$(( seq + 1 ))
    work="${OUT}/work-${seq}"; rm -rf "${work}"; cp -r "${FIX}" "${work}"; rm -f "${work}/answers.json"
    echo "-- ${seq}: ${model} ${runs}회차"
    run_session "${work}" "${model}" "${PROMPT}" "${OUT}/run-${seq}.jsonl" "${TURNS}"
    echo "${seq} ${model}" >> "${OUT}/runs.txt"
    probe "${seq}"
    # 한 모델 몫이 목표 이상이면 다음 모델로, 주간 95% 넘거나 5시간 창이 초기화되면 중단
    verdict="$(PYTHONIOENCODING=utf-8 "${PY}" "$(pwd)/tools/measure-model.py" check "${OUT}" "${model}" "${TARGET}")"
    echo "   ${verdict}"
    case "${verdict}" in stop*) break 2;; next*) break;; esac
  done
done
PYTHONIOENCODING=utf-8 "${PY}" "$(pwd)/tools/measure-model.py" report "${OUT}" "${FIX}/answers.json"
