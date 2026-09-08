# claude-config

개인용 Claude 설정 원본 저장소. Claude Code(CLI·VS Code 확장)와 Claude.ai(웹·데스크톱·Design)에서 쓰는 **저장소를 가리지 않는** 스킬·공통 지침(CLAUDE.md)·훅·VS Code 설정을 여기서 관리하고 배포한다.

저장소 전용 규칙·스킬은 각 저장소(`CLAUDE.md`, `.claude/skills/`)에 두고, 여기서는 **참조만** 한다. 다른 저장소의 내용을 이쪽으로 복사하지 않는다.

## 구조

```text
CLAUDE.md                                  이 저장소 안에서 Claude가 지킬 규칙 (기본/작업 영역 구분, 검증 방법)
.claude/hooks/baseline-guard.sh            기본 영역(claude-md·skills·scripts·vscode) 쓰기 앞에서 확인을 강제하는 저장소 전용 훅
drafts/                                    작업 영역 — 승격 전 초안. 배포·pack 대상 아님
docs/HANDOFF.md                            새 세션 인수인계 — 현재 상태·결정 사항 (세션 시작 시 먼저 읽기)
docs/PROGRESS.md                           진행 보드 — 완료/할 일을 C-NN ID로 추적 (세션 끝날 때 갱신)
claude-md/CLAUDE.md                        전역 공통 지침 → ~/.claude/CLAUDE.md
skills/dev-release/                        SemVer 등급 판단 + 릴리즈 컷 절차
  ├─ SKILL.md
  └─ references/
      ├─ semver-rules.md                   등급 기준, 저장소 유형별 관점
      ├─ release-steps.md                  명령어, 자동 워크플로, 버전 파일 위치
      └─ release-notes-format.md           한국어 릴리즈 노트 기본 형식
skills/_template/                          새 스킬 틀 (SKILL.md + references/detail.md)
scripts/hooks/git-guardrails.sh            push·강제삭제 등 앞에서 확인 프롬프트를 강제하는 PreToolUse 훅
scripts/hooks/statusline.sh                모델·브랜치·컨텍스트 사용률·비용을 항상 보여주는 상태줄
scripts/settings.example.json              ~/.claude/settings.json 예시 (권한 허용/거부, 훅, 상태줄)
scripts/pack.sh                            skills/* → dist/<이름>.zip (_로 시작하는 폴더 제외)
vscode/extensions.txt                      VS Code 확장 목록 (새 기기 부트스트랩용)
vscode/settings.json                       VS Code 사용자 설정 스냅샷 (Claude Code 확장 설정 포함)
vscode/install.ps1 · install.sh            새 기기에서 확장 설치 + 설정 복사
```

## 기본 영역과 작업 영역

이 저장소는 **기본 영역**(실제로 `~/.claude`와 웹에 배포되는 원본)과 **작업 영역**(승격 전 초안)을 나눈다. 작업 중 떠오른 개선이 검증 없이 기본 영역에 섞여 들어가 "기본"이 흔들리는 것을 막기 위해서다.

| 영역 | 경로 | 들어가는 조건 |
| --- | --- | --- |
| 기본 | `claude-md/`, `skills/<이름>/`(`_` 제외), `scripts/`, `vscode/` | 3시나리오 시험 통과 **+ 사용자가 "기본에 반영해"라고 요청** |
| 작업 | `drafts/` (기본 영역과 같은 구조) | 아무 때나. `pack.sh`·설치 절차가 보지 않으므로 배포되지 않음 |

강제 장치는 [.claude/hooks/baseline-guard.sh](.claude/hooks/baseline-guard.sh) — 이 저장소에서 Claude가 기본 영역 파일을 쓰려 하면(Edit/Write뿐 아니라 Bash `sed -i`·리다이렉트·`cp` 등도) 확인 프롬프트가 뜬다. 승격·오탈자 수정처럼 의도한 변경이면 승인하고, 아니면 `drafts/`로 돌아간다. 승격 절차는 [drafts/README.md](drafts/README.md).

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

## 설치

### Claude Code (CLI · VS Code 확장 공통)

Windows(Git Bash)·Mac·Linux 공통. `~/.claude/`는 CLI와 VS Code 확장이 같은 파일을 읽는다.

```bash
cp -r skills/dev-release ~/.claude/skills/
cp claude-md/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/hooks && cp scripts/hooks/*.sh ~/.claude/hooks/
```

