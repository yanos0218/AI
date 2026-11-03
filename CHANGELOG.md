# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Fixed

- `tools/install.sh`가 환경변수 `CLAUDE_CONFIG_BASE_VER`로 설치 버전을 받음, `.git` 없는 zip 설치에서 "base 버전"이 비던 문제 수정([Issue #248](https://github.com/yanos0218/AI/issues/248))
  - `tools/install.ps1`이 릴리즈 태그를 넘기고 임시 복원 코드를 제거함, 패키지 설치에서는 PROGRESS 행 갱신 안내를 건너뜀

### Changed

- `docs/install.md` Windows 절에 한 줄 설치 확인 결과와 `raw` 주소 5분 캐시·릴리즈 기준 안내 추가([Issue #247](https://github.com/yanos0218/AI/issues/247))
- CI에 `설치기 PowerShell 5.1 시험` job 추가, `tools/test-install-ps1.ps1`이 `windows-latest`의 Windows PowerShell 5.1로 `install.ps1`을 시험함([Issue #249](https://github.com/yanos0218/AI/issues/249))
  - 시나리오 A는 bash를 숨긴 1단계, B는 러너의 실제 Git·Python으로 2단계, 5.1 시험 결과는 첫 CI 실행 뒤 확정
- `docs/os-differences.md` Windows 초기 설치 행에 시험 기기가 초기화한 깨끗한 PC(기존 개발 PC와 다른 기기)임을 기록

## [0.18.0] - 2026-11-04

### Added

- `tools/install.ps1` 추가, bash·git·python이 없는 Windows에서 PowerShell 한 줄로 설정을 설치함([Issue #247](https://github.com/yanos0218/AI/issues/247))
  - 1단계는 최신 릴리즈 zip의 `base/`를 복사하고 `settings.json`이 없으면 훅·상태줄을 뺀 값으로 생성(bash 없이 훅을 등록하면 `git-guardrails`가 명령을 막을 수 있어서)
  - 2단계는 Git for Windows·Python이 있으면(없으면 동의 후 `winget`으로 설치, `winget`이 실패하면 설치 파일 직접 내려받기, [Issue #250](https://github.com/yanos0218/AI/issues/250)) `tools/install.sh`로 훅까지 병합
  - 시험 `tools/test-install-ps1.sh` 11건(PowerShell 7), 실제 Windows에서 1단계·한글 출력·`winget` 실패 폴백·Git(sha256 대조)·Python 직접 설치는 2026-11-03~04에 확인함
  - 훅 병합까지 끝나는 전체 흐름과 Windows PowerShell 5.1 CI 시험은 아직 확인 전([Issue #249](https://github.com/yanos0218/AI/issues/249))

### Fixed

- `tools/install.sh`·`tools/check-install.sh`가 `python3` 이름이 실행 안 되는 Windows 스토어 별칭이어도 되는 `python`을 고르도록 수정([Issue #250](https://github.com/yanos0218/AI/issues/250))
  - 실제 Windows에서 `python3` 별칭이 앞서 `settings.json` 병합이 실패했음(2026-11-03), 시험 `tools/test-install-ps1.sh`에 재현 추가
  - 훅 쪽 같은 문제는 [Issue #251](https://github.com/yanos0218/AI/issues/251)에서 판단함

## [0.17.0] - 2026-11-02

### Added

- `tools/test-handoff-stale-check.sh` 추가, `handoff-stale-check.sh`를 임시 폴더와 가짜 `gh`로 12건 시험함([Issue #238](https://github.com/yanos0218/AI/issues/238))
  - 닫힌 표기 제외 오탐([Issue #237](https://github.com/yanos0218/AI/issues/237)) 재발을 막음, CI 설치 병합 시험 잡에서 세 운영체제 실행
- `tools/ci-wait.sh` 추가, 푸시한 커밋의 CI를 끝까지 기다려 통과·실패·미검증을 한 줄로 보고함([Issue #229](https://github.com/yanos0218/AI/issues/229))
  - push·pull_request 실행만 세고 이슈 이벤트 워크플로는 제외, 실행 0건은 종료 코드 2(미검증)
  - 시험 `tools/test-ci-wait.sh`(가짜 `gh`)를 CI 세 운영체제 시험에 추가
  - 저장소 `.claude/settings.json`에 `Bash(bash tools/ci-wait.sh *)` 허용 규칙, 저장소 `CLAUDE.md` 검증 절에 사용 문구 추가, `base/`는 변경 없음([Issue #230](https://github.com/yanos0218/AI/issues/230))
- `tools/eng-scan.py` 추가, 대화 기록의 진행 설명 중 영어 우세 블록 비율을 월별로 집계함([Issue #222](https://github.com/yanos0218/AI/issues/222), 효과 측정 대상 [Issue #223](https://github.com/yanos0218/AI/issues/223))
  - 2026-10-28 기준선은 9월 5.3%(599블록 중 32), 10월 3.5%(770블록 중 27), 합계 4.3%
  - 파일명 나열 같은 오탐이 섞여 절대값보다 월별 추세로 봄
- 전역 지침(`base/claude-md/CLAUDE.md`)에 self-audit 후보 3건 반영([Issue #224](https://github.com/yanos0218/AI/issues/224), 후보 출처 [Issue #220](https://github.com/yanos0218/AI/issues/220))
  - §4 사용자에게 시키는 명령은 실행 위치와 확인 여부(확인함·미검증)를 함께 적음
  - §5 다음 작업을 추천하거나 대기 이유를 설명하기 전에 대상 이슈의 최신 댓글과 현재 파일 상태를 직접 확인함
  - §8 설계 제시 때 사전 검토(문제·파생 문제·대안·위험) 칸을 채움
- `tools/check-docs.sh`가 마지막에 검사한 파일 수를 출력하고 0개면 실패 처리함([Issue #224](https://github.com/yanos0218/AI/issues/224))
- CI lint 작업에 파이썬 3.6 호환 정적 검사 추가(`vermin==1.9.2 --target=3.6-`, 대상 `base/hooks`·`tools`·`drafts/hooks`·`.claude/hooks`)([Issue #219](https://github.com/yanos0218/AI/issues/219))
  - 3.6 기기 없이도 3.7 이상 전용 기능이 들어오는 것을 막음. 실제 3.6 실행 확인은 여전히 RHEL 8 기기에서 함
- `dev-release` 스킬 8단계에 Release 제목이 `vX.Y.Z - 한국어 제목` 꼴인지 확인하고 아니면 `gh release edit --title`로 보충하는 단계 추가([Issue #221](https://github.com/yanos0218/AI/issues/221))
  - v0.14.0·v0.13.1 Release가 제목 없이 만들어진 일이 근거임
  - 문안 수정이라 발동 조건은 그대로이고, 확인 명령은 v0.16.0·v0.14.0 실제 Release에서 제목이 나오는 것을 직접 확인함
- 기본 영역 `settings.example.json`에 `"language": "korean"` 추가, `tools/settings_merge.py`가 설치 때 이 값으로 맞춤([Issue #223](https://github.com/yanos0218/AI/issues/223), 조사 [Issue #222](https://github.com/yanos0218/AI/issues/222))
  - 도구 호출 앞뒤 진행 설명이 영어로 시작하는 재발(대화 기록 1235블록 중 약 4.8%)을 줄이려는 것임
  - 효과는 12회 비교 시험이 양쪽 0건이라 판단 불가, 반영 뒤 월별 영어 비율로 확인함
  - 병합 시험에 language 어긋남·키 없음 사례 2건 추가
- 쉬운 설명 요청 지침 주입 훅 초안 `drafts/hooks/easy-explain-hint.sh`·`easy_explain.py`와 시험 `tools/test-easy-explain.sh` 9건([Issue #222](https://github.com/yanos0218/AI/issues/222), 후보 출처 [Issue #220](https://github.com/yanos0218/AI/issues/220))
- 문서 낡음 알림 훅 `base/hooks/doc-drift-check.sh`·`doc_drift.py`를 기본 영역으로 승격하고 `settings.example.json`의 PreToolUse(Bash, `if: Bash(git *)`)에 등록, 시험 `tools/test-doc-drift.sh` 27건(Windows 경로 사례 1건은 Windows에서만 돌아 그 밖의 운영체제는 26건)([Issue #219](https://github.com/yanos0218/AI/issues/219), 조사 [Issue #218](https://github.com/yanos0218/AI/issues/218))
  - 커밋 때 삭제·이름변경된 경로가 다른 `.md`에 남았는지, 올리는 `.md`의 상대 링크 대상이 있는지, `CHANGELOG.md` 릴리즈 섹션에 다음 릴리즈를 가리키는 미정 문구가 남았는지를 경고만 함
  - 최근 커밋 50건 재생에서 AI 저장소는 2건 모두 실제 낡음(live-status 승격의 README 경로, v0.16.0 컷에 남은 미정 문구), OpenClaw·kolo-api는 0건, kolo_pwa는 `.gitignore` 대상 파일을 가리키는 링크 오탐 2건이 나와 그 경우를 제외하도록 고친 뒤 0건, 평균 약 90ms
  - 훅은 명령 문자열만 보므로 `git -C $변수 commit`처럼 경로를 셸 변수로 쓰면 저장소를 못 찾아 경고가 빠지는 한계가 있음(2026-10-27 라이브 세션 확인)
  - 윈도우에서 `git -C /c/Users/...`(Git Bash 경로)를 윈도우 파이썬이 못 읽어 경고가 조용히 빠지던 것을 `C:/Users/...`로 바꿔 읽게 고침(2026-10-27 Windows 시험에서 발견), 시험 1건 추가
  - PowerShell에는 등록하지 않음(Bash만)

### Changed

- `docs/review-vs-official.md` 읽기 차단 행에 Mac 대화형 재현을 추가([Issue #228](https://github.com/yanos0218/AI/issues/228))
  - `Bash` 읽기가 대화형에서 막히지 않는 것이 Windows·Linux·Mac 모두 확인됨(2026-10-28)
- `docs/monthly-check.md` 갱신([Issue #233](https://github.com/yanos0218/AI/issues/233), [Issue #234](https://github.com/yanos0218/AI/issues/234))
  - 8번 사용량에 `/usage` 경고 목록 기록을 추가하고, 5번에 모델 새 버전이 나온 달의 `/doctor prompt-audit` 실행을 추가함
- 전역 `CLAUDE.md`를 줄임([Issue #236](https://github.com/yanos0218/AI/issues/236))
  - §5의 조사·`--limit`·저장소 상태 수정 세부 규칙을 `base/claude-md-details/research.md`로 옮기고 본문에는 경로와 한 줄 요약만 남김(약 1.9KB 감소(12,586 → 10,734바이트), `/usage` 경고 "Trim ~/.claude/CLAUDE.md" 반영)
  - 사고 날짜·집계 설명 4곳 제거
  - `install.sh`가 `~/.claude/claude-md-details/`로 복사하고 `check-install.sh`가 대조
  - 형식 검사 훅(`format_check.py`)이 `claude-md-details/`를 명령형 예외 경로로 취급(시험 1건 추가)
- `base/agents/auditor.md` 모델 변경([Issue #236](https://github.com/yanos0218/AI/issues/236))
  - Sonnet에서 Haiku로 낮춤(`/usage` 경고 "단순 서브에이전트에 더 싼 모델" 반영, 읽기 전용 검색이라 위험이 작음)

### Fixed

- `handoff-stale-check.sh`가 "닫음"으로 적은 HANDOFF 줄의 이슈를 낡은 참조로 오탐하던 것을 수정함([Issue #224](https://github.com/yanos0218/AI/issues/224))
- `handoff-stale-check.sh`가 "닫힌 [#N]"으로 닫혔다고 밝힌 표기까지 낡은 참조로 오탐하던 것을 수정함([Issue #237](https://github.com/yanos0218/AI/issues/237))
  - 줄 전체가 아니라 그 표기의 번호만 제외해 같은 줄의 다른 번호는 계속 검사함
- `tools/test-easy-explain.sh`가 임시 폴더로 `CLAUDE_CONFIG_DIR`을 돌려, "깨진 JSON" 사례가 실제 `hook-errors.log`에 가짜 오류 줄을 남기던 것을 수정함([Issue #225](https://github.com/yanos0218/AI/issues/225))
- `tools/ci-wait.sh`가 결론이 빈 job(끝나지 않음)이 있어도 "CI 통과"로 보고하던 것을 수정함, 결과 구분자를 탭에서 `|`로 바꾸고 빈 결론은 `미완료`로 세어 통과에서 제외, `gh run watch`가 실행이 끝나기 전에 돌아오면 상태가 `completed`가 될 때까지 최대 5번 다시 기다리고 끝내 안 끝나면 통과 아님, 시험 `tools/test-ci-wait.sh`에 사례 추가([Issue #232](https://github.com/yanos0218/AI/issues/232))
- `docs/review-vs-official.md`의 읽기 차단 서술을 정정함, `Bash` 읽기는 `-p`에서만 거부되고 대화형(Windows·Linux)에서는 막히지 않음([Issue #228](https://github.com/yanos0218/AI/issues/228))
- 낡은 문서 표기 정정(README의 live-status 경로, `docs/github.md`의 Release 버전·공개 여부·Dependabot 알림, `docs/config-lifecycle.md`·`review-vs-official.md`·`repo-standard.md`·`PROGRESS.md`·`testing.md`, 0.16.0 항목의 MINOR 문구, [Issue #217](https://github.com/yanos0218/AI/issues/217))

## [0.16.0] - 2026-10-26

### Added

- 실시간 세션 현황 화면 `base/skills/live-status/`(기본 영역 승격)와 시험 `tools/test-live-status.sh` 105건([Issue #213](https://github.com/yanos0218/AI/issues/213), 에이전트 팀 구역은 실제 팀 파일 확인 전 [Issue #216](https://github.com/yanos0218/AI/issues/216))
  - 파이썬 표준 라이브러리 서버가 `claude agents --json`(세션)과 Claude Code가 남기는 서브에이전트 기록 파일을 읽어 구조도(세션 아래 서브에이전트)와 최근 30분 타임라인을 보여 줌, 기본 포트 8766
  - 서브에이전트 상태는 `meta.json`의 `finished`와 기록 파일 수정 시각으로 판정(작업 중·조용함·끝남, finished 표시가 없는 옛 기록은 끝남 추정), 기록은 첫 줄만 읽음, 문서화되지 않은 형식이라 읽지 못하면 화면에 알림
  - 127.0.0.1에만 묶고 Host 검사, 대화 내용과 전체 경로와 전체 ID는 내보내지 않음, 작업 제목은 `LIVE_SHOW_TITLES=0`으로 숨김, 일시적으로 목록이 비어도 연속 3번 안 보일 때만 끝남으로 처리
  - 화면은 핵심 정보 순서로 설계: 한 문장 요약과 숫자 타일 넷(작업 중 세션, 서브에이전트 진행, 가장 오래 걸리는 중, 오늘 실사용 토큰), 지금 진행 중, 쉬는 중, 접어 둔 최근 끝난 것, 타임라인, 읽는 법
  - 토큰은 usage-dashboard의 `usage-log/hourly.json` 집계(입력+출력, 캐시 읽기 제외)를 읽고, 같은 서버가 기존 사용량 화면을 `/usage/`로 연결(허용 파일 2개만, 돌아가는 줄만 주입), `LIVE_SHOW_USAGE=0`으로 끔
  - 배경 셸 명령은 미표시, 화면은 WebKit 캡처로 밝은·어두운 테마와 좁은 폭을 확인했고 Linux 서버를 SSH 터널로 연 사용자 PC 브라우저에서 사용자가 직접 확인(2026-10-25, 항목별 결과는 전달 안 됨)
  - 에이전트 팀 구역(공식 문서 형식의 `teams/`·`tasks/` 파일을 읽어 구성원과 공유 작업 개수만 표시, 실제 팀 파일은 미확인)
  - 방금 끝난 일을 "내 차례"·"방금 끝남"으로 강조, 탭 제목·아이콘에 상태 표시, 토큰 단위를 만·억으로 통일
- 알림 훅 초안 `drafts/hooks/notify.sh`와 시험 `tools/test-notify.sh` 18건([Issue #5](https://github.com/yanos0218/AI/issues/5), 초안이라 배포 안 됨)
  - `permission_prompt`면 "승인 대기", `Stop`이 백그라운드 작업 없이 60초 넘게 걸렸으면 "작업 끝" 알림
  - 본문은 폴더 이름과 `session_id` 앞 8자뿐, 훅 입력은 인자와 환경변수로만 넘겨 주입 방지
  - 실제 알림 도착과 Windows 분기는 미검증

### Changed

- `docs/testing.md` 훅 시험 절에 `claude -p --allowedTools`가 프롬프트를 삼키는 주의사항 추가([Issue #211](https://github.com/yanos0218/AI/issues/211))
- `tools/test-live-status.sh`가 파이썬 3.6(Rocky Linux 8 기본)에서 `usage.py`의 `fromisoformat` 예외로 중간에 죽어 약 30건이 연쇄 실패하던 것을 고침([Issue #213](https://github.com/yanos0218/AI/issues/213))
  - 캐시 만료 판정 구간(2g)만 3.6에서 "건너뜀"으로 표시하고 나머지는 그대로 시험, 이 기기(Rocky Linux 8.10, 파이썬 3.6.8)에서 통과
- 토큰 대시보드(`usage-dashboard`) 캐시 만료 판정과 화면 개선을 기본 영역에 반영([Issue #215](https://github.com/yanos0218/AI/issues/215), [Issue #214](https://github.com/yanos0218/AI/issues/214) 조사 근거)
  - `usage.py`가 "쉬어서 캐시 만료"를 5분 고정이 아니라 기록에 남은 캐시 종류(1시간형 3600초·5분형 300초, 모르면 5분)로 판정, 구독의 메인 대화는 1시간형이라 이전엔 과대 집계
  - 이전에 쌓은 기록의 쉰 뒤 횟수는 5분 기준 그대로(최근 30일 요약에서 점차 사라짐)
  - `dashboard.html`에 맨 위 한 문장 요약, 보조 글자 대비 4.5:1 이상, 글자 12px 이상, 세션 시작 크기 도움말, 캐시 재작성 설명을 캐시 수명에 맞게 정정
  - `tools/test-live-status.sh`에 만료 판정 시험 4건 추가(시험을 5분 고정으로 되돌리면 실패하는 것 확인)

- 안전 훅 `git-guardrails.sh`가 실패하면 통과하지 않고 차단하도록 설정에 `"onFailure": "block"` 추가, Claude Code 2.1.295 이상 필요([Issue #211](https://github.com/yanos0218/AI/issues/211), 설정 키 추가라 이 컷이 MINOR)
  - 시작 실패와 시간 초과는 모든 Bash·PowerShell 명령을 막고, 스크립트가 예상 밖 오류(종료 코드 1)로 끝나면 EXIT 트랩이 전체 차단 대신 확인 창(`ask`)을 띄움
  - `gh-throttle`·`format-guard`는 제외, 복구 방법은 `docs/install.md`
  - 새 세션(Claude Code 2.1.309, Haiku) 시험 6가지: 정상 통과, 종료 코드 1 차단, 시간 초과 차단, 옵션 없으면 통과(현 상태), 실제 훅에 오류 주입 시 확인 창, 실제 훅 정상 명령 통과
  - `tools/test-git-guardrails.sh` 8건 추가, CI에서 세 운영체제 실행, `tools/test-install-merge.sh`에 설치 확인 1건 추가
