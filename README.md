# claude-config

**개인용 Claude 설정의 원본 저장소.** 개발자가 아닌 사용자가 여러 프로젝트를 오가며 Claude Code(CLI·VS Code)와 Claude.ai(웹·데스크톱)를 쓸 때, 매번 같은 설명을 반복하지 않고 · 멋대로 진행하거나 너무 자주 묻지 않게 하고 · 검증 없이 "됐다"고 못 하게 하고 · 결론만 짧게 듣기 위한 지침·스킬·훅·설정을 여기서 만들고, 검증하고, 각 기기와 웹에 배포함.

저장소 전용 규칙은 각 저장소에 두고 여기서는 참조만 함. 다른 저장소 내용을 복사하지 않음.

구성 요소가 어떻게 이어지고 어떤 순서로 운영되는지(자산 수명·훅이 도는 시점·세션·릴리즈·점검)는 [docs/operating-flow.md](docs/operating-flow.md). 맨 위에 전체 흐름도(그림)가 있음.

## 구조 — 네 묶음

파일은 역할이 넷으로 나뉨. **①만 실제로 배포**되고, 나머지는 ①을 만들고 지키기 위한 것임. 폴더 이름이 곧 영역임.

### ① `base/` — 배포되는 것 (기본 영역)

검증을 마치고 사용자가 반영을 요청한 것만 들어옴. `~/.claude`와 Claude.ai에 복사되는 원본. Claude가 여기를 고치려 하면 [baseline-guard.sh](.claude/hooks/baseline-guard.sh)가 확인을 요구함.

