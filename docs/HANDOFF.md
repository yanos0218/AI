# 인수인계 — claude-config

새 세션·새 기기에서 이 파일 하나로 이어서 작업하기 위한 문서(저장소 `CLAUDE.md`가 자동으로 불러옴). 관련 `.md`를 다시 조사하지 않도록 아래 "문서 지도"가 읽을 곳을 알려줌. 갱신은 세션 끝에 한 번.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만듦. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 함.

## 지금 (2026-10-22) · 마지막 월 점검 2026-10-07([#171](https://github.com/yanos0218/AI/issues/171))

- 변경 이력은 [CHANGELOG.md](../CHANGELOG.md) `[Unreleased]`, 기기별 설치 버전은 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태)이 원본(여기엔 적지 않음).
- 사용자 기기에서 할 일은 [#194](https://github.com/yanos0218/AI/issues/194)를 닫기 전 확인 3가지이고 결과는 댓글로 남김. ① WSL에서 `git pull --ff-only` 뒤 `check-install.sh` 종료 코드 0과 `test-install-merge.sh` 실패 0건([#201](https://github.com/yanos0218/AI/issues/201)), ② Linux(Rocky) 새 대화형 세션에서 상태줄 모델·훅 동작·스크래치패드 읽기, ③ Mac에서 `bash tools/fingerprint.sh --common`을 다른 기기 출력과 `diff --strip-trailing-cr`.
- Windows·Linux(Rocky 8.10, 파이썬 3.6.8)·WSL 설치 확인과 Windows·Linux 읽기 차단 시험은 끝났고 파이썬 3.6 결함은 [#202](https://github.com/yanos0218/AI/issues/202)로 고쳐 닫음. 읽기 차단 줄은 세 기기에서 손으로 켠 임시 불일치라 기본 영역 반영은 [#195](https://github.com/yanos0218/AI/issues/195)에서 결정.
- 바로 코드를 건드릴 열린 task는 없음([#201](https://github.com/yanos0218/AI/issues/201)은 수정을 마치고 WSL 확인 대기). 보류는 [#174](https://github.com/yanos0218/AI/issues/174)(전역 지침 후보 2건), [#178](https://github.com/yanos0218/AI/issues/178)(한도 측정, 사용자 요청 시), [#181](https://github.com/yanos0218/AI/issues/181)(다른 기기 설치 때 검증), 요구사항 미정은 #5·#7·#8·#9·#10. [#193](https://github.com/yanos0218/AI/issues/193)은 조사 이슈라 사용자가 마무리라고 할 때까지 열어 둠, 후속은 [#195](https://github.com/yanos0218/AI/issues/195)(읽기 차단 기본 반영 결정), [#197](https://github.com/yanos0218/AI/issues/197)(OS별 구분표·세 러너 CI·`fingerprint --common` 완료, 덧입히기 구조는 Windows 출력으로 실제 차이가 확인되면 설계).
- 문서 갱신 누락 검사(CHANGELOG 경고, `handoff-stale-check` 알림, HANDOFF 자동 로드)는 2026-10-21 새 세션 시험으로 모두 확인을 마침(#192 닫음).
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
