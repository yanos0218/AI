# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).

## [Unreleased]

### Added

- `base/rules/docs-format.md` — 첫 모듈 규칙(문서 형식). `tools/install.sh`가 `~/.claude/rules/`에 설치
- `base/skills/dev-workflow/` — 저장소의 파일·폴더 구조와 테스트 방법을 정하고, 작업 뒤 테스트 실행 증거를 보고하는 스킬. 발동 문구 7개, references 2개. 3시나리오 발동 시험 통과(기록 `docs/progress/C-13.md`)

### Changed

- `tools/check-install.sh` — VS Code 확장을 `base/vscode/extensions.txt`와 대조해 빠진 것을 MISSING으로 보고(목록 밖 확장은 개수만). Mac은 `code`가 PATH에 없으면 앱 내장 경로 사용
- `base/settings.example.json` — allow에 검사·조회 명령 12개 추가(`python -m py_compile`, `npx markdownlint-cli2`, `npx shellcheck`, `bash -n`, `gh issue list/view`, `gh run view/watch`, `cat`, `head`, `wc`, `grep`)
- `base/skills/dev-release/SKILL.md` — `allowed-tools`로 읽기 전용 git·gh 명령 사전 승인
- `base/claude-md/CLAUDE.md` §5 — 조사 규칙(공식 우선·날짜·직접 실행 검증·출처·`docs/research/`)과 "서브에이전트·시험 세션은 Sonnet"
- `base/claude-md/CLAUDE.md` §2 — "정의된 규칙에서 스스로 벗어나지 않는다. 벗어나야 하면 근거 → 제안 → 승인 → 규칙 문서 먼저" 한 줄 추가

### Fixed

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

[Unreleased]: https://github.com/yanos0218/AI/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/yanos0218/AI/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yanos0218/AI/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yanos0218/AI/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yanos0218/AI/releases/tag/v0.1.0
