# claude-config 진행 보드 (PROGRESS)

> "지금 어디까지 됐고, 다음에 뭘 할지"를 이 문서 하나로 추적한다. kolo_pwa `docs/PROGRESS.md`와 같은 역할.
>
> **역할 분리**
>
> - 이 문서 = **자산 현황 + 배포 상태** (살아있는 표, 계속 갱신). 할 일·완료 이력은 Issues
> - [HANDOFF.md](HANDOFF.md) = **새 세션이 처음 읽는 요약** (목적, 결정 사항, 이 보드로 가는 안내)
> - [README.md](../README.md) = **무엇이 왜 이렇게 만들어졌는지** (구조, 설치, 검토표)
> - git log = 완료된 변경 이력
>
> **업데이트 규칙**: §0 표는 자산 단계·배포 여부가 바뀔 때 갱신한다. 새 할 일은 `gh issue create --label task`로. 세션이 끝날 때 이 표와 HANDOFF "현재 상태"를 같이 갱신한다.
>
> **크기 규칙 ([Issue #49](https://github.com/yanos0218/AI/issues/49), 2026-09-08; 범위 조정 [Issue #11](https://github.com/yanos0218/AI/issues/11) 2026-09-12)**: 이 파일은 **§0 자산 현황 표**만 담는다. 할 일·발견한 문제·완료 이력은 전부 GitHub Issue로 관리한다(라벨 `task`/`bug`, open/closed로 진행 상태 구분).

---

## 0. 자산 현황 — 단계와 배포 상태

모든 자산(지침·스킬·훅·설정)은 아래 네 단계 중 하나에 있다. 단계는 **앞으로만** 간다. 뒤로 가야 하면(기본에서 문제 발견) 기본 영역은 그대로 두고 수정안을 `drafts/`에 만들어 다시 검증한다.

| 단계 | 뜻 | 있는 곳 |
| --- | --- | --- |
| 계획 | 하기로 했지만 파일이 없음 | GitHub Issue(`task` 라벨)만 |
| 초안 | 파일은 있지만 시험 전 | `drafts/` |
| 검증 | 시험 진행 중, 결과가 이 보드에 기록됨 | `drafts/` (시험 기록은 §1~§3 항목에) |
| 기본 | 시험 통과 + 사용자 반영 요청 → 승격 커밋 | `base/` |

"기본"이 되면 끝이 아니라 **배포**(어느 표면에 실제로 설치됐는가)와 **관리**([Issue #42](https://github.com/yanos0218/AI/issues/42) 정기 점검 대상)가 따라온다. 배포 열은 표면별로 `✓` 설치됨 / `✗` 미설치 / `-` 해당 없음 / `?` 확인 필요.

| 자산 | 단계 | Windows | Mac mini | Linux | 웹(Claude.ai) | 다음 행동 |
| --- | --- | --- | --- | --- | --- | --- |
| 전역 지침 `base/claude-md/CLAUDE.md` | 기본 | ✓ v0.9.0 (2026-09-13) | ✓ v0.6.0 | ✗ | ✓ Project instructions (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| dev-release 스킬 | 기본 (3시나리오 통과 2026-09-08, 0단계 미인증 시나리오 통과 2026-09-09) | ✓ v0.5.0 (2026-09-12) | ✓ v0.5.0 | ✗ | ✓ v0.6.0 (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| git-guardrails 훅 | 기본 (새 세션 push 차단 확인 2026-09-08) | ✓ | ✓ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| gh-throttle 훅 | 기본 (mkdir 락 기반 실제 직렬화로 개선, 병렬 3개 실측 확인 2026-09-13, [Issue #74](https://github.com/yanos0218/AI/issues/74)) | ✓ v0.9.0 | ✗ | ✗ | - | Mac·Linux 설치 시 |
| session-start-check 훅(SessionStart) | 기본 (설정 버전·저장소 표준 4시나리오 2026-09-12 + self-audit 안내 4시나리오 2026-09-13 직접 실행 확인) | ✓ | ✗ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| config-changelog 훅 | 기본 (임시 HOME 7케이스 통과, 2026-09-09) | ✓ v0.4.0 | ✓ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| statusline 훅 | 기본 (터미널 CLI 전용, VS Code 패널엔 안 나옴) | ✓ 육안 확인 2026-09-12 | ✓ 설치 (VS Code 패널만 써서 표시 없음) | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| `settings.example.json` (권한·훅·상태줄·env) | 기본 | ✓ v0.9.0 | ✓ (`model` 키 유지 병합) | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| 서브에이전트 재귀 차단(`env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`) | 기본 (새 세션에서 재귀 시도 → 차단 실측 확인 2026-09-13, [Issue #75](https://github.com/yanos0218/AI/issues/75)) | ✓ v0.9.0 | ✗ | ✗ | - | Mac·Linux 설치 시 |
| `base/vscode/` 확장 목록·설정·설치 스크립트 | 기본 | ✓ v0.3.0 | ✓ 확장 13개 (2026-09-09, Settings Sync가 안 켜져 있어 `install.sh`로 설치. settings.json은 기존 것 유지) | - | - | - |
| baseline-guard·session-end-check 훅 (이 저장소 전용, `.claude/`) | 기본 (새 세션 차단 확인 2026-09-08 / 트리 상태 시험 2026-09-09) | 저장소 안에서만 동작 | 동일 | 동일 | - | - |
| dev-workflow 스킬 | 기본 (3시나리오 통과 2026-09-09, v0.5.0) | ✓ | ✓ | ✗ | ✓ v0.6.0 (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| 모듈 규칙 `base/rules/docs-format.md` | 기본 (v0.5.0) | ✓ | ✓ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| repo-setup 스킬 | 기본 (3시나리오 통과 2026-09-09, v0.6.0) | ✓ v0.8.0 (2026-09-13) | ✓ v0.6.0 | ✗ | ✓ v0.6.0 (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| self-audit 스킬 (대화 기록 기반 CLAUDE.md 감사) | 기본 (3시나리오 통과 2026-09-13: "self-audit 해줘"·"이번 달 CLAUDE.md 점검해줘" 발동, "테스트 어떻게 해?" 오발동 안 함. 감사 표시 파일 쓰기는 작업 디렉터리 밖이라 매번 승인 필요 — 정상) | ✓ | ✗ | ✗ | ✗ | 웹 업로드는 다음 `pack.sh` 배치 때 |
| 블로그용 스킬 | 계획 (역할 구분 선행) | | | | | [Issue #7](https://github.com/yanos0218/AI/issues/7) |
| 사업기획용 스킬 | 계획 (요구사항 미정) | | | | | [Issue #8](https://github.com/yanos0218/AI/issues/8) |
| 이 저장소 CI (lint.yml + check-docs.sh) | 기본 (첫 Actions 실행 success, 2026-09-08) | 저장소 안에서만 | 동일 | 동일 | - | - |
| 성향 데이터 → 전역 지침 후보 | 초안 (`drafts/observations/`, `/insights` 후보 1건 → [Issue #15](https://github.com/yanos0218/AI/issues/15)) | | | | | [Issue #9](https://github.com/yanos0218/AI/issues/9)/[Issue #15](https://github.com/yanos0218/AI/issues/15), 월 점검 |
| GitHub 활용 (`@claude` Actions) | 결정 대기 (web은 [Issue #30](https://github.com/yanos0218/AI/issues/30)로 이미 결정) | | | | | [Issue #61](https://github.com/yanos0218/AI/issues/61) |

## 1. 완료

완료 이력은 GitHub Issues에 있다(closed, `task`/`bug` 라벨) — `gh issue list --state closed --label task`. 46건은 2026-09-12에 이관, 그 뒤로는 이슈가 닫히는 시점이 곧 완료 시점이다.

## 2. 할 일 — 개발·설정

할 일은 GitHub Issues로 관리한다([Issue #11](https://github.com/yanos0218/AI/issues/11), 2026-09-12). `gh issue list --state open --label task`로 확인. 작업 중 발견한 문제는 `bug` 라벨.

## 3. 할 일 — 배포·운영·비개발

§2와 같은 곳(Issues)에서 관리한다.

## 4. 결정 사항 (다시 묻지 말 것)

HANDOFF.md "결정 사항" 절이 원본. 여기서는 중복하지 않는다.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인 — README 검토표 "보류" 참고
- Code Review(관리형 PR 자동 리뷰) — Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
- Claude Code GitHub Actions(`@claude` 멘션) — `gh pr list`가 이 저장소에서 0건, PR 위에서 도는 기능이라 지금 켜도 쓸 자리가 없다.
  - PR 습관이 생기기 전엔 재검토 안 함([Issue #61](https://github.com/yanos0218/AI/issues/61), 2026-09-13)