`~/.claude/settings.json`이 없으면 `scripts/settings.example.json`을 복사하고, 있으면 `permissions`·`hooks`·`statusLine` 키를 합친다(`model` 등 기기별 값은 기존 것 유지). `$schema` 덕에 VS Code에서 자동완성·검증이 된다. 상태줄 스크립트는 jq → python → node 순으로 있는 것을 쓰므로 Linux에 jq가 없어도 된다. 스킬 목록은 세션 시작 시 고정되므로 복사 후 **새 세션**에서 확인한다.

### Claude.ai (웹 · 데스크톱 · Cowork)

1. `bash scripts/pack.sh` → `dist/<스킬이름>.zip` 생성
2. Claude.ai **Customize → Skills → + → Upload a skill**에서 zip 업로드
3. 공통 지침은 프로젝트(Project)의 **Project instructions**에 `claude-md/CLAUDE.md` 내용을 붙여넣어 대체

### VS Code

**평소 동기화는 VS Code 내장 Settings Sync**(계정 메뉴 → *Backup and Sync Settings*, GitHub 계정)로 한다. 설정·단축키·스니펫·확장·UI 상태·프로필이 계정 단위로 자동 반영되고, 경로 같은 기계 종속 설정은 알아서 제외된다. 커뮤니티에서도 개인 사용자는 Settings Sync, 팀·재현성이 필요하면 dotfiles 저장소를 쓰는 게 일반적이다.

이 저장소의 `vscode/`는 **Settings Sync를 보완**한다.

- `extensions.txt` — **선별한** 확장 목록. 새 기기 부트스트랩용이며, 손으로 관리한다(`code --list-extensions` 결과를 그대로 덮어쓰지 않는다).
- `settings.json` — 사용자 설정 스냅샷(Claude Code 확장 설정 포함).
- `install.ps1`(Windows) / `install.sh`(Mac·Linux) — 확장을 설치하고, 설정 파일이 없을 때만 복사한다. 이미 있으면 덮어쓰지 않는다.

#### 확장 선별 기준

기준은 하나 — **실제 저장소가 있는 스택인가, 그리고 CI가 실제로 돌리는 도구인가.** 커뮤니티 "필수" 목록(Prettier·ESLint·GitLens·Error Lens)은 참고만 했다.

| 판단 | 확장 | 이유 |
| --- | --- | --- |
| 유지 | claude-code, 한국어 팩, markdownlint, GitHub Actions, Python 3종, Java pack + Gradle, PowerShell, Remote-SSH, Live Server | 정적 PWA·Spring Boot·FastAPI·셸/PS·Markdown CI·NAS/서버 SSH — 전부 실제 저장소에 대응 |
| 추가 | Error Lens | 진단을 줄 옆에 바로 보여줌. 코드를 직접 읽지 않는 사용 방식에 가장 도움이 되는 커뮤니티 필수 항목 |
| 제외 | auto-rename-tag | `editor.linkedEditing`(이미 켜져 있음)이 같은 기능 |
| 제외 | diff-merge, PDF 뷰어 | VS Code 내장 diff/merge 에디터로 충분, PDF는 외부 뷰어 |
| 제외 | containers, lldb-dap, python-envs | 로컬에서 Docker/C·C++ 디버깅/환경 관리자를 쓰는 저장소가 없음 |
| Mac 전용 | swift-vscode | Xcode가 있는 Mac에서만 의미. Windows 목록에서 제외 |
| 보류 | Prettier, ESLint, GitLens, EditorConfig | 저장소에 설정 파일(`.prettierrc`, `eslint.config.js`, `.editorconfig`)이 없어 켜면 CI와 다른 기준으로 잔소리만 함. 프로젝트에 설정이 생기면 그때 추가 |

이미 설치돼 있는 제외 대상은 `code --uninstall-extension <id>`로 지운다. Settings Sync가 켜져 있으면 Mac에도 같이 반영되니, Mac에서 쓰는 것(swift 등)은 Mac에서 다시 설치한다.

### Claude Code CLI (터미널)

VS Code 확장은 자체 바이너리를 번들해서 쓰므로 **터미널의 `claude` 명령은 별도 설치**해야 한다. 공식 권장은 네이티브 설치(npm 방식은 사용 중단):

```powershell
# Windows
irm https://claude.ai/install.ps1 | iex
```

```bash
# Mac/Linux
curl -fsSL https://claude.ai/install.sh | bash
```

