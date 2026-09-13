# claude-config

**개인용 Claude 설정의 원본 저장소.** 개발자가 아닌 사용자가 여러 프로젝트를 오가며 Claude Code(CLI·VS Code)와 Claude.ai(웹·데스크톱)를 쓸 때, 매번 같은 설명을 반복하지 않고 · 멋대로 진행하거나 너무 자주 묻지 않게 하고 · 검증 없이 "됐다"고 못 하게 하고 · 결론만 짧게 듣기 위한 지침·스킬·훅·설정을 여기서 만들고, 검증하고, 각 기기와 웹에 배포한다.

저장소 전용 규칙은 각 저장소에 두고 여기서는 참조만 한다. 다른 저장소 내용을 복사하지 않는다.

## 구조 — 네 묶음

파일은 역할이 넷으로 나뉜다. **①만 실제로 배포**되고, 나머지는 ①을 만들고 지키기 위한 것이다. 폴더 이름이 곧 영역이다.

### ① `base/` — 배포되는 것 (기본 영역)

검증을 마치고 사용자가 반영을 요청한 것만 들어온다. `~/.claude`와 Claude.ai에 복사되는 원본. Claude가 여기를 고치려 하면 [baseline-guard.sh](.claude/hooks/baseline-guard.sh)가 확인을 요구한다.

| 경로 | 무엇 |
| --- | --- |
| [base/claude-md/CLAUDE.md](base/claude-md/CLAUDE.md) | 모든 프로젝트에 적용되는 공통 지침 (언어, 답변 방식, 확인 기준, 검증, Git) |
| [base/skills/dev-release/](base/skills/dev-release/SKILL.md) | "버전 올려줘 / 릴리즈 하자"에 발동하는 릴리즈 절차 스킬 |
| [base/skills/dev-workflow/](base/skills/dev-workflow/SKILL.md) | "테스트 어떻게 해 / 파일 정리해줘"에 발동. 구조·테스트 방법을 문서로 정하고 실행 증거를 보고 |
| [base/skills/repo-setup/](base/skills/repo-setup/SKILL.md) | "저장소 표준 맞춰줘 / 뭐가 빠졌는지 봐줘"에 발동. [docs/repo-standard.md](docs/repo-standard.md) 9항목 대조 후 고른 것만 생성 |
| [base/skills/self-audit/](base/skills/self-audit/SKILL.md) | "self-audit 해줘 / CLAUDE.md 점검해줘"에 발동. 대화 기록을 서브에이전트로 읽어 문서화 안 된 결정·안 지켜진 규칙 후보를 찾음(3시나리오 발동 시험 통과, 2026-09-13) |
| [base/hooks/](base/hooks/) | 위험한 명령 앞 확인을 강제하는 `git-guardrails.sh`, 상태줄 `statusline.sh`, 설정 변경 이력 `config-changelog.sh`, 새 세션마다 저장소 표준·설치 버전·self-audit 안내를 조용히 확인하는 `session-start-check.sh` |
| [base/settings.example.json](base/settings.example.json) | `~/.claude/settings.json` 예시 (허용·거부 명령, 훅, 상태줄) |
| [base/rules/](base/rules/) | 모듈 규칙 — 기본 지침을 건드리지 않고 주제별로 붙이는 파일. `~/.claude/rules/`에 설치 |
| [base/vscode/](base/vscode/) | 새 기기에 VS Code 확장·설정을 맞추는 목록과 스크립트 |
| [base/skills/_template/](base/skills/_template/SKILL.md) | 새 스킬을 시작할 때 복사하는 틀 (배포 제외) |

### ② `drafts/` — 만드는 중인 것 (작업 영역)

`base/`와 같은 구조로 초안을 두고, 시험을 통과하면 ①로 옮긴다. 배포·pack 대상이 아니다. 승격 절차는 [drafts/README.md](drafts/README.md). [drafts/observations/](drafts/observations/)는 세션마다 관찰한 사용자 요청·대화 방식(원자료)이다.

### ③ `docs/` — 이 저장소를 운영하기 위한 문서