| 경로 | 무엇 |
| --- | --- |
| [base/claude-md/CLAUDE.md](base/claude-md/CLAUDE.md) | 모든 프로젝트에 적용되는 공통 지침 (언어, 답변 방식, 확인 기준, 검증, Git) |
| [base/skills/dev-release/](base/skills/dev-release/SKILL.md) | "버전 올려줘 / 릴리즈 하자"에 발동하는 릴리즈 절차 스킬 |
| [base/skills/dev-workflow/](base/skills/dev-workflow/SKILL.md) | "테스트 어떻게 해 / 파일 정리해줘"에 발동. 구조·테스트 방법을 문서로 정하고 실행 증거를 보고 |
| [base/skills/repo-setup/](base/skills/repo-setup/SKILL.md) | "저장소 표준 맞춰줘 / 뭐가 빠졌는지 봐줘"에 발동. [docs/repo-standard.md](docs/repo-standard.md) 9항목 대조 후 고른 것만 생성 |
| [base/skills/self-audit/](base/skills/self-audit/SKILL.md) | "self-audit 해줘 / CLAUDE.md 점검해줘"에 발동. 대화 기록을 서브에이전트로 읽어 문서화 안 된 결정·안 지켜진 규칙 후보를 찾음(3시나리오 발동 시험 통과, 2026-09-13) |
| [base/skills/pdf-extract/](base/skills/pdf-extract/SKILL.md) | "PDF 요약해줘 / PDF 텍스트 뽑아줘"에 발동. MarkItDown으로 텍스트 변환 후 읽어 토큰 절약(4쪽 실측 −62%), 스캔본·글자 깨짐은 직접 읽기로 전환. MarkItDown은 `~/.claude/venvs/markitdown` 가상환경(설치는 사용자 승인 후) |
| [base/skills/config-update/](base/skills/config-update/SKILL.md) | "설정 업데이트해줘"에 발동. 어느 저장소에 있든 원본 경로(`~/.claude/.claude-config-version`)로 원격을 받아와 `base/`가 바뀌었을 때만 `install.sh`+`check-install.sh` 실행(2시나리오 발동 시험 2026-09-17, 원격 확인 3시나리오 2026-09-28) |
| [base/skills/live-status/](base/skills/live-status/SKILL.md) | "실시간 대시보드 켜줘 / 지금 돌고 있는 세션 보여줘"에 발동. `claude agents --json`과 서브에이전트 기록을 읽어 세션·서브에이전트 구조도와 타임라인을 로컬 웹 화면으로 보여 줌(토큰 소모 없음) |
| [base/skills/usage-dashboard/](base/skills/usage-dashboard/SKILL.md) | "토큰 대시보드 켜줘 / 대시보드 열어줘"에 발동. 요청할 때만 켜는 토큰 사용 기록(Stop 훅)과 로컬 대시보드, Windows·Mac 전용 |
| [base/hooks/](base/hooks/) | 전역 훅 12개<br>위험 명령 확인 `git-guardrails.sh`, GitHub 쓰기 간격 `gh-throttle.sh`, 커밋·이슈·문서 형식 검사 `format-guard.sh`·`md-format-check.sh`, 커밋 때 문서 낡음 알림 `doc-drift-check.sh`, 상태줄 `statusline.sh`, 설정 변경·대량 조회 기록, 컴팩션 안전망, 세션 시작 점검, verifier 차단. 언제 도는지는 [docs/operating-flow.md](docs/operating-flow.md#훅이-도는-시점) |
| [base/agents/](base/agents/) | 용도별 서브에이전트<br>조사 `researcher`(Sonnet, 읽기·웹만), 문서·참조 점검 `auditor`(Sonnet, 읽기만), 검사 실행 `verifier`(Haiku, 쓰기·커밋 명령은 `verifier-guard.sh`가 차단). `~/.claude/agents/`에 설치 |
| [base/settings.example.json](base/settings.example.json) | `~/.claude/settings.json` 예시 (허용·거부 명령, 훅, 상태줄, 기본 모델·effort) |
| [base/rules/](base/rules/) | 모듈 규칙<br>기본 지침을 건드리지 않고 주제별로 붙이는 파일. `~/.claude/rules/`에 설치 |
| [base/vscode/](base/vscode/) | 새 기기에 VS Code 확장·설정을 맞추는 목록과 스크립트 |
| [base/skills/_template/](base/skills/_template/SKILL.md) | 새 스킬을 시작할 때 복사하는 틀 (배포 제외) |

### ② `drafts/` — 만드는 중인 것 (작업 영역)

`base/`와 같은 구조로 초안을 두고, 시험을 통과하면 ①로 옮김. 배포·pack 대상이 아님. 승격 절차는 [drafts/README.md](drafts/README.md). 초안 목록과 단계는 [docs/PROGRESS.md §0](docs/PROGRESS.md#0-자산-현황--단계와-배포-상태) 표.

### ③ `docs/` — 이 저장소를 운영하기 위한 문서

| 경로 | 무엇 |
| --- | --- |
| [docs/operating-flow.md](docs/operating-flow.md) | 구성 요소가 적용되는 곳, 훅이 도는 시점, 세션·자산·배포·릴리즈·점검 흐름 |
| [docs/HANDOFF.md](docs/HANDOFF.md) | Claude가 새 대화를 시작할 때 읽는 입구<br>지금 상태, 작업 종류별 문서 지도, 핵심 원칙 |
| [docs/decisions.md](docs/decisions.md) | 굳어진 결정 사항(주제별)<br>"다시 묻지 말 것" 목록 |
| [docs/PROGRESS.md](docs/PROGRESS.md) | 진행 보드<br>자산별 단계(계획→초안→검증→기본)와 기기별 배포 상태. 할 일은 GitHub Issues(라벨 `task`/`bug`) |
| [docs/versioning.md](docs/versioning.md) | 이 저장소의 버전·릴리즈 규칙 |
| [docs/install.md](docs/install.md) | 기기·웹별 설치 상세 |
| [docs/github.md](docs/github.md) | GitHub를 어디까지 쓰는지, Actions 한도, Claude와 어떻게 엮는지 |
| [docs/repo-standard.md](docs/repo-standard.md) | GitHub를 쓰는 모든 저장소의 최소선 체크리스트와 저장소별 현황 |
| [docs/review-vs-official.md](docs/review-vs-official.md) | 공식 문서·커뮤니티 권장과 대조한 검토표 (반영/습관/보류) |
| [docs/research.md](docs/research.md) | 조사 규칙(최신·검증·출처, 기록은 Issues `research` 라벨) |
| [docs/issue-format.md](docs/issue-format.md) | 이슈 라벨별 작성 형식(개발/버그·에러/조사/제안) |
| [docs/skill-development.md](docs/skill-development.md) | 새 스킬 만드는 절차와 시험 방법 |
| [docs/os-differences.md](docs/os-differences.md) | 운영체제별 차이 구분표<br>공통·운영체제별(코드·설치)·기기별로 나눈 항목과 새 차이가 생겼을 때 처리 순서 |
| [docs/models.md](docs/models.md) | 개발 작업의 기본 모델·effort 기준(Sonnet 5.5 medium), 올리는 법, 기기 간 어긋남 확인 |
| [docs/testing.md](docs/testing.md) | 바꾼 것별 검사 명령·시험 도구, 세 OS(Mac bash 3.2) 호환 규칙, 설치는 커밋 뒤 |
| [docs/research/](docs/research/README.md) | 2026-09-13 이전 조사 기록(archive)<br>새 조사는 Issues `research` 라벨 |
| [docs/tool-catalog.md](docs/tool-catalog.md) | 조사한 외부 도구·내장 기능 목록<br>상황별 판정(도입·조건부·쓰지 말 것)과 확인일, 근거 이슈 |
| [docs/monthly-check.md](docs/monthly-check.md) | 월 점검 체크리스트 14항목 |
| [docs/config-lifecycle.md](docs/config-lifecycle.md) | 다른 저장소에서 작업해도 기본 설정이 유지되는 구조(기본·모듈·프로젝트 층)와 변경 이력 장치 |
| [CHANGELOG.md](CHANGELOG.md) · [CLAUDE.md](CLAUDE.md) | 기본 영역의 버전별 변경 이력 · 이 저장소 안에서 Claude가 지킬 규칙 |

### ④ `tools/`, `.claude/`, `.github/` — 자동화·검사

| 경로 | 무엇 |
| --- | --- |
| [tools/bootstrap.sh](tools/bootstrap.sh) | 신규 기기용 단일 명령 설치<br>저장소를 `~/claude-config`에 clone(있으면 pull) 후 `install.sh` 자동 실행 |
| [tools/install.sh](tools/install.sh) | `base/` → `~/.claude` 설치 (멱등, settings 병합, `--dry-run`). 기기 3대 공통 |
| [tools/test-skill.sh](tools/test-skill.sh) | 스킬 발동 시험<br>시나리오 저장소에 넣고 새 세션으로 실행, 발동·비용 추출 (기본 Sonnet) |
| [tools/test-agent.sh](tools/test-agent.sh) | 에이전트 발동 시험<br>같은 폴더 에이전트 전부를 `--agents`로 넘겨 새 세션으로 실행, 위임 대상·에이전트 안 도구 호출·훅 차단·토큰 추출 |
| [tools/pack.sh](tools/pack.sh) | ①의 스킬을 웹 업로드용 zip으로 (zip 없으면 python 폴백) |
| [tools/check-docs.sh](tools/check-docs.sh) | 문서 줄 수 상한과 필수 파일 검사 (CI와 로컬 공용)<br>[tools/check-doc-sync.py](tools/check-doc-sync.py)를 불러 문서 갱신 누락(존재·깨진 참조·개수)도 검사 |
| [tools/check-doc-sync.py](tools/check-doc-sync.py) | 문서 갱신 누락 검사<br>도구·훅·스킬·에이전트·문서가 README·operating-flow에 있는지, 문서 속 경로가 실제로 있는지, 개수 표기가 맞는지 |
| [tools/check-install.sh](tools/check-install.sh) | 설치본 `~/.claude`가 `base/`와 같은지, 프로젝트마다 쌓인 권한·설정 이력은 무엇인지 보고 |
| [tools/settings_merge.py](tools/settings_merge.py) | `install.sh`·`check-install.sh`가 쓰는 settings.json 병합·대조 규칙<br>사용자 값 보존, 변경 시 백업 |
| [tools/test-install-merge.sh](tools/test-install-merge.sh) | 설치 병합 시험<br>임시 폴더에서 사용자 allow·훅·고친 스킬이 보존되고 백업되는지, 재실행·`--dry-run` 결과 확인 |
| [tools/measure-model.sh](tools/measure-model.sh) | 모델별 구독 한도 소모 측정<br>같은 읽기 전용 작업을 모델마다 돌려 5시간·주간 한도 사용률과 정답률 비교, 한도를 쓰므로 실행 전 확인 |
| [tools/fingerprint.sh](tools/fingerprint.sh) | 기기 지문<br>반응에 영향을 주는 값(설치 버전·설치본 최신 여부·모델·effort·CLI·확장·memory 수 등)을 줄마다 [공통](같아야 함)·[기기별](달라도 정상)로 표시해 출력<br>`--common`으로 [공통] 줄만 뽑아 기기끼리 `diff` |
| [tools/test-hooks-py.sh](tools/test-hooks-py.sh) | 파이썬 본체 훅 시험<br>판정 사례, 파이썬 없음·깨진 입력 때 막는 훅은 막고 기록 훅은 통과하는지, 한글 기록 |
| [tools/test-session-start-check.sh](tools/test-session-start-check.sh) | 세션 시작 훅의 설정 낡음 판정 시험<br>원격 앞섬·문서만 바뀐 커밋·옛 버전 파일 형식·fetch 주기 |
| [tools/test-format-guard.sh](tools/test-format-guard.sh) | 형식 검사 훅 시험<br>명령 형태별(커밋·이슈·PowerShell·heredoc) 게시 전 판정과 `.md` 저장 후 판정 |
| [tools/test-progress-stale-check.sh](tools/test-progress-stale-check.sh)<br>[tools/test-git-guardrails.sh](tools/test-git-guardrails.sh)<br>[tools/test-notify.sh](tools/test-notify.sh)<br>[tools/test-live-status.sh](tools/test-live-status.sh)<br>[tools/test-doc-drift.sh](tools/test-doc-drift.sh)<br>[tools/test-easy-explain.sh](tools/test-easy-explain.sh) | 저장소 훅·초안 시험<br>PROGRESS 낡음 알림 훅(설치 버전이 행에 없으면 알림)<br>git-guardrails 훅(판정 유지, 오류 때 전체 차단 대신 확인 창, `onFailure` 등록)<br>알림 훅 초안 `drafts/hooks/notify.sh`(세 운영체제 분기, 60초 임계, 주입 방지)<br>실시간 세션 현황 `base/skills/live-status`(상태 추적·HTTP·Host 검사·개인정보 비노출)<br>문서 낡음 알림 훅 `base/hooks/doc-drift-check.sh`(사라진 경로 참조·링크 대상·CHANGELOG 문구, 경고만) |
| [tools/check-cram.sh](tools/check-cram.sh)·[base/hooks/check-cram.py](base/hooks/check-cram.py) | 목록 줄바꿈 규칙(콜론·em-dash 크램) 검사<br>한 단어 필드명 + 서술문 아닌 값은 필드 나열로 보고 통과<br>`--staged`로 커밋 전 자동 검사, `--add-exception`으로 오탐 예외 등록 |
| [.claude/hooks/](.claude/hooks/) | 저장소 전용 훅<br>`baseline-guard.sh`+`baseline_guard.py`(`base/` 쓰기 확인, 공통 모듈은 `base/hooks/hooklib.py`), `pre-commit-check.sh`(이슈 번호·크램 검사로 커밋 차단, `base/`·`tools/` 변경에 CHANGELOG가 없으면 경고), `handoff-stale-check.sh`(세션 시작 때 HANDOFF가 닫힌 이슈를 가리키면 알림), `progress-stale-check.sh`(세션 시작 때 PROGRESS §0 이 기기 행에 설치 버전이 없으면 알림), `session-end-check.sh`(base/ 변경 시 PROGRESS §0 갱신, 그 외엔 관련 Issue 댓글·닫기 확인 안내) |
| [.github/workflows/lint.yml](.github/workflows/lint.yml) | push마다 markdownlint·shellcheck·문서 상한 검사 |
| [.github/workflows/issue-format-check.yml](.github/workflows/issue-format-check.yml) | 이슈 본문·댓글이 올라오면 라벨별 필수 헤딩과 목록 줄바꿈 규칙을 검사해 위반을 댓글과 라벨로 알림 |
| [.github/dependabot.yml](.github/dependabot.yml) | 워크플로가 쓰는 액션 버전 업데이트 |

## 어디서 무엇이 적용되나

같은 SKILL.md가 모든 표면에서 통하지만, **넣는 방법과 지원 범위가 다르다.** 웹에 올린 스킬과 `~/.claude/skills/`는 서로 자동 동기화되지 않음.

| 표면 | 스킬 | CLAUDE.md | 훅 | 비고 |
| --- | --- | --- | --- | --- |
| Claude Code CLI | `~/.claude/skills/` 복사 | `~/.claude/CLAUDE.md` | `~/.claude/settings.json` | 전부 지원 |
| Claude Code VS Code 확장 | CLI와 동일 (`~/.claude` 공유) | 동일 | 동일 | 명령/스킬은 CLI의 부분집합(`/`로 확인). `!`·탭 완성 없음 |
| Claude.ai 웹 · 데스크톱 채팅 | **Customize → Skills**에 zip 업로드(Pro 이상) | 없음 → 프로젝트 **Project instructions**에 붙여넣기 | 없음 | 계정 단위. 코드 실행 켜져 있어야 함 |
| Cowork (데스크톱) | 계정에서 켠 스킬을 세션 시작 시 로드. `~/.claude/skills/`는 **안 읽음** | 없음 | 없음 | 로컬 전용 스킬을 쓰려면 웹에도 올리거나 저장소 `.claude/skills/`에 커밋 |
| Claude Design (`claude.ai/design`) | 없음<br>디자인 시스템(스크린샷·자산·코드베이스) 첨부로 대체 | 없음 | 없음 | 결과를 Claude Code로 handoff 가능 |
| 클라우드 세션 (claude.ai/code) | 계정 스킬 + 저장소 `.claude/skills/` | 저장소 `CLAUDE.md` | 저장소 settings | 개인 `~/.claude`는 전달 안 됨 |

결론: **원본은 이 저장소, 배포는 두 갈래**다: (1) `~/.claude`에 복사(CLI·VS Code), (2) `pack.sh`로 zip 만들어 웹에 업로드(웹·데스크톱·Cowork). 웹에서 켠 스킬을 CLI로 끌어오는 `CLAUDE_CODE_SYNC_SKILLS=1 claude -p ...`도 있지만 비대화형 전용이라 이 저장소 방식이 더 단순함.

## 설치 (요약)

기본 영역이 바뀌면 각 기기에서 다시 설치함. 상세와 Claude.ai·VS Code 절차는 [docs/install.md](docs/install.md).

```bash
# 신규 기기 — clone 없이 한 줄로
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yanos0218/AI/main/tools/bootstrap.sh)"

# 이미 clone된 저장소 — 갱신
bash tools/install.sh            # --dry-run 으로 먼저 볼 수 있음
```

이미 설치돼 있으면 어느 저장소에 있든 "설정 업데이트해줘"라고 말해도 된다(`config-update` 스킬).

CLAUDE.md·훅·스킬을 복사하고 `settings.json`에 `permissions`·`hooks`·`statusLine`·`env`·`model`·`effortLevel`·`modelSettings`·`language` 키를 합침(그 밖의 기기별 키는 유지). 스킬·훅은 **새 세션**부터 적용됨. 어느 기기에 어느 버전이 깔렸는지는 [docs/PROGRESS.md §0](docs/PROGRESS.md#0-자산-현황--단계와-배포-상태) 표.
