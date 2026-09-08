# 설치 — 표면별 상세

[README](../README.md) "설치"의 요약을 풀어 쓴 것. 기본 영역이 바뀌어 다시 설치할 때 이 문서를 따른다.

## Claude Code (CLI · VS Code 확장 공통)

Windows(Git Bash)·Mac·Linux 공통. `~/.claude/`는 CLI와 VS Code 확장이 같은 파일을 읽는다.

```bash
cp -r base/skills/dev-release ~/.claude/skills/
cp base/claude-md/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/hooks && cp base/hooks/*.sh ~/.claude/hooks/
```

`~/.claude/settings.json`이 없으면 `base/settings.example.json`을 복사하고, 있으면 `permissions`·`hooks`·`statusLine` 키를 합친다(`model` 등 기기별 값은 기존 것 유지). `$schema` 덕에 VS Code에서 자동완성·검증이 된다. 상태줄 스크립트는 jq → python → node 순으로 있는 것을 쓰므로 Linux에 jq가 없어도 된다. 스킬 목록은 세션 시작 시 고정되므로 복사 후 **새 세션**에서 확인한다.

## Claude.ai (웹 · 데스크톱 · Cowork)

1. `bash tools/pack.sh` → `dist/<스킬이름>.zip` 생성
2. Claude.ai **Customize → Skills → + → Upload a skill**에서 zip 업로드
3. 공통 지침은 프로젝트(Project)의 **Project instructions**에 `base/claude-md/CLAUDE.md` 내용을 붙여넣어 대체

## VS Code

**평소 동기화는 VS Code 내장 Settings Sync**(계정 메뉴 → *Backup and Sync Settings*, GitHub 계정)로 한다. 설정·단축키·스니펫·확장·UI 상태·프로필이 계정 단위로 자동 반영되고, 경로 같은 기계 종속 설정은 알아서 제외된다. 커뮤니티에서도 개인 사용자는 Settings Sync, 팀·재현성이 필요하면 dotfiles 저장소를 쓰는 게 일반적이다.

이 저장소의 `base/vscode/`는 **Settings Sync를 보완**한다.

- `extensions.txt` — **선별한** 확장 목록. 새 기기 부트스트랩용이며, 손으로 관리한다(`code --list-extensions` 결과를 그대로 덮어쓰지 않는다).
- `settings.json` — 사용자 설정 스냅샷(Claude Code 확장 설정 포함).
- `install.ps1`(Windows) / `install.sh`(Mac·Linux) — 확장을 설치하고, 설정 파일이 없을 때만 복사한다. 이미 있으면 덮어쓰지 않는다.

### 확장 선별 기준

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

## Claude Code CLI (터미널)

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

## 참고

- [VS Code — Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [Claude 도움말 — 스킬 사용](https://support.claude.com/en/articles/12512180-use-skills-in-claude), [Claude Code 공식 — VS Code 확장](https://code.claude.com/docs/en/vs-code)