| 경로 | 무엇 |
| --- | --- |
| [docs/HANDOFF.md](docs/HANDOFF.md) | Claude가 새 대화를 시작할 때 읽는 "지금 상황" 메모 — 무엇이 어디까지 됐고 무엇을 결정했는지 |
| [docs/PROGRESS.md](docs/PROGRESS.md) | 진행 보드 — 자산별 단계(계획→초안→검증→기본)와 기기별 배포 상태. 할 일은 GitHub Issues(라벨 `task`/`bug`) |
| [docs/versioning.md](docs/versioning.md) | 이 저장소의 버전·릴리즈 규칙 |
| [docs/install.md](docs/install.md) | 기기·웹별 설치 상세 |
| [docs/github.md](docs/github.md) | GitHub를 어디까지 쓰는지, Actions 한도, Claude와 어떻게 엮는지 |
| [docs/repo-standard.md](docs/repo-standard.md) | GitHub를 쓰는 모든 저장소의 최소선 체크리스트와 저장소별 현황 |
| [docs/review-vs-official.md](docs/review-vs-official.md) | 공식 문서·커뮤니티 권장과 대조한 검토표 (반영/습관/보류) |
| [docs/research.md](docs/research.md) | 조사 규칙(최신·검증·출처, 기록은 Issues `research` 라벨) |
| [docs/monthly-check.md](docs/monthly-check.md) | 월 점검 체크리스트 12항목 |
| [docs/config-lifecycle.md](docs/config-lifecycle.md) | 다른 저장소에서 작업해도 기본 설정이 유지되는 구조(기본·모듈·프로젝트 층)와 변경 이력 장치 |
| [CHANGELOG.md](CHANGELOG.md) · [CLAUDE.md](CLAUDE.md) | 기본 영역의 버전별 변경 이력 · 이 저장소 안에서 Claude가 지킬 규칙 |

### ④ `tools/`, `.claude/`, `.github/` — 자동화·검사

| 경로 | 무엇 |
| --- | --- |
| [tools/install.sh](tools/install.sh) | `base/` → `~/.claude` 설치 (멱등, settings 병합, `--dry-run`). 기기 3대 공통 |
| [tools/test-skill.sh](tools/test-skill.sh) | 스킬 발동 시험 — 시나리오 저장소에 넣고 새 세션으로 실행, 발동·비용 추출 (기본 Sonnet) |
| [tools/pack.sh](tools/pack.sh) | ①의 스킬을 웹 업로드용 zip으로 (zip 없으면 python 폴백) |
| [tools/check-docs.sh](tools/check-docs.sh) | 문서 줄 수 상한과 필수 파일 검사 (CI와 로컬 공용) |
| [tools/check-install.sh](tools/check-install.sh) | 설치본 `~/.claude`가 `base/`와 같은지, 프로젝트마다 쌓인 권한·설정 이력은 무엇인지 보고 |
| [.claude/hooks/](.claude/hooks/) | 저장소 전용 훅 — `baseline-guard.sh`(`base/` 쓰기 확인), `session-end-check.sh`(base/ 변경 시 PROGRESS §0 갱신, 그 외엔 관련 Issue 댓글·닫기 확인 안내) |
| [.github/workflows/lint.yml](.github/workflows/lint.yml) | push마다 markdownlint·shellcheck·문서 상한 검사 |
| [.github/dependabot.yml](.github/dependabot.yml) | 워크플로가 쓰는 액션 버전 업데이트 |

## 어디서 무엇이 적용되나

같은 SKILL.md가 모든 표면에서 통하지만, **넣는 방법과 지원 범위가 다르다.** 웹에 올린 스킬과 `~/.claude/skills/`는 서로 자동 동기화되지 않는다.

| 표면 | 스킬 | CLAUDE.md | 훅 | 비고 |
| --- | --- | --- | --- | --- |
| Claude Code CLI | `~/.claude/skills/` 복사 | `~/.claude/CLAUDE.md` | `~/.claude/settings.json` | 전부 지원 |
| Claude Code VS Code 확장 | CLI와 동일 (`~/.claude` 공유) | 동일 | 동일 | 명령/스킬은 CLI의 부분집합(`/`로 확인). `!`·탭 완성 없음 |
| Claude.ai 웹 · 데스크톱 채팅 | **Customize → Skills**에 zip 업로드(Pro 이상) | 없음 → 프로젝트 **Project instructions**에 붙여넣기 | 없음 | 계정 단위. 코드 실행 켜져 있어야 함 |
| Cowork (데스크톱) | 계정에서 켠 스킬을 세션 시작 시 로드. `~/.claude/skills/`는 **안 읽음** | 없음 | 없음 | 로컬 전용 스킬을 쓰려면 웹에도 올리거나 저장소 `.claude/skills/`에 커밋 |
| Claude Design (`claude.ai/design`) | 없음 — 디자인 시스템(스크린샷·자산·코드베이스) 첨부로 대체 | 없음 | 없음 | 결과를 Claude Code로 handoff 가능 |
| 클라우드 세션 (claude.ai/code) | 계정 스킬 + 저장소 `.claude/skills/` | 저장소 `CLAUDE.md` | 저장소 settings | 개인 `~/.claude`는 전달 안 됨 |

