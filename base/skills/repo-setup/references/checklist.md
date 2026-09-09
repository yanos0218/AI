# 저장소 표준 9항목 — 판정 기준과 최소 형태

SKILL.md §1의 2·3번 단계를 보충한다. 저장소에 자체 기준이 있으면 그쪽이 우선.

| # | 항목 | ✓ 판정 | 최소 형태 (✗일 때 제안) |
| --- | --- | --- | --- |
| 1 | 문서 CI | `.github/workflows/*.yml`에 markdownlint 스텝 | `markdownlint-cli2` 액션 + `.markdownlint.jsonc`(MD013 끔). push는 `main`만, `concurrency`, `timeout-minutes` |
| 2 | 테스트/빌드 CI | 워크플로에 스택별 검사 명령 | 정적 사이트 `node --check`, Java `gradlew test`, Python `pytest`, 셸 `shellcheck -S warning`, PowerShell `Invoke-ScriptAnalyzer`, 문서 저장소 상한 검사. 명령은 문서에 적기 전에 한 번 실행 |
| 3 | `CHANGELOG.md` | 파일 존재 + Keep a Changelog 헤더 | 릴리즈가 있으면 `[Unreleased]` 누적, 없으면 `## YYYY-MM-DD` 절. 첫 항목은 "이 파일 신설" |
| 4 | 저장소 `CLAUDE.md` | 200줄 이하, 규칙만(설명은 docs/) | 세션 시작 시 읽을 문서, 검증 방법, "날짜 + 사고 + 규칙" 절 틀 |
| 5 | Issues | 열린·닫힌 이슈가 있거나 CLAUDE.md에 "발견한 문제는 Issue" 규칙 | 규칙 한 줄. 이슈 템플릿은 만들지 않는다(1인) |
| 6 | 진행 보드 | `docs/PROGRESS.md` 또는 동급(항목 ID + 상태) | 완료/할 일 두 절 + ID 규칙 |
| 7 | Dependabot 알림 | `gh api repos/<o>/<r>/vulnerability-alerts` 204 | 저장소 설정 변경이라 사용자가 클릭. 워크플로가 있으면 `.github/dependabot.yml`(github-actions, monthly) |
| 8 | 비밀 차단 | `.gitignore`에 `.env*`·키 파일 패턴, 이력에 비밀 없음 | `.gitignore` 보강. 이력에 있으면 **재발급 + `git filter-repo`**를 사용자에게 제안(실행은 확인 후) |
| 9 | Actions 한도 | 워크플로에 `concurrency`·`timeout-minutes`·경로 필터 중 둘 이상 | 셋 다 추가. 비공개 저장소 월 2,000분 |

## 스택 판별 단서

| 단서 | 스택 |
| --- | --- |
| `*.sh`만, README가 폴더별 | 운영 스크립트 모음 → 2번은 `shellcheck`, `bash -n` |
| `index.html` + `*.js`, 빌드 도구 없음 | 정적 사이트 |
| `build.gradle` / `pom.xml` | Java |
| `pyproject.toml` / `requirements.txt` | Python |
| `*.md`가 대부분 | 문서 시스템 → 2번은 문서 상한·링크 검사 |

## 활동 없는 저장소

마지막 커밋이 6개월 이상 전이면 1~9를 전부 붙이는 것이 과할 수 있다. "보관(archive) / 최소(3·4·8만) / 전부" 중 고르게 한다.
