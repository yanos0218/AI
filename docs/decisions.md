# 결정 사항 (다시 묻지 말 것)

성공해서 굳어진 결정 모음. HANDOFF의 문서 지도가 가리킬 때, 또는 아래 주제와 관련된 작업 전에 읽음. **안 하기로 한 것은 [PROGRESS.md §5 보류·기각](PROGRESS.md#5-보류기각).** 둘이 "성공 사례/실패 사례" 짝임.

주제별로 묶었고 항목 안의 날짜는 결정한 날. 항목 문장은 HANDOFF에서 옮기며 바꾸지 않음(2026-10-21, [Issue #191](https://github.com/yanos0218/AI/issues/191)).

## 영역·승격·릴리즈

- 다른 저장소 내용은 복사하지 않고 참조만.
- (2026-09-09) **다른 저장소의 일은 이 보드에 두지 않는다.** 여기 두는 것은 저장소를 가리지 않는 결정·절차·표준·스킬까지. 특정 저장소에서의 실행(OpenClaw PR, Script 키 처리 등)은 그 저장소의 Issue·문서로.
- (2026-09-08) 이 저장소도 태그를 씀. `docs/versioning.md`
  - 시작 `v0.1.0`, 기본 영역 변경만 등급 반영, Release에 `pack.sh` zip 첨부.
- (2026-09-08) 기본 영역(`base/claude-md/`, `base/skills/<이름>/`, `scripts/`, `base/vscode/`)은 검증 통과 + 사용자의 명시적 반영 요청이 있을 때만 수정. 초안은 `drafts/`. `baseline-guard` 훅이 확인을 강제함.
- (2026-09-09) 저장소 표준 적용은 `repo-setup` 스킬로
  - 판정표 → 사용자가 고른 것만 생성. 다른 저장소에 적용하는 일은 그 저장소에서.
- (2026-09-17) `base/` 반영(승격)과 릴리즈 컷은 별개 이벤트임을 재확인
  - 승격은 검증+요청 즉시, 컷은 쌓였다가 필요할 때. 매번 묶으면 번호 소진 사고 재발([Issue #107](https://github.com/yanos0218/AI/issues/107) 논의 중 정리).
- (2026-10-26) `live-status` 스킬을 에이전트 팀 구역 미검증인 채로 기본 영역에 승격
  - 팀 기능을 쓰지 않으면 영원히 못 하는 확인이라 승격을 막지 않고 SKILL.md 한계로 표기, 확인은 [Issue #216](https://github.com/yanos0218/AI/issues/216)으로 분리([Issue #213](https://github.com/yanos0218/AI/issues/213)).
- (2026-09-17) 다른 저장소용 이슈 라벨을 `task`/`bug`/`error`/`research` 4개로 고정 요구하려던 초안을 철회
  - kolo_pwa·kolo-api 실사용 관찰(참고용) 결과 "라벨이 있어도 문서화 안 되면 하나로 몰린다"만 확인됨 → 저장소 자유 + 문서화 원칙만 요구로 완화([Issue #107](https://github.com/yanos0218/AI/issues/107)).

## 강제 수단: 훅·검사

- 강제가 필요한 규칙은 CLAUDE.md 문장이 아니라 훅으로.
- (2026-09-13) `git-guardrails.sh`(yes/no 승인)와 AskUserQuestion(선택형 확인)은 계층이 달라 합칠 수 없음
  - 훅의 `hookSpecificOutput`엔 선택지를 보여줄 필드가 없음.
  - 대신 방법이 여럿인 확인은 계획 단계에서 AskUserQuestion으로 먼저 정하고, 훅은 실행 직전 마지막 확인만 담당하도록 역할을 나눴음.
  - 훅 reason도 패턴별로 구체화([Issue #65](https://github.com/yanos0218/AI/issues/65)).
- (2026-10-24) 안전 훅 `git-guardrails.sh`에만 `onFailure: "block"`을 켜고, 스크립트 오류는 EXIT 트랩이 확인 창(`ask`)으로 바꿈([Issue #211](https://github.com/yanos0218/AI/issues/211))
  - 종료 코드 0·2 이외(1 포함)와 시간 초과를 실패로 치므로 그대로 켜면 `set -u` 오류 하나로 모든 명령이 막힘
  - 시간 초과만 막는 쪽으로 남기고, `gh-throttle`(대기가 본업)·`format-guard`(python 부재 때 커밋이 막힘)는 제외
  - 최소 버전 Claude Code 2.1.295, 훅이 전체 명령을 막으면 `Edit`로 `~/.claude/settings.json`의 `onFailure` 줄을 지워 복구
- (2026-09-15) 목록 줄바꿈 규칙 위반은 사람이 수동으로 재검색하는 대신 `tools/check-cram.sh`가 커밋 시 기계적으로 검사·차단한다([Issue #99](https://github.com/yanos0218/AI/issues/99)).
- (2026-09-15) PreToolUse/PostToolUse 훅은 매 도구 호출마다 Claude에게 실시간으로 알림을 보여줄 수 없다(실제 세션 3개로 확인)
  - 서브에이전트 위임 습관은 `bulk-read-log.sh`의 사후 로그 + `session-start-check.sh`의 개수 기준(10건) 점검으로 대체([Issue #100](https://github.com/yanos0218/AI/issues/100)).
- (2026-09-16) PreCompact 훅도 같은 계열 제약: 컴팩션 요약 **내용에는 개입 불가**(차단·메시지만 가능, 공식 문서 확인). "강제"가 아니라 "안전망"(git 상태·최근 테스트·미완료 체크리스트를 별도 저장 후 컴팩션 직후 노출)으로 설계, 초안 진행 중([Issue #104](https://github.com/yanos0218/AI/issues/104)).
- (2026-09-18) 이슈 형식 위반은 `issue-format-check.yml`(GitHub Actions)이 사후 자동 확인한다(사전 차단 불가)
  - 이슈·코멘트 본문은 크램 확인과 게시 명령을 `&&`로 묶어서 올림. 순서로만 적어 게시가 그대로 진행된 사례 2건 재발 방지([Issue #118](https://github.com/yanos0218/AI/issues/118)).
- (2026-09-18) release 커밋에만 거는 좁은 차단 훅 대신, `dev-release` §2 절차에 "바뀐 파일 전체를 훑어 관련 문서 갱신 확인" 단계를 추가했음
  - release 아닌 커밋(`docs/github.md` 미갱신)에서 난 미스는 좁은 훅으로 못 잡았을 사례가 근거([Issue #121](https://github.com/yanos0218/AI/issues/121)).
- (2026-10-17) 전역 지침 검증은 문안 위험도에 맞춰 토큰을 쓴다([Issue #182](https://github.com/yanos0218/AI/issues/182), `drafts/README.md` 승격 조건 1)
  - 막는·승인 흐름 문안은 반영 전 1회로 실제로 틀리는지 먼저 보고, 알림성 문안은 문안 검토 + 월 점검 self-audit로 확인.

## 이슈·조사 운영

- (2026-09-09) 토큰이 필요하면 `gh auth status`로 확인하고 없으면 멈춤. 채팅에 붙여넣으라고 하지 않는다(전역 §7, dev-release 0단계).
- (2026-09-08) 사용자 성향 데이터는 세 곳(로컬 auto memory, claude.ai 메모리, `/insights`)에서 모아 Issue(`task` 라벨)로 후보 등록하고, 전역 지침 반영은 사용자 확인 후(2026-09-12부터 `drafts/claude-md/` 대신).
- (2026-09-28) `drafts/observations/`(날짜별 관찰 기록·memory 사본·claude.ai 내보내기) 폐지. 월 점검에서 auto memory는 각 기기에서 직접 읽고, 대화 방식은 self-audit가 대화 기록을 직접 읽는다(사용자 요청).
- (2026-09-13) 조사 기록은 파일(`docs/research/`)이 아니라 GitHub Issue `research` 라벨로 남긴다(파일·이슈 이중 기록 낭비 지적). 그 이전 기록은 archive로 유지.
- (2026-09-26) 조사 이슈는 주제별 하나를 살아있는 문서로 쓴다(본문=최신 요약, 댓글=갱신 이력, "마무리" 전까지 열어 둠). 단발성만 새 이슈([Issue #133](https://github.com/yanos0218/AI/issues/133)).

## 문서·형식 규칙

- (2026-09-18) 폴더별 안내 문서(하위 폴더 README)는 만들지 않음. README 구조 목록이 대신함.

## 환경·도구

- (2026-10-21) HANDOFF는 저장소 `CLAUDE.md`의 `@docs/HANDOFF.md` import로 세션 시작 때 자동 로드함([Issue #191](https://github.com/yanos0218/AI/issues/191))
  - 시험(Haiku, `claude -p` 2.1.304)에서 import가 로드됨을 확인했고 비용은 세션당 1,991 토큰(교대 4회 반복 모두 동일)
  - 서브에이전트도 `Explore`·`Plan`을 뺀 모두가 같은 양을 추가로 로드함
  - 대안인 한 줄 알림은 읽기가 Claude의 순응에 달려 채택하지 않음, HANDOFF 40줄 상한이 비용 방어선
- (2026-10-21) `install.sh`가 만든 백업은 수동 정리가 잊히므로 설치할 때마다 자동으로 종류별 최근 3개만 남김(사용자 결정, [Issue #196](https://github.com/yanos0218/AI/issues/196))
  - 대상은 `.bak.<숫자 14자리>` 이름뿐이고 직접 만든 백업은 건드리지 않음, `--dry-run`은 목록만 보여 줌
  - #194의 "사용자 값을 말없이 지우지 않는다" 원칙의 예외이며, 지운 목록은 설치 출력에 남음
- (2026-10-21) AI 저장소는 의도적으로 공개이고 협력자가 없으며 외부 사용자는 조회만 가능함(사용자 확인, [Issue #198](https://github.com/yanos0218/AI/issues/198))
  - 공개 저장소라 표준 러너 Actions 분이 무료이고 비밀 스캔을 쓸 수 있어 2026-10-21에 비밀 스캔을 켬, 푸시 보호는 켜지 않음
  - 외부 사용자에게 권한을 준 적이 없어 낯선 글을 막는 규칙이나 봇 조건은 추가하지 않음(사용자 판단)
  - 이 저장소 밖의 저장소는 이 문서의 범위가 아님
- VS Code 동기화는 내장 Settings Sync가 주, `base/vscode/`는 부트스트랩·백업. Prettier/ESLint/GitLens는 저장소에 설정 파일이 생길 때까지 보류. (2026-09-09) 기본 목록 밖에 추가 설치된 확장은 문제없으면 지우지 않음. Mac은 VS Code만 쓰고 Xcode 안 씀.
- (2026-10-21) 개발 작업 기본은 Sonnet 5.5·effort medium, 어려운 설계·디버깅만 `/model opus`. 모델은 전체 ID로 고정하고 설치마다 원본 값으로 덮어씀([Issue #187](https://github.com/yanos0218/AI/issues/187), [models.md](models.md)).

## 작업 방식·보류

- 에이전트 팀·샌드박스(Windows 미지원)·LSP 플러그인·알림 훅은 보류. 병렬 작업은 설정이 아니라 습관 항목.
- (v0.2.0에서 변경) 로컬 커밋은 작업 단위마다 묻지 않고. push·배포·삭제·외부 설정은 확인 후. 배치 = 메시지 하나.
- (2026-09-16) 결정 사항 전체 재검토. 전부 유효 확인됨: Notification 훅([Issue #5](https://github.com/yanos0218/AI/issues/5), 병렬 세션 실사용 전 보류 그대로), 샌드박스 Windows 미지원(공식 문서 재확인), 버전 태그 체계(`v0.10.0` 태그 존재, 작업 트리는 그 이후 커밋 진행 중), 훅 강제 원칙(`.claude/hooks/`에 baseline-guard·session-end-check·pre-commit-check 그대로 존재).
