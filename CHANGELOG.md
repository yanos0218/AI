# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Added

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
- 문서 낡음 알림 훅 초안 `drafts/hooks/doc-drift-check.sh`·`doc_drift.py`와 시험 `tools/test-doc-drift.sh` 26건([Issue #219](https://github.com/yanos0218/AI/issues/219), 조사 [Issue #218](https://github.com/yanos0218/AI/issues/218))
  - 커밋 때 삭제·이름변경된 경로가 다른 `.md`에 남았는지, 올리는 `.md`의 상대 링크 대상이 있는지, `CHANGELOG.md` 릴리즈 섹션에 "다음 컷"이 남았는지를 경고만 함
  - 최근 커밋 50건 재생에서 AI 저장소는 2건 모두 실제 낡음(live-status 승격의 README 경로, v0.16.0 컷의 "다음 컷" 문구), OpenClaw·kolo-api는 0건, kolo_pwa는 `.gitignore` 대상 파일을 가리키는 링크 오탐 2건이 나와 그 경우를 제외하도록 고친 뒤 0건, 평균 약 90ms

### Fixed

- `handoff-stale-check.sh`가 "닫음"으로 적은 HANDOFF 줄의 이슈를 낡은 참조로 오탐하던 것을 수정함([Issue #224](https://github.com/yanos0218/AI/issues/224))
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

## [0.15.0] - 2026-10-24

### Changed

- `config-update` 스킬 8단계가 `check-install.sh`의 PROGRESS "기록" 줄을 판정 줄과 함께 전달하고, 기록이 "없음"이면 claude-config 세션에서 갱신하라고만 알림([Issue #181](https://github.com/yanos0218/AI/issues/181))
  - 보고 문장만 바뀌고 도구 호출·권한은 그대로라 문안 검토로 승격함, `drafts/README.md` 승격 조건에 이 예외를 먼저 추가
  - 명령을 `;`·`&&`로 묶지 않고 하나씩 실행하라는 문단과 `fetch`·`pull` 거부 시 우회하지 않고 보고하라는 문장도 같이 반영, 새 세션 시험 2시나리오 통과(2026-10-24)
- 작업 폴더 밖 읽기 차단을 기본 영역에 반영, 모든 기기에 `permissions.blockReadsOutsideWorkingDirectories: true`가 설치됨([Issue #195](https://github.com/yanos0218/AI/issues/195), [Issue #205](https://github.com/yanos0218/AI/issues/205))
  - `Read`와 `Bash`로 작업 폴더 밖을 읽으면 거부되고, `python3 -c`·`node -e` 같은 인라인 코드는 확인 창으로 넘어감
  - 설치가 `~/.claude`와 원본 저장소 경로를 기기에 맞게 계산해 `permissions.additionalDirectories`에 합집합으로 넣음, 안 넣으면 다른 저장소에서 `config-update`가 버전 파일을 못 읽음(2026-10-22 시험)
  - `tools/fingerprint.sh`의 `permissions 추가 키`는 base가 정한 키와 기기별 경로를 사용자 추가로 세지 않음
  - 시험 `tools/test-install-merge.sh` 10번 추가
- `tools/install.sh`가 설치 때 사용자가 넣은 값을 지우지 않도록 변경([Issue #194](https://github.com/yanos0218/AI/issues/194), 조사 [Issue #193](https://github.com/yanos0218/AI/issues/193))
  - `settings.json`은 `permissions` 목록 합집합, base 훅만 교체하고 사용자 훅 유지, `env`는 base 키만 덮음, 값이 바뀔 때 `.bak.<시각>` 백업(병합 규칙은 새 `tools/settings_merge.py`)
  - 내용이 다른 스킬은 `~/.claude/backups/claude-config/<시각>/`에 보관한 뒤 교체
  - 이 도구가 만든 백업(`CLAUDE.md.bak.<시각>`, `settings.json.bak.<시각>`, 보관 폴더)은 설치할 때마다 종류별 최근 3개만 남기고 자동 정리, 직접 만든 이름은 건드리지 않고 병합 실패 때는 정리하지 않음([Issue #196](https://github.com/yanos0218/AI/issues/196))
  - `tools/check-install.sh`는 "설치하면 바뀔 항목이 없는가"로 대조하고 사용자 추가 항목은 정보로 표시
  - 시험 스크립트 `tools/test-install-merge.sh` 추가, CI(`lint.yml`)의 `install-test` 잡이 Ubuntu·macOS·Windows 러너에서 돌림([Issue #197](https://github.com/yanos0218/AI/issues/197))
  - `settings_merge.py` 출력을 UTF-8로 고정, Windows 러너에서 파이프 출력 인코딩(cp1252)이 한글을 못 써 `UnicodeEncodeError`가 나던 것을 CI로 발견해 수정
  - 시험에 설치 뒤 `check-install.sh`·`fingerprint.sh` 실행(한글 출력이 파이프에서 깨지지 않는지)을 추가해 세 러너에서 확인
  - `tools/fingerprint.sh`는 줄마다 [공통]·[기기별] 표지를 붙이고 `--common`으로 [공통]만 출력, `settings base 대비`·`permissions 추가 키`·`사용자 추가 항목` 행 추가, 출력 UTF-8 고정([Issue #197](https://github.com/yanos0218/AI/issues/197))
  - 출력 형식이 바뀌어 이전 출력(Mac 1대분)과는 줄 형식이 다름
  - 깨진 JSON(주석·끝 쉼표)이나 모양이 이상한 `settings.json`은 오류 없이 병합만 건너뛰고 이유를 알림, 파일은 그대로 두며 `install.sh`는 실패 종료 코드로 끝나 성공으로 오해되지 않음
- `docs/HANDOFF.md`를 새 세션의 입구로 슬림화([Issue #191](https://github.com/yanos0218/AI/issues/191))
  - 60줄·10.4KB에서 37줄·3.7KB로, 결정 사항 26개는 `docs/decisions.md`로 이동(내용 변경 없음)
  - 작업 종류별 문서 지도 추가, 설치 버전·최근 반영 내역 같은 복사본은 제거
  - 저장소 `CLAUDE.md` 세션 시작 규칙을 HANDOFF 하나만 먼저 읽는 것으로 변경, HANDOFF 상한 60 → 40
- 전역 지침 `base/claude-md/CLAUDE.md` §5 지적 처리 규칙 변경([Issue #190](https://github.com/yanos0218/AI/issues/190))
  - 실수가 실제 문제로 이어졌을 때만 기록을 제안
  - 같은 내용의 지적이 기간과 상관없이 누적 2회 이상이면 기록 대신 훅·CI 검사로 강제하는 방안을 먼저 제안
  - 알림성 문안이라 문안 검토로 갈음, 지켜지는지는 월 점검 self-audit에서 확인
- 기존 `.md` 문서의 문장형 끝맺음 약 220줄을 음슴체로, 줄바꿈 위반 17줄을 하위 bullet·`<br>`로 정리([Issue #189](https://github.com/yanos0218/AI/issues/189))
  - 대상은 지침 문서(`CLAUDE.md`·`rules/`·`skills/`·`agents/`) 밖의 `.md` 21개, `docs/research/` 보관 기록 포함
  - 의미·링크·코드 값은 그대로, 종결 어미와 줄 구성만 변경
- 전역 지침 `base/claude-md/CLAUDE.md`
  - §2에 질문이 여럿 섞인 메시지는 모두 명시적으로 답하는 규칙 추가([Issue #174](https://github.com/yanos0218/AI/issues/174))
  - §5 조사 기록 범위를 "결정에 쓴 조사"에서 "사용자가 요청한 조사 포함"으로 확대([Issue #174](https://github.com/yanos0218/AI/issues/174))
  - 알림성 문안이라 문안 검토로 갈음, 지켜지는지는 월 점검 self-audit에서 확인
- `base/hooks/format_check.py`가 명령 나누기(heredoc 구간·명령 자리)를 `hooklib.py`에서 가져다 씀, 중복 구현 삭제([Issue #164](https://github.com/yanos0218/AI/issues/164))
  - 판정이 달라지는 경우는 하나: `sudo`·`env`·`time`·`command`·백틱 뒤의 `gh`·`git commit`도 검사 대상이 됨(전엔 통과)
  - `tools/test-format-guard.sh` 32 → 34건(해당 사례 2건 추가)

### Added

- `.claude/hooks/progress-stale-check.sh`(SessionStart) 추가, PROGRESS §0 이 기기 행에 설치 버전이 없으면 알림([Issue #207](https://github.com/yanos0218/AI/issues/207))
  - 설치 뒤 기기 행 갱신 누락이 반복돼 문장 규칙 대신 기계 검사로 바꿈, 저장소 전용이라 버전 등급 미반영
  - `tools/test-progress-stale-check.sh` 11건, CI 설치 병합 시험 잡에서 세 운영체제 실행
- `tools/fingerprint.sh`에 `설치본` 줄([기기별]) 추가([Issue #203](https://github.com/yanos0218/AI/issues/203))
  - 저장소 현재 `base/` 해시와 설치 해시를 비교해 `최신`·`낡음(저장소 해시)`·`비교 못 함`을 표시함
  - 두 기기의 해시가 같아도 둘 다 낡은 경우를 잡음
  - `tools/test-install-merge.sh`에 11번 추가(4건), 전체 85건 통과
- `docs/testing.md`에 "훅 알림·경고 시험" 절 추가, 사본 저장소에서 `claude -p`로 SessionStart 알림과 PreToolUse 경고가 도착하는지 사용자 손 없이 확인하는 방법과 시험 전제(훅은 명령 실행 전에 돎, 설정은 세션 시작 때 고정)([Issue #199](https://github.com/yanos0218/AI/issues/199))
- `docs/os-differences.md` 추가, 같은 저장소를 Windows·Mac에서 쓸 때 공통·운영체제별(코드·설치)·기기별 항목을 구분한 표와 새 차이가 생겼을 때의 처리 순서([Issue #197](https://github.com/yanos0218/AI/issues/197))
- 저장소 `CLAUDE.md`가 `@docs/HANDOFF.md` import로 HANDOFF를 세션 시작 때 자동 로드([Issue #191](https://github.com/yanos0218/AI/issues/191), 저장소 전용이라 버전 등급 미반영)
  - 시험에서 로드를 확인했고 비용은 세션당 1,991 토큰, `tools/check-doc-sync.py`가 import 대상 파일이 있는지 검사
- `tools/check-doc-sync.py` 문서 갱신 누락 검사 추가, `tools/check-docs.sh`가 불러 CI와 커밋 전 검사에 적용([Issue #192](https://github.com/yanos0218/AI/issues/192))
  - 도구·훅·스킬·에이전트·문서가 README·operating-flow에 있는지, 문서 속 백틱 경로가 실제로 있는지, 훅·스킬·에이전트·권한 개수 표기가 맞는지 대조
  - 검사로 드러난 누락 2건(README의 `measure-model.sh`, `statusline.sh`)도 같이 고침
- 저장소 전용 훅 2개, 버전 등급 미반영
  - `handoff-stale-check.sh`(SessionStart), HANDOFF "지금" 절이 이미 닫힌 이슈를 가리키면 알림
  - `pre-commit-check.sh`에 `base/`·`tools/` 변경인데 CHANGELOG가 없으면 경고 추가(막지 않음, 예외는 커밋 본문 `Docs: 해당 없음(이유)`)
  - 새 세션 시험에서 경고가 화면에 안 보여, `additionalContext`(Claude 전용)에 `systemMessage`(사용자 화면)를 함께 내도록 수정([Issue #192](https://github.com/yanos0218/AI/issues/192))
  - 원인은 훅이 명령 실행 전에 돌아 `git add x && git commit`처럼 한 줄이면 add 전이라 스테이징 목록이 비어 경고·커밋 차단(markdownlint·shellcheck)이 통째로 빠지던 것, 명령에 `git add`가 있으면 수정된 추적 파일과 새 파일을, `commit -a`면 수정된 추적 파일을 대상으로 보게 수정
  - 한계: `git add 파일`이어도 다른 새 파일까지 검사해 무관한 새 `.md` 위반에 막힐 수 있고, 줄바꿈 규칙(크램) 검사는 스테이징분만 봄
- `base/hooks/format_check.py`가 `.md` 저장 때 새로 쓴 내용의 문장형 끝맺음(음슴체)도 검사([Issue #188](https://github.com/yanos0218/AI/issues/188))
  - 문장 끝이 `다`인 줄을 위반으로 보고 exit 2, 코드 블록·인용·백틱·제목 줄은 제외
  - 지침 문서(`CLAUDE.md`·`SKILL.md`·`AGENTS.md`, `.claude/`·`rules/`·`skills/`·`agents/`·`commands/`·`test-fixtures/` 아래)는 검사하지 않음
  - 저장소에 `.claude/no-eumseum-check`(빈 파일)를 두면 그 저장소는 끔
  - 표 줄은 셀 끝(`… 다 |`)과 `<br>` 조각도 검사
  - `tools/test-format-guard.sh` 34 → 43건, 기존 문장형 문서를 다시 쓰면 그 부분은 음슴체로 바꿔야 저장 검사를 통과함
- `base/settings.example.json`에 기본 모델·effort 고정 키 추가([Issue #187](https://github.com/yanos0218/AI/issues/187))
  - `model: claude-sonnet-5-5`, `effortLevel: medium`, Sonnet·Opus 5.5 `modelSettings` medium
  - `tools/install.sh`가 세 키를 설치마다 base 값으로 맞추고 `tools/check-install.sh`가 대조, `tools/fingerprint.sh`가 모델 환경변수 설정 여부 출력
  - 기존에 기기에서 `/model`로 바꿔 둔 값은 설치 때 되돌아옴
- `docs/models.md` 개발 작업 기본 모델·effort 기준 추가
- `docs/operating-flow.md`에 5층 구성 매핑 표 추가([Issue #185](https://github.com/yanos0218/AI/issues/185), 문서 전용이라 버전 등급 미반영)
- `tools/fingerprint.sh` 기기 지문 도구와 `docs/issue-format.md`의 반응 차이 사례 양식 추가([Issue #186](https://github.com/yanos0218/AI/issues/186), 저장소 도구·문서라 버전 등급 미반영)

### Fixed

- `base/vscode/install.sh`가 Windows 작업 폴더를 WSL로 읽을 때 확장 16개를 하나도 설치하지 못하던 것을 수정([Issue #208](https://github.com/yanos0218/AI/issues/208))
  - `extensions.txt`가 CRLF로 체크아웃돼 확장 ID 끝에 `\r`이 붙었고, 출력을 버려서 실패가 보이지 않았음
  - 스크립트가 읽을 때 CR을 지우고, `.gitattributes`에 `base/vscode/extensions.txt text eol=lf`를 추가함
  - 시험 `tools/test-install-merge.sh` 13번 추가
  - 설정 파일이 Remote - WSL 서버가 읽지 않는 `~/.config/Code/User`에 복사되는 문제는 이번 수정 범위 밖
- `base/vscode/install.sh`가 WSL에서 Windows VS Code(`/mnt/` 아래 `code`)를 잡아 확장을 Windows 쪽에 설치하고 `settings.json`을 Windows가 읽지 않는 WSL 홈에 복사하던 것을 수정([Issue #204](https://github.com/yanos0218/AI/issues/204))
  - 같은 조건이면 `base/vscode/install.ps1`과 WSL 쪽 `code` 안내를 내고 종료 코드 1로 멈춤, `tools/check-install.sh`의 안내 문구도 맞춤
  - 시험 `tools/test-install-merge.sh`에 12번 추가(7건, 가짜 `code`로 흉내), 실제 WSL에서의 확인은 사용자 기기에서 함
- `tools/check-install.sh`가 WSL에서 Windows VS Code를 잡아 확장 16개를 전부 MISSING으로 보고하고 실패로 끝나던 것을 수정([Issue #201](https://github.com/yanos0218/AI/issues/201))
  - WSL이고 `code`가 `/mnt/` 아래이면 MISSING 목록은 보이되 판정에서 빼고 안내 한 줄을 냄, WSL 안 `code`의 MISSING은 그대로 실패로 셈
  - 시험 `tools/test-install-merge.sh`에 7b 추가(가짜 `code`로 흉내), 실제 WSL에서의 확인은 사용자 기기에서 함
- 파이썬 3.6(RHEL 8 계열 기본)에서 한글 출력이 `UnicodeEncodeError`로 죽던 것을 수정([Issue #202](https://github.com/yanos0218/AI/issues/202))
  - `reconfigure`가 없으면 `io.TextIOWrapper`로 감싸도록 `tools/settings_merge.py`·`tools/fingerprint.sh`·`tools/check-doc-sync.py`를 고침
  - locale이 `C`이면 `install.sh`의 `settings.json` 병합이 실패했고 `fingerprint.sh`·`check-doc-sync.py`도 트레이스백으로 끝났음
  - 시험 `tools/test-install-merge.sh`에 6b(ASCII 출력) 추가, `docs/testing.md`에 3.6 규칙 추가
- `base/hooks/compact-snapshot.sh`가 파이썬 3.6에서 컴팩션 스냅샷의 "최근 테스트/빌드 명령" 절을 조용히 빠뜨리던 것을 수정([Issue #202](https://github.com/yanos0218/AI/issues/202))
  - 보호 없는 `reconfigure` 호출이 `AttributeError`로 죽었고 훅은 종료 코드 0이라 드러나지 않았음
  - 다른 훅처럼 `PYTHONIOENCODING=utf-8`을 지정하고 `reconfigure` 줄을 뺌, `tools/test-hooks-py.sh`에 시험 2건 추가
- `tools/check-doc-sync.py`가 Windows에서 스킬 폴더 이름을 빈 문자열로 읽던 것을 수정([Issue #200](https://github.com/yanos0218/AI/issues/200))
  - `_template`까지 세어 "스킬 7개로 적었는데 실제는 8개"로 실패했고, README 스킬 목록 누락 검사는 조용히 건너뛰고 있었음

## [0.14.0] - 2026-10-17

### Changed

- 전역 지침 `base/claude-md/CLAUDE.md`
  - §2에 큰 작업(커밋 여러 개, 릴리즈, 설계 제시) 끝 보고에서 문제·개선점·파생 문제·아이디어를 훑는 규칙 추가([Issue #169](https://github.com/yanos0218/AI/issues/169))
  - §4에 CI 대기는 `gh run watch`, 실행은 워크플로 이름과 전체 SHA로 고르는 규칙 추가([Issue #176](https://github.com/yanos0218/AI/issues/176))
  - 새 세션 전후 비교 2회씩, PATCH

### Added

- `tools/measure-model.sh`
  - 같은 읽기 전용 작업을 모델별로 `claude -p` 반복 실행해 구독 한도 소모(5시간·주간 %p)와 정답률을 비교하는 측정 도구, 시험 문서 `tools/test-fixtures/model-compare/`([Issue #178](https://github.com/yanos0218/AI/issues/178), 기본 영역 아님)
- `tools/install.sh`·`tools/check-install.sh`
  - 설치 끝에 PROGRESS §0 기기 행에 적을 버전(`git describe`)을 출력하고, `check-install.sh`가 그 행과 설치 버전 파일을 대조해 한 줄로 보고. PROGRESS 설치 버전 표기를 `git describe` 하나로 통일([Issue #180](https://github.com/yanos0218/AI/issues/180), 기본 영역 아님)

### Fixed

- `base/hooks/config_changelog.py`·`base/settings.example.json`
  - 보호 경로와 쓰기 명령이 명령 어디에든 따로 있기만 해도 기록하던 오탐 수정(133행 중 실제 쓰기 1행). 같은 명령 조각에서 쓰기 명령 뒤에 보호 경로가 있을 때만, 복사·이동은 목적지만 봄. `$HOME` 경로 인식 추가
  - Bash·PowerShell 등록에 `.claude`가 든 명령일 때만 뜨는 `if` 조건 추가(모든 명령마다 프로세스가 뜨던 것, [Issue #147](https://github.com/yanos0218/AI/issues/147))
  - [Issue #173](https://github.com/yanos0218/AI/issues/173), 시험 31/31, PATCH
- `base/hooks/check-cram.py`
  - 한 단어 필드명에 서술문이 아닌 한 문장 값이 붙은 필드-값 형식 줄과 큰따옴표 안 콜론을 크램으로 잡던 오탐 수정, 예외 목록 6줄 정리([Issue #175](https://github.com/yanos0218/AI/issues/175), 저장소 .md 2,564줄 판정 동일·시험 32/32, PATCH)
- `self-audit` 스킬 `references/method.md` 3절
  - 이슈 본문을 저장소 이슈 형식 문서 우선으로 쓰고, 없으면 배경/제안 내용/기대 효과/결정 헤딩. "근거 한 줄 + 이유"만 적어 이슈 형식 검사에 걸리던 문제([Issue #172](https://github.com/yanos0218/AI/issues/172), 새 세션 시험 2회, PATCH)
