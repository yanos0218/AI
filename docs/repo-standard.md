# 저장소 표준 — GitHub를 쓰는 모든 저장소의 최소선

"GitHub를 쓰는 환경이면 무조건 있어야 하는 것"의 목록. 새 저장소를 만들 때와 기존 저장소를 열 때 대조한다. 전역 지침(§5)이 세션당 한 번 미달 항목을 제안하고, 만드는 건 사용자가 결정한다. 저장소 전용 규칙은 각 저장소 `CLAUDE.md`가 우선.

## 체크리스트

| # | 항목 | 왜 | 최소 형태 |
| --- | --- | --- | --- |
| 1 | CI<br>문서 검사 | .md가 늘어나면 형식이 깨져도 아무도 모른다 | `markdownlint-cli2` 워크플로 + `.markdownlint.jsonc`(MD013 끔) |
| 2 | CI<br>테스트/빌드 | "됐다"의 증거. 스택에 맞게 하나 | 정적 사이트: 브라우저 테스트·`node --check`, Java: `gradlew test`, Python: `pytest`, 셸: `shellcheck`, 문서 저장소: 문서 상한 검사 |
| 3 | `CHANGELOG.md` | 릴리즈가 없는 저장소일수록 미루면 영원히 안 씀(kolo-api 8일 방치 전례) | Keep a Changelog. 릴리즈 없는 저장소는 날짜 섹션, 커밋과 같은 자리에서 갱신 |
| 4 | 저장소 `CLAUDE.md` | 매 세션 같은 배경 설명 반복을 막음 | 200줄 이하, "날짜 + 사고 + 규칙" 형식, 상세는 `docs/`로 |
| 5 | Issues | 문제·할 일을 잃지 않기 위해 | 라벨 이름·개수는 저장소 자유(claude-config의 `task`/`bug`/`error`/`research` 4개를 강제하지 않음). 최소 요구는 "문제(이미 생긴 일)"와 "할 일(계획된 것)"을 구분하는 라벨이 있고, 언제 어떤 라벨을 쓰는지 그 저장소 문서(`CLAUDE.md` 등)에 한 줄로 정의돼 있는 것. 제목·본문 형식·sub-issue 사용법은 claude-config [issue-format.md](issue-format.md)를 참고(강제 아님, 저장소 자체 관례가 있으면 그쪽 우선). 템플릿은 안 만든다(1인). 팀·협업 저장소는 별도<br>실제로 그런 저장소가 생기면 `repo-setup` 조사 단계에서 다시 정한다(이슈 템플릿·담당자·마일스톤이 필요해질 가능성이 큼). 커밋에 `#N`, 끝나면 `Closes #N` |
| 6 | 진행 보드 | 지금 어디까지 됐는지 | `docs/PROGRESS.md` 또는 동급 |
| 7 | Dependabot 알림 | 무료, 클릭 1회 | Settings → Security → Dependabot alerts |
| 8 | 비밀 정보 차단 | `.env`·토큰 커밋 방지 | `.gitignore` + 전역 `permissions.deny` |
| 9 | Actions 한도 방지 | 비공개 저장소 월 2,000분·아티팩트 500MB·API 시간당 1,000회 | 경로 필터, `concurrency`, `timeout-minutes`, main만 push 트리거, 폴링은 스크립트로. 상세는 [github.md](github.md) "Actions 제한과 방지" |

## 현황 (2026-09-13)

| 저장소 | 1 문서 CI | 2 테스트 CI | 3 CHANGELOG | 4 CLAUDE.md | 5 Issues | 6 보드 | 7 Dependabot | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| kolo_pwa | ✓ (`test.yml` 안) | ✓ Playwright | ✓ | ✓ | ✓ `bug`/`task`(2026-09-13, 기존 백로그는 소급 안 함) | ✓ | ✓ | |
| kolo-api | ✓ `markdownlint.yml` | ✓ `build.yml` | ✓ | ✓ | ✓ `bug`/`task`(2026-09-13) | kolo_pwa 보드 공용 | ✓ | |
| OpenClaw | ✓ `lint.yml` | - (문서 시스템) | ✓ | `workspace/AGENTS.md` (CLAUDE.md는 `@AGENTS.md` import로 연결 가능) | ✗ | ? | ✗ | |
| AI (이 저장소) | ✓ `lint.yml` | ✓ shellcheck·문서 상한 | ✓ | ✓ | ✓ task+bug 통합 | ✓ | ✓ | |
| Script | ✗ | ✗ (shellcheck 후보) | ✗ | ✗ | ✗ | ✗ | ✓ | **이력에 개인키** ([Issue #56](https://github.com/yanos0218/AI/issues/56)) |
| Etc | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | |

Script·Etc는 활동이 적어(마지막 push 2026-06) 보관/최소/전부 중 사용자가 고른다. 자동으로 맞춰 주는 `repo-setup` 스킬은 초안·1시나리오 통과([Issue #56](https://github.com/yanos0218/AI/issues/56)).
