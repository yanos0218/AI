# claude-config 저장소 규칙

세션 시작: `docs/HANDOFF.md` → `docs/PROGRESS.md`(§0 표) → 열린 Issue(`gh issue list --state open`) 순으로 읽는다. 할 일은 `task`, 발견한 문제는 `bug` 라벨.

## 기본 영역과 작업 영역

- **기본 영역** = `base/` (실제로 배포되는 원본). `base/skills/_*`는 틀이라 예외. 여기 있는 것은 검증이 끝났고 사용자가 기본 반영을 요청한 것뿐이다.
- **작업 영역** = `drafts/`. 새 스킬·지침 수정안·훅 초안은 전부 여기서 만든다. 승격 조건은 `drafts/README.md`.
- 작업 중 기본 영역의 개선점이 보이면 **고치지 말고** `docs/PROGRESS.md`에 `C-NN` 항목으로 적는다. 사용자가 "기본에 반영해"라고 하기 전까지 기본 영역은 건드리지 않는다. `.claude/hooks/baseline-guard.sh`가 이를 확인 프롬프트로 강제한다.
- 예외: 기본 영역의 오탈자·깨진 링크처럼 동작에 영향 없는 수정은 확인 프롬프트에서 사유를 말하고 승인받으면 된다.

## 규칙 이탈

- 이 저장소의 목적은 Claude를 규칙적으로 만드는 것이다. 그러므로 여기서 정한 규칙(이 파일, `docs/versioning.md`, `drafts/README.md`, `docs/PROGRESS.md` 머리말)에서 **Claude 스스로 벗어나지 않는다.**
- 벗어나야 할 이유가 생기면: 멈추고 → 근거(공식 문서·커뮤니티·실제 사고)를 찾아 → 사용자에게 제안 → 승인되면 **규칙 문서를 먼저 고친 뒤** 진행한다. 순서를 바꾸지 않는다.
- 2026-09-09: 승격마다 릴리즈 컷을 제안해 versioning.md "모이면 컷"을 어겼다. 이 절이 그 재발 방지다.

## 검증

- 스킬 발동 테스트는 `bash tools/test-skill.sh <스킬 폴더> <시나리오 git 저장소> "<사용자 말>"` — 시나리오 저장소의 `.claude/skills/`에 넣고 새 세션(`claude -p`, 기본 Sonnet)으로 돌려 발동·도구 호출·비용을 본다. 같은 세션 안에서 스킬을 직접 호출하는 것은 발동 테스트가 아니다. 세션이 "했다"고 말한 것과 실제 파일 변경을 대조한다.
- 문서만 바꿨으면 `npx markdownlint-cli2 "docs/*.md" README.md`. 줄 길이(MD013)는 이 저장소에서 무시한다.

## 문서 규칙

- 파일마다 역할이 하나다. README = 입구(구조·설치 요약·링크). HANDOFF = 지금 상황(현재 상태는 **4줄 이하 + 링크**, 상세는 PROGRESS §0). PROGRESS = 자산 단계·배포 표 + 완료 이력. 할 일은 GitHub Issues. 상세 주제는 `docs/<주제>.md` 하나씩.
- 줄 수 상한(`tools/check-docs.sh`가 CI에서 검사): README 120, 이 파일 60, `base/claude-md/CLAUDE.md` 200, HANDOFF 60, PROGRESS 300, SKILL.md 80. 넘으면 줄이는 게 아니라 **분리**한다 — README는 `docs/`로, PROGRESS는 kolo_pwa처럼 항목을 `docs/progress/C-NN.md`로.
- 새 주제를 README에 절로 추가하지 않는다. `docs/`에 파일을 만들고 README 구조 목록에 한 줄 + 링크.
- 형식: markdownlint 통과(MD013 제외), Keep a Changelog, 릴리즈 노트는 음슴체, 표는 헤더 구분선 정렬.
- 링크: 파일·폴더 경로와 `C-NN` 항목은 항상 클릭되는 링크로 쓴다. `C-NN`은 `docs/PROGRESS.md#c-nn`(항목 줄의 `<a id="c-nn">` 앵커). 코드 블록 안에는 링크가 안 되므로 구조 목록은 표로.

## 문서 갱신

- 세션 끝: `docs/PROGRESS.md`(§0 자산 현황표의 단계·배포 열 + 항목 상태) + `docs/HANDOFF.md`(현재 상태) 갱신.
- 세션 끝: 그날 드러난 요청·대화·작업 방식을 `drafts/observations/YYYY-MM-DD.md`에 짧게 적는다(원자료, 하루 파일 하나). 전역 지침 반영은 월 점검 때 후보로만.
- 할 일과 발견한 문제는 GitHub Issue로 관리한다(라벨 `task`/`bug`, [C-54](docs/PROGRESS.md#c-54) 2026-09-12). 진행 보드는 §0 배포 표만 담당.
- 여러 세션에 걸치는 이슈는 **작업할 때마다 댓글로 진행 상황을 남긴다.** 끝났을 때 요약 하나만 쓰지 않는다 — 중간에 뭘 했는지가 댓글 이력으로 남아야 한다. 끝나면 커밋에 `Closes #N`.
- 자산 단계는 계획 → 초안 → 검증 → 기본 순으로만 올린다. 단계를 올리는 커밋에는 근거(시험 결과 또는 사용자 요청)를 본문에 적는다.
- 기본 영역을 바꾸면 README 구조·검토표와 설치본(`~/.claude/...`)도 같은 배치에서 맞춘다.
