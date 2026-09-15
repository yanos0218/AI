# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Changed

- `base/rules/docs-format.md`
  - 목록 줄바꿈 규칙을 "길어지면"에서 "길이 무관 항상 분리"로 강화, 표 셀은 `<br>`로([Issue #86](https://github.com/yanos0218/AI/issues/86)·[Issue #87](https://github.com/yanos0218/AI/issues/87))
  - "필드명: 값" 구조화된 기록(조사 이슈 등)은 예외로 유지
- `.markdownlint.jsonc`
  - MD033 allowed_elements에 `br` 추가(표 셀 줄바꿈 허용, [Issue #87](https://github.com/yanos0218/AI/issues/87))
- 강화된 규칙을 로컬 `.md` 파일 전체와 GitHub Issue 본문 10개에 소급 적용
  - `.md` 파일: [Issue #88](https://github.com/yanos0218/AI/issues/88)·[Issue #89](https://github.com/yanos0218/AI/issues/89)·[Issue #90](https://github.com/yanos0218/AI/issues/90)
  - GitHub Issue 본문(#58, #60, #62, #63, #71, #75, #79, #81, #83, #88): [Issue #91](https://github.com/yanos0218/AI/issues/91)
- `base/rules/docs-format.md`
  - `—`뿐 아니라 `:`(콜론) 기반 "라벨: 설명" 크램도 같은 기준으로 대상에 포함, 나열 도입 콜론("형식: A, B, C")은 예외로 명시([Issue #93](https://github.com/yanos0218/AI/issues/93))
  - 적용 범위를 "`.md` 파일 → Issue·PR 본문 → Release 노트"처럼 하나씩 나열하며 매번 뭔가 빠뜨리던 것을, "Claude가 쓰는 텍스트 전부가 기본값"인 포괄형으로 변경(댓글·닫을 때 코멘트 포함, [Issue #95](https://github.com/yanos0218/AI/issues/95)·[Issue #96](https://github.com/yanos0218/AI/issues/96))
- 콜론 기반 규칙을 로컬 `.md` 파일 전체·GitHub Issue 본문 40건·댓글 17건에 소급 적용([Issue #93](https://github.com/yanos0218/AI/issues/93)·[Issue #97](https://github.com/yanos0218/AI/issues/97))
- 저장소 전체 재검색으로 놓친 크램 추가 발견·수정: `drafts/observations/*.md`, `docs/github.md`(목록 항목이 아니라 문단 크램), `docs/issue-format.md` 자기모순 1건([Issue #98](https://github.com/yanos0218/AI/issues/98))

### Added

- `docs/issue-format.md`
  - 이슈 라벨별 작성 형식 4종(개발/버그·에러/조사/제안) 정의
  - `error` 라벨 신설(`bug`와 구분, [Issue #83](https://github.com/yanos0218/AI/issues/83))
  - "이슈 수명 관리" 절 추가: 하나의 목표는 이슈 하나로 유지, 파생 작업은 sub-issue로 연결([Issue #92](https://github.com/yanos0218/AI/issues/92))
  - 이슈 제목은 마크다운을 렌더링하지 않으니 기호 없이 쓴다는 규칙 추가([Issue #95](https://github.com/yanos0218/AI/issues/95))
  - git 훅이 못 보는 GitHub 댓글·릴리즈 노트는 `tools/check-cram.sh`를 수동으로 돌리라는 절 추가([Issue #99](https://github.com/yanos0218/AI/issues/99))
- `docs/research.md` §3
  - 조사 이슈 형식을 "다시 볼 시점" 대신 "조사일"+"출처"로 변경(버전 등급 미반영 — `docs/` 전용, [Issue #84](https://github.com/yanos0218/AI/issues/84))
- `docs/monthly-check.md`
  - 파생 관계인데 sub-issue로 안 묶인 것 없는지 점검하는 항목 추가([Issue #94](https://github.com/yanos0218/AI/issues/94))
  - 크램 검사 예외 목록을 검토해 휴리스틱에 반영하는 항목 추가([Issue #99](https://github.com/yanos0218/AI/issues/99))
- `tools/check-cram.sh`·`tools/check-cram.py`
  - 목록 줄바꿈 규칙(콜론·em-dash 크램) 자동 검사 도구 신설. `--staged`로 커밋 전 자동 검사, `--add-exception`으로 오탐 예외 등록
  - `.claude/hooks/pre-commit-check.sh`에 연결해 스테이징된 `.md`의 크램을 커밋 차단(deny)([Issue #99](https://github.com/yanos0218/AI/issues/99))
  - 라벨이 백틱·볼드로 감싼 파일명·기능명이면 길이 무관하게 항상 검출하도록 보완(일반 텍스트 필드명 라벨만 길이로 관대하게, [Issue #99](https://github.com/yanos0218/AI/issues/99))
- `base/hooks/bulk-read-log.sh`(PostToolUse)
  - 대량 조회로 보이는 명령(`gh issue list --json body/comments`, 큰 `--limit` 등)을 `~/.claude/bulk-read-log.md`에 조용히 기록
  - PreToolUse/PostToolUse가 매 호출마다 Claude에게 실시간으로 알리는 건 기술적으로 안 됨을 실제 세션 3개로 확인하고 채택한 대안([Issue #100](https://github.com/yanos0218/AI/issues/100))
- `base/hooks/session-start-check.sh`
  - 4번 확인 추가: 대량 조회 로그가 10건 넘으면 다음 세션 시작 때 검토·초기화를 안내([Issue #100](https://github.com/yanos0218/AI/issues/100))

### Fixed

- 파생 이슈 15건(#65~#93 계열)이 본문에 언급만 되고 sub-issue로 연결 안 된 채 방치된 걸 소급 연결([Issue #94](https://github.com/yanos0218/AI/issues/94))
- 이슈 제목 11건에서 렌더링 안 되는 백틱 제거, GitHub Release 노트 2건(v0.2.0, v0.9.0)의 콜론 크램 수정([Issue #95](https://github.com/yanos0218/AI/issues/95))

## [0.9.1] - 2026-09-14

### Changed

- `base/rules/docs-format.md`
  - 목록 항목이 "(N) 설명A — 설명B"처럼 한 줄에 길게 늘어지면 본문 줄 + 하위 bullet으로 나눠 쓰는 규칙 추가
  - 처음엔 GitHub Issue·PR 본문에만 적용했다가 `.md` 파일 전반으로 확대([Issue #79](https://github.com/yanos0218/AI/issues/79)·[Issue #80](https://github.com/yanos0218/AI/issues/80))
  - 기존 `.md` 파일 14개에 소급 적용([Issue #81](https://github.com/yanos0218/AI/issues/81))
  - GitHub Release 노트 8개(v0.1.0~v0.8.0)에도 별도로 소급 적용([Issue #82](https://github.com/yanos0218/AI/issues/82))
- `.claude/hooks/pre-commit-check.sh`
  - `chore(release):` 커밋은 이슈 번호 확인을 건너뛰도록 예외 처리(버전 등급 미반영 — `.claude/` 전용, [Issue #79](https://github.com/yanos0218/AI/issues/79))

### Fixed

- `docs/versioning.md`
  - 이슈 백업 명령에 `--limit`이 없어 기본값 30개만 백업되던 문제 수정(버전 등급 미반영 — `docs/` 전용, [Issue #78](https://github.com/yanos0218/AI/issues/78))

## [0.9.0] - 2026-09-13

### Added

- `base/hooks/gh-throttle.sh`
  - mkdir 락 + 공유 타임스탬프로 gh 콘텐츠 생성 명령을 실제 직렬화(최소 2초 간격)해 GitHub 2차 속도 제한 예방(MINOR — 새 훅 추가)
  - 대상: `gh issue/pr/release/label`의 `create/comment/close/edit/reopen`, `gh api`의 POST/PATCH/PUT/DELETE
  - 병렬 서브에이전트가 간격 없이 gh를 호출해 계정이 일시 차단된 인시던트([Issue #71](https://github.com/yanos0218/AI/issues/71)) 재발 방지
  - 병렬 3개 실측으로 순차 처리 확인
- `base/settings.example.json`
  - `env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH: "1"` 추가해 서브에이전트의 재귀적 하위 서브에이전트 생성을 전역 차단(MINOR — 새 설정 키 추가)
  - 공식 문서 확인 + 실제 새 세션에서 재귀 시도 시 `Agent is disabled ... in subagents as well as here` 오류·`spawned_by_subagents: 0` 실측 확인
  - `tools/install.sh`·`tools/check-install.sh`에 `env` 키 병합·대조 추가
- `.claude/hooks/pre-commit-check.sh`
  - `base/` 또는 `docs/*.md` 규칙 문서를 바꾸는 커밋인데 메시지에 이슈 번호(`#숫자`)가 없으면 확인(`ask`)을 띄움
  - "착수 시점에 먼저 Issue부터 연다"는 CLAUDE.md 문장만으론 두 번(Issue #64, #66) 안 지켜져 훅으로 강제
  - 버전 등급 미반영 — `.claude/` 전용

### Changed

- 조사 기록 방식
  - `docs/research/<주제>.md` 파일에서 GitHub Issue `research` 라벨로 전환(파일·이슈 이중 기록 방지)
  - `base/claude-md/CLAUDE.md` §5, `docs/research.md` §3, README·monthly-check·review-vs-official 갱신
  - 2026-09-13 이전 기록은 `docs/research/`에 archive로 유지
- `base/hooks/git-guardrails.sh`
  - 하나의 정규식으로 뭉쳐 있던 매칭을 패턴별 if-elif로 나눠 구체적인 이유를 보여주도록 개선
  - 명령을 스크립트 파일로 감싸(`bash x.sh`) 문자열 매칭을 우회하던 취약점도 보강해 스크립트 내용까지 같이 검사
  - 11개 패턴·우회/회귀 시나리오 전부 직접 실행 확인([Issue #65](https://github.com/yanos0218/AI/issues/65)·[Issue #73](https://github.com/yanos0218/AI/issues/73))
- `.claude/hooks/pre-commit-check.sh`
  - 위와 같은 스크립트 감싸기 우회 취약점 보강([Issue #73](https://github.com/yanos0218/AI/issues/73))
- `base/claude-md/CLAUDE.md` §3
  - 확인 후 진행 항목 중 방법이 여럿인 경우 훅 확인 직전이 아니라 계획 단계에서 AskUserQuestion으로 먼저 확정하도록 규칙 추가([Issue #65](https://github.com/yanos0218/AI/issues/65))
- `base/claude-md/CLAUDE.md` §5
  - 서브에이전트 위임 습관 2건 추가
  - 정지시킨 서브에이전트의 뒤늦은 보고는 검증 없이 반영하지 않기
  - 병렬 위임 시 겹치지 않는 파일 배정([Issue #74](https://github.com/yanos0218/AI/issues/74))
- `CHANGELOG.md`
  - 보존 범위를 최근 3개 릴리즈로 축소(버전 등급 미반영 — 문서 전용, [Issue #76](https://github.com/yanos0218/AI/issues/76))

## [0.8.0] - 2026-09-13

### Added

- `base/skills/self-audit/`
  - 대화 기록을 서브에이전트(Sonnet)로 읽어 CLAUDE.md·규칙 문서와 실제 작업 방식의 간극(반복 지적·안 지켜진 규칙·미문서화 결정)을 찾는 스킬(ykdojo `review-claudemd` 패턴 응용)
  - 후보 제시까지만 자동, 문서 반영은 항상 사용자 확인 후
  - `tools/test-skill.sh` 3시나리오 발동 시험 통과("self-audit 해줘"·"이번 달 CLAUDE.md 점검해줘" 발동, "테스트 어떻게 해?" 오발동 안 함, 총 $1.37)
  - 감사 표시 파일 쓰기는 작업 디렉터리 밖이라 매번 승인 필요함을 확인(정상, 2026-09-13)
- `base/hooks/session-start-check.sh` 세 번째 확인
  - self-audit 표시 파일과 현재 세션 트랜스크립트 개수를 비교해 15개 이상 쌓이면 실행을 제안(실행은 여전히 사용자가 말할 때만)
  - 4시나리오(마커 없음/미만/이상, 마커 있음/미만/이상) 직접 실행 확인
- `.claude/hooks/pre-commit-check.sh`
  - 이 저장소 전용 `PreToolUse` 훅. `git commit` 시도 시 `check-docs.sh`·markdownlint·shellcheck를 먼저 돌리고 실패하면 커밋을 막음(버전 등급 미반영 — `.claude/` 전용)
- `CLAUDE.md`
  - "새 기본 영역 자산(훅·스킬·설정 키)은 구현 전에 설계를 채팅에 제시하고 승인받은 뒤 만든다"는 규칙(버전 등급 미반영)

### Changed

- `base/hooks/*.sh`, `base/vscode/install.sh`, `.claude/hooks/*.sh`, `tools/*.sh`
  - 13개 스크립트 전부 `${var}`·`[[ ]]` 스타일로 통일
  - 기존엔 신규 스크립트 2개만 이 스타일이었으나 사용자 요청으로 전체 확대
  - shellcheck `-S warning` 기준 실제 위험은 이전부터 0건, `--enable=all`로 잡히는 스타일 항목만 정리(2026-09-13)

[Unreleased]: https://github.com/yanos0218/AI/compare/v0.9.1...HEAD
[0.9.1]: https://github.com/yanos0218/AI/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/yanos0218/AI/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/yanos0218/AI/compare/v0.7.0...v0.8.0
