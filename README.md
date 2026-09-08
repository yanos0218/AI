# claude-config

개인용 Claude 설정 원본 저장소. Claude Code(CLI·VS Code 확장)와 Claude.ai(웹·데스크톱·Design)에서 쓰는 **저장소를 가리지 않는** 스킬·공통 지침(CLAUDE.md)·훅·VS Code 설정을 여기서 관리하고 배포한다.

저장소 전용 규칙·스킬은 각 저장소(`CLAUDE.md`, `.claude/skills/`)에 두고, 여기서는 **참조만** 한다. 다른 저장소의 내용을 이쪽으로 복사하지 않는다.

## 구조

```text
docs/HANDOFF.md                            새 세션 인수인계 — 현재 상태·다음 할 일·결정 사항 (세션 시작 시 먼저 읽기)
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
- [HumanLayer — Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md), [Writing a CLAUDE.md that Claude actually follows](https://dev.to/peterverse180/writing-a-claudemd-that-claude-actually-follows-4llo)
- [mattpocock/skills — git-guardrails](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md), [claude-code-dotfiles](https://github.com/elizabethfuentes12/claude-code-dotfiles)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code), [josix/awesome-claude-md](https://github.com/josix/awesome-claude-md)
- [Dale Seo — CLAUDE.md 작성 가이드](https://daleseo.com/claude-code-claude-md/), [GeekNews — Claude Code로 좋은 결과 얻기](https://news.hada.io/topic?id=22425)
