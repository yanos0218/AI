# 저장소 표준 — GitHub를 쓰는 모든 저장소의 최소선

"GitHub를 쓰는 환경이면 무조건 있어야 하는 것"의 목록. 새 저장소를 만들 때와 기존 저장소를 열 때 대조한다. 전역 지침(§5)이 세션당 한 번 미달 항목을 제안하고, 만드는 건 사용자가 결정한다. 저장소 전용 규칙은 각 저장소 `CLAUDE.md`가 우선.

## 체크리스트

| # | 항목 | 왜 | 최소 형태 |
| --- | --- | --- | --- |
| 1 | CI — 문서 검사 | .md가 늘어나면 형식이 깨져도 아무도 모른다 | `markdownlint-cli2` 워크플로 + `.markdownlint.jsonc`(MD013 끔) |
| 2 | CI — 테스트/빌드 | "됐다"의 증거. 스택에 맞게 하나 | 정적 사이트: 브라우저 테스트·`node --check`, Java: `gradlew test`, Python: `pytest`, 셸: `shellcheck`, 문서 저장소: 문서 상한 검사 |
| 3 | `CHANGELOG.md` | 릴리즈가 없는 저장소일수록 미루면 영원히 안 씀(kolo-api 8일 방치 전례) | Keep a Changelog. 릴리즈 없는 저장소는 날짜 섹션, 커밋과 같은 자리에서 갱신 |
| 4 | 저장소 `CLAUDE.md` | 매 세션 같은 배경 설명 반복을 막음 | 200줄 이하, "날짜 + 사고 + 규칙" 형식, 상세는 `docs/`로 |
| 5 | Issues — 발견한 문제 | 작업 중 튀어나온 문제를 잃지 않기 위해. 계획·상태는 진행 보드가 담당 | 문제 하나 = Issue 하나, 커밋에 `#N` |
| 6 | 진행 보드 | 지금 어디까지 됐는지 | `docs/PROGRESS.md` 또는 동급 |
| 7 | Dependabot 알림 | 무료, 클릭 1회 | Settings → Security → Dependabot alerts |
| 8 | 비밀 정보 차단 | `.env`·토큰 커밋 방지 | `.gitignore` + 전역 `permissions.deny` |
| 9 | Actions 분 절약 | 비공개 저장소 월 2,000분 | 경로 필터(docs만 바뀌면 테스트 생략), `concurrency` |

## 현황 (2026-09-08)

| 저장소 | 1 문서 CI | 2 테스트 CI | 3 CHANGELOG | 4 CLAUDE.md | 5 Issues | 6 보드 | 7 Dependabot |
| --- | --- | --- | --- | --- | --- | --- | --- |
| kolo_pwa | ✓ (`test.yml` 안) | ✓ Playwright | ✓ | ✓ | ✗ | ✓ | ✓ |
| kolo-api | ✓ `markdownlint.yml` | ✓ `build.yml` | ✓ | ✓ | ✗ | kolo_pwa 보드 공용 | ✓ |
| OpenClaw | ✓ `lint.yml` | - (문서 시스템) | ✓ | `workspace/AGENTS.md` (CLAUDE.md는 `@AGENTS.md` import로 연결 가능) | ✗ | ? | ✗ |
| AI (이 저장소) | ✓ `lint.yml` | ✓ shellcheck·문서 상한 | ✓ | ✓ | 시험 예정 (C-34) | ✓ | ✗ |
| Script | ✗ | ✗ (shellcheck 후보) | ✗ | ✗ | ✗ | ✗ | ✗ |
| Etc | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

Script·Etc는 활동이 적어(마지막 push 2026-06) 다음에 열 때 표준을 맞추면 된다. 이 표준을 자동으로 맞춰 주는 스킬(`repo-setup`)은 C-35.
