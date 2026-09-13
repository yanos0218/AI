# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

## [0.9.0] - 2026-09-13

### Added

- `base/hooks/gh-throttle.sh` — mkdir 락 + 공유 타임스탬프로 gh 콘텐츠 생성 명령을 실제 직렬화(최소 2초 간격)해 GitHub 2차 속도 제한 예방(MINOR — 새 훅 추가)
  - 대상: `gh issue/pr/release/label`의 `create/comment/close/edit/reopen`, `gh api`의 POST/PATCH/PUT/DELETE
  - 병렬 서브에이전트가 간격 없이 gh를 호출해 계정이 일시 차단된 인시던트([Issue #71](https://github.com/yanos0218/AI/issues/71)) 재발 방지
  - 병렬 3개 실측으로 순차 처리 확인
- `base/settings.example.json` — `env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH: "1"` 추가해 서브에이전트의 재귀적 하위 서브에이전트 생성을 전역 차단(MINOR — 새 설정 키 추가)
  - 공식 문서 확인 + 실제 새 세션에서 재귀 시도 시 `Agent is disabled ... in subagents as well as here` 오류·`spawned_by_subagents: 0` 실측 확인
  - `tools/install.sh`·`tools/check-install.sh`에 `env` 키 병합·대조 추가
- `.claude/hooks/pre-commit-check.sh` — `base/` 또는 `docs/*.md` 규칙 문서를 바꾸는 커밋인데 메시지에 이슈 번호(`#숫자`)가 없으면 확인(`ask`)을 띄움
  - "착수 시점에 먼저 Issue부터 연다"는 CLAUDE.md 문장만으론 두 번(Issue #64, #66) 안 지켜져 훅으로 강제
  - 버전 등급 미반영 — `.claude/` 전용

### Changed

- 조사 기록 방식을 `docs/research/<주제>.md` 파일에서 GitHub Issue `research` 라벨로 전환(파일·이슈 이중 기록 방지)
  - `base/claude-md/CLAUDE.md` §5, `docs/research.md` §3, README·monthly-check·review-vs-official 갱신
  - 2026-09-13 이전 기록은 `docs/research/`에 archive로 유지
- `base/hooks/git-guardrails.sh` — 하나의 정규식으로 뭉쳐 있던 매칭을 패턴별 if-elif로 나눠 구체적인 이유를 보여주도록 개선
  - 명령을 스크립트 파일로 감싸(`bash x.sh`) 문자열 매칭을 우회하던 취약점도 보강해 스크립트 내용까지 같이 검사
  - 11개 패턴·우회/회귀 시나리오 전부 직접 실행 확인([Issue #65](https://github.com/yanos0218/AI/issues/65)·[Issue #73](https://github.com/yanos0218/AI/issues/73))
- `.claude/hooks/pre-commit-check.sh` — 위와 같은 스크립트 감싸기 우회 취약점 보강([Issue #73](https://github.com/yanos0218/AI/issues/73))
- `base/claude-md/CLAUDE.md` §3 — 확인 후 진행 항목 중 방법이 여럿인 경우 훅 확인 직전이 아니라 계획 단계에서 AskUserQuestion으로 먼저 확정하도록 규칙 추가([Issue #65](https://github.com/yanos0218/AI/issues/65))
- `base/claude-md/CLAUDE.md` §5 — 서브에이전트 위임 습관 2건 추가
  - 정지시킨 서브에이전트의 뒤늦은 보고는 검증 없이 반영하지 않기
  - 병렬 위임 시 겹치지 않는 파일 배정([Issue #74](https://github.com/yanos0218/AI/issues/74))
- `CHANGELOG.md` 보존 범위를 최근 3개 릴리즈로 축소(버전 등급 미반영 — 문서 전용, [Issue #76](https://github.com/yanos0218/AI/issues/76))

## [0.8.0] - 2026-09-13

### Added

- `base/skills/self-audit/` — 대화 기록을 서브에이전트(Sonnet)로 읽어 CLAUDE.md·규칙 문서와 실제 작업 방식의 간극(반복 지적·안 지켜진 규칙·미문서화 결정)을 찾는 스킬(ykdojo `review-claudemd` 패턴 응용)
  - 후보 제시까지만 자동, 문서 반영은 항상 사용자 확인 후
  - `tools/test-skill.sh` 3시나리오 발동 시험 통과("self-audit 해줘"·"이번 달 CLAUDE.md 점검해줘" 발동, "테스트 어떻게 해?" 오발동 안 함, 총 $1.37)
  - 감사 표시 파일 쓰기는 작업 디렉터리 밖이라 매번 승인 필요함을 확인(정상, 2026-09-13)
- `base/hooks/session-start-check.sh` 세 번째 확인 — self-audit 표시 파일과 현재 세션 트랜스크립트 개수를 비교해 15개 이상 쌓이면 실행을 제안(실행은 여전히 사용자가 말할 때만)
  - 4시나리오(마커 없음/미만/이상, 마커 있음/미만/이상) 직접 실행 확인
- `.claude/hooks/pre-commit-check.sh` — 이 저장소 전용 `PreToolUse` 훅. `git commit` 시도 시 `check-docs.sh`·markdownlint·shellcheck를 먼저 돌리고 실패하면 커밋을 막음(버전 등급 미반영 — `.claude/` 전용)
- `CLAUDE.md` "새 기본 영역 자산(훅·스킬·설정 키)은 구현 전에 설계를 채팅에 제시하고 승인받은 뒤 만든다"는 규칙(버전 등급 미반영)

### Changed

- `base/hooks/*.sh`, `base/vscode/install.sh`, `.claude/hooks/*.sh`, `tools/*.sh` 13개 스크립트 전부 `${var}`·`[[ ]]` 스타일로 통일
  - 기존엔 신규 스크립트 2개만 이 스타일이었으나 사용자 요청으로 전체 확대
  - shellcheck `-S warning` 기준 실제 위험은 이전부터 0건, `--enable=all`로 잡히는 스타일 항목만 정리(2026-09-13)

## [0.7.0] - 2026-09-13

### Added

- `base/claude-md/CLAUDE.md` §7 — 복합 명령에서 `cd <경로> && <명령>` 대신 `git -C <경로>`나 절대 경로를 쓴다는 한 줄
  - `Read` deny 규칙과 겹쳐 정적 분석이 안 돼 승인 프롬프트가 뜨던 문제([Issue #1](https://github.com/yanos0218/AI/issues/1))
- `base/hooks/session-start-check.sh` — 전역 `SessionStart` 훅(matcher `startup`)
  - 새 세션마다 읽기 전용으로 두 가지를 조용히 확인: (1) 지금 저장소에 `CLAUDE.md`가 없고 `.claude/.no-repo-setup-suggest`도 없으면 repo-setup 제안을 상기시킴, (2) `~/.claude/.claude-config-version`에 적힌 버전이 원본 저장소 최신과 다르면 재설치를 상기시킴
  - 4개 시나리오(표준 없음/있음/억제 표시/버전 낡음) 직접 실행 확인([Issue #62](https://github.com/yanos0218/AI/issues/62))
- `tools/install.sh` — 설치할 때마다 `~/.claude/.claude-config-version`에 원본 경로+버전을 기록(위 훅이 읽음)
- `base/claude-md/CLAUDE.md` §5 — 저장소 표준 제안을 거절하면 `.claude/.no-repo-setup-suggest`를 만들어 다음부턴 묻지 않는다는 한 줄

### Fixed

- `base/vscode/install.sh` — `code`가 PATH에 없어도 Mac 앱 내장 경로(`/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code`)로 폴백
  - 코드만 반영, Mac에서의 실제 동작 확인은 다음 Mac 세션([Issue #57](https://github.com/yanos0218/AI/issues/57))

### Changed

- `base/skills/repo-setup/references/checklist.md` 항목 5·6 — Issues 판정 기준을 "개인용은 문제+할 일 통합(`bug`/`task`), 팀·협업은 별도 조사"로, 진행 보드 항목 6을 "할 일을 Issue로 관리하면 배포 표만 있어도 됨"으로 수정
  - [Issue #11](https://github.com/yanos0218/AI/issues/11), 2026-09-12

[Unreleased]: https://github.com/yanos0218/AI/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/yanos0218/AI/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/yanos0218/AI/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/yanos0218/AI/compare/v0.6.0...v0.7.0