`~/.claude/`(CLAUDE.md·skills·hooks·settings.json)는 CLI와 확장이 **같은 파일을 공유**하므로 한 번만 설치하면 둘 다 적용된다. Windows에서는 Claude Code가 명령 실행에 Git Bash를 쓰기 때문에 Git for Windows가 필수이고, 훅 스크립트(`bash ~/.claude/hooks/...`)도 그 bash로 돈다. 설치 후 `claude doctor`로 상태를 확인한다.

Claude Code 확장 자체 설정(`claudeCode.*`)은 VS Code 설정에, 허용 명령·훅·MCP·모델은 `~/.claude/settings.json`에 둔다 — 후자는 CLI와 확장이 공유한다.

## 공식 문서·커뮤니티 대비 검토 (2026-09 기준)

생산성·토큰·실수 방지·병렬 작업 관점에서 공식 문서(best-practices, costs, context-window, permissions, hooks, agent-view, worktrees)와 커뮤니티 설정을 대조한 결과. **반영**은 이 저장소에 들어간 것, **습관**은 설정이 아니라 쓰는 방식, **보류**는 이유가 있어 안 넣은 것.

| 분류 | 항목 | 상태 | 비고 |
| --- | --- | --- | --- |
| 실수 방지 | 되돌리기 어려운 명령 앞 확인 강제 | 반영 | `git-guardrails.sh` — PreToolUse 훅은 모든 권한 모드에서 먼저 실행됨 |
| 실수 방지 | 비밀 파일 읽기/편집 거부 | 반영 | `permissions.deny`: `.env`, `secrets/`, `~/.ssh` |
| 실수 방지 | 검증 없이 "됐다" 금지 | 반영 | CLAUDE.md §4. 공식: "Claude에게 돌릴 수 있는 검사를 주고 증거를 보이게 하라" |
| 실수 방지 | 계획 먼저(plan mode) | 습관 | 여러 파일 건드리거나 방향이 불확실하면 Shift+Tab. 한 문장으로 diff를 설명할 수 있으면 생략 |
| 실수 방지 | 같은 지적 두 번이면 `/clear` 후 더 나은 프롬프트로 | 습관 | 공식 "correcting over and over" 실패 패턴 |
| 토큰 | 상태줄에 컨텍스트 % 상시 표시 | 반영 | `statusline.sh` — 70%/85%에서 색 바뀜. 컴팩션 전에 `/compact` 또는 `/clear` 판단 |
| 토큰 | 컴팩션 시 보존할 것 지정 | 반영 | CLAUDE.md §5 — 수정 파일·테스트 결과·미완료 체크리스트 |
| 토큰 | 대량 읽기는 서브에이전트로 | 반영 | CLAUDE.md §5 |
| 토큰 | CLAUDE.md 200줄 이하, 절차는 스킬로 | 반영 | 현재 60줄 |
| 토큰 | 작업 바뀌면 `/clear`, 곁가지 질문은 `/btw` | 습관 | 긴 세션의 한 줄 질문도 전체 컨텍스트를 다시 보냄 |
| 토큰 | 모델·effort 조절 | 습관 | 단순 작업은 `/effort` 낮추기, 서브에이전트는 Sonnet/Haiku. Fable은 thinking 끌 수 없음 |
| 토큰 | 안 쓰는 MCP 서버 끄기, CLI(`gh`) 우선 | 습관 | 현재 MCP 없음 |
| 생산성 | 안전한 읽기 명령 사전 허용 | 반영 | `permissions.allow` — Manual 모드에서 프롬프트 감소 |
| 생산성 | 세션 이름 붙이기 `/rename`, `--continue` | 습관 | 작업 단위로 세션을 브랜치처럼 |
| 생산성 | 반복 프롬프트는 스킬로, 매번 지켜야 하면 훅으로 | 반영 | 이 저장소의 존재 이유 |
| 생산성 | 코드 인텔리전스 플러그인(LSP) | 보류 | Java/Python 저장소에서 파일 탐색 줄여줌. 필요해지면 `/plugin`에서 언어별 설치 |
| 병렬 | worktree로 세션 격리 (`claude --worktree 이름`) | 습관 | 각 저장소 `.gitignore`에 `.claude/worktrees/` 추가 필요. kolo_pwa처럼 공유 파일(`CACHE_NAME`)이 있으면 그 저장소 규칙대로 머지는 순차 |
| 병렬 | 에이전트 뷰 (`claude agents`, `claude --bg "..."`) | 습관 | 백그라운드 세션은 자동으로 worktree에 격리되고 **브랜치를 자동 push**함(main엔 안 함) — git-guardrails가 확인을 요구하면 "Needs input"에 뜨므로 거기서 승인 |
| 병렬 | 서브에이전트 병렬 호출 | 습관 | 서로 독립인 영역을 한 메시지에서 동시에 |
| 병렬 | 에이전트 팀 | 보류 | 실험 기능, 토큰 약 7배. 개인 프로젝트 규모엔 과함 |
| 병렬 | 샌드박스 | 보류 | Windows 미지원(WSL2만). Mac/Linux에서는 `/sandbox`로 켜면 명령 승인이 더 줄어듦 |
| 알림 | 입력 대기 시 소리/알림 훅 | 보류 | 병렬 세션을 돌리기 시작하면 `Notification` 훅 추가 |

