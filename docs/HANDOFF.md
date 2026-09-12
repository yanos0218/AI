# 인수인계 — claude-config

새 세션을 시작할 때 이 파일을 먼저 읽고, 할 일은 [PROGRESS.md](PROGRESS.md)에서 본다. 세션이 끝날 때 "현재 상태"와 PROGRESS.md를 갱신한다.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만든다. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 한다.

## 현재 상태 (2026-09-12) · 마지막 월 점검: 없음 (첫 점검 2026-10 예정, `docs/monthly-check.md`)

- 저장소: github.com/yanos0218/AI (비공개). **v0.6.0까지 릴리즈**(2026-09-08 v0.1.0 첫 컷 → v0.2.0 지침 확인 기준 변경 → v0.3.0 `base/`·`tools/` 경로 재구성 → 2026-09-09 v0.4.0 config-changelog 훅 → v0.5.0 rules 모듈·dev-workflow·지침 §2·§5·§7 → v0.6.0 repo-setup 스킬, 사용자 명시 요청 컷). CI(`lint.yml`) 초록. 자산별 단계·기기별 배포는 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태) 표가 원본.
- **Windows PC = v0.6.0**(2026-09-12 `install.sh` 재실행, `check-install.sh` 전부 same). CLI `~/.local/bin/claude.exe` v2.1.263, VS Code 확장 13개. 훅 2개(git-guardrails·baseline-guard)는 새 `claude -p` 세션에서 차단 동작 확인. 상태줄은 **터미널 CLI 전용**(VS Code 패널엔 안 나옴), Windows 터미널 육안 확인으로 [C-10](PROGRESS.md#c-10) 완료(2026-09-12).
- **Mac mini·Windows·웹(Claude.ai) = v0.6.0**(웹은 2026-09-12 사용자 업로드, 발동 미검증 — [C-17](PROGRESS.md#c-17)). **Linux는 미반영.** 설치는 `docs/install.md`. Mac 설치 중 `tools/*.sh`의 `python` 호출 실패 → python3 우선으로 수정. Mac은 PATH에 CLI가 없어도 VS Code 확장 내장 바이너리로 `claude` 명령 실행 가능(경로는 [C-10](PROGRESS.md#c-10)).
- 설정이 다른 저장소 작업 중 흔들리지 않게 하는 구조(기본·모듈·프로젝트 층)와 이력 장치는 `docs/config-lifecycle.md`(2026-09-09). 이력 훅은 v0.4.0에서 기본 영역.
- C-18 결정 완료(웹은 OpenClaw에서), C-26 완료(웹 메모리 검토). OpenClaw `CLAUDE.md` 초안은 스크래치패드 브랜치, Script 키 처리 추천은 `docs/progress/C-35.md` — 둘 다 그 저장소에서 사용자 지시로 진행.
- §3 진행(2026-09-09): Dependabot·2FA 확인, Actions 월 환산 11%, Issues 시험 시작(#1), `base/rules/` 첫 모듈, repo-setup 스킬 **승격·v0.6.0**([C-35](PROGRESS.md#c-35) 완료; Script 점검에서 **이력 속 개인키 발견** → 사용자 결정), claude.ai 메모리는 zip 파일 대기([C-26](PROGRESS.md#c-26)).
- §2 개발·설정 항목 정리(2026-09-09): `tools/install.sh`·`test-skill.sh`, Stop 훅, 권한 목록 보완, 전역 지침 §5 조사 규칙 승격. 전부 `[Unreleased]`, Windows 재설치됨.
- 조사 규칙 `docs/research.md` + 기록 색인 `docs/research/`(2026-09-09), 토큰 절감 절은 `docs/review-vs-official.md`. 전역 반영은 [C-49](PROGRESS.md#c-49).
- **[C-45](PROGRESS.md#c-45) 플러그인화 보류(2026-09-09)** — 플러그인은 스킬·훅만 싣고 지침·rules·permissions·statusLine은 못 실어 `install.sh`가 남음. 근거 `docs/research/plugins.md`. 부산물: `claude plugin validate base/skills` 통과 → [C-52](PROGRESS.md#c-52).
- **[C-25](PROGRESS.md#c-25) `/insights` Mac 실행 완료(2026-09-09)** — 3세션뿐이라 얕음. 후보는 릴리즈 전 `gh auth` 점검·토큰 붙여넣기 금지 → [C-53](PROGRESS.md#c-53) **승격 완료(사용자 승인 2026-09-09)** — 전역 §7 한 줄 + dev-release 0단계, Mac 재설치. Windows는 다음 설치 때. 상세 `docs/progress/C-53.md`. 시험 중 `test-skill.sh` 버그 2건 수정([#3](https://github.com/yanos0218/AI/issues/3)). `check-install.sh`는 VS Code 확장도 대조. 토큰 노출 건은 사용자가 "다른 저장소라 무관"으로 판단(토큰은 계정 단위라 이견은 전달함).
- 저장소 검토 `docs/audit-2026-09.md`(2026-09-09): 문제 7·제안 7 → 보드 [C-44](PROGRESS.md#c-44)~[C-48](PROGRESS.md#c-48). 규칙 이탈 금지 절을 저장소 CLAUDE.md에 추가, 전역판은 [C-47](PROGRESS.md#c-47).
- dev-workflow 스킬 승격·Windows 설치(2026-09-09, `[Unreleased]`). dev-release 발동 테스트 3시나리오 통과(2026-09-08). 테스트 방법은 저장소 `CLAUDE.md` "검증" 절. 관찰: `cd X && ls` 복합 명령은 `Read(./.env)` deny 규칙과 겹쳐 승인 프롬프트가 뜨고, `python -m py_compile`은 allow 목록에 없음 → [C-11](PROGRESS.md#c-11).

## 다음 할 일

[PROGRESS.md](PROGRESS.md) §2·§3의 `C-NN` 항목. 추천 순서: [C-16](PROGRESS.md#c-16)(Linux 반영, v0.6.0 기준) → Script·Etc 표준 적용은 그 저장소에서 `repo-setup`으로(사용자 지시 시, 순서는 `docs/progress/C-35.md`).

## 결정 사항 (다시 묻지 말 것)

- 다른 저장소 내용은 복사하지 않고 참조만.
- 강제가 필요한 규칙은 CLAUDE.md 문장이 아니라 훅으로.
- VS Code 동기화는 내장 Settings Sync가 주, `base/vscode/`는 부트스트랩·백업. Prettier/ESLint/GitLens는 저장소에 설정 파일이 생길 때까지 보류. (2026-09-09) 기본 목록 밖에 추가 설치된 확장은 문제없으면 지우지 않는다. Mac은 VS Code만 쓰고 Xcode 안 씀.
- 에이전트 팀·샌드박스(Windows 미지원)·LSP 플러그인·알림 훅은 보류. 병렬 작업은 설정이 아니라 습관 항목.
- (v0.2.0에서 변경) 로컬 커밋은 작업 단위마다 묻지 않고. push·배포·삭제·외부 설정은 확인 후. 배치 = 메시지 하나.
- (2026-09-09) **다른 저장소의 일은 이 보드에 두지 않는다.** 여기 두는 것은 저장소를 가리지 않는 결정·절차·표준·스킬까지. 특정 저장소에서의 실행(OpenClaw PR, Script 키 처리 등)은 그 저장소의 Issue·문서로.
- (2026-09-08) 이 저장소도 태그를 쓴다. `docs/versioning.md` — 시작 `v0.1.0`, 기본 영역 변경만 등급 반영, Release에 `pack.sh` zip 첨부.
- (2026-09-08) 기본 영역(`base/claude-md/`, `base/skills/<이름>/`, `scripts/`, `base/vscode/`)은 검증 통과 + 사용자의 명시적 반영 요청이 있을 때만 수정. 초안은 `drafts/`. `baseline-guard` 훅이 확인을 강제한다.
- (2026-09-09) 저장소 표준 적용은 `repo-setup` 스킬로 — 판정표 → 사용자가 고른 것만 생성. 다른 저장소에 적용하는 일은 그 저장소에서.
- (2026-09-09) 토큰이 필요하면 `gh auth status`로 확인하고 없으면 멈춘다. 채팅에 붙여넣으라고 하지 않는다(전역 §7, dev-release 0단계).
- (2026-09-08) 사용자 성향 데이터는 세 곳(로컬 auto memory, claude.ai 메모리, `/insights`)에서 모아 `drafts/claude-md/`에 후보로 두고, 전역 지침 반영은 사용자 확인 후.
