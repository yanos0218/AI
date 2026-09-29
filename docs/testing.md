# 검증 — 무엇을 바꾸면 무엇을 돌리나

이 저장소에서 바꾼 것을 확인하는 명령과 규칙. 저장소 [CLAUDE.md](../CLAUDE.md) "검증" 절에서 분리함(2026-09-29, [Issue #166](https://github.com/yanos0218/AI/issues/166)).

## 바꾼 것별 검사

| 바꾼 것 | 돌릴 것 | 비고 |
| --- | --- | --- |
| `.md` 문서 | `npx markdownlint-cli2 "**/*.md"`<br>`bash tools/check-docs.sh` | CI와 같이 모든 `.md`, 제외 폴더는 `.markdownlint-cli2.jsonc`. 줄 길이(MD013)는 무시<br>검사한 수는 `Linting: N files`, 마지막 줄 `0 issues in 0 files`는 "문제 있는 파일 0개"라는 뜻<br>줄 수 상한은 [CLAUDE.md](../CLAUDE.md) "문서 규칙" |
| 셸 스크립트 | `npx shellcheck -S warning <파일>` | CI 대상은 [.github/workflows/lint.yml](../.github/workflows/lint.yml)(2026-09-29 기준 27개)<br>모든 스크립트를 `${var}`·`[[ ]]` 스타일로 씀<br>`--enable=all`이 더 잡는 것은 전부 스타일이라 쓰지 않음(2026-09-13 확인) |
| 파이썬 | `python3 -m py_compile <파일>` | 훅은 Rocky Linux 3.9에서도 돌도록 3.8 문법만 |
| 훅 | [tools/test-hooks-py.sh](../tools/test-hooks-py.sh)<br>[tools/test-session-start-check.sh](../tools/test-session-start-check.sh)<br>[tools/test-format-guard.sh](../tools/test-format-guard.sh) | 판정 사례·실패 시 동작<br>설정 낡음 판정<br>형식 검사 게시 전·저장 후 |
| 스킬 | [tools/test-skill.sh](../tools/test-skill.sh) | 새 세션 발동 시험, 방법은 [skill-development.md](skill-development.md) "시험 방법" |
| 에이전트 | [tools/test-agent.sh](../tools/test-agent.sh) | 위임 대상·도구 호출·훅 차단 |
| 설치본 | `bash tools/check-install.sh` | `~/.claude`가 `base/`와 같은지 |

- 스킬 발동 시험은 같은 세션 안에서 스킬을 직접 부르는 것으로 대신하지 않는다
  - 세션이 "했다"고 말한 것과 실제 파일 변경을 대조한다.
- 검사가 실제로 몇 개를 봤는지 확인한다
  - 0줄로 세거나 파일을 건너뛰고 "통과"로 끝난 일이 2026-09-28~29에 세 번 있었음([Issue #151](https://github.com/yanos0218/AI/issues/151)·[Issue #161](https://github.com/yanos0218/AI/issues/161)).

## 세 OS에서 도는 스크립트 쓰기

Windows(Git Bash, bash 5, gawk)에서만 시험하면 Mac(bash 3.2, BSD 도구)에서 조용히 틀린다. 2026-09-28~29에 같은 부류 버그 6건([Issue #151](https://github.com/yanos0218/AI/issues/151)·[Issue #154](https://github.com/yanos0218/AI/issues/154)·[Issue #162](https://github.com/yanos0218/AI/issues/162) 등).

- bash 4 이상 전용 문법을 쓰지 않는다
  - `mapfile`·`readarray`·`declare -A`·`${var,,}` 금지.
  - `set -u`에서 빈 배열은 `${a[@]+"${a[@]}"}`로 펼친다.
- GNU 전용 옵션을 쓰지 않는다
  - `sed -i`(인자 없이), `stat -c`, `date -d`, `readlink -f`, `grep -P` 금지.
  - `awk -v`에 여러 줄 값을 넘기지 않는다(BSD awk 오류). 환경변수로 넘기고 `ENVIRON`으로 읽는다.
- 파이썬은 이름을 고정하지 않는다
  - Mac은 `python` 없이 `python3`만 있음. 훅은 `python` → `python3` 순(Windows는 `python3`가 느린 스토어 별칭), 도구는 `command -v python3 || command -v python`.
- 빈 글롭은 `shopt -s nullglob`으로 건너뛴다
  - 폴더가 비면 글롭이 문자 그대로 넘어간다.

## 설치는 커밋 뒤에

- `base/`를 바꾼 뒤 `bash tools/install.sh`는 커밋한 다음에 돌린다
  - 설치 스크립트는 커밋된 `base/` 트리 해시를 버전 표시 파일 3행에 기록한다.
  - 커밋 전에 설치하면 다음 세션에 거짓 "설정이 낡았습니다" 알림이 뜬다(2026-09-29, [Issue #150](https://github.com/yanos0218/AI/issues/150) 반영 중 발견).
- 설치 뒤에는 `bash tools/check-install.sh`로 대조한다.