## GitHub 활용

Claude와 GitHub를 엮는 방법은 크게 넷이다. 아래는 **사용자 저장소 현황(2026-09-08 `gh`로 조사)**과 대조한 결과이며, 상태 표기는 위 검토표와 같다(**결정 필요**는 사용자 판단이 있어야 하는 것).

현황: 저장소 11개 전부 비공개, GitHub Free 플랜(브랜치 보호 불가 — Pro 필요). 이슈 0개(백로그는 각 저장소 `docs/PROGRESS.md`의 `P-NN`). PR은 kolo_pwa·kolo-api가 Dependabot뿐이고 OpenClaw만 Codex(OpenAI 클라우드 에이전트)가 만든 PR 18개 — 즉 사람이 브랜치→PR을 쓰는 습관은 없고 `main` 직접 push. Actions는 kolo_pwa(`test.yml` 경로 필터로 분 절약, `release.yml` 태그 push→Release)·OpenClaw(`lint.yml`, `release.yml`)에 있고 Release는 각각 30·42개.

| 방법 | 무엇을 해주나 | 상태 | 비고 |
| --- | --- | --- | --- |
| `gh` CLI를 Claude가 직접 사용 | PR·이슈·Actions 결과·Release 조회/생성. MCP보다 토큰이 적게 듦 | 반영 | `permissions.allow`에 `gh pr view`·`gh run list`·`gh release view` 사전 허용. dev-release가 `gh release create`·`gh run list`를 씀 |
| 태그 push → Release 자동 생성 | 릴리즈 노트 파일을 태그 전에 커밋하면 Actions가 Release를 만듦 | 반영 | kolo_pwa·OpenClaw에 이미 있음. dev-release §0이 워크플로 존재를 감지해 절차를 맞춤 |
| 이 저장소를 설정의 원본으로 | `~/.claude`를 기기마다 손으로 맞추지 않고 clone → 설치 스크립트 | 반영 | 커뮤니티 dotfiles 방식과 동일. Mac·Linux 반영은 `docs/PROGRESS.md` C-15/16 |
| **Claude Code on the web** (`claude.ai/code`) | 브라우저·폰에서 지시 → 클라우드 VM이 저장소를 clone해 작업 → PR 생성. `claude --cloud "..."`로 터미널에서 보내고 `--teleport`로 받아옴. PR의 CI 실패·리뷰 코멘트를 자동 수정(auto-fix)도 가능 | **결정 필요** | Pro/Max 가능, 별도 VM 비용 없음(플랜 한도 공유). OpenClaw에서 Codex로 하던 "클라우드가 PR 만들기"의 Claude 버전. 저장소 `CLAUDE.md`·`.claude/`는 적용되지만 `~/.claude`는 전달 안 됨 |
| **Claude Code GitHub Actions** (`@claude` 멘션) | 이슈·PR 코멘트에 `@claude ...`라고 쓰면 Actions 러너에서 Claude가 코드를 고치고 커밋·PR. `prompt`를 주면 일정(cron)·이벤트 자동 실행도 가능 | **결정 필요** | `/install-github-app`으로 5분 설치. 구독 토큰(`claude setup-token`)이면 API 과금 없이 플랜 한도 사용, 단 Actions 분은 소모(비공개 저장소 월 한도 있음). 이슈를 안 쓰고 1인이라 지금은 이득이 작다 — PR 단위 작업이 자리 잡은 뒤 |
| PR 자동 리뷰 — Code Review(관리형) | PR마다 다중 에이전트가 검토해 인라인 코멘트 | 보류 | Team/Enterprise 전용, 건당 15~25달러. 개인은 로컬 `/code-review`(무료, 세션 한도) 또는 `/code-review ultra`(크레딧)로 대체 |
| 브랜치 → PR → merge 습관 | 위 두 "결정 필요" 항목의 전제. 리뷰 코멘트·auto-fix·`@claude`가 전부 PR 위에서 동작 | 습관 | kolo_pwa `CONTRIBUTING.md`가 GitHub Flow를 정해 뒀지만 1인이라 강제 안 함. 브랜치 보호는 Free 플랜에서 불가 |
| GitHub 이슈를 백로그로 | 커뮤니티는 `gh issue create`로 할 일을 만들고 `@claude`에 넘기는 흐름을 씀 | 보류 | 사용자 저장소는 `docs/PROGRESS.md` + `P-NN`이 확정. 바꾸지 않는다 |
| 이 저장소 CI | markdownlint·shellcheck | 할 일 | `docs/PROGRESS.md` C-12 |

