# 테스트 명령 표와 docs/testing.md 틀

SKILL.md §1-A를 보충한다. 저장소에 `docs/testing.md`가 이미 있으면 그쪽이 우선하고, 이 파일은 빠진 절을 채울 때만 참고한다.

## 1. 스택별 최소 검사와 본 테스트

"최소 검사"는 테스트가 하나도 없는 저장소에 먼저 제안하는 것. "본 테스트"는 있으면 그것이 공식 명령.

| 스택 (판별 단서) | 최소 검사 | 본 테스트 |
| --- | --- | --- |
| 정적 HTML/JS (빌드 도구 없음, `index.html`) | `node --check <js>` 전부, markdownlint | 브라우저 테스트 페이지(`tests/test.html`) + 헤드리스 브라우저(Playwright)로 CI 실행 |
| Node (`package.json`) | `npm run lint` 또는 `node --check` | `npm test` |
| Java/Gradle (`build.gradle`, `gradlew`) | `./gradlew compileJava` | `./gradlew test` (DB가 필요하면 로컬 DB 기동 후) |
| Python (`pyproject.toml`, `*.py`) | `python -m py_compile <files>` | `python -m pytest` |
| 셸 스크립트 (`*.sh`) | `bash -n`, `shellcheck -S warning` | 스크립트가 `--dry-run`을 지원하면 그것 |
| PowerShell (`*.ps1`) | `pwsh -NoProfile -Command "Invoke-ScriptAnalyzer"` | 동일 |
| Markdown 시스템·문서 저장소 | `markdownlint-cli2`, 깨진 링크 검사 | 문서 상한·필수 파일 검사 스크립트 |
| Swift/iOS (`*.xcodeproj`) | `xcodebuild build` | `xcodebuild test -scheme <이름>` |

원칙:

- CI(`.github/workflows/*.yml`)가 돌리는 명령이 있으면 로컬도 **같은 명령**을 쓴다. 다르면 문서에 왜 다른지 적는다.
- 문서만 바뀐 변경에 무거운 테스트를 돌리지 않도록 CI에 경로 필터가 있는지 본다(비공개 저장소는 Actions 분 한도).
- 명령은 문서에 적기 전에 **한 번 직접 실행**한다. 안 되는 명령을 적어 두면 문서가 거짓 신호가 된다.

## 2. docs/testing.md 틀

절 번호와 제목은 유지하고, 내용은 그 저장소 것으로 채운다. 없는 절은 "없음"이라고 적고 지우지 않는다.

```markdown
# 테스트 가이드

## 1. 구성
무엇이 어디서 돌아가나 — 로컬(수동/훅), CI(워크플로 이름·잡·경로 필터). 표로.

## 2. 실행 방법
복사해서 바로 쓸 수 있는 명령. 사전 조건(서버 기동, 환경 변수)도 여기.

## 3. 결과 확인 방법
어디를 보면 통과/실패를 아는지 (터미널 출력, 브라우저 페이지, Actions 탭).

## 4. 유지보수 정책
- 기능을 바꿨으면 그 테스트도 같은 커밋에서 바꾼다.
- 버그를 고쳤으면 재발 방지 테스트를 남긴다.
- PR 체크리스트·CLAUDE.md에서 이 문서를 가리킨다.

## 5. 아직 없는 것 (알고 있는 한계)
테스트가 없는 영역과 이유. 나중에 추가할 때의 후보 방법.
```

## 3. 판단이 갈릴 때

- **테스트가 전혀 없고 사용자가 개발자가 아니다** → 최소 검사 하나만 제안하고 CI에 넣는다. 프레임워크 도입은 사용자가 원할 때.
- **테스트는 있는데 문서가 없다** → 문서만 만든다. 테스트를 고치지 않는다.
- **CI와 로컬 명령이 다르다** → CI 쪽을 정답으로 보고 로컬을 맞춘다. 맞출 수 없으면(플랫폼 차이) 둘 다 적고 차이를 명시.
