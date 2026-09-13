# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).

## [Unreleased]

### Added

- `base/hooks/gh-throttle.sh` — `gh issue/pr/release/label`의 `create/comment/close/edit/reopen`, `gh api`의 POST/PATCH/PUT/DELETE 명령 앞에 1.5초 지연을 강제해 GitHub 2차 속도 제한(secondary rate limit)을 예방(MINOR — 새 훅 추가, [Issue #72](https://github.com/yanos0218/AI/issues/72)). 병렬 서브에이전트가 간격 없이 gh를 호출해 계정이 일시 차단된 인시던트([Issue #71](https://github.com/yanos0218/AI/issues/71)) 재발 방지
- `.claude/hooks/pre-commit-check.sh` — `base/` 또는 `docs/*.md` 규칙 문서를 바꾸는 커밋인데 메시지에 이슈 번호(`#숫자`)가 없으면 확인(`ask`)을 띄움. "착수 시점에 먼저 Issue부터 연다"는 CLAUDE.md 문장만으론 두 번(Issue #64, #66) 안 지켜져 훅으로 강제(버전 등급 미반영 — `.claude/` 전용)

### Changed

- 조사 기록 방식을 `docs/research/<주제>.md` 파일에서 GitHub Issue `research` 라벨로 전환(파일·이슈 이중 기록 방지). `base/claude-md/CLAUDE.md` §5, `docs/research.md` §3, README·monthly-check·review-vs-official 갱신. 2026-09-13 이전 기록은 `docs/research/`에 archive로 유지
- `base/hooks/git-guardrails.sh` — 하나의 정규식으로 뭉쳐 있던 매칭을 패턴별 if-elif로 나눠, 어떤 명령이 왜 되돌리기 어려운지 구체적인 이유를 보여주도록 개선(11개 패턴 전부 positive/negative 실행 확인, [Issue #65](https://github.com/yanos0218/AI/issues/65))
- `base/claude-md/CLAUDE.md` §3 — 확인 후 진행 항목 중 방법이 여럿인 경우 훅 확인 직전이 아니라 계획 단계에서 AskUserQuestion으로 먼저 확정하도록 규칙 추가([Issue #65](https://github.com/yanos0218/AI/issues/65))

## [0.8.0] - 2026-09-13

### Added

- `base/skills/self-audit/` — 대화 기록을 서브에이전트(Sonnet)로 읽어 CLAUDE.md·규칙 문서와 실제 작업 방식의 간극(반복 지적·안 지켜진 규칙·미문서화 결정)을 찾는 스킬(ykdojo `review-claudemd` 패턴 응용). 후보 제시까지만 자동, 문서 반영은 항상 사용자 확인 후. `tools/test-skill.sh` 3시나리오 발동 시험 통과("self-audit 해줘"·"이번 달 CLAUDE.md 점검해줘" 발동, "테스트 어떻게 해?" 오발동 안 함, 총 $1.37), 감사 표시 파일 쓰기는 작업 디렉터리 밖이라 매번 승인 필요함을 확인(정상, 2026-09-13)
- `base/hooks/session-start-check.sh` 세 번째 확인 — self-audit 표시 파일과 현재 세션 트랜스크립트 개수를 비교해 15개 이상 쌓이면 실행을 제안(실행은 여전히 사용자가 말할 때만). 4시나리오(마커 없음/미만/이상, 마커 있음/미만/이상) 직접 실행 확인

- `.claude/hooks/pre-commit-check.sh` — 이 저장소 전용 `PreToolUse` 훅. `git commit` 시도 시 `check-docs.sh`·markdownlint·shellcheck를 먼저 돌리고 실패하면 커밋을 막음(버전 등급 미반영 — `.claude/` 전용)
- `CLAUDE.md` "새 기본 영역 자산(훅·스킬·설정 키)은 구현 전에 설계를 채팅에 제시하고 승인받은 뒤 만든다"는 규칙(버전 등급 미반영)

### Changed

- `base/hooks/*.sh`, `base/vscode/install.sh`, `.claude/hooks/*.sh`, `tools/*.sh` 13개 스크립트 전부 `${var}`·`[[ ]]` 스타일로 통일. 기존엔 신규 스크립트 2개만 이 스타일이었으나 사용자 요청으로 전체 확대(shellcheck `-S warning` 기준 실제 위험은 이전부터 0건, `--enable=all`로 잡히는 스타일 항목만 정리, 2026-09-13)

## [0.7.0] - 2026-09-13

### Added

- `base/claude-md/CLAUDE.md` §7 — 복합 명령에서 `cd <경로> && <명령>` 대신 `git -C <경로>`나 절대 경로를 쓴다는 한 줄. `Read` deny 규칙과 겹쳐 정적 분석이 안 돼 승인 프롬프트가 뜨던 문제([Issue #1](https://github.com/yanos0218/AI/issues/1))
- `base/hooks/session-start-check.sh` — 전역 `SessionStart` 훅(matcher `startup`). 새 세션마다 읽기 전용으로 두 가지를 조용히 확인: (1) 지금 저장소에 `CLAUDE.md`가 없고 `.claude/.no-repo-setup-suggest`도 없으면 repo-setup 제안을 상기시킴, (2) `~/.claude/.claude-config-version`에 적힌 버전이 원본 저장소 최신과 다르면 재설치를 상기시킴. 4개 시나리오(표준 없음/있음/억제 표시/버전 낡음) 직접 실행 확인([Issue #62](https://github.com/yanos0218/AI/issues/62))
- `tools/install.sh` — 설치할 때마다 `~/.claude/.claude-config-version`에 원본 경로+버전을 기록(위 훅이 읽음)
- `base/claude-md/CLAUDE.md` §5 — 저장소 표준 제안을 거절하면 `.claude/.no-repo-setup-suggest`를 만들어 다음부턴 묻지 않는다는 한 줄

### Fixed

- `base/vscode/install.sh` — `code`가 PATH에 없어도 Mac 앱 내장 경로(`/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code`)로 폴백. 코드만 반영, Mac에서의 실제 동작 확인은 다음 Mac 세션([Issue #57](https://github.com/yanos0218/AI/issues/57))

### Changed

- `base/skills/repo-setup/references/checklist.md` 항목 5·6 — Issues 판정 기준을 "개인용은 문제+할 일 통합(`bug`/`task`), 팀·협업은 별도 조사"로, 진행 보드 항목 6을 "할 일을 Issue로 관리하면 배포 표만 있어도 됨"으로 수정([Issue #11](https://github.com/yanos0218/AI/issues/11), 2026-09-12)

## [0.6.0] - 2026-09-09

### Added

- `base/skills/repo-setup/` — 저장소가 최소 표준(`docs/repo-standard.md` 9항목)을 갖췄는지 대조하고 빠진 것을 제안표로 보인 뒤 사용자가 고른 것만 만드는 스킬. 비밀 파일 이력 검사를 §0에 둠. 3시나리오 발동 시험 통과(기록 [Issue #56](https://github.com/yanos0218/AI/issues/56))

### Changed

- README 구조 표에 dev-workflow·repo-setup 행 추가

## [0.5.0] - 2026-09-09

기존 기기는 `bash tools/install.sh`로 재설치(지침 §2·§5·§7, dev-release 0단계, rules 모듈, 권한 12개). Windows는 §7·dev-release 0단계가 아직 없음.

### Added

- `base/rules/docs-format.md` — 첫 모듈 규칙(문서 형식). `tools/install.sh`가 `~/.claude/rules/`에 설치
- `base/skills/dev-workflow/` — 저장소의 파일·폴더 구조와 테스트 방법을 정하고, 작업 뒤 테스트 실행 증거를 보고하는 스킬. 발동 문구 7개, references 2개. 3시나리오 발동 시험 통과(기록 [Issue #45](https://github.com/yanos0218/AI/issues/45))

### Changed

- `base/claude-md/CLAUDE.md` §7 — 토큰이 필요하면 `gh auth status`로 먼저 확인, 없으면 멈추고 사용자가 직접 넣게 안내, 채팅에 붙여넣으라고 하지 않는다(C-53, 2026-09-09 토큰 노출 사고 근거)
- `base/skills/dev-release/` — 체크리스트 0단계 `gh auth status`, `references/release-steps.md` 명령 순서 맨 앞에 자격증명 확인. 미인증 시나리오 발동 시험 통과([Issue #15](https://github.com/yanos0218/AI/issues/15))
- `tools/check-install.sh` — VS Code 확장을 `base/vscode/extensions.txt`와 대조해 빠진 것을 MISSING으로 보고(목록 밖 확장은 개수만). Mac은 `code`가 PATH에 없으면 앱 내장 경로 사용
- `base/settings.example.json` — allow에 검사·조회 명령 12개 추가(`python -m py_compile`, `npx markdownlint-cli2`, `npx shellcheck`, `bash -n`, `gh issue list/view`, `gh run view/watch`, `cat`, `head`, `wc`, `grep`)
- `base/skills/dev-release/SKILL.md` — `allowed-tools`로 읽기 전용 git·gh 명령 사전 승인
- `base/claude-md/CLAUDE.md` §5 — 조사 규칙(공식 우선·날짜·직접 실행 검증·출처·`docs/research/`)과 "서브에이전트·시험 세션은 Sonnet"
- `base/claude-md/CLAUDE.md` §2 — "정의된 규칙에서 스스로 벗어나지 않는다. 벗어나야 하면 근거 → 제안 → 승인 → 규칙 문서 먼저" 한 줄 추가

### Fixed

- `tools/test-skill.sh` — `--tools`를 공백으로 쪼개 넘겨 `Bash(gh *)` 같은 규칙이 깨졌음 → 쉼표 구분·배열 전달. 같은 이름 스킬이 `~/.claude/skills/`에 있으면 설치본이 초안을 가리므로 시험 동안 `~/.claude/skill-test-aside/`로 비켜 둠([#3](https://github.com/yanos0218/AI/issues/3))
- `tools/install.sh`·`check-install.sh`·`test-skill.sh`·`pack.sh` — `python3`를 먼저 찾고 없을 때 `python`. Mac/Linux엔 `python`이 없어 settings.json 병합이 조용히 건너뛰어졌음(Mac 반영 중 발견)

## [0.4.0] - 2026-09-09

### Added

- `base/hooks/config-changelog.sh` — PostToolUse 훅. Claude가 `~/.claude`의 CLAUDE.md·settings*.json·rules/·hooks/를 편집하면 `~/.claude/config-changelog.md`에 시각·도구·대상·작업 폴더를 기록(막지 않음). `base/settings.example.json`의 `hooks.PostToolUse`에 등록
- `tools/check-install.sh` — 설치본↔`base/` 대조, `rules/`·프로젝트 로컬 권한·변경 이력 보고

## [0.3.0] - 2026-09-08

설치 경로가 바뀌었다. 재설치 명령은 `docs/install.md`.

### Changed

- 기본 영역을 `base/` 한 폴더로 모음 — `claude-md/`→`base/claude-md/`, `skills/`→`base/skills/`, `scripts/hooks/`→`base/hooks/`, `scripts/settings.example.json`→`base/settings.example.json`, `vscode/`→`base/vscode/`
- 도구를 `tools/`로 — `scripts/pack.sh`→`tools/pack.sh`, `.github/scripts/check-docs.sh`→`tools/check-docs.sh`
- `baseline-guard.sh`가 `base/` 접두사 하나로 판단

### Fixed

- `tools/pack.sh` — `zip`이 없는 환경(Windows Git Bash)에서 python zipfile로 폴백 (C-29)

## [0.2.0] - 2026-09-08

확인 기준이 바뀌었으므로 기기마다 `claude-md/CLAUDE.md`를 다시 설치해야 한다.

### Changed

- `claude-md/CLAUDE.md` §3 — 작업 단위가 끝난 로컬 커밋은 묻지 않고 한다. 배치 = 사용자 메시지 하나, "진행해줘"처럼 끝을 지정하면 그 끝까지 재확인하지 않는다. 외부 서비스 쓰기에 저장소 설정 변경 포함
- `claude-md/CLAUDE.md` §5 — GitHub 저장소가 저장소 표준(`docs/repo-standard.md`)에 미달하면 세션당 한 번만 제안
- `claude-md/CLAUDE.md` §7 — "커밋은 요청할 때만" → "작업 단위마다"

## [0.1.0] - 2026-09-08

첫 릴리즈. Windows에만 설치된 상태.

### Added

- 전역 공통 지침 `claude-md/CLAUDE.md` — 언어·답변·확인 기준·검증·컨텍스트·문서 동기화·Git·코드 8개 절
- `skills/dev-release/` — SemVer 등급 판단 + 릴리즈 컷 절차, references 3개. 새 세션 3시나리오 발동 테스트 통과
- `scripts/hooks/git-guardrails.sh` — push·reset --hard·clean -f·--no-verify·publish 등 앞에서 확인 프롬프트 강제
- `scripts/hooks/statusline.sh` — 모델·브랜치·컨텍스트 사용률·비용 상태줄
- `scripts/settings.example.json` — 권한 allow/deny, 훅, 상태줄 예시
- `scripts/pack.sh` — 스킬을 웹 업로드용 zip으로
- `vscode/` — 선별 확장 13개 목록, 설정 스냅샷, 설치 스크립트(Windows·Mac/Linux)
- `skills/_template/` — 새 스킬 틀
- 저장소 운영: `docs/HANDOFF.md`(인수인계), `docs/PROGRESS.md`(자산 현황표 + `C-NN` 보드), `CLAUDE.md`(기본/작업 영역 규칙), `drafts/`(승격 전 초안), `.claude/hooks/baseline-guard.sh`(기본 영역 쓰기 확인 강제)
- README — 표면별 적용 범위, 설치, 공식 문서 대비 검토표, GitHub 활용 선택지

[Unreleased]: https://github.com/yanos0218/AI/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/yanos0218/AI/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/yanos0218/AI/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/yanos0218/AI/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/yanos0218/AI/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yanos0218/AI/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yanos0218/AI/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yanos0218/AI/releases/tag/v0.1.0
