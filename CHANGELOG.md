# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Changed

- `README.md`
  - "새 스킬 추가"·"dev-release 시험 시나리오"·"규칙과 문서를 고칠 때" 절 제거(구조 표·설치 요약·링크만 남기는 "입구" 역할로 축소, 119→95줄)
  - "새 스킬 추가" 절차는 [docs/skill-development.md](docs/skill-development.md) 신설로 옮기고, docs/ 표에 이미 링크가 있어 README 쪽 절은 완전히 삭제(중복 제거)
  - 시험 시나리오는 `base/skills/dev-release/references/test-scenarios.md`로 이동. "규칙과 문서를 고칠 때"는 `CLAUDE.md`·`base/claude-md/CLAUDE.md`와 중복이라 삭제
- `base/skills/dev-release/SKILL.md`
  - 신설한 `references/test-scenarios.md` 참조 한 줄 추가(버그 수정 수준 — PATCH)
  - §2 체크리스트에 8번(마일스톤 생성·이슈 배정·닫기) 추가, 명령은 `references/release-steps.md` §4 신설. 앞으로의 릴리즈부터 자동 적용(PATCH, [Issue #109](https://github.com/yanos0218/AI/issues/109))
- `docs/github.md`
  - "이슈·마일스톤·라벨" 행에 마일스톤 도입 반영(버전 등급 미반영 — `docs/` 전용)

### Fixed

- GitHub Release 노트 2건(v0.11.0, v0.11.1)의 em-dash 크램 수정(발행 전 `tools/check-cram.sh` 확인을 빠뜨렸던 것, `gh release edit`로 소급 정정. 버전 등급 미반영 — 문서 전용)

## [0.11.1] - 2026-09-17

### Changed

- `base/skills/repo-setup/references/checklist.md` 5번(Issues)
  - 라벨 이름·개수 강제(`task`/`bug`/`error`/`research` 4개)를 철회하고, 저장소 자유 + "문제/할 일 구분 라벨 하나씩 + 문서화" 원칙만 요구하도록 완화([Issue #107](https://github.com/yanos0218/AI/issues/107), 다른 저장소 실사용 관찰 근거)
- `docs/issue-format.md`
  - 제목 원칙 절 신설(고정 템플릿 강제 안 함, 저장소 자체 백로그 ID 우선)
  - sub-issue `--add-sub-issue` 사용 예시 2건 보강
- `docs/repo-standard.md` 5번(Issues)
  - 위와 동일하게 완화, `issue-format.md` 참고 링크 추가

## [0.11.0] - 2026-09-17

### Added

- `base/skills/config-update/`
  - "설정 업데이트해줘"에 발동, 어느 저장소에 있든 원본 경로(`~/.claude/.claude-config-version`)로 `install.sh`+`check-install.sh` 실행(발동/오발동 2시나리오 확인, [Issue #105](https://github.com/yanos0218/AI/issues/105)·[Issue #106](https://github.com/yanos0218/AI/issues/106))
- `tools/bootstrap.sh`
  - 신규 기기용 단일 명령 설치. `curl`로 받아 `bash`로 실행하면 clone(또는 pull) 후 `install.sh` 자동 실행(빈 `HOME` 시뮬레이션으로 신규 clone·기존 pull 두 경로 실행 확인)

### Changed

- `base/claude-md/CLAUDE.md` §5
  - SessionStart 훅의 버전 낡음 알림을 보면 다른 작업 전에 갱신 여부부터 물어보도록 규칙 추가(알림을 보고도 넘어간 실제 사례로 확인, [Issue #105](https://github.com/yanos0218/AI/issues/105))

### Fixed

- `docs/versioning.md`
  - 등급 반영 범위에 남아있던 `scripts/`를 `tools/`로 정정(2026-09-08 저장소 재구성 때 놓친 참조, 버전 등급 미반영 — `docs/` 전용)

## [0.10.0] - 2026-09-15

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
- `base/hooks/git-guardrails.sh`
  - `git push` 확인 문구에 관련 문서(`.md`) 갱신 상기 추가. 이번 push에 실제 포함된 `.md` 목록을 보여주고, 특정 파일로 못 박지 않고 "나열 안 된 다른 문서에도 걸쳐 있을 수 있다"고 안내([Issue #102](https://github.com/yanos0218/AI/issues/102))

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
- `docs/versioning.md` 등급 반영 범위 목록에 `base/hooks/`·`base/rules/`·`base/settings.example.json`이 빠져 있어 표의 MINOR 예시("훅·설정 키 추가")·v0.9.0 전례와 안 맞던 것 수정([Issue #103](https://github.com/yanos0218/AI/issues/103))

[Unreleased]: https://github.com/yanos0218/AI/compare/v0.11.1...HEAD
[0.11.1]: https://github.com/yanos0218/AI/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/yanos0218/AI/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/yanos0218/AI/compare/v0.9.1...v0.10.0
