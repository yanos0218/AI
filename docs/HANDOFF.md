# 인수인계 — claude-config

새 세션을 시작할 때 이 파일을 먼저 읽고, 할 일은 [PROGRESS.md](PROGRESS.md)에서 본다. 세션이 끝날 때 "현재 상태"와 PROGRESS.md를 갱신한다.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만든다. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 한다.

## 현재 상태 (2026-09-08)

- 저장소: github.com/yanos0218/AI (비공개), `main` = `d5a3fc1`. **v0.1.0 릴리즈 완료(2026-09-08)**. 이후 로컬 커밋: GitHub 검토표, README 입구화(230→111줄, `docs/install.md`·`github.md`·`review-vs-official.md` 분리), CI(`lint.yml`)·문서 상한 검사·dependabot. 이후 저장소 표준(`docs/repo-standard.md`), 전역 지침 수정안(`drafts/claude-md/`, **C-37 사용자 결정 대기**), 관찰 기록 신설. **push 전** — push하면 첫 Actions 실행 결과를 `gh run list`로 확인할 것.
- **dev-release 발동 테스트 완료(2026-09-08)** — README 시험 시나리오 3개를 스크래치패드에 임시 git 저장소로 만들고 `claude -p "..." --output-format stream-json --verbose` 새 세션으로 실행. A(versioning.md)·B(두 자리 태그) 통과. C(태그·CHANGELOG 없음)는 처음에 `v0.1.0`을 스스로 정해 실패 → SKILL.md §0·§1에 "태그 없으면 형식·시작 번호와 CHANGELOG 생성 여부를 먼저 묻는다" 추가 후 재시험 통과. 설치본 `~/.claude/skills/dev-release/`에도 복사됨.
- 테스트 중 관찰: `cd X && ls -la` 같은 복합 명령은 settings의 `Read(./.env)` deny 규칙 때문에 승인 프롬프트가 뜸(스킬 문제 아님, 모델이 `git -C`·Glob으로 우회함). `python -m py_compile`은 allow 목록에 없어 막힘.
- 자산별 단계(계획/초안/검증/기본)와 표면별 배포 상태는 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태) 표가 원본. 아래 두 줄은 요약.
- Windows PC에 설치 완료: `~/.claude/CLAUDE.md`, `~/.claude/skills/dev-release/`, `~/.claude/hooks/{git-guardrails,statusline}.sh`, `~/.claude/settings.json`(권한 allow/deny·훅·상태줄), CLI `~/.local/bin/claude.exe` v2.1.263, VS Code 확장 13개 선별 설치.
- **Mac mini·Linux는 아직 미반영** — `scripts/hooks/*.sh` 복사 + `scripts/settings.example.json`의 `permissions`/`hooks`/`statusLine` 키를 각자 `settings.json`에 합치면 된다. Mac은 `~/.claude/CLAUDE.md`가 이미 있을 수 있으니 덮어쓰기 전에 내용 확인.
- 웹(Claude.ai)에는 아직 아무것도 안 올림 — `bash scripts/pack.sh` → Customize → Skills 업로드, Project instructions에 `claude-md/CLAUDE.md` 붙여넣기.

## 다음 할 일

[PROGRESS.md](PROGRESS.md) §2·§3의 `C-NN` 항목. 추천 순서: C-09(커밋) → C-10(상태줄·훅 확인) → C-18(GitHub 활용 결정, 사용자 판단) → C-13(개발용 스킬) → C-15/16/17(Mac·Linux·웹 반영).

## 결정 사항 (다시 묻지 말 것)

- 다른 저장소 내용은 복사하지 않고 참조만.
- 강제가 필요한 규칙은 CLAUDE.md 문장이 아니라 훅으로.
- VS Code 동기화는 내장 Settings Sync가 주, `vscode/`는 부트스트랩·백업. Prettier/ESLint/GitLens는 저장소에 설정 파일이 생길 때까지 보류.
- 에이전트 팀·샌드박스(Windows 미지원)·LSP 플러그인·알림 훅은 보류. 병렬 작업은 설정이 아니라 습관 항목.
- 커밋은 사용자가 요청할 때만. push·배포·삭제는 확인 후.
- (2026-09-08) 이 저장소도 태그를 쓴다. `docs/versioning.md` — 시작 `v0.1.0`, 기본 영역 변경만 등급 반영, Release에 `pack.sh` zip 첨부.
- (2026-09-08) 기본 영역(`claude-md/`, `skills/<이름>/`, `scripts/`, `vscode/`)은 검증 통과 + 사용자의 명시적 반영 요청이 있을 때만 수정. 초안은 `drafts/`. `baseline-guard` 훅이 확인을 강제한다.
- (2026-09-08) 사용자 성향 데이터는 세 곳(로컬 auto memory, claude.ai 메모리, `/insights`)에서 모아 `drafts/claude-md/`에 후보로 두고, 전역 지침 반영은 사용자 확인 후.
