# 인수인계 — claude-config

새 세션을 시작할 때 이 파일을 먼저 읽고, 할 일은 [PROGRESS.md](PROGRESS.md)에서 본다. 세션이 끝날 때 "현재 상태"와 PROGRESS.md를 갱신한다.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만든다. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 한다.

## 현재 상태 (2026-09-09) · 마지막 월 점검: 없음 (첫 점검 2026-10 예정, `docs/monthly-check.md`)

- 저장소: github.com/yanos0218/AI (비공개). **v0.4.0까지 릴리즈**(2026-09-08 v0.1.0 첫 컷 → v0.2.0 지침 확인 기준 변경 → v0.3.0 `base/`·`tools/` 경로 재구성 → 2026-09-09 v0.4.0 config-changelog 훅). CI(`lint.yml`) 초록. 자산별 단계·기기별 배포는 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태) 표가 원본.
- **Windows PC는 v0.4.0과 동일**(`tools/check-install.sh`로 확인). CLI `~/.local/bin/claude.exe` v2.1.263, VS Code 확장 13개. 훅 2개(git-guardrails·baseline-guard)는 새 `claude -p` 세션에서 차단 동작 확인, 상태줄 표시만 사용자가 대화형 세션에서 확인하면 [C-10](PROGRESS.md#c-10) 완료.
- **Mac mini·Linux·웹(Claude.ai)은 미반영.** 설치는 `docs/install.md`. Mac은 기존 `~/.claude/CLAUDE.md`가 있을 수 있으니 덮어쓰기 전에 확인. 웹은 Release v0.4.0의 `dev-release.zip` + Project instructions에 `base/claude-md/CLAUDE.md`.
- 설정이 다른 저장소 작업 중 흔들리지 않게 하는 구조(기본·모듈·프로젝트 층)와 이력 장치는 `docs/config-lifecycle.md`(2026-09-09). 이력 훅은 v0.4.0에서 기본 영역.
- §3 진행(2026-09-09): Dependabot·2FA 확인, Actions 월 환산 11%, Issues 시험 시작(#1), `base/rules/` 첫 모듈, repo-setup 스킬 초안(Script 점검에서 **이력 속 개인키 발견** → 사용자 결정), claude.ai 메모리는 zip 파일 대기([C-26](PROGRESS.md#c-26)).
- §2 개발·설정 항목 정리(2026-09-09): `tools/install.sh`·`test-skill.sh`, Stop 훅, 권한 목록 보완, 전역 지침 §5 조사 규칙 승격. 전부 `[Unreleased]`, Windows 재설치됨.
- 조사 규칙 `docs/research.md` + 기록 색인 `docs/research/`(2026-09-09), 토큰 절감 절은 `docs/review-vs-official.md`. 전역 반영은 [C-49](PROGRESS.md#c-49).
- 저장소 검토 `docs/audit-2026-09.md`(2026-09-09): 문제 7·제안 7 → 보드 [C-44](PROGRESS.md#c-44)~[C-48](PROGRESS.md#c-48). 규칙 이탈 금지 절을 저장소 CLAUDE.md에 추가, 전역판은 [C-47](PROGRESS.md#c-47).
- dev-workflow 스킬 승격·Windows 설치(2026-09-09, `[Unreleased]`). dev-release 발동 테스트 3시나리오 통과(2026-09-08). 테스트 방법은 저장소 `CLAUDE.md` "검증" 절. 관찰: `cd X && ls` 복합 명령은 `Read(./.env)` deny 규칙과 겹쳐 승인 프롬프트가 뜨고, `python -m py_compile`은 allow 목록에 없음 → [C-11](PROGRESS.md#c-11).

## 다음 할 일

[PROGRESS.md](PROGRESS.md) §2·§3의 `C-NN` 항목. 추천 순서: [C-10](PROGRESS.md#c-10)(상태줄·훅 확인) → [C-18](PROGRESS.md#c-18)(GitHub 활용 결정, 사용자 판단) → [C-13](PROGRESS.md#c-13)(개발용 스킬) → [C-15](PROGRESS.md#c-15)/16/17(Mac·Linux·웹 반영).

## 결정 사항 (다시 묻지 말 것)

- 다른 저장소 내용은 복사하지 않고 참조만.
- 강제가 필요한 규칙은 CLAUDE.md 문장이 아니라 훅으로.
- VS Code 동기화는 내장 Settings Sync가 주, `base/vscode/`는 부트스트랩·백업. Prettier/ESLint/GitLens는 저장소에 설정 파일이 생길 때까지 보류.
- 에이전트 팀·샌드박스(Windows 미지원)·LSP 플러그인·알림 훅은 보류. 병렬 작업은 설정이 아니라 습관 항목.
- (v0.2.0에서 변경) 로컬 커밋은 작업 단위마다 묻지 않고. push·배포·삭제·외부 설정은 확인 후. 배치 = 메시지 하나.
- (2026-09-08) 이 저장소도 태그를 쓴다. `docs/versioning.md` — 시작 `v0.1.0`, 기본 영역 변경만 등급 반영, Release에 `pack.sh` zip 첨부.
- (2026-09-08) 기본 영역(`base/claude-md/`, `base/skills/<이름>/`, `scripts/`, `base/vscode/`)은 검증 통과 + 사용자의 명시적 반영 요청이 있을 때만 수정. 초안은 `drafts/`. `baseline-guard` 훅이 확인을 강제한다.
- (2026-09-08) 사용자 성향 데이터는 세 곳(로컬 auto memory, claude.ai 메모리, `/insights`)에서 모아 `drafts/claude-md/`에 후보로 두고, 전역 지침 반영은 사용자 확인 후.
