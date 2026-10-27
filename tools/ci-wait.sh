#!/usr/bin/env bash
# 푸시한 커밋(HEAD)의 CI 실행을 끝까지 기다리고 통과 여부를 마지막 줄에 한 줄로 알린다(Issue #229).
#   bash tools/ci-wait.sh [저장소경로]
# 종료 코드 0=통과, 1=실패·미통과, 2=실행 0건(미검증)
# 완료 대기는 gh run watch에 맡긴다. 직접 짠 대기 반복문은 끝나지 않은 사례가 있다(전역 §4).
# 푸시 직후엔 실행이 목록에 아직 없을 수 있어 목록 조회만 CI_WAIT_SLEEP(기본 5)초 간격으로 최대 3번 다시 한다.
set -u
repo="${1:-.}"
cd "${repo}" || { echo "저장소 경로를 열 수 없음: ${repo}" >&2; exit 2; }
sha="$(git rev-parse HEAD)" || { echo "git 저장소가 아님: ${repo}" >&2; exit 2; }

# 이슈·댓글 이벤트로 도는 워크플로(이슈 형식 검사 등)도 같은 커밋에 붙으므로 push·pull_request 실행만 센다
ids=""
for attempt in 0 1 2 3; do
  raw="$(gh run list --commit "${sha}" --json databaseId,event --jq '.[] | "\(.databaseId)\t\(.event)"' | tr -d '\r')"
  ids=""
  while IFS=$'\t' read -r rid ev; do
    case "${ev}" in push|pull_request) ids="${ids}${ids:+ }${rid}" ;; esac
  done <<< "${raw}"
  [[ -n "${ids}" ]] && break
  [[ "${attempt}" -lt 3 ]] && sleep "${CI_WAIT_SLEEP:-5}"
done

if [[ -z "${ids}" ]]; then
  echo "CI 미검증 — 커밋 ${sha:0:7}의 실행 0건 (워크플로가 안 돌았거나 아직 생성 전)"
  exit 2
fi

# 실행이 success면 그 안의 skipped job(조건부 job)은 정상이다. 실행 단위 skipped·cancelled는 통과로 세지 않는다
runs=0; bad_runs=0; jobs=0; jobs_ok=0; jobs_skip=0; failed=""; first_bad=""
for id in ${ids}; do
  runs=$((runs + 1))
  # 실패하면 watch가 0이 아닌 값으로 끝난다. 판정은 아래 view의 결과로 하므로 값은 버린다
  gh run watch "${id}" --exit-status > /dev/null 2>&1
  out="$(gh run view "${id}" --json workflowName,conclusion,jobs --jq \
    '"run\t" + .workflowName + "\t" + (.conclusion | tostring), (.jobs[] | "job\t" + (.conclusion | tostring) + "\t" + .name)' | tr -d '\r')"
  if [[ -z "${out}" ]]; then
    echo "[${id}] 결과를 읽지 못함"
    bad_runs=$((bad_runs + 1)); [[ -z "${first_bad}" ]] && first_bad="${id}"
    continue
  fi
  while IFS=$'\t' read -r kind a b; do
    if [[ "${kind}" = "run" ]]; then
      echo "[${a}] ${b}"
      if [[ "${b}" != "success" ]]; then
        bad_runs=$((bad_runs + 1)); [[ -z "${first_bad}" ]] && first_bad="${id}"
      fi
    else
      jobs=$((jobs + 1))
      printf '  %-10s %s\n' "${a}" "${b}"
      case "${a}" in
        success) jobs_ok=$((jobs_ok + 1)) ;;
        skipped) jobs_skip=$((jobs_skip + 1)) ;;
        *) failed="${failed:+${failed}, }${b}" ;;
      esac
    fi
  done <<< "${out}"
done

skip_note=""; [[ "${jobs_skip}" -gt 0 ]] && skip_note=", 건너뜀 ${jobs_skip}개"
if [[ "${bad_runs}" -eq 0 && "${jobs}" -ge 1 && -z "${failed}" ]]; then
  echo "CI 통과 — 실행 ${runs}건, job ${jobs}개${skip_note} (커밋 ${sha:0:7})"
  exit 0
fi
echo "CI 실패 — 실행 ${runs}건 중 ${bad_runs}건 통과 아님, job ${jobs}개 중 성공 ${jobs_ok}개${skip_note}${failed:+, 성공·건너뜀 아님 ${failed}} (커밋 ${sha:0:7})"
echo "로그는 gh run view ${first_bad:-<실행ID>} --log-failed"
exit 1