결론: **원본은 이 저장소, 배포는 두 갈래** — (1) `~/.claude`에 복사(CLI·VS Code), (2) `pack.sh`로 zip 만들어 웹에 업로드(웹·데스크톱·Cowork). 웹에서 켠 스킬을 CLI로 끌어오는 `CLAUDE_CODE_SYNC_SKILLS=1 claude -p ...`도 있지만 비대화형 전용이라 이 저장소 방식이 더 단순하다.

## 설치 (요약)

기본 영역이 바뀌면 각 기기에서 다시 설치한다. 상세와 Claude.ai·VS Code 절차는 [docs/install.md](docs/install.md).

```bash
bash tools/install.sh            # --dry-run 으로 먼저 볼 수 있음
```

CLAUDE.md·훅·스킬을 복사하고 `settings.json`에 `permissions`·`hooks`·`statusLine` 키를 합친다(기기별 `model` 등은 유지). 스킬·훅은 **새 세션**부터 적용된다. 어느 기기에 어느 버전이 깔렸는지는 [docs/PROGRESS.md §0](docs/PROGRESS.md#0-자산-현황--단계와-배포-상태) 표.

## 새 스킬 추가

1. `base/skills/_template/`을 `drafts/skills/<이름>/`으로 복사한다.
2. `SKILL.md`는 A4 한 장(50~60줄) 이내. 긴 자료는 `references/`로 빼고 SKILL.md에 "언제 읽을지"만 적는다. 참조는 한 단계만.
3. frontmatter `description`에 **사용자가 실제로 쓰는 말투**("~해줘", "~하자")를 따옴표로 넣고 3인칭으로 쓴다 — 이것이 발동 기준이다.
4. 날짜·특정 저장소 사례 같은 시점 의존 정보는 넣지 않는다. 필요하면 "저장소 문서 참고"로 가리킨다.
5. 새 세션에서 3가지 상황으로 시험한 뒤 완료로 본다.

### dev-release 시험 시나리오

| 상황 | 기대 동작 |
| --- | --- |
| `docs/versioning.md`가 있는 저장소에서 "몇 버전으로 올려야 해?" | §0에서 문서를 찾았다고 알리고, 그 문서 기준으로 등급과 근거 제시. 릴리즈는 실행하지 않음 |
| 태그가 `v2.9` 같은 두 자리인 저장소에서 "릴리즈 컷 하자" | 두 자리 형식을 유지하고, 체크리스트를 답변에 복사해 진행. 6번에서 멈추고 확인 요청 |
| 태그도 CHANGELOG도 없는 저장소 | CHANGELOG를 만들지 여부부터 확인. 임의로 태그 형식을 정하지 않음 |

## 규칙과 문서를 고칠 때

- 어떤 저장소에서든 같은 지적을 두 번 받거나 실수가 실제 문제로 이어졌으면, 저장소 전용이면 그 저장소 `CLAUDE.md`에, 저장소를 가리지 않으면 `base/claude-md/CLAUDE.md`에 기록한다.
- 줄을 추가할 때 "이 줄이 없으면 Claude가 실제로 실수하는가?"에 예일 때만. 반드시 지켜져야 하는 것은 CLAUDE.md 문장이 아니라 훅으로 만든다.
- `base/claude-md/CLAUDE.md`를 고쳤으면 `~/.claude/CLAUDE.md`로 다시 복사한다(Mac·Windows 각각). 웹용은 Project instructions도 갱신.

- README는 **입구**다. 새 주제는 `docs/`에 파일을 만들고 README에는 구조 목록 한 줄과 링크만 추가한다. 문서별 줄 수 상한은 `CLAUDE.md`에 있고 CI가 검사한다.
