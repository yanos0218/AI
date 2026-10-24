# 설치 — 표면별 상세

[README](../README.md) "설치"의 요약을 풀어 쓴 것. 기본 영역이 바뀌어 다시 설치할 때 이 문서를 따름.

## Claude Code (CLI · VS Code 확장 공통)

Windows(Git Bash)·Mac·Linux 공통. `~/.claude/`는 CLI와 VS Code 확장이 같은 파일을 읽음.

```bash
bash tools/install.sh --dry-run   # 무엇이 바뀔지 확인
bash tools/install.sh             # 설치 + check-install.sh 대조
```

기존 `~/.claude/CLAUDE.md`가 다르면 `.bak.<시각>`으로 백업한 뒤 교체하고 diff 명령을 알려 준다(Mac처럼 이미 다른 내용이 있을 수 있는 기기용). 손으로 하려면 아래와 같음.

```bash
cp -r base/skills/<이름> ~/.claude/skills/
cp base/claude-md/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/hooks && cp base/hooks/*.sh ~/.claude/hooks/
mkdir -p ~/.claude/agents && cp base/agents/*.md ~/.claude/agents/
```

`~/.claude/settings.json`이 없으면 `base/settings.example.json`을 복사하고, 있으면 사용자가 넣은 값을 지우지 않고 base 값을 병합함([tools/settings_merge.py](../tools/settings_merge.py), [Issue #194](https://github.com/yanos0218/AI/issues/194)). `permissions`의 allow·ask·deny는 합집합, `hooks`는 base 훅 스크립트를 가리키는 항목만 base 것으로 바꾸고 사용자가 직접 넣은 훅은 유지, `env`는 base 키만 덮음. `statusLine`·`model`·`effortLevel`·`modelSettings`는 base 값으로 맞추고(기본 모델 기준은 [models.md](models.md)), 그 밖의 기기별 키는 유지. 값이 바뀔 때는 `settings.json.bak.<시각>`으로 백업하고, 내용이 다른 스킬은 `~/.claude/backups/claude-config/<시각>/`에 보관한 뒤 교체함. 이 도구가 만든 백업(`CLAUDE.md.bak.<시각>`, `settings.json.bak.<시각>`, 보관 폴더)은 설치할 때마다 종류별 최근 3개만 남기고 자동으로 지움([Issue #196](https://github.com/yanos0218/AI/issues/196)). 이름이 `.bak.<숫자 14자리>`인 것만 대상이라 직접 만든 백업은 그대로고, `--dry-run`은 지울 목록만 보여 주며, 병합이 실패한 설치에서는 지우지 않음. base에서 뺀 allow 항목과 훅은 기기에 남을 수 있고, `check-install.sh`가 정보로 알려 줌. `settings.json`이 깨진 JSON이면 병합만 건너뛰고 나머지는 설치한 뒤 실패로 끝나니, 파일을 고치고 다시 실행함. `$schema` 덕에 VS Code에서 자동완성·검증이 됨. 상태줄 스크립트는 jq → python → node 순으로 있는 것을 써서 Linux에 jq가 없어도 됨. 설치·대조 스크립트 자체는 `python3` → `python` 순으로 찾음(Windows Git Bash엔 `python`만, Mac/Linux엔 `python3`만 있는 경우가 많음). 스킬 목록은 세션 시작 시 고정되므로 복사 후 **새 세션**에서 확인 필요. `permissions.blockReadsOutsideWorkingDirectories`가 켜져 있어 작업 폴더 밖 읽기가 막히므로, 설치가 `~/.claude`와 원본 저장소 경로를 계산해 `permissions.additionalDirectories`에 합집합으로 넣음(그래야 다른 저장소에서도 `config-update`가 버전 파일과 원본 저장소를 읽음, [Issue #205](https://github.com/yanos0218/AI/issues/205)). 다른 저장소를 읽어야 하면 세션에서 `/add-dir`로 그 폴더를 추가함.

**Rocky/AlmaLinux 등 RHEL 계열 최소 설치본**은 버전마다 기본 포함 도구가 다르다(8.10: git·python3 없음, diff·jq 있음 / 9.x: git·diff 없음, python3·jq 있음 — AlmaLinux 8.10·9.8 WSL로 각각 검증, 2026-09-16). 버전을 따지지 말고 먼저 `dnf install -y git diffutils python3`를 실행한다(이미 있으면 `dnf`가 그냥 건너뛰므로 안전). 안 하면 `install.sh`가 python3/python을 못 찾아 멈추거나, `check-install.sh`가 모든 파일을 "다르다"고 오탐한다([Issue #6](https://github.com/yanos0218/AI/issues/6)).

`git-guardrails` 훅은 설정의 `onFailure: "block"`을 쓰므로 Claude Code 2.1.295 이상이 필요함([Issue #211](https://github.com/yanos0218/AI/issues/211)).
이 훅이 시작 실패나 시간 초과로 모든 명령을 막으면 `Edit`로 `~/.claude/settings.json`에서 해당 항목의 `"onFailure": "block"` 줄을 지우거나 직접 편집해 복구함.

영문 로케일 Linux 서버에서 Claude 출력의 한글이 깨져 보여도 한글 폰트·로케일은 설치하거나 바꾸지 않고 그대로 쓴다(2026-09-16 결정, [Issue #6](https://github.com/yanos0218/AI/issues/6)). 검증 기준도 특정 배포판이 아니라 RHEL 계열 전체임.

## Claude.ai (웹 · 데스크톱 · Cowork)

1. `bash tools/pack.sh` → `dist/<스킬이름>.zip` 생성
2. Claude.ai **Customize → Skills → + → Upload a skill**에서 zip 업로드
3. 공통 지침은 프로젝트(Project)의 **Project instructions**에 `base/claude-md/CLAUDE.md` 내용을 붙여넣어 대체

## VS Code

**평소 동기화는 VS Code 내장 Settings Sync**(계정 메뉴 → *Backup and Sync Settings*, GitHub 계정)로 함. 설정·단축키·스니펫·확장·UI 상태·프로필이 계정 단위로 자동 반영되고, 경로 같은 기계 종속 설정은 알아서 제외됨. 커뮤니티에서도 개인 사용자는 Settings Sync, 팀·재현성이 필요하면 dotfiles 저장소를 쓰는 게 일반적임.

이 저장소의 `base/vscode/`는 **Settings Sync를 보완**함.

- `extensions.txt`
  - **선별한** 확장 목록. 새 기기 부트스트랩용이며, 손으로 관리한다(`code --list-extensions` 결과를 그대로 덮어쓰지 않는다).
- `settings.json`
  - 사용자 설정 스냅샷(Claude Code 확장 설정 포함).
- `install.ps1`(Windows) / `install.sh`(Mac·Linux)
  - 확장을 설치하고, 설정 파일이 없을 때만 복사함. 이미 있으면 덮어쓰지 않음.

### 확장 선별 기준

기준은 하나. **실제 저장소가 있는 스택인가, 그리고 CI가 실제로 돌리는 도구인가.** 커뮤니티 "필수" 목록(Prettier·ESLint·GitLens·Error Lens)은 참고만 했음.

| 판단 | 확장 | 이유 |
| --- | --- | --- |
| 유지 | claude-code, 한국어 팩, markdownlint, GitHub Actions, Python 3종, Java pack + Gradle, PowerShell, Remote-SSH, Live Server | 정적 PWA·Spring Boot·FastAPI·셸/PS·Markdown CI·NAS/서버 SSH<br>전부 실제 저장소에 대응 |
| 추가 | Error Lens | 진단을 줄 옆에 바로 보여줌. 코드를 직접 읽지 않는 사용 방식에 가장 도움이 되는 커뮤니티 필수 항목 |
| 제외 | auto-rename-tag | `editor.linkedEditing`(이미 켜져 있음)이 같은 기능 |
| 제외 | diff-merge, PDF 뷰어 | VS Code 내장 diff/merge 에디터로 충분, PDF는 외부 뷰어 |
| 제외 | containers, lldb-dap, python-envs | 로컬에서 Docker/C·C++ 디버깅/환경 관리자를 쓰는 저장소가 없음 |
| Mac 전용 | swift-vscode | Xcode가 있는 Mac에서만 의미. Windows 목록에서 제외 |
| 보류 | Prettier, ESLint, GitLens, EditorConfig | 저장소에 설정 파일(`.prettierrc`, `eslint.config.js`, `.editorconfig`)이 없어 켜면 CI와 다른 기준으로 잔소리만 함. 프로젝트에 설정이 생기면 그때 추가 |

"제외"는 기본 목록에 넣지 않는다는 뜻이지 지우라는 뜻이 아님. 기본 목록 밖에 이미 설치된 확장(의존 확장, 기기별로 쓰는 것)은 문제를 일으키지 않는 한 그대로 둔다(2026-09-09 결정). `install.sh`는 설치만 하고 삭제하지 않으며, `check-install.sh`도 VS Code 확장은 대조하지 않음. Settings Sync가 켜져 있으면 Mac에도 같이 반영되니, Mac에서 쓰는 것(swift 등)은 Mac에서 다시 설치함. WSL에서 `code`가 `/mnt/` 아래 Windows VS Code이면 `check-install.sh`가 MISSING 목록은 보여 주되 판정에서 빼고 안내만 함([Issue #201](https://github.com/yanos0218/AI/issues/201), 마운트 위치를 바꿨으면 `WIN_MOUNT_ROOT`로 지정).

## Claude Code CLI (터미널)

VS Code 확장은 자체 바이너리를 번들해서 쓰므로 **터미널의 `claude` 명령은 별도 설치**해야 함. 공식 권장은 네이티브 설치(npm 방식은 사용 중단):

```powershell
# Windows
irm https://claude.ai/install.ps1 | iex
```

```bash
# Mac/Linux
curl -fsSL https://claude.ai/install.sh | bash
```

`~/.claude/`(CLAUDE.md·skills·hooks·settings.json)는 CLI와 확장이 **같은 파일을 공유**하므로 한 번만 설치하면 둘 다 적용됨. Windows에서는 Claude Code가 명령 실행에 Git Bash를 쓰기 때문에 Git for Windows가 필수이고, 훅 스크립트(`bash ~/.claude/hooks/...`)도 그 bash로 돎. 설치 후 `claude doctor`로 상태를 확인함.

Claude Code 확장 자체 설정(`claudeCode.*`)은 VS Code 설정에, 허용 명령·훅·MCP·모델은 `~/.claude/settings.json`에 둠. 후자는 CLI와 확장이 공유함.

## 참고

- [VS Code — Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [Claude 도움말 — 스킬 사용](https://support.claude.com/en/articles/12512180-use-skills-in-claude)
- [Claude Code 공식 — VS Code 확장](https://code.claude.com/docs/en/vs-code)
