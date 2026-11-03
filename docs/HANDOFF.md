# 인수인계 — claude-config

새 세션·새 기기에서 이 파일 하나로 이어서 작업하기 위한 문서(저장소 `CLAUDE.md`가 자동으로 불러옴). 관련 `.md`를 다시 조사하지 않도록 아래 "문서 지도"가 읽을 곳을 알려줌. 갱신은 세션 끝에 한 번.

## 목적 (변하지 않음)

Claude를 개인용으로 원활하고 효율적으로 쓰기 위한 설정 원본 저장소. 개발자가 아닌 사용자가 여러 스택의 프로젝트를 오가며 Claude에게 (1) 매번 같은 배경을 다시 설명하지 않고, (2) 멋대로 진행하거나 너무 자주 묻지 않게 하고, (3) 검증 없이 "됐다"는 말을 못 하게 하고, (4) 결론만 짧게 듣도록 만듦. 저장소별 규칙은 각 저장소에 두고 여기서는 **참조만** 함.

## 지금 (2026-11-02) · 마지막 월 점검 2026-11-02(전 항목 완료, 이전 [#171](https://github.com/yanos0218/AI/issues/171))

- 변경 이력은 [CHANGELOG.md](../CHANGELOG.md) `[Unreleased]`, 기기별 설치 버전은 [PROGRESS.md §0](PROGRESS.md#0-자산-현황--단계와-배포-상태)이 원본(여기엔 적지 않음).
- 2026-11-04에 v0.18.0을 컷함(MINOR, Windows PowerShell 한 줄 설치기 `tools/install.ps1`, 실제 Windows 시험 중이라 훅 병합까지의 확인은 [#247](https://github.com/yanos0218/AI/issues/247) 댓글이 최신). 2026-11-02에 v0.17.0을 컷함(MINOR, `language: korean`·문서 낡음 훅 승격·전역 지침 3건·`research.md` 분리 포함). 웹(Claude.ai)은 Release zip 업로드와 Project instructions 갱신이 남음(사용자 작업, 분리 파일이 웹에서 안 보이는 문제는 [#243](https://github.com/yanos0218/AI/issues/243)). 세 기기는 v0.16.0 이후 `base/` 변경을 2026-10-27~28에 이미 설치해 v0.17.0과 기본 영역이 같음. 2026-10-28에 `/usage` 경고 반영으로 `auditor` Haiku화와 전역 지침 세부 규칙 분리([#236](https://github.com/yanos0218/AI/issues/236))를 Mac mini·Windows·Linux 모두 설치함(2026-10-28). 새 세션 조사 요청 시험에서 모두 첫 도구 호출이 `research.md` 읽기였음(2026-10-28, Windows 3회와 Linux 1회로 합쳐 4회).
- 남은 확인은 Mac mini의 다른 저장소 폴더 대화형 `config-update`, Linux 대화형 `Bash`가 읽기 차단을 건너뛰는 불일치(2026-10-27, `-p`에선 거부, Windows 대화형은 2026-10-27 재현 확인, Mac 대화형도 2026-10-28 재현 확인, Mac은 2.1.314에서도 2026-11-02 재현, 남은 것은 Windows·Linux 새 버전 재시험)임([#228](https://github.com/yanos0218/AI/issues/228), 근거는 닫힌 [#195](https://github.com/yanos0218/AI/issues/195) 댓글, Windows의 대화형·멀티루트는 2026-10-27에 확인).
- 진행 중은 효과·실행 확인 대기인 것들임.
  - [#223](https://github.com/yanos0218/AI/issues/223)·[#224](https://github.com/yanos0218/AI/issues/224)는 한두 달 뒤 영어 비율·재발 여부, [#221](https://github.com/yanos0218/AI/issues/221)은 v0.17.0 컷(2026-11-02)에서 제목 확인 단계가 동작해 `v0.17.0 - ...` 꼴을 확인함(닫기만 남음).
  - 문서 낡음 훅([#219](https://github.com/yanos0218/AI/issues/219))은 2026-10-27 기본 승격과 확인을 마쳐 닫음(한계는 [operating-flow.md](operating-flow.md)). 훅 초안 [#222](https://github.com/yanos0218/AI/issues/222)(쉬운 설명, CLI·VS Code 주입 확인, 영어 진행 설명 감지 훅은 `language` 효과를 본 뒤 결정), 승격은 사용자 요청 때. [#216](https://github.com/yanos0218/AI/issues/216)(에이전트 팀 파일 확인 대기), [#220](https://github.com/yanos0218/AI/issues/220)(self-audit 후보, 7번 보류), 조사 #209·#210·#212·#218은 2026-10-28 닫음(#210의 후속 [#234](https://github.com/yanos0218/AI/issues/234)·#235는 2026-10-28 닫음, [#233](https://github.com/yanos0218/AI/issues/233)은 2026-11-02 `/usage` 경고가 4건에서 "Trim" 1건으로 줄어 [#242](https://github.com/yanos0218/AI/issues/242)로 이어짐), 2026-11-02 월 점검에서 연 [#240](https://github.com/yanos0218/AI/issues/240)(self-audit 후보, 문서 반영 끝·4건 보류)·[#242](https://github.com/yanos0218/AI/issues/242)(전역 지침 줄이기, 수정안 시험 끝·`base/` 반영은 다음 컷과 묶는 안)·[#243](https://github.com/yanos0218/AI/issues/243)(웹에서 분리 파일 안 보이는 문제)·[#244](https://github.com/yanos0218/AI/issues/244)(메모리 검토 후보), 보류 [#5](https://github.com/yanos0218/AI/issues/5)·요구사항 미정 #7·#8.
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
