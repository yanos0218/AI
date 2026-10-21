# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Changed

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
  - 기존에 기기에서 `/model`로 바꿔 둔 값은 설치 때 되돌아옴, 다음 컷에서 MINOR 후보
- `docs/models.md` 개발 작업 기본 모델·effort 기준 추가
- `docs/operating-flow.md`에 5층 구성 매핑 표 추가([Issue #185](https://github.com/yanos0218/AI/issues/185), 문서 전용이라 버전 등급 미반영)
- `tools/fingerprint.sh` 기기 지문 도구와 `docs/issue-format.md`의 반응 차이 사례 양식 추가([Issue #186](https://github.com/yanos0218/AI/issues/186), 저장소 도구·문서라 버전 등급 미반영)

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

## [0.13.1] - 2026-10-07

### Changed

- `base/claude-md/CLAUDE.md` §1·§2
  - 도구 호출 앞뒤 진행 설명도 한국어, 첫 설명부터 결론 뒤 비유·예시 하나(2026-10-07 self-audit, PATCH)
- `docs/issue-format.md` 공통 절
  - 이슈 본문·코멘트에 체크박스를 쓰지 않는 규칙 명시([Issue #171](https://github.com/yanos0218/AI/issues/171), 버전 등급 미반영, 문서 전용)
- `base/claude-md/CLAUDE.md` §4
  - 검사 결과는 실제로 검사한 대상 수까지 읽고, 0건이거나 실제와 맞지 않으면 "미검증"으로 보는 규칙 추가. 0줄로 세고 ok를 찍는 검사에서 반영 전 2회 모두 "통과" 보고, 반영 후 2회 모두 문제를 짚음([Issue #167](https://github.com/yanos0218/AI/issues/167), PATCH)
- `CLAUDE.md` 검증 절
  - `docs/testing.md`로 분리(60/60 → 57줄), 시험 도구 목록·세 OS 호환 규칙·설치는 커밋 뒤 추가, `docs/skill-development.md`에 Mac 시험 준비 추가([Issue #166](https://github.com/yanos0218/AI/issues/166), 버전 등급 미반영 — 문서 전용)

## [0.13.0] - 2026-09-29

### Added

- `base/hooks/format-guard.sh`·`md-format-check.sh`·`format_check.py` 형식 검사 훅 승격
  - 커밋·이슈·PR·릴리즈 본문을 게시 직전에 검사해 목록 줄바꿈·음슴체 위반이면 막고, `.md`에 새로 쓴 부분은 저장 뒤 사유를 돌려줌. `settings.example.json`에 `git`·`gh` 명령과 `.md` 편집일 때만 뜨게 등록, 같은 호출 중복 실행 방지([Issue #141](https://github.com/yanos0218/AI/issues/141), MINOR)
- `tools/test-format-guard.sh`
  - 형식 검사 훅 시험 32건, `drafts/hooks/`에서 옮김([Issue #141](https://github.com/yanos0218/AI/issues/141), PATCH)
- `base/skills/usage-dashboard` 스킬 승격
  - 요청할 때만 켜는 토큰 사용 기록과 로컬 대시보드(5시간 블록·시간·일·월, 저장소·메인/서브에이전트·모델별, 요청 순위와 원인). 세션 시작 크기가 평소보다 커지면 화면에만 강조, 세션 시작 알림(`usage.sh check`)은 뺌(사용자 결정, 대시보드와 중복·세션 시작 지연). `settings.example.json`에 async Stop 훅 등록, 꺼져 있으면 훅은 바로 끝남. Windows·Mac 전용([Issue #136](https://github.com/yanos0218/AI/issues/136), MINOR)
- `tools/test-session-start-check.sh`
  - 세션 시작 훅의 설정 낡음 판정 시험. 임시 원격·복제본·가짜 HOME으로 원격 앞섬, 문서만 바뀐 커밋, 옛 버전 파일 형식, fetch 주기와 기다리지 않음을 확인([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)

### Changed

- `base/claude-md/CLAUDE.md` §8
  - 설계를 보일 때 채울 칸(무엇을·왜, 바뀌는 파일, 검증 방법, 문서 동기화 대상, 결정 필요) 추가. 새 세션 비교에서 반영 전 2회 모두 검증·문서 칸 없음, 반영 후 2회 모두 채움([Issue #155](https://github.com/yanos0218/AI/issues/155), PATCH)
- `base/vscode/extensions.txt`
  - `redhat.vscode-yaml`·`timonwong.shellcheck` 추가(설정 파일 없이 동작, CI와 같은 기준), 파일 아이콘 `pkief.material-icon-theme` 추가와 `settings.json`에 아이콘 테마 지정, Mac에서 쓰지 않는 Swift 확장 주석 삭제([Issue #165](https://github.com/yanos0218/AI/issues/165), PATCH)
- `base/hooks/check-cram.py`
  - 목록 줄바꿈 판정기를 `tools/`에서 옮김, 전역 형식 검사 훅과 저장소 커밋 검사(`tools/check-cram.sh`)가 같은 판정기를 씀([Issue #141](https://github.com/yanos0218/AI/issues/141), PATCH)
- `.github/workflows/lint.yml`
  - shellcheck 대상에 `base/skills/*/scripts/*.sh`와 `drafts/hooks/*.sh` 추가, 초안 폴더가 비어도 실패하지 않게 빈 글롭은 건너뜀(`nullglob`), 로컬 같은 대상 경고 0건([Issue #161](https://github.com/yanos0218/AI/issues/161), PATCH)
- `tools/install.sh`
  - 버전 표시 파일 3행에 `base/` 트리 해시를 기록함. 1·2행은 그대로라 기존 세션 시작 훅과 호환, 문서만 바뀐 커밋을 설정 변경과 구별하는 데 씀([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)

### Fixed

- `.claude/hooks/session-end-check.sh`
  - 공백·이름 바뀐 파일의 경로를 일부만 읽어 `base/` 변경을 놓치던 문제와, 규칙과 반대로 "닫기(Closes #N)"를 안내하던 문구. 경로 전체와 옛·새 경로를 읽고 `Refs #N` 안내로 바꿈([Issue #163](https://github.com/yanos0218/AI/issues/163), PATCH)
- `tools/test-skill.sh`·`tools/test-agent.sh`
  - `--tools ""`처럼 빈 값이면 Mac bash 3.2에서 `tool_rules` 빈 배열로 멈추던 문제, 빈 배열 안전하게 펼침([Issue #162](https://github.com/yanos0218/AI/issues/162), PATCH)
- `base/hooks/session-start-check.sh`
  - 원본 저장소가 원격보다 뒤처져도 낡음 알림이 안 뜨던 문제와, 문서만 바뀐 커밋에도 알림이 뜨던 거짓 경보. 하루 한 번 백그라운드 fetch, 뒤처지면 원격 기준, `base/` 트리 해시로 비교(옛 설치본은 태그 비교)([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)
- `base/skills/config-update`
  - 원격을 확인하지 않아 낡은 버전을 최신으로 판정하던 문제. fetch → 뒤처졌고 작업 트리가 깨끗하면 `pull --ff-only` → `base/` 트리 비교 → 다를 때만 설치([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)
- `.claude/hooks/pre-commit-check.sh`
  - 명령을 `sed`로 꺼내며 뒤의 설명 글까지 삼켜, 설명에 "#64"·"chore(release):"가 있으면 이슈 번호 확인을 건너뛰고 커밋이 아닌 명령에 확인 창을 띄우던 문제. JSON으로 정확히 꺼냄([Issue #156](https://github.com/yanos0218/AI/issues/156), PATCH)
- `tools/check-install.sh`
  - 프로젝트 루트 기본값이 Windows 전용(`/c/Git`)이라 Mac·Linux에서 조용히 "(없음)"이던 문제. 기본값을 이 저장소의 상위 폴더로, 경로가 없으면 안내([Issue #157](https://github.com/yanos0218/AI/issues/157), PATCH)
- `tools/test-session-start-check.sh`
  - 실제 v0.12.0 태그에 기대 `base/`가 바뀐 뒤 "문서만 바뀐 커밋" 사례가 건너뛰어지던 문제. 시험 안에서 태그와 문서 커밋을 만들어 15건 모두 실행([Issue #158](https://github.com/yanos0218/AI/issues/158), PATCH)
- `tools/check-install.sh`·`tools/install.sh`·`tools/pack.sh`
  - 스킬 폴더의 파이썬 캐시(`__pycache__`)까지 비교·복사·압축해 거짓 `DIFF`가 나고 설치본·웹 zip에 캐시가 섞이던 문제. 세 곳 모두 제외([Issue #160](https://github.com/yanos0218/AI/issues/160), PATCH)
- `tools/check-docs.sh`
  - Mac 기본 bash 3.2에 없는 `mapfile` 때문에 모든 파일을 0줄로 세고 통과시키던 문제, 하위 프로세스 없는 내장 `read`로 줄 수를 세도록 바꿈([Issue #151](https://github.com/yanos0218/AI/issues/151), PATCH)
- `tools/test-hooks-py.sh`
  - `python` 명령을 고정으로 불러 `python3`만 있는 Mac에서 7건이 실패하던 문제, 훅과 같은 순서(`python` → `python3`)로 고르도록 바꿈([Issue #151](https://github.com/yanos0218/AI/issues/151), PATCH)
- `tools/test-skill.sh`
  - 시험 중 스킬이 자신을 다시 설치하면(config-update) 끝날 때 비켜 둔 설치본이 새 폴더 안으로 들어가 이중 폴더가 생기던 문제. 복구 전에 대상 폴더를 치움([Issue #152](https://github.com/yanos0218/AI/issues/152), PATCH)
- `tools/test-agent.sh`
  - Mac에서 PyYAML이 없으면 변환 실패를 무시하고 세션을 띄워 "토큰 0"만 나오던 문제와, `--installed`에서 bash 3.2가 빈 배열로 멈추던 문제. 변환 실패 시 안내 후 종료, 빈 배열 안전하게 펼침([Issue #154](https://github.com/yanos0218/AI/issues/154), PATCH)
- `tools/check-cram.sh`
  - `--staged`에서 추가된 줄 번호 목록을 `awk -v`로 넘겨, Mac 기본 awk가 오류를 내고 여러 줄을 추가한 파일을 건너뛰어 통과시키던 문제. 환경변수로 넘기도록 바꿈([Issue #151](https://github.com/yanos0218/AI/issues/151), PATCH)
