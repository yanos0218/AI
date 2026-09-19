# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Added

- `tools/check-install.sh`
  - `--summary` 옵션 신설: 6개 섹션 상세 없이 마지막 판정 줄만 출력. 릴리즈 컷 때 grep으로 걸러도 "설정 변경 이력" 섹션이 새서 컨텍스트를 불필요하게 채우던 문제 해결([Issue #123](https://github.com/yanos0218/AI/issues/123), PATCH)

### Changed

- `.gitattributes`
  - `.md`·`.json`에 `eol=lf` 추가. `core.autocrlf=true` 환경에서 커밋마다 반복되던 CRLF 경고 제거([Issue #123](https://github.com/yanos0218/AI/issues/123), 버전 등급 미반영 — 저장소 설정 전용)
- `docs/github.md`
  - "gh CLI를 Claude가 직접 사용" 행에 `-q`로 필요한 필드만 추출하는 습관 명시(원본 JSON을 그대로 받으면 토큰이 늘어남, [Issue #123](https://github.com/yanos0218/AI/issues/123), 버전 등급 미반영 — 문서 전용)

## [0.11.3] - 2026-09-18

### Added

- `base/skills/dev-release/SKILL.md` §2
  - 5번 단계 신설: 릴리즈 전 바뀐 파일 전체를 훑어 세션 요약·진행 보드 문서 갱신 여부 확인. release 커밋에만 거는 좁은 차단 훅 대신 택한 방식([Issue #121](https://github.com/yanos0218/AI/issues/121), PATCH)

### Changed

- `docs/issue-format.md`·`CLAUDE.md`·`docs/repo-standard.md`
  - 커밋의 `Closes #N`(push 순간 자동 닫힘)을 `Refs #N` + 검증 후 수동 `gh issue close`로 교체. push 이후에도 검증할 게 남아 있으면 검증 전에 이슈가 닫히던 위험 방지([Issue #122](https://github.com/yanos0218/AI/issues/122), 버전 등급 미반영 — 문서 전용)
- `base/skills/dev-release/SKILL.md`·`references/release-steps.md`
  - 마일스톤 배정용 커밋 grep 패턴을 `closes #N`에서 `(refs|closes) #N`으로 확장(과거 커밋 호환, PATCH, [Issue #122](https://github.com/yanos0218/AI/issues/122))

## [0.11.2] - 2026-09-18

### Added

- `.github/workflows/issue-format-check.yml` 신설
  - 이슈가 열리거나 수정될 때 `docs/issue-format.md` 규정(라벨별 필수 헤딩·크램)을 자동 검사해 코멘트+`needs-format-fix` 라벨로 알린다. 사전 차단은 못 함(이슈는 PR과 달리 상태 체크로 막을 방법이 없음). `tools/check-cram.sh` 재사용, 새 스크립트는 안 만듦(버전 등급 미반영 — `base/` 밖 저장소 CI 전용)
  - 카테고리 라벨(`task`/`bug`/`error`/`research`)이 2개 이상 동시에 붙으면 그 자체를 위반으로 보고([Issue #115](https://github.com/yanos0218/AI/issues/115), 버전 등급 미반영)
- `docs/issue-format.md`
  - "문서를 먼저 연다" 경고 신설(2026-09-18, 문서를 안 읽고 이슈 3건(#110~#112)을 만들어 제목 길이·본문 템플릿·크램 검사·sub-issue 연결 4가지를 한꺼번에 어긴 뒤 소급 정정. 버전 등급 미반영 — 문서 전용)
  - 크램 확인·게시 명령을 `&&`로 묶으라는 문장 추가(2026-09-18, 검사와 게시를 `;`로만 나눠 써서 검사 실패에도 게시가 그대로 진행된 사례 2건(#114, #117) 재발 방지. 버전 등급 미반영 — 문서 전용, [Issue #118](https://github.com/yanos0218/AI/issues/118))
- `base/claude-md/CLAUDE.md` 5절
  - kolo_pwa 세션이 정식 승격 절차 없이 설치본(`~/.claude/CLAUDE.md`)에만 직접 추가했던 규칙 2건을 원본에 승격(`--limit`/페이지네이션 오인 방지, 저장소 상태를 직접 고치기 전 기존 절차 확인). 승격 전엔 `install.sh` 실행 한 번으로 그 2건이 설치본에서 조용히 사라지는 위험이 있었다(PATCH)

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

- `base/skills/config-update/SKILL.md` 6단계
  - install.sh의 "새 세션부터 적용" 경고가 보고 대상에서 빠져, 갱신 직후에도 같은 세션이 옛 규칙으로 계속 동작하는 걸 사용자가 모르게 되는 문제를 우선 고침. 이후 실험·공식 문서로 CLAUDE.md·스킬은 세션 재시작 없이도 자동 반영됨을 확인해, 훅 등록·권한 변경이 섞인 경우로 "새 세션 권장" 범위를 좁힘(PATCH, [Issue #110](https://github.com/yanos0218/AI/issues/110)/[#111](https://github.com/yanos0218/AI/issues/111))
  - 이 저장소(`yanos0218/AI`) 전용 GitHub 이슈 링크가 들어 있어 다른 저장소·기기에 설치될 때 이식성이 떨어지던 것 제거(PATCH, [Issue #112](https://github.com/yanos0218/AI/issues/112))
- `.github/workflows/issue-format-check.yml`
  - 라벨을 떼는(`unlabeled`) 동작이 트리거에 없어, 위반이 해소돼도 재검사가 안 되던 문제(실제 테스트로 발견, [Issue #117](https://github.com/yanos0218/AI/issues/117), 버전 등급 미반영)
- GitHub Release 노트 2건(v0.11.0, v0.11.1)의 em-dash 크램 수정(발행 전 `tools/check-cram.sh` 확인을 빠뜨렸던 것, `gh release edit`로 소급 정정. 버전 등급 미반영 — 문서 전용)
- Issue #109 본문의 크램 2건 수정(같은 종류 실수 반복 — `gh issue create`도 검사 대상 목록에 빠져 있었음, `docs/issue-format.md` "공통" 절에 추가. 버전 등급 미반영 — 문서 전용)

## [0.11.1] - 2026-09-17

### Changed

- `base/skills/repo-setup/references/checklist.md` 5번(Issues)
  - 라벨 이름·개수 강제(`task`/`bug`/`error`/`research` 4개)를 철회하고, 저장소 자유 + "문제/할 일 구분 라벨 하나씩 + 문서화" 원칙만 요구하도록 완화([Issue #107](https://github.com/yanos0218/AI/issues/107), 다른 저장소 실사용 관찰 근거)
- `docs/issue-format.md`
  - 제목 원칙 절 신설(고정 템플릿 강제 안 함, 저장소 자체 백로그 ID 우선)
  - sub-issue `--add-sub-issue` 사용 예시 2건 보강
- `docs/repo-standard.md` 5번(Issues)
  - 위와 동일하게 완화, `issue-format.md` 참고 링크 추가

[Unreleased]: https://github.com/yanos0218/AI/compare/v0.11.3...HEAD
[0.11.3]: https://github.com/yanos0218/AI/compare/v0.11.2...v0.11.3
[0.11.2]: https://github.com/yanos0218/AI/compare/v0.11.1...v0.11.2
[0.11.1]: https://github.com/yanos0218/AI/compare/v0.11.0...v0.11.1