추천 순서: PR 습관(브랜치에서 작업 → `gh pr create` → merge)을 먼저 한 저장소에서 시도하고, 그게 편하면 Claude Code on the web을 켠다. `@claude` Actions는 이슈를 쓰기 시작할 때.

### GitHub 기능 전체 대비 사용 수준 (2026-09-08)

"전부 써야 하나"에 대한 답은 **아니오**. 계정은 GitHub Free이고 저장소가 전부 비공개라 애초에 못 쓰는 기능이 있고, 1인 개발에서 커뮤니티가 공통으로 권하는 수준은 "main + 기능 브랜치, Conventional Commits, SemVer 태그, Actions로 테스트·배포, 나머지는 필요해질 때"다. 현재 사용 수준은 그 권장과 거의 일치한다.

| 기능 | 현재 | 판단 | 이유 |
| --- | --- | --- | --- |
| 저장소·커밋·push | 11개 저장소, Conventional Commits | 쓴다 | 백업·이력의 기본 |
| Releases·태그 | kolo_pwa 30, OpenClaw 42, 이 저장소 v0.1.0 | 쓴다 | 어느 기기에 어느 버전이 깔렸는지의 기준점. zip 첨부로 웹 업로드 산출물도 보관 |
| Actions | kolo_pwa test·release, OpenClaw lint·release | 쓴다 | 월 2,000분 한도. kolo_pwa처럼 경로 필터로 절약. 이 저장소는 C-12 |
| Dependabot 알림 | kolo_pwa·kolo-api만 켜짐 | **켠다** | 무료, 저장소 Settings → Security 클릭 1회. AI·OpenClaw·Script·Etc는 꺼져 있음 |
| Dependabot 버전 업데이트 | kolo_pwa(actions만) | 유지 | 의존성 트리가 있는 저장소만 |
| PR | 사람이 만든 PR 없음(Codex·Dependabot뿐) | 필요할 때 | Claude 클라우드·`@claude`·리뷰 코멘트가 전부 PR 위에서 도니, 그걸 쓰기로 하면 같이 시작 |
| 이슈·마일스톤·라벨 | 이슈 0, 마일스톤 0, 라벨 기본값 | 안 쓴다 | `docs/PROGRESS.md` + `P-NN`이 대체. 커뮤니티 다수는 이슈를 백로그로 쓰지만, 1인이면 파일 하나가 더 빠르다 |
| Projects(칸반) | 켜져 있으나 미사용 | 안 쓴다 | 이슈를 안 쓰면 의미 없음 |
| Wiki·Discussions·Pages | 꺼짐 | 불가/불필요 | Free 비공개 저장소는 Wiki·Pages 불가. 문서는 `docs/`, 서비스는 NAS |
| 브랜치 보호·룰셋·CODEOWNERS | 없음 | **불가**(Pro 필요) | 대신 로컬 훅(`git-guardrails`)이 push 앞에서 확인. 두 번째 개발자가 오면 Pro($4/월) |
| Secret scanning·Code scanning | 없음 | 불가(Free 비공개) | 대신 `permissions.deny`로 `.env` 읽기·편집 차단, CLAUDE.md §7 |
| Codespaces | 미사용(월 120시간 무료) | 안 쓴다 | 브라우저 개발 환경은 Claude Code on the web이 같은 자리 |
| Copilot | 미사용 | 안 쓴다 | Claude가 그 역할 |
| Packages·Gists | 미사용 | 안 쓴다 | 배포 산출물이 없음 |
| Actions secrets·Environments | 0개 | 필요할 때 | `@claude` Actions를 켜면 토큰 1개가 처음 생김 |
| 2FA | 확인 불가(토큰 권한 부족) | **확인** | GitHub 필수화 대상. Settings → Password and authentication |

