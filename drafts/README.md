# drafts — 작업 영역

기본 영역(`base/`)에 아직 들어가지 않은 초안을 둠. `pack.sh`와 설치 절차는 이 폴더를 보지 않으므로, 여기 있는 것은 어디에도 배포되지 않음. 지금 어떤 초안이 어느 단계인지는 [docs/PROGRESS.md §0](../docs/PROGRESS.md#0-자산-현황--단계와-배포-상태) 표에 있음.

구조는 기본 영역을 그대로 따라 만듦.

| 경로 | 무엇 |
| --- | --- |
| `drafts/skills/<이름>/` | 새 스킬 초안<br>[base/skills/_template](../base/skills/_template/SKILL.md)을 복사해서 시작 |
| `drafts/hooks/<이름>.sh` | 새 훅 초안<br>판정이 복잡하면 셸 입구 + 파이썬 본체(`<이름>.py`, 공통 모듈은 [base/hooks/hooklib.py](../base/hooks/hooklib.py)) |
| `drafts/agents/<이름>.md` | 새 에이전트 초안<br>[tools/test-agent.sh](../tools/test-agent.sh)로 시험 |

전역 지침(`base/claude-md/CLAUDE.md`) 수정안은 파일로 두지 않고 GitHub Issue(`task` 라벨)로 제안한다(2026-09-12부터).

## 기본 영역으로 올리는 조건 (승격)

1. 자산 종류에 맞는 시험을 통과했음.
   - 스킬은 새 세션에서 3가지 상황([docs/skill-development.md](../docs/skill-development.md) "시험 방법").
   - 에이전트는 [tools/test-agent.sh](../tools/test-agent.sh)로 새 세션 시험.
   - 훅은 시험 스크립트(예: [tools/test-hooks-py.sh](../tools/test-hooks-py.sh))와 실제 명령·세션에서의 동작 확인.
   - 전역 지침은 문안의 위험도에 맞춘다([Issue #182](https://github.com/yanos0218/AI/issues/182), 2026-10-17).
     - 행동을 막거나 승인 흐름을 바꾸는 문안은 새 세션 비교. 반영 전 1회를 먼저 돌려 실제로 틀릴 때만 반영 후 2회를 돌림. 반영 후 조건은 시험 저장소 `CLAUDE.md`에 문안을 넣어 대신할 수 있음.
     - 실제 사고가 근거인 알림성 문안은 문안 검토로 갈음하고, 지켜지는지는 월 점검 self-audit가 평소 대화 기록에서 확인함.
     - 공통으로 통과 기준은 시험 전에 정함. 시험 상황을 만들 수 없으면 돌리지 않고 미검증으로 둔 뒤 실제 상황에서 확인함.
2. 사용자가 "기본에 반영해"라고 명시적으로 요청했음.
3. `git mv drafts/<경로> base/<경로>`로 옮기고, 커밋 제목은 `feat(<영역>): <이름> 기본 영역 승격`. 관련 Issue는 검증이 끝난 뒤 `gh issue close`로 닫음. 필요하면 `docs/HANDOFF.md` 결정 사항에 한 줄 추가.

`.claude/hooks/baseline-guard.sh`가 기본 영역 쓰기 앞에서 확인 프롬프트를 띄움. 승격 작업이면 승인하고, 아니면 여기로 돌아옴.
