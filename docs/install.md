# 설치 — 표면별 상세

[README](../README.md) "설치"의 요약을 풀어 쓴 것. 기본 영역이 바뀌어 다시 설치할 때 이 문서를 따름.

## Claude Code (CLI · VS Code 확장 공통)

Windows(Git Bash)·Mac·Linux 공통. `~/.claude/`는 CLI와 VS Code 확장이 같은 파일을 읽음.

```bash
bash tools/install.sh --dry-run   # 무엇이 바뀔지 확인
bash tools/install.sh             # 설치 + check-install.sh 대조
```

기존 `~/.claude/CLAUDE.md`가 다르면 `.bak.<시각>`으로 백업한 뒤 교체하고 diff 명령을 알려 줌(Mac처럼 이미 다른 내용이 있을 수 있는 기기용). 손으로 하려면 아래와 같음.

```bash
cp -r base/skills/<이름> ~/.claude/skills/
cp base/claude-md/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/hooks && cp base/hooks/*.sh ~/.claude/hooks/
mkdir -p ~/.claude/agents && cp base/agents/*.md ~/.claude/agents/
```

스킬 목록은 세션 시작 시 고정되므로 복사 후 **새 세션**에서 확인 필요.

### Windows 처음 설치 (PowerShell 한 줄)