**효과가 나는 최소 수준**: (1) 커밋·push, (2) 태그·Release, (3) Actions로 테스트 — 이 셋은 이미 하고 있다. 그다음 한 단계는 PR인데, 이건 GitHub 자체 때문이 아니라 Claude 자동화(위 표의 "결정 필요" 2건)를 쓸 때 비로소 값어치가 생긴다.


## 새 스킬 추가

1. `skills/_template/`을 복사해 이름을 바꾼다.
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

## 규칙을 고칠 때

- 어떤 저장소에서든 같은 지적을 두 번 받거나 실수가 실제 문제로 이어졌으면, 저장소 전용이면 그 저장소 `CLAUDE.md`에, 저장소를 가리지 않으면 `claude-md/CLAUDE.md`에 기록한다.
- 줄을 추가할 때 "이 줄이 없으면 Claude가 실제로 실수하는가?"에 예일 때만. 반드시 지켜져야 하는 것은 CLAUDE.md 문장이 아니라 훅으로 만든다.
- `claude-md/CLAUDE.md`를 고쳤으면 `~/.claude/CLAUDE.md`로 다시 복사한다(Mac·Windows 각각). 웹용은 Project instructions도 갱신.

## 참고한 자료

- [Claude Code 공식 — Best practices](https://code.claude.com/docs/en/best-practices), [CLAUDE.md와 메모리](https://code.claude.com/docs/en/memory), [Skills](https://code.claude.com/docs/en/skills), [VS Code 확장](https://code.claude.com/docs/en/vs-code)
- [Agent Skills 공식 — 작성 모범 사례](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), [anthropics/skills](https://github.com/anthropics/skills)
- [Claude 도움말 — 스킬 사용](https://support.claude.com/en/articles/12512180-use-skills-in-claude), [Claude Design 시작하기](https://support.claude.com/en/articles/14604416-get-started-with-claude-design)
- [VS Code — Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [Claude Code 공식 — GitHub Actions](https://code.claude.com/docs/en/github-actions), [Code Review](https://code.claude.com/docs/en/code-review), [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [GitHub 플랜 비교 공식](https://docs.github.com/en/get-started/learning-about-github/githubs-plans), [Rulesets Free 비공개 저장소 불가 — community](https://github.com/orgs/community/discussions/190190), [The Git Workflow That Actually Works for Solo Developers (2026)](https://dev.to/armorbreak/the-git-workflow-that-actually-works-for-solo-developers-2026-2mna), [Popit — GitHub로 프로젝트 관리하기](https://www.popit.kr/github%EB%A1%9C-%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8-%EA%B4%80%EB%A6%AC%ED%95%98%EA%B8%B0-part1-%EC%9D%B4%EC%8A%88-%EB%B0%9C%EA%B8%89-%EB%B6%80%ED%84%B0-%EC%BD%94%EB%93%9C%EB%A6%AC%EB%B7%B0%EA%B9%8C/)
- [Dale Seo — Claude Code GitHub Actions 사용법](https://daleseo.com/claude-code-action/), [Hyperithm — Claude Code 심화 활용법](https://tech.hyperithm.com/claude_code_guides_2), [doug-skinner/github-cli-claude-skill](https://github.com/doug-skinner/github-cli-claude-skill)
- [HumanLayer — Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md), [Writing a CLAUDE.md that Claude actually follows](https://dev.to/peterverse180/writing-a-claudemd-that-claude-actually-follows-4llo)
- [mattpocock/skills — git-guardrails](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md), [claude-code-dotfiles](https://github.com/elizabethfuentes12/claude-code-dotfiles)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code), [josix/awesome-claude-md](https://github.com/josix/awesome-claude-md)
- [Dale Seo — CLAUDE.md 작성 가이드](https://daleseo.com/claude-code-claude-md/), [GeekNews — Claude Code로 좋은 결과 얻기](https://news.hada.io/topic?id=22425)
