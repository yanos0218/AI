# 인수인계 — claude-config

새 세션을 시작할 때 이 파일을 먼저 읽고, 할 일은 GitHub Issues(`gh issue list --state open --label task`)에서 본다. 세션이 끝날 때 "현재 상태"와 필요하면 PROGRESS.md §0을 갱신한다.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만든다. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 한다.

## 현재 상태 (2026-09-15) · 마지막 월 점검: 없음 (첫 점검 2026-10 예정, `docs/monthly-check.md`)

- 저장소 v0.10.0(MINOR, 2026-09-15 컷)
  - 신규 훅 `bulk-read-log.sh` 추가 + `git-guardrails.sh`·`session-start-check.sh` 기능 확장. CI(`lint.yml`) 초록.
  - 배포 현황은 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태) 표가 원본. Windows는 v0.10.0, Mac·웹은 v0.6.0, Linux는 미반영.
- 할 일·발견한 문제는 GitHub Issues로 관리한다([Issue #11](https://github.com/yanos0218/AI/issues/11), 2026-09-12). 완료 이력은 [PROGRESS.md §1](PROGRESS.md#1-완료)에 짧은 색인 + 이슈 링크로.
- Script 저장소 이력에서 개인키 발견
  - 처리는 그 저장소 일, 아직 사용자 결정 대기.
- 그 밖의 결정 배경·조사 근거는 `git log`와 각 문서 "참고" 절, 닫힌 이슈에 남아 있다.

## 다음 할 일

할 일은 GitHub Issues(`gh issue list --state open --label task`)에서 확인 — [#6](https://github.com/yanos0218/AI/issues/6) Linux 반영이 먼저. Script·Etc 표준 적용은 그 저장소에서 `repo-setup`으로(사용자 지시 시, 순서는 [Issue #56](https://github.com/yanos0218/AI/issues/56)).

## 결정 사항 (다시 묻지 말 것)

성공해서 굳어진 결정은 아래 목록. **안 하기로 한 것은 [PROGRESS.md §5 보류·기각](PROGRESS.md#5-보류기각).** 둘이 "성공 사례/실패 사례" 짝이다.

- 다른 저장소 내용은 복사하지 않고 참조만.
- 강제가 필요한 규칙은 CLAUDE.md 문장이 아니라 훅으로.
- VS Code 동기화는 내장 Settings Sync가 주, `base/vscode/`는 부트스트랩·백업. Prettier/ESLint/GitLens는 저장소에 설정 파일이 생길 때까지 보류. (2026-09-09) 기본 목록 밖에 추가 설치된 확장은 문제없으면 지우지 않는다. Mac은 VS Code만 쓰고 Xcode 안 씀.
- 에이전트 팀·샌드박스(Windows 미지원)·LSP 플러그인·알림 훅은 보류. 병렬 작업은 설정이 아니라 습관 항목.
- (v0.2.0에서 변경) 로컬 커밋은 작업 단위마다 묻지 않고. push·배포·삭제·외부 설정은 확인 후. 배치 = 메시지 하나.
- (2026-09-09) **다른 저장소의 일은 이 보드에 두지 않는다.** 여기 두는 것은 저장소를 가리지 않는 결정·절차·표준·스킬까지. 특정 저장소에서의 실행(OpenClaw PR, Script 키 처리 등)은 그 저장소의 Issue·문서로.
- (2026-09-08) 이 저장소도 태그를 쓴다. `docs/versioning.md`
  - 시작 `v0.1.0`, 기본 영역 변경만 등급 반영, Release에 `pack.sh` zip 첨부.
- (2026-09-08) 기본 영역(`base/claude-md/`, `base/skills/<이름>/`, `scripts/`, `base/vscode/`)은 검증 통과 + 사용자의 명시적 반영 요청이 있을 때만 수정. 초안은 `drafts/`. `baseline-guard` 훅이 확인을 강제한다.
- (2026-09-09) 저장소 표준 적용은 `repo-setup` 스킬로
  - 판정표 → 사용자가 고른 것만 생성. 다른 저장소에 적용하는 일은 그 저장소에서.
- (2026-09-09) 토큰이 필요하면 `gh auth status`로 확인하고 없으면 멈춘다. 채팅에 붙여넣으라고 하지 않는다(전역 §7, dev-release 0단계).
- (2026-09-08) 사용자 성향 데이터는 세 곳(로컬 auto memory, claude.ai 메모리, `/insights`)에서 모아 Issue(`task` 라벨)로 후보 등록하고, 전역 지침 반영은 사용자 확인 후(2026-09-12부터 `drafts/claude-md/` 대신).
- (2026-09-13) 조사 기록은 파일(`docs/research/`)이 아니라 GitHub Issue `research` 라벨로 남긴다(파일·이슈 이중 기록 낭비 지적). 그 이전 기록은 archive로 유지.
- (2026-09-13) `git-guardrails.sh`(yes/no 승인)와 AskUserQuestion(선택형 확인)은 계층이 달라 합칠 수 없다
  - 훅의 `hookSpecificOutput`엔 선택지를 보여줄 필드가 없음.
  - 대신 방법이 여럿인 확인은 계획 단계에서 AskUserQuestion으로 먼저 정하고, 훅은 실행 직전 마지막 확인만 담당하도록 역할을 나눴다.
  - 훅 reason도 패턴별로 구체화([Issue #65](https://github.com/yanos0218/AI/issues/65)).
- (2026-09-15) 목록 줄바꿈 규칙 위반은 사람이 수동으로 재검색하는 대신 `tools/check-cram.sh`가 커밋 시 기계적으로 검사·차단한다([Issue #99](https://github.com/yanos0218/AI/issues/99)).
- (2026-09-15) PreToolUse/PostToolUse 훅은 매 도구 호출마다 Claude에게 실시간으로 알림을 보여줄 수 없다(실제 세션 3개로 확인)
  - 서브에이전트 위임 습관은 `bulk-read-log.sh`의 사후 로그 + `session-start-check.sh`의 개수 기준(10건) 점검으로 대체([Issue #100](https://github.com/yanos0218/AI/issues/100)).
