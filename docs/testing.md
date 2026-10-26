# 검증 — 무엇을 바꾸면 무엇을 돌리나

이 저장소에서 바꾼 것을 확인하는 명령과 규칙. 저장소 [CLAUDE.md](../CLAUDE.md) "검증" 절에서 분리함(2026-09-29, [Issue #166](https://github.com/yanos0218/AI/issues/166)).

## 바꾼 것별 검사

| 바꾼 것 | 돌릴 것 | 비고 |
| --- | --- | --- |
| `.md` 문서 | `npx markdownlint-cli2 "**/*.md"`<br>`bash tools/check-docs.sh`<br>`python3 tools/check-doc-sync.py` | CI와 같이 모든 `.md`, 제외 폴더는 `.markdownlint-cli2.jsonc`. 줄 길이(MD013)는 무시<br>검사한 수는 `Linting: N files`, 마지막 줄 `0 issues in 0 files`는 "문제 있는 파일 0개"라는 뜻<br>줄 수 상한은 [CLAUDE.md](../CLAUDE.md) "문서 규칙" |
| 셸 스크립트 | `npx shellcheck -S warning <파일>` | CI 대상은 [.github/workflows/lint.yml](../.github/workflows/lint.yml)(2026-10-26 기준 40개)<br>모든 스크립트를 `${var}`·`[[ ]]` 스타일로 씀<br>`--enable=all`이 더 잡는 것은 전부 스타일이라 쓰지 않음(2026-09-13 확인) |
| 파이썬 | `python3 -m py_compile <파일>` | Rocky Linux 8 기본 파이썬이 3.6.8이라 훅·도구는 3.6에서도 돌게 씀, 3.7 이상 전용 기능 금지는 아래 "세 OS에서 도는 스크립트 쓰기" |
| 훅 | [tools/test-hooks-py.sh](../tools/test-hooks-py.sh)<br>[tools/test-session-start-check.sh](../tools/test-session-start-check.sh)<br>[tools/test-format-guard.sh](../tools/test-format-guard.sh)<br>[tools/test-progress-stale-check.sh](../tools/test-progress-stale-check.sh)<br>[tools/test-git-guardrails.sh](../tools/test-git-guardrails.sh)<br>[tools/test-notify.sh](../tools/test-notify.sh)<br>[tools/test-doc-drift.sh](../tools/test-doc-drift.sh)<br>[tools/test-easy-explain.sh](../tools/test-easy-explain.sh) | 판정 사례·실패 시 동작<br>설정 낡음 판정<br>형식 검사 게시 전·저장 후<br>PROGRESS 기기 행 낡음 알림(세 운영체제 CI)<br>git-guardrails 오류 안전망과 `onFailure` 등록(세 운영체제 CI)<br>알림 훅 초안 분기·임계·주입 방지(세 운영체제 CI)<br>문서 낡음 알림 훅 초안, 임시 git 저장소 사례 26건(세 운영체제 CI). 실제 커밋 재생은 `git diff --binary -M <부모> <커밋>`을 부모 상태에 `git apply --index`로 얹고 훅을 돌려 경고 건수와 시간을 셈(오탐 측정, 승격 전 다른 저장소에서도 반복) |
| 스킬 | [tools/test-skill.sh](../tools/test-skill.sh)<br>[tools/test-live-status.sh](../tools/test-live-status.sh) | 새 세션 발동 시험, 방법은 [skill-development.md](skill-development.md) "시험 방법"<br>보고·안내 문장만 바뀐 수정은 문안 검토([drafts/README.md](../drafts/README.md) 승격 조건 1, [Issue #181](https://github.com/yanos0218/AI/issues/181))<br>실시간 현황 스킬은 가짜 목록·가짜 실행 파일로 상태 추적·HTTP·개인정보를 확인하고 화면 모양은 사용자가 직접 봄(세 운영체제 CI) |
| 에이전트 | [tools/test-agent.sh](../tools/test-agent.sh) | 위임 대상·도구 호출·훅 차단 |
| 전역 지침 | 문안 위험도별 기준([drafts/README.md](../drafts/README.md) 승격 조건 1) | 막는·승인 흐름 문안은 반영 전 1회로 실제로 틀리는지 먼저 본 뒤 반영 후 2회<br>사고 근거 알림성 문안은 문안 검토, 준수는 월 점검 self-audit |
| 설치본 | `bash tools/check-install.sh` | `~/.claude`가 `base/`와 같은지 |
| 설치 병합 | [tools/test-install-merge.sh](../tools/test-install-merge.sh) | 임시 폴더에 사용자 allow·훅·고친 스킬을 넣고 `install.sh`를 돌려 보존·백업·재실행 동일·`--dry-run` 무변경·오래된 백업 자동 정리(종류별 3개)를 확인([Issue #194](https://github.com/yanos0218/AI/issues/194))<br>실제 `~/.claude`는 건드리지 않음<br>CI [lint.yml](../.github/workflows/lint.yml)의 `install-test` 잡이 Ubuntu·macOS·Windows(Git Bash) 세 러너에서 돌림, 공개 저장소라 분 무료([Issue #197](https://github.com/yanos0218/AI/issues/197)) |
| 훅 알림·경고 | `claude -p`로 사본 저장소에서 비대화 세션 | 방법은 아래 "훅 알림·경고 시험"([Issue #199](https://github.com/yanos0218/AI/issues/199))<br>한도를 쓰므로 실행 전 사용자 확인 |
| 기기 간 차이 | [tools/fingerprint.sh](../tools/fingerprint.sh) | 반응이 달라 보일 때 먼저 각 기기의 `설치본 = 최신` 줄을 확인하고([Issue #203](https://github.com/yanos0218/AI/issues/203)) `--common` 출력을 기기끼리 `diff --strip-trailing-cr`, 비어 있으면 일치. Windows는 PowerShell이 아니라 Git Bash에서 실행(PowerShell의 `bash`는 WSL, [os-differences.md](os-differences.md))([Issue #186](https://github.com/yanos0218/AI/issues/186), [Issue #197](https://github.com/yanos0218/AI/issues/197))<br>세 러너 CI가 한글 출력·표지 동작을 시험함<br>사례 기록 양식은 [issue-format.md](issue-format.md) "반응 차이 사례"<br>자동 실행하지 않음 |
| 모델 비교 | [tools/measure-model.sh](../tools/measure-model.sh) | 같은 작업을 모델별로 돌려 구독 한도 소모(5시간·주간 %p)와 정답률 비교([Issue #178](https://github.com/yanos0218/AI/issues/178))<br>시험 문서는 [tools/test-fixtures/model-compare/](../tools/test-fixtures/model-compare/)(위반 5개를 일부러 심어 markdownlint 제외)<br>한도를 쓰므로 실행 전 사용자 확인 |

- 스킬 발동 시험은 같은 세션 안에서 스킬을 직접 부르는 것으로 대신하지 않음
  - 세션이 "했다"고 말한 것과 실제 파일 변경을 대조함.
- 검사가 실제로 몇 개를 봤는지 확인함
  - 0줄로 세거나 파일을 건너뛰고 "통과"로 끝난 일이 2026-09-28~29에 세 번 있었음([Issue #151](https://github.com/yanos0218/AI/issues/151)·[Issue #161](https://github.com/yanos0218/AI/issues/161)).

## 훅 알림·경고 시험

SessionStart 알림이나 PreToolUse 경고가 Claude에게 실제로 도착하는지는 스크립트 단독 실행으로 알 수 없음. 사용자가 새 세션을 여러 번 여는 대신 아래로 시험함([Issue #192](https://github.com/yanos0218/AI/issues/192), 2026-10-21).

- 시험 전제
  - 훅 설정은 세션 시작 때 고정되므로 같은 세션 안에서 설정을 바꿔 시험하지 않음.
  - 훅은 명령 실행 전에 돌므로 같은 줄에서 훅 파일을 고치면 훅은 고치기 전 상태로 돎(2026-10-21, 이 때문에 "훅 미실행"으로 오진함).
  - `git add x && git commit`처럼 한 줄이면 훅이 돌 때 add 전이라 스테이징 목록이 비어 있음. 검사 대상은 add 전 상태로 판단해야 함.
- SessionStart 알림 시험
  - 저장소를 임시 폴더에 clone하고 알림이 날 상태를 일부러 만듦(예: HANDOFF "지금" 절에 닫힌 이슈 번호). `gh`가 쓰이는 훅은 사본의 origin을 실제 저장소 주소로 바꿈. 사본에서 커밋·push하지 않음.
  - 사본 폴더에서 `claude -p --model sonnet --max-turns 1 "세션 시작할 때 훅이 준 알림이 있었으면 그대로 옮겨 써줘. 없으면 없다고만 해줘. 도구는 쓰지 마."`를 실행하고 답변에 알림 원문이 있는지 봄.
  - `claude`가 PATH에 없으면 VS Code 확장의 `~/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude`를 씀.
- `claude -p` 호출 주의
  - `--allowedTools`는 뒤에 오는 값을 모두 도구 이름으로 읽어 프롬프트를 삼킴(`Error: Input must be provided either through stdin or as a prompt argument`).
  - 프롬프트는 표준입력으로 넘기거나 `--allowedTools=Bash`처럼 `=`로 붙임([Issue #211](https://github.com/yanos0218/AI/issues/211), 2026-10-25).
- PreToolUse 경고 시험
  - 변경을 먼저 `git add`로 스테이징한 뒤 대상 명령을 따로 실행해 경고가 결과에 붙는지 봄. 훅 스크립트는 사본에서 JSON 입력을 파이프로 넣어 출력과 종료 코드도 봄.
- 시험이 맞게 열렸는지 확인함
  - 새 세션이 시험 폴더에서 열렸는지는 `~/.claude/projects/` 아래에 그 폴더 이름의 기록 폴더가 있는지로 봄(2026-10-21, 원래 저장소에서 열려 시험이 무효였던 사례).
  - 답변에 전역 훅 알림만 있고 저장소 훅 알림이 없으면 훅 실패가 아니라 폴더를 잘못 연 것인지 먼저 의심함.

## 세 OS에서 도는 스크립트 쓰기

Windows(Git Bash, bash 5, gawk)에서만 시험하면 Mac(bash 3.2, BSD 도구)에서 조용히 틀림. 2026-09-28~29에 같은 부류 버그 6건([Issue #151](https://github.com/yanos0218/AI/issues/151)·[Issue #154](https://github.com/yanos0218/AI/issues/154)·[Issue #162](https://github.com/yanos0218/AI/issues/162) 등).

- bash 4 이상 전용 문법을 쓰지 않음
  - `mapfile`·`readarray`·`declare -A`·`${var,,}` 금지.
  - `set -u`에서 빈 배열은 `${a[@]+"${a[@]}"}`로 펼침.
- GNU 전용 옵션을 쓰지 않음
  - `sed -i`(인자 없이), `stat -c`, `date -d`, `readlink -f`, `grep -P` 금지.
  - `awk -v`에 여러 줄 값을 넘기지 않는다(BSD awk 오류). 환경변수로 넘기고 `ENVIRON`으로 읽음.
- 파이썬은 이름을 고정하지 않음
  - Mac은 `python` 없이 `python3`만 있음. 훅은 `python` → `python3` 순(Windows는 `python3`가 느린 스토어 별칭), 도구는 `command -v python3 || command -v python`.
- 파이썬 3.7 이상 전용 기능을 쓰지 않음
  - Rocky Linux 8 기본 3.6.8에서 `sys.stdout.reconfigure`, `datetime.fromisoformat`, `subprocess.run(capture_output=)`, `dataclasses`, `from __future__ import annotations`가 없음([Issue #202](https://github.com/yanos0218/AI/issues/202)).
  - 출력 인코딩은 `reconfigure`가 없으면 `io.TextIOWrapper`로 감쌈([tools/settings_merge.py](../tools/settings_merge.py) `utf8_stdio`), 훅 셸 입구는 `PYTHONIOENCODING=utf-8`을 지정함.
  - CI 러너는 모두 3.7 이상이라 3.6 실행은 CI가 못 잡음. 대신 lint 작업이 `vermin --target=3.6-`로 훅·도구(`base/hooks`·`tools`·`drafts/hooks`·`.claude/hooks`)의 3.7 이상 전용 기능을 정적으로 막음([Issue #219](https://github.com/yanos0218/AI/issues/219) 2026-10-26, 스킬 스크립트는 3.6 건너뜀 처리라 제외). 파이썬 관련 변경 뒤에는 RHEL 8 계열 기기에서 `tools/test-install-merge.sh`와 `tools/test-hooks-py.sh`를 직접 돌림.
  - `tools/test-hooks-py.sh`의 입력 도우미는 `python3 -c`에 한글을 실어 3.6에서 `LC_ALL=C`로는 실행되지 않음(명령줄 해석 실패, 훅 결함 아님), `LC_ALL=C.UTF-8`로 돌림.
  - 예외는 `usage-dashboard`의 `fromisoformat`, Linux 제외 대상이라 그대로 둠.
  - [tools/test-live-status.sh](../tools/test-live-status.sh)의 캐시 만료 판정 구간은 3.6에서 "건너뜀"으로 표시하고 나머지는 그대로 시험함([Issue #213](https://github.com/yanos0218/AI/issues/213)).
- 빈 글롭은 `shopt -s nullglob`으로 건너뜀
  - 폴더가 비면 글롭이 문자 그대로 넘어감.
- 임시 경로를 네이티브 프로그램에 직접 넘기지 않음
  - Windows Git Bash의 `/tmp/...`는 네이티브 파이썬·node가 못 찾음(2026-10-25, 실시간 현황 시험에서 `FileNotFoundError`, [Issue #213](https://github.com/yanos0218/AI/issues/213)).
  - 파일 입출력은 셸 리다이렉트로 하고, node처럼 경로를 인자로 받는 것에는 `cygpath -m`을 거침.
- 서버를 띄우는 파이썬은 이름 조회에 기대지 않음
  - 표준 `HTTPServer`는 바인드 때 `getfqdn`(역방향 DNS 조회)을 불러, DNS가 없는 macOS 러너에서 서버가 뜨기 전에 멈춤(같은 날, 파이썬 3.15).
  - 127.0.0.1 전용 서버는 `socketserver.TCPServer.server_bind`만 쓰고, 시험은 `socket.getfqdn`을 예외로 바꿔 놓고 열어 봄.
- 새 시험 스크립트는 푸시 전에 CI 환경 차이를 먼저 의심함
  - 처음 CI에 올라가는 시험은 로컬 Mac에서 통과해도 Windows 경로·DNS·최신 파이썬에서 실패할 수 있음.
  - 시작 실패는 서버 로그·프로세스·포트를 시험 출력에 남겨 한 번에 원인을 보게 함.

## 설치는 커밋 뒤에

- `base/`를 바꾼 뒤 `bash tools/install.sh`는 커밋한 다음에 돌림
  - 설치 스크립트는 커밋된 `base/` 트리 해시를 버전 표시 파일 3행에 기록함.
  - 커밋 전에 설치하면 다음 세션에 거짓 "설정이 낡았습니다" 알림이 뜬다(2026-09-29, [Issue #150](https://github.com/yanos0218/AI/issues/150) 반영 중 발견).
- 설치 뒤에는 `bash tools/check-install.sh`로 대조함.
- Windows에서 설치·시험이 유난히 느리면(`install.sh` 3분 이상) 보안 프로그램의 파일시스템 필터 드라이버를 먼저 의심함
  - `fltmc filters`로 서드파티 필터를 확인하고, `/usr/bin/true` 50회 반복 시간(정상 약 8초)으로 재 봄.
  - 2026-10-24 AhnLab Safe Transaction 중지로 28초가 8초가 됨(Defender 예외는 무효, [Issue #206](https://github.com/yanos0218/AI/issues/206)).
