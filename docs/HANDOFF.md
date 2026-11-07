# 인수인계 — claude-config

새 세션·새 기기에서 이 파일 하나로 이어서 작업하기 위한 문서(저장소 `CLAUDE.md`가 자동으로 불러옴). 관련 `.md`를 다시 조사하지 않도록 아래 "문서 지도"가 읽을 곳을 알려줌. 갱신은 세션 끝에 한 번.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만듦. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 함.

## 지금 (2026-11-07) · 마지막 월 점검 2026-11-02(전 항목 완료, 이전 [#171](https://github.com/yanos0218/AI/issues/171))

- 최신 릴리즈는 v0.18.4(2026-11-05), 컷 이력은 [CHANGELOG.md](../CHANGELOG.md)와 GitHub Release, 컷 이후 변경은 `[Unreleased]`에 있음(2026-11-07 훅 수정 3건: `git-guardrails` 옵션·인자가 낀 위험 명령 판정 [#268](https://github.com/yanos0218/AI/issues/268)·[#269](https://github.com/yanos0218/AI/issues/269), 형식 검사 훅 옵션이 낀 `git commit` [#270](https://github.com/yanos0218/AI/issues/270), #268·#269·#270은 닫음). 기기별 설치 버전은 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태)이 원본(여기엔 적지 않음).
- 사용자 쪽 대기: 자동 모드에서 훅 확인 질문(터미널 권한 프롬프트) 표시 여부의 거절 시험([#273](https://github.com/yanos0218/AI/issues/273), 기본 모드는 [#268](https://github.com/yanos0218/AI/issues/268)에서 Bash·PowerShell 모두 질문 표시와 거절 시 차단 확인), Linux에 2026-11-07 훅 수정 설치(Windows·Mac mini는 설치함), Windows·Linux `config-update`, 웹(Claude.ai) Release zip 업로드와 Project instructions 갱신([#243](https://github.com/yanos0218/AI/issues/243)), 두 번째 Windows PC는 2026-11-07 저장소 기반 설치로 바꿈(#258·#259 닫음, 자동 모드의 확인 질문 표시는 [#273](https://github.com/yanos0218/AI/issues/273)에서 재확인), Linux 대화형 `Bash`의 읽기 차단 우회 재시험([#228](https://github.com/yanos0218/AI/issues/228), 근거는 닫힌 [#195](https://github.com/yanos0218/AI/issues/195) 댓글).
- 효과 확인 대기: [#223](https://github.com/yanos0218/AI/issues/223)·[#224](https://github.com/yanos0218/AI/issues/224)(한두 달 뒤 영어 비율·재발), 훅 초안 [#222](https://github.com/yanos0218/AI/issues/222)(승격은 사용자 요청 때), [#216](https://github.com/yanos0218/AI/issues/216)(에이전트 팀 파일), self-audit 후보 [#220](https://github.com/yanos0218/AI/issues/220)·[#240](https://github.com/yanos0218/AI/issues/240), 보류 [#5](https://github.com/yanos0218/AI/issues/5)·요구사항 미정 #7·#8.
- 다음 세션 첫 행동은 `gh issue list --state open`으로 최신 상태 확인(이 요약보다 이슈 최신 댓글이 정확), 새 달 첫 세션이면 월 점검 제안([monthly-check.md](monthly-check.md)).

## 문서 지도 (작업 종류 → 읽을 문서)

| 작업 | 읽을 문서 |
| --- | --- |
| 기본 영역(`base/`) 수정·승격 | [decisions.md](decisions.md) "영역·승격·릴리즈", [drafts/README.md](../drafts/README.md) |
| 훅·검사 만들기·고치기 | [operating-flow.md](operating-flow.md) "훅이 도는 시점", [testing.md](testing.md), [decisions.md](decisions.md) "강제 수단" |
| 스킬 만들기 | [skill-development.md](skill-development.md) |
| 이슈 작성·조사 기록 | [issue-format.md](issue-format.md), [research.md](research.md) |
| 릴리즈 컷·버전 | [versioning.md](versioning.md), `dev-release` 스킬 |
| 기기 설치·갱신·웹 | [install.md](install.md), [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태) |
| 모델·effort, 기기 간 반응 차이, 운영체제별 차이 | [models.md](models.md), [os-differences.md](os-differences.md), `tools/fingerprint.sh` |
| 검사·시험 방법 | [testing.md](testing.md) |
| 월 점검 | [monthly-check.md](monthly-check.md) |
| GitHub 사용·다른 저장소 표준 | [github.md](github.md), [repo-standard.md](repo-standard.md) |
| 전체 구조·설정 이력·외부 도구 | [operating-flow.md](operating-flow.md), [config-lifecycle.md](config-lifecycle.md), [tool-catalog.md](tool-catalog.md) |

## 핵심 원칙 (전체 결정은 [decisions.md](decisions.md), 기각은 [PROGRESS.md §5](PROGRESS.md#5-보류기각))

- 기본 영역은 사용자가 반영을 요청할 때만 수정, 승격과 릴리즈 컷은 별개.
- 강제가 필요한 규칙은 문장이 아니라 훅·CI로, 같은 지적이 2회 이상이면 기계 검사로.
- 다른 저장소의 일은 이 저장소에 두지 않음, 조사 기록은 Issue `research` 라벨.
- `.md`는 음슴체·목록 줄바꿈 규칙, 저장 때 훅이 검사함.