bash·git·python이 없는 깨끗한 Windows에서 시작하는 방법임([Issue #247](https://github.com/yanos0218/AI/issues/247)). PowerShell(관리자 권한 불필요 여부는 미검증)에서 한 줄을 실행함.

```powershell
irm https://raw.githubusercontent.com/yanos0218/AI/main/tools/install.ps1 | iex
```

- 1단계(PowerShell만)
  - 최신 릴리즈 zip을 받아 `base/`를 `~/.claude`에 복사함. 저장소를 따로 받지 않음.
  - `settings.json`이 없으면 훅과 상태줄을 뺀 값으로 만듦. bash 없이 훅을 등록하면 `git-guardrails`(`onFailure: "block"`)가 모든 명령을 막을 수 있어서임.
  - 이미 `settings.json`이 있으면 건드리지 않음.
- 2단계(Git for Windows와 Python 3가 있을 때)
  - zip 안의 `tools/install.sh`로 훅 포함 전체 병합을 실행함.
  - 둘 중 없는 것이 있으면 동의를 물은 뒤 `winget`으로 설치함.
    - `winget`이 없거나 실패하면(2026-11-03 `winget` v1.2 PC에서 프로그램이 죽음) 설치 파일을 직접 받아 무음 설치함. Git은 GitHub 릴리즈의 sha256과 대조하고, Python은 3.12.10 주소 고정(해시 없음). 64비트(x64)만 지원함.
    - 권한 창(UAC)은 화면에서 직접 결정함. 거절하거나 실패하면 1단계에서 멈추고 직접 설치 주소를 안내함.
  - 설치 뒤 같은 명령을 다시 실행해도 안전함(같은 파일은 건드리지 않고 다른 파일은 백업 후 교체).
- 주의
  - `irm ... | iex` 한 줄로 실행함. `.ps1` 파일로 저장해 실행하면 한글이 깨지거나 실행 정책에 막힐 수 있음.
  - 설치가 끝나면 Claude Code와 터미널 창을 모두 닫고 **새 터미널 창**에서 Claude Code를 시작함.
    - 설치 전에 연 창은 방금 바뀐 PATH를 모름. 같은 창에서 다시 시작하면 `python`·`python3`가 모두 Store 별칭으로 잡혀 상태줄이 `[] 0%`로 깨지고 python을 쓰는 훅이 실패함(2026-11-04 실제 PC, [Issue #259](https://github.com/yanos0218/AI/issues/259)).
    - Claude Code 세션 안에서 설치기를 실행하면 그 세션에 훅이 바로 적용됨. 세션이 Git Bash 없이 시작했으면 훅이 `bash`를 찾지 못해 `git-guardrails`(`onFailure: "block"`)가 이후 명령을 모두 막음. 다시 시작하면 풀림(2026-11-04 실제 PC, [Issue #258](https://github.com/yanos0218/AI/issues/258)).
    - 설치기는 Git·Python을 새로 설치했으면 새 창 안내를, Claude Code 세션 안(`CLAUDECODE=1`)에서 Git Bash 없이 시작했으면 차단 경고를 끝에 출력함.
  - 보안 프로그램이 한 줄 실행을 막으면 [GitHub Releases](https://github.com/yanos0218/AI/releases)에서 zip을 받아 Git Bash에서 `bash tools/install.sh`를 실행함.
  - 설정 파일과 `tools/install.sh`는 최신 릴리즈 zip에서 오므로 릴리즈 컷 전의 `base/`·`tools/` 변경은 반영되지 않음. `install.ps1` 자체만 `main`에서 받음.
  - 주소의 `main` 파일은 GitHub가 약 5분 캐시하므로 push 직후에는 옛 `install.ps1`이 내려올 수 있음.
  - 갱신
    - 이 설치는 원본 저장소(git)가 없는 패키지 설치라 `config-update` 스킬로 갱신할 수 없음. 스킬은 패키지 설치를 알아보고 한 줄 설치기 재실행을 안내한 뒤 끝남([Issue #248](https://github.com/yanos0218/AI/issues/248)).
    - 새 릴리즈가 나오면 세션 시작 훅이 하루 한 번 최신 릴리즈 태그를 받아 비교해 한 줄로 알림. 같은 한 줄 명령을 다시 실행하면 갱신됨([Issue #252](https://github.com/yanos0218/AI/issues/252)).
  - 시험용 환경변수는 `tools/install.ps1` 머리말 참고(`CLAUDE_CONFIG_DIR`, `CLAUDE_CONFIG_ZIP`, `CLAUDE_CONFIG_ASSUME`).
  - 2026-11-04 실제 깨끗한 Windows(`winget` v1.2, bash·git·python 없음)에서 한 줄 실행으로 훅 병합까지 끝나고 새 Claude Code 세션에서 `/hooks`와 상태줄이 보이는 것을 확인함([Issue #247](https://github.com/yanos0218/AI/issues/247)). Windows PowerShell 5.1 CI 시험은 [Issue #249](https://github.com/yanos0218/AI/issues/249).

### Windows에서 실행하는 위치

`.sh` 스크립트는 **Git Bash**(Git for Windows에 들어 있음)에서 실행함. PowerShell·cmd에서는 돌지 않음.

PowerShell에서 `bash`가 `CommandNotFoundException`("'bash' 용어가 cmdlet, 함수, 스크립트 파일 또는 실행할 수 있는 프로그램 이름으로 인식되지 않습니다")으로 실패하면 이 PC에 bash가 없다는 뜻임(2026-11-03 Windows 실제 오류).

- 해결
  - [Git for Windows](https://git-scm.com/downloads/win)를 설치한 뒤 **Git Bash**를 새로 열어 실행함(관리자 권한 불필요 여부는 미검증).
  - 이미 설치했는데 같은 오류면 PATH에 없는 것이므로 PowerShell에서 전체 경로로 호출함.
    - `& "C:\Program Files\Git\bin\bash.exe" tools/install.sh --dry-run`
    - 이 경로는 공식 setup 문서의 `CLAUDE_CODE_GIT_BASH_PATH` 예시에서 확인했고, 실제 실행은 미검증.
- WSL이 없는 PC라서 `bash`가 WSL로 새지는 않았음(WSL이 있었다면 오류 문구가 달랐을 것).
- `install.sh` 파일 하나만 내려받아 실행하면 안 됨.
  - 같은 저장소의 `base/`와 `tools/settings_merge.py`를 복사하고 `git`으로 버전을 구하기 때문임.
  - 저장소를 따로 받지 않으려면 아래 한 줄 설치(`bootstrap.sh`)를 Git Bash에서 실행함.

- 열기
  - 시작 메뉴에서 "Git Bash"를 열거나, VS Code 터미널 프로필을 Git Bash로 고름.
- PowerShell·cmd에서 `bash`를 치면 Git Bash가 아니라 WSL(`C:\WINDOWS\system32\bash.exe`)이 실행됨.
  - `~/.claude`가 없는 리눅스 홈을 보고 설치되어 Windows의 Claude Code에는 적용되지 않음([Issue #194](https://github.com/yanos0218/AI/issues/194), [os-differences.md](os-differences.md)).
- 확인 명령(Git Bash에서)
  - `uname -s`가 `MINGW64_NT-...`처럼 `MINGW`로 시작하면 Git Bash임.
  - `command -v python python3` 중 하나는 나와야 함(설치·대조 스크립트가 필요로 함).
- `./tools/install.sh`처럼 직접 실행하지 않고 항상 `bash tools/install.sh`로 호출함.
  - 저장소의 `.sh`에는 실행 권한이 없어 Mac·Linux에서도 직접 실행은 안 됨.
- 신규 기기용 한 줄 설치(`tools/bootstrap.sh`, [README](../README.md) "설치")도 Git Bash에서 실행함.
- PowerShell에서 실행하는 것은 VS Code용 `base/vscode/install.ps1`뿐임(`pwsh -File base/vscode/install.ps1`).

### settings.json 병합

`~/.claude/settings.json`이 없으면 `base/settings.example.json`을 복사하고, 있으면 사용자가 넣은 값을 지우지 않고 base 값을 병합함([tools/settings_merge.py](../tools/settings_merge.py), [Issue #194](https://github.com/yanos0218/AI/issues/194)).

- 키별 병합 방식
  - `permissions`의 allow·ask·deny
    - 합집합.
  - `hooks`
    - base 훅 스크립트를 가리키는 항목만 base 것으로 바꾸고, 사용자가 직접 넣은 훅은 유지.
  - `env`
    - base 키만 덮음.
  - `statusLine`·`model`·`effortLevel`·`modelSettings`·`language`
    - base 값으로 맞춤(기본 모델 기준은 [models.md](models.md)).
  - 그 밖의 기기별 키
    - 유지.
- 백업
  - 값이 바뀔 때 `settings.json.bak.<시각>`으로 백업.
  - 내용이 다른 스킬은 `~/.claude/backups/claude-config/<시각>/`에 보관한 뒤 교체.
  - 이 도구가 만든 백업(`CLAUDE.md.bak.<시각>`, `settings.json.bak.<시각>`, 보관 폴더)은 설치할 때마다 종류별 최근 3개만 남기고 자동 삭제([Issue #196](https://github.com/yanos0218/AI/issues/196)).
  - 이름이 `.bak.<숫자 14자리>`인 것만 대상이라 직접 만든 백업은 그대로임.
  - `--dry-run`은 지울 목록만 보여 주고, 병합이 실패한 설치에서는 지우지 않음.
- 읽기 차단과 추가 폴더
  - `permissions.blockReadsOutsideWorkingDirectories`가 켜져 있어 `Read` 도구의 작업 폴더 밖 읽기가 막힘. 대화형 `Bash`는 막히지 않음([Issue #228](https://github.com/yanos0218/AI/issues/228), [review-vs-official.md](review-vs-official.md)).
  - 설치가 `~/.claude`와 원본 저장소 경로를 계산해 `permissions.additionalDirectories`에 합집합으로 넣음. 그래야 다른 저장소에서도 `config-update`가 버전 파일과 원본 저장소를 읽음([Issue #205](https://github.com/yanos0218/AI/issues/205)).
  - 다른 저장소를 읽어야 하면 세션에서 `/add-dir`로 그 폴더를 추가함.
- 주의할 점
  - base에서 뺀 allow 항목과 훅은 기기에 남을 수 있고, `check-install.sh`가 정보로 알려 줌.
  - `settings.json`이 깨진 JSON이면 병합만 건너뛰고 나머지는 설치한 뒤 실패로 끝남. 파일을 고치고 다시 실행함.
  - `$schema` 덕에 VS Code에서 자동완성·검증이 됨.
- 실행 환경
  - 상태줄 스크립트는 jq → python → node 순으로 있는 것을 써서 Linux에 jq가 없어도 됨.
  - 설치·대조 스크립트는 `python3` → `python` 순으로 찾음(Windows Git Bash엔 `python`만, Mac/Linux엔 `python3`만 있는 경우가 많음).

### git-guardrails 훅

- `onFailure: "block"` 설정을 쓰므로 Claude Code 2.1.295 이상이 필요함([Issue #211](https://github.com/yanos0218/AI/issues/211)).
- 이 훅이 시작 실패나 시간 초과로 모든 명령을 막으면 복구함.
  - `Edit`로 `~/.claude/settings.json`에서 해당 항목의 `"onFailure": "block"` 줄을 지우거나 직접 편집.

### Rocky/AlmaLinux 등 RHEL 계열 최소 설치본

- 버전마다 기본 포함 도구가 다름
  - 8.10: git·python3 없음, diff·jq 있음.
  - 9.x: git·diff 없음, python3·jq 있음.
  - AlmaLinux 8.10·9.8 WSL로 각각 검증(2026-09-16).
- 버전을 따지지 말고 먼저 `dnf install -y git diffutils python3`를 실행함.
  - 이미 있으면 `dnf`가 그냥 건너뛰므로 안전.
  - 안 하면 `install.sh`가 python3/python을 못 찾아 멈추거나, `check-install.sh`가 모든 파일을 "다르다"고 오탐함([Issue #6](https://github.com/yanos0218/AI/issues/6)).
- 영문 로케일 Linux 서버에서 Claude 출력의 한글이 깨져 보여도 한글 폰트·로케일은 설치하거나 바꾸지 않고 그대로 씀.
  - 2026-09-16 결정, [Issue #6](https://github.com/yanos0218/AI/issues/6).
  - 검증 기준도 특정 배포판이 아니라 RHEL 계열 전체임.

## Claude Code CLI (터미널)

VS Code 확장은 자체 바이너리를 번들해서 쓰므로 **터미널의 `claude` 명령은 별도 설치**해야 함. 공식 권장은 네이티브 설치(npm 방식은 사용 중단).

```powershell
# Windows
irm https://claude.ai/install.ps1 | iex
```

```bash
# Mac/Linux
curl -fsSL https://claude.ai/install.sh | bash
```

- `~/.claude/`(CLAUDE.md·skills·hooks·settings.json)는 CLI와 확장이 **같은 파일을 공유**하므로 한 번만 설치하면 둘 다 적용됨.
- Git for Windows는 Claude Code 자체에는 선택이지만, 이 설정에는 필요함(2026-11-03 공식 문서 확인, [setup](https://code.claude.com/docs/en/setup)).
  - 없으면 Claude Code는 셸 명령을 PowerShell 도구로 실행함.
  - 이 저장소의 훅은 `bash ~/.claude/hooks/...` 형태라 Git Bash가 있어야 돎. 없으면 훅이 PowerShell로 실행되어 깨질 수 있음.
- 설치 후 `claude doctor`로 상태를 확인함.
- 설정 위치
  - 확장 자체 설정(`claudeCode.*`)은 VS Code 설정.
  - 허용 명령·훅·MCP·모델은 `~/.claude/settings.json`(CLI와 확장이 공유).

## Claude.ai (웹 · 데스크톱 · Cowork)

1. `bash tools/pack.sh` → `dist/<스킬이름>.zip` 생성
2. Claude.ai **Customize → Skills → + → Upload a skill**에서 zip 업로드
3. 공통 지침은 프로젝트(Project)의 **Project instructions**에 `base/claude-md/CLAUDE.md` 내용을 붙여넣어 대체

## VS Code

**평소 동기화는 VS Code 내장 Settings Sync**(계정 메뉴 → *Backup and Sync Settings*, GitHub 계정)로 함. 설정·단축키·스니펫·확장·UI 상태·프로필이 계정 단위로 자동 반영되고, 경로 같은 기계 종속 설정은 알아서 제외됨. 커뮤니티에서도 개인 사용자는 Settings Sync, 팀·재현성이 필요하면 dotfiles 저장소를 쓰는 게 일반적임.

이 저장소의 `base/vscode/`는 **Settings Sync를 보완**함.

- `extensions.txt`
  - **선별한** 확장 목록. 새 기기 부트스트랩용이며, 손으로 관리함(`code --list-extensions` 결과를 그대로 덮어쓰지 않음).
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
| 보류 | Prettier, ESLint, GitLens, EditorConfig | 저장소에 설정 파일(`.prettierrc`, `eslint.config.js`, `.editorconfig`)이 없어 켜면 CI와 다른 기준으로 잔소리만 함<br>프로젝트에 설정이 생기면 그때 추가 |

"제외"는 기본 목록에 넣지 않는다는 뜻이지 지우라는 뜻이 아님.

- 기본 목록 밖에 이미 설치된 확장(의존 확장, 기기별로 쓰는 것)은 문제를 일으키지 않는 한 그대로 둠(2026-09-09 결정).
- `install.sh`는 설치만 하고 삭제하지 않으며, `check-install.sh`도 VS Code 확장은 대조하지 않음.
- Settings Sync가 켜져 있으면 Mac에도 같이 반영되니, Mac에서 쓰는 것(swift 등)은 Mac에서 다시 설치함.
- WSL에서 `code`가 `/mnt/` 아래 Windows VS Code이면 `check-install.sh`가 MISSING 목록은 보여 주되 판정에서 빼고 안내만 함.
  - [Issue #201](https://github.com/yanos0218/AI/issues/201).
  - 마운트 위치를 바꿨으면 `WIN_MOUNT_ROOT`로 지정.

## 참고

- [VS Code — Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [Claude 도움말 — 스킬 사용](https://support.claude.com/en/articles/12512180-use-skills-in-claude)
- [Claude Code 공식 — VS Code 확장](https://code.claude.com/docs/en/vs-code)
