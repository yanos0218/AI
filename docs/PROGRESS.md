# claude-config 진행 보드 (PROGRESS)

> "지금 어디까지 됐고, 다음에 뭘 할지"를 이 문서 하나로 추적한다. kolo_pwa `docs/PROGRESS.md`와 같은 역할.
>
> **역할 분리**
>
> - 이 문서 = **자산 현황 + 배포 상태** (살아있는 표, 계속 갱신). 할 일·완료 이력은 Issues
> - [HANDOFF.md](HANDOFF.md) = **새 세션이 처음 읽는 입구** (목적, 지금 상태, 문서 지도, 핵심 원칙)
> - [decisions.md](decisions.md) = **굳어진 결정 사항** (주제별)
> - [README.md](../README.md) = **무엇이 왜 이렇게 만들어졌는지** (구조, 설치, 검토표)
> - git log = 완료된 변경 이력
>
> **업데이트 규칙**: §0 표는 자산 단계·배포 여부가 바뀔 때 갱신한다. 새 할 일은 `gh issue create --label task`로. 세션이 끝날 때 이 표와 HANDOFF "지금" 절을 같이 갱신한다.
>
> **크기 규칙 ([Issue #49](https://github.com/yanos0218/AI/issues/49), 2026-09-08; 범위 조정 [Issue #11](https://github.com/yanos0218/AI/issues/11) 2026-09-12)**: 이 파일은 **§0 자산 현황 표**만 담는다. 할 일·발견한 문제·완료 이력은 전부 GitHub Issue로 관리한다(라벨 `task`/`bug`, open/closed로 진행 상태 구분).

---

## 0. 자산 현황 — 단계와 배포 상태

모든 자산(지침·스킬·훅·설정)은 아래 네 단계 중 하나에 있음. 단계는 **앞으로만** 감. 뒤로 가야 하면(기본에서 문제 발견) 기본 영역은 그대로 두고 수정안을 `drafts/`에 만들어 다시 검증함.

| 단계 | 뜻 | 있는 곳 |
| --- | --- | --- |
| 계획 | 하기로 했지만 파일이 없음 | GitHub Issue(`task` 라벨)만 |
| 초안 | 파일은 있지만 시험 전 | `drafts/` |
| 검증 | 시험 진행 중, 결과는 해당 이슈 댓글에 | `drafts/` |
| 기본 | 시험 통과 + 사용자 반영 요청 → 승격 커밋 | `base/` |

"기본"이 되면 끝이 아니라 **배포**(어느 표면에 실제로 설치됐는가)와 **관리**([Issue #42](https://github.com/yanos0218/AI/issues/42) 정기 점검 대상)가 따라옴. 시험·승격 이력은 각 행의 이슈에 있음.

### 표면별 설치 버전

설치할 때 이 표만 고침. 아래 자산 표의 칸은 이 버전 기준이다(2026-09-29 git 기록으로 계산, [#168](https://github.com/yanos0218/AI/issues/168)).

- 버전 표기
  - 릴리즈 태그 기준 `git describe` 값 하나만 쓴다(예: `v0.13.1-8-gca8f24e` = v0.13.1 이후 8커밋, 커밋 ca8f24e)
  - `tools/install.sh`가 끝에 적을 값을 출력하고, `tools/check-install.sh`가 이 행과 설치 버전 파일을 대조한다([#180](https://github.com/yanos0218/AI/issues/180))

| 표면 | 설치된 것 | 설치일 | 다음 |
| --- | --- | --- | --- |
| Windows | `v0.14.0-72-gfaabf6a`(읽기 차단과 허용 폴더 계산 기본 반영 [#195](https://github.com/yanos0218/AI/issues/195) [#205](https://github.com/yanos0218/AI/issues/205)) | 2026-10-24 | 해당 없음(최신 설치) |
| Mac mini | `v0.14.0-64-gd8d7300`(읽기 차단과 허용 폴더 계산 기본 반영 [#195](https://github.com/yanos0218/AI/issues/195) [#205](https://github.com/yanos0218/AI/issues/205)) | 2026-10-24 | 해당 없음(최신 설치) |
| Linux(RHEL 계열) | `v0.14.0-51-gb5191f8`(install.sh 사용자 값 보존 병합 포함, 읽기 차단 줄 수동 추가 [#195](https://github.com/yanos0218/AI/issues/195), 파이썬 3.6.8 한글 출력 수정 반영 [#202](https://github.com/yanos0218/AI/issues/202)) | 2026-10-22 | Mac 지문 `diff`([#194](https://github.com/yanos0218/AI/issues/194)), 새 대화형 세션 확인은 2026-10-22 정상 |
| 웹(Claude.ai) | 스킬 3개 v0.11.4, Project instructions | 2026-09-19~20, 2026-09-12 | v0.14.0 Release zip 업로드, Project instructions 갱신 |

### 자산별 단계와 배포

칸은 `✓` 최신 / `갱신 대기` 옛 버전이 있음 / `✗` 미설치 / `-` 해당 없음.

| 자산 | 단계 | Windows | Mac mini | Linux | 웹(Claude.ai) | 다음 행동 |
| --- | --- | --- | --- | --- | --- | --- |
| 전역 지침 `base/claude-md/CLAUDE.md` | 기본 (2026-10-17 §2 큰 작업 끝 점검·§4 CI 대기 추가, 새 세션 전후 2회씩 [#169](https://github.com/yanos0218/AI/issues/169) [#176](https://github.com/yanos0218/AI/issues/176)) | ✓ | ✓ | ✓ | 갱신 대기(Project instructions 2026-09-12) | - |
| 모듈 규칙 `base/rules/docs-format.md` | 기본 (2026-09-28 이슈·PR 음슴체, 필드 예외 범위) | ✓ | ✓ | ✓ | - | - |
| `settings.example.json` (권한·훅·상태줄·env·기본 모델·effort) | 기본 (2026-09-29 형식 검사·대시보드 훅 등록 [#141](https://github.com/yanos0218/AI/issues/141) [#136](https://github.com/yanos0218/AI/issues/136), 기록 훅 async·`if` 조건 [#147](https://github.com/yanos0218/AI/issues/147), 2026-10-21 모델·effort 고정 키 [#187](https://github.com/yanos0218/AI/issues/187), 2026-10-22 읽기 차단과 허용 폴더 계산 [#195](https://github.com/yanos0218/AI/issues/195) [#205](https://github.com/yanos0218/AI/issues/205)) | ✓ | ✓ | ✓ | - | 다른 저장소 폴더에서 연 대화형 세션의 `config-update` 확인(Windows·Mac mini, [#195](https://github.com/yanos0218/AI/issues/195) 미검증 항목) |
| 서브에이전트 재귀 차단 `env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` | 기본 (재귀 시도 차단 실측 2026-09-13 [#75](https://github.com/yanos0218/AI/issues/75)) | ✓ | ✓ | ✓ | - | - |
| git-guardrails 훅 | 기본 (push 차단 확인 2026-09-08, 제한 시간 초과 통과 문제 수정 2026-09-28 [#142](https://github.com/yanos0218/AI/issues/142)) | ✓ | ✓ | ✓ | - | - |
| gh-throttle 훅 | 기본 (병렬 직렬화 실측 2026-09-13 [#74](https://github.com/yanos0218/AI/issues/74), 제한 시간 30초 [#142](https://github.com/yanos0218/AI/issues/142)) | ✓ | ✓ | ✓ | - | - |
| session-start-check 훅(SessionStart) | 기본 (설정 낡음 판정 수정 2026-09-28 [#150](https://github.com/yanos0218/AI/issues/150), `tools/test-session-start-check.sh` 15/15) | ✓ | ✓ | ✓ | - | Windows 느린 시각 훅 시간 측정 |
| bulk-read-log 훅(PostToolUse) | 기본 (2026-09-15 [#100](https://github.com/yanos0218/AI/issues/100), 서브에이전트 조회 제외 [#134](https://github.com/yanos0218/AI/issues/134)) | ✓ | ✓ | ✓ | - | - |
| config-changelog 훅 | 기본 (2026-10-17 조각 단위 판정·명령 등록 `if` 반영, 시험 31/31 [#173](https://github.com/yanos0218/AI/issues/173)·[#147](https://github.com/yanos0218/AI/issues/147)) | ✓ | ✓ | ✓ | - | - |
| 훅 파이썬 전환(`hooklib.py` + 셸 입구·파이썬 본체) | 기본 (2026-09-28 승격, 30일 명령 766건 대조 [#144](https://github.com/yanos0218/AI/issues/144)) | ✓ | ✓ | ✓ | - | Linux 파이썬 3.6.8에서 훅 시험 32/32 통과(2026-10-22, [#202](https://github.com/yanos0218/AI/issues/202)), 새 세션에서 실제 동작 확인 |
| statusline 훅 | 기본 (터미널 CLI 전용, VS Code 패널엔 안 나옴) | ✓ | ✓ | ✓ | - | - |
| 컴팩션 안전망 훅(`compact-snapshot.sh`·`compact-snapshot-show.sh`) | 기본 (2026-09-27 승격, 실제 자동 컴팩션에서 확인 [#104](https://github.com/yanos0218/AI/issues/104)) | ✓ | ✓ | ✓ | - | - |
| 형식 검사 훅(`format-guard.sh`·`md-format-check.sh`·`format_check.py`·`check-cram.py`) | 기본 (2026-09-29 승격, 시험 32/32, 새 세션에서 위반 커밋 차단 확인 [#141](https://github.com/yanos0218/AI/issues/141)) | ✓ | ✓ | ✓ | - | `check-cram.py` 필드-값 형식 예외 판정 2026-10-17 기본 반영 [#175](https://github.com/yanos0218/AI/issues/175)<br>`.md` 문장형 검사 2026-10-21 추가, 시험 41/41 [#188](https://github.com/yanos0218/AI/issues/188) |
| 용도별 에이전트 3종(`base/agents/` + `verifier-guard`) | 기본 (2026-09-27 승격, 새 세션 18회 [#131](https://github.com/yanos0218/AI/issues/131)) | ✓ | ✓ | ✓ | - | VS Code 화면에서 위임 사용 확인 |
| dev-release 스킬 | 기본 (3시나리오 2026-09-08, 문서 동기화 확인 단계 [#121](https://github.com/yanos0218/AI/issues/121)) | ✓ | ✓ | ✓ | 갱신 대기(v0.11.4) | - |
| dev-workflow 스킬 | 기본 (3시나리오 2026-09-09) | ✓ | ✓ | ✓ | 갱신 대기(v0.11.4) | - |
| repo-setup 스킬 | 기본 (3시나리오 2026-09-09) | ✓ | ✓ | ✓ | 갱신 대기(v0.11.4) | - |
| self-audit 스킬 | 기본 (3시나리오 2026-09-13, 이슈 본문 형식 수정 2026-10-07 [#172](https://github.com/yanos0218/AI/issues/172)) | ✓ | ✓ | ✓ | ✗ | Mac·Linux 새 세션 발동 미검증 |
| config-update 스킬 | 기본 (원격 확인 수정 3시나리오 2026-09-28 [#150](https://github.com/yanos0218/AI/issues/150)) | ✓ | ✓ | ✓ | ✗ | 결과 보고에 PROGRESS 기록 줄 포함·명령 하나씩 실행 문구 수정안 `drafts/skills/` 초안, 다른 기기 갱신 때 8단계 보고 확인 뒤 승격 [#181](https://github.com/yanos0218/AI/issues/181) |
| pdf-extract 스킬 | 기본 (2026-09-27 승격, 새 세션 6시나리오 [#132](https://github.com/yanos0218/AI/issues/132)) | ✓ (MarkItDown 가상환경) | ✓ (MarkItDown 가상환경 2026-09-29) | ✗ (Python 3.10+ 가상환경 필요, Rocky는 python3.11) | - (웹은 PDF 직접 처리) | CID 깨짐 PDF 미시험 |
| usage-dashboard 스킬(요청 시 켜는 기록 훅 + 로컬 대시보드) | 기본 (2026-09-29 승격, Windows 실사용·Mac 화면 확인 [#136](https://github.com/yanos0218/AI/issues/136)) | ✓ | ✓ | - (Linux 제외) | - (로컬 전용) | `claude -p` 세션은 기록 안 됨, 90일 쌓인 뒤(2026-12 말) Windows 처리 시간 측정 |
| `base/vscode/` 확장 목록·설정·설치 스크립트 | 기본 (2026-09-29 16개 [#165](https://github.com/yanos0218/AI/issues/165), Mac 폴백 확인 [#57](https://github.com/yanos0218/AI/issues/57), 2026-10-24 WSL의 Windows `code` 중단 [#204](https://github.com/yanos0218/AI/issues/204)) | ✓ | ✓ | - | - | - |
| `tools/bootstrap.sh` (신규 기기 설치) | 기본 (빈 `HOME` 시뮬레이션 2026-09-17) | - | - | - | - | 실제 신규 기기에서 curl 한 줄 검증 |
| 저장소 전용 훅(`.claude/hooks/` baseline-guard·pre-commit-check·session-end-check) | 기본 (2026-09-29 커밋 검사 우회·경로 읽기 수정 [#156](https://github.com/yanos0218/AI/issues/156) [#163](https://github.com/yanos0218/AI/issues/163)) | 저장소 안 | 저장소 안 | 저장소 안 | - | - |
| 이 저장소 CI(lint.yml + check-docs.sh) | 기본 (2026-09-08, shellcheck 대상 확대 [#161](https://github.com/yanos0218/AI/issues/161)) | GitHub | GitHub | GitHub | - | - |
| 성향 데이터 → 전역 지침 후보 | 초안 (월 점검에서 auto memory·대화 기록 검토 [#9](https://github.com/yanos0218/AI/issues/9) [#15](https://github.com/yanos0218/AI/issues/15)) | - | - | - | - | 월 점검 |
| 블로그용 스킬 | 계획 (역할 구분 선행 [#7](https://github.com/yanos0218/AI/issues/7)) | - | - | - | - | - |
| 사업기획용 스킬 | 계획 (요구사항 미정 [#8](https://github.com/yanos0218/AI/issues/8)) | - | - | - | - | - |

## 1. 완료

완료 이력은 GitHub Issues에 있다(closed, `task`/`bug` 라벨).

- 조회: `gh issue list --state closed --label task`
- 46건은 2026-09-12에 이관, 그 뒤로는 이슈가 닫히는 시점이 곧 완료 시점임

## 2. 할 일 — 개발·설정

할 일은 GitHub Issues로 관리한다([Issue #11](https://github.com/yanos0218/AI/issues/11), 2026-09-12). `gh issue list --state open --label task`로 확인. 작업 중 발견한 문제는 `bug` 라벨.

## 3. 할 일 — 배포·운영·비개발

§2와 같은 곳(Issues)에서 관리함.

## 4. 결정 사항 (다시 묻지 말 것)

[decisions.md](decisions.md)가 원본. 여기서는 중복하지 않음.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인
  - [review-vs-official.md](review-vs-official.md) 검토표 "보류" 참고
- Code Review(관리형 PR 자동 리뷰)
  - Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
- Claude Code GitHub Actions(`@claude` 멘션)
  - `gh pr list`가 이 저장소에서 0건, PR 위에서 도는 기능이라 지금 켜도 쓸 자리가 없음.
  - PR 습관이 생기기 전엔 재검토 안 함([Issue #61](https://github.com/yanos0218/AI/issues/61), 2026-09-13)
- 설계 도우미 에이전트 `architect`([Issue #153](https://github.com/yanos0218/AI/issues/153), [Issue #145](https://github.com/yanos0218/AI/issues/145), 2026-10-21 기각)
  - 새 세션 시험(2026-09-29, 메인 Sonnet)에서 메인 토큰 절약 없음(194k 대 190k), 비용 약 2배
  - 하나로 이어진 작업은 메인 모델 단독이 유리하다는 공식 비용 문서와 위임 1회 평균 약 370만 토큰이라는 30일 실측이 근거
  - 재시험(메인 Opus, 큰 설계)은 Opus 세션 2회 이상이 필요해 한도 부담이 크고 결론을 바꿀 가능성이 낮아 하지 않음
  - 설계 틀은 전역 지침 §8, 빠진 항목 훑기는 §2에 이미 반영됨
