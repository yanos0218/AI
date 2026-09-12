# claude-config 진행 보드 (PROGRESS)

> "지금 어디까지 됐고, 다음에 뭘 할지"를 이 문서 하나로 추적한다. kolo_pwa `docs/PROGRESS.md`와 같은 역할.
>
> **역할 분리**
>
> - 이 문서 = **현재 상태 + 할 일** (살아있는 보드, 계속 갱신)
> - [HANDOFF.md](HANDOFF.md) = **새 세션이 처음 읽는 요약** (목적, 결정 사항, 이 보드로 가는 안내)
> - [README.md](../README.md) = **무엇이 왜 이렇게 만들어졌는지** (구조, 설치, 검토표)
> - git log = 완료된 변경 이력
>
> **업데이트 규칙**: 작업 시작 시 `[ ]`→`[~]`, 완료 시 `[x]`와 날짜. 새 할 일이 떠오르면 즉시 `C-NN` ID를 붙여 §2 또는 §3에 추가한다. 세션이 끝날 때 이 보드와 HANDOFF "현재 상태"를 같이 갱신한다.
>
> **크기 규칙 ([C-40](#c-40), 2026-09-08; 범위 조정 [C-54](#c-54) 2026-09-12)**: 이 파일은 **§0 자산 현황 표 + 최근 30일 완료 이력**만 담는다. 할 일과 발견한 문제는 GitHub Issue로 관리한다(라벨 `task`/`bug`). 오래된 완료 항목은 월 점검 때 `docs/progress/archive-YYYY-MM.md`로 옮긴다. 한 항목의 설명이 3줄을 넘으면 `docs/progress/C-NN.md`로 빼고 여기엔 한 줄 + 링크만.

---

## 0. 자산 현황 — 단계와 배포 상태

모든 자산(지침·스킬·훅·설정)은 아래 네 단계 중 하나에 있다. 단계는 **앞으로만** 간다. 뒤로 가야 하면(기본에서 문제 발견) 기본 영역은 그대로 두고 수정안을 `drafts/`에 만들어 다시 검증한다.

| 단계 | 뜻 | 있는 곳 |
| --- | --- | --- |
| 계획 | 하기로 했지만 파일이 없음 | 이 보드의 `C-NN` 항목만 |
| 초안 | 파일은 있지만 시험 전 | `drafts/` |
| 검증 | 시험 진행 중, 결과가 이 보드에 기록됨 | `drafts/` (시험 기록은 §1~§3 항목에) |
| 기본 | 시험 통과 + 사용자 반영 요청 → 승격 커밋 | `base/` |

"기본"이 되면 끝이 아니라 **배포**(어느 표면에 실제로 설치됐는가)와 **관리**([C-21](#c-21) 정기 점검 대상)가 따라온다. 배포 열은 표면별로 `✓` 설치됨 / `✗` 미설치 / `-` 해당 없음 / `?` 확인 필요.

| 자산 | 단계 | Windows | Mac mini | Linux | 웹(Claude.ai) | 다음 행동 |
| --- | --- | --- | --- | --- | --- | --- |
| 전역 지침 `base/claude-md/CLAUDE.md` | 기본 | ✓ v0.6.0 (2026-09-12) | ✓ v0.6.0 | ✗ | ✓ Project instructions (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| dev-release 스킬 | 기본 (3시나리오 통과 2026-09-08, 0단계 미인증 시나리오 통과 2026-09-09) | ✓ v0.5.0 (2026-09-12) | ✓ v0.5.0 | ✗ | ✓ v0.6.0 (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| git-guardrails 훅 | 기본 (새 세션 push 차단 확인 2026-09-08) | ✓ | ✓ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| config-changelog 훅 | 기본 (임시 HOME 7케이스 통과, 2026-09-09) | ✓ v0.4.0 | ✓ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| statusline 훅 | 기본 (터미널 CLI 전용, VS Code 패널엔 안 나옴) | ✓ 육안 확인 2026-09-12 | ✓ 설치 (VS Code 패널만 써서 표시 없음) | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| `settings.example.json` (권한·훅·상태줄) | 기본 | ✓ | ✓ (`model` 키 유지 병합) | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| `base/vscode/` 확장 목록·설정·설치 스크립트 | 기본 | ✓ v0.3.0 | ✓ 확장 13개 (2026-09-09, Settings Sync가 안 켜져 있어 `install.sh`로 설치. settings.json은 기존 것 유지) | - | - | - |
| baseline-guard·session-end-check 훅 (이 저장소 전용, `.claude/`) | 기본 (새 세션 차단 확인 2026-09-08 / 트리 상태 시험 2026-09-09) | 저장소 안에서만 동작 | 동일 | 동일 | - | - |
| dev-workflow 스킬 | 기본 (3시나리오 통과 2026-09-09, v0.5.0) | ✓ | ✓ | ✗ | ✓ v0.6.0 (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| 모듈 규칙 `base/rules/docs-format.md` | 기본 (v0.5.0) | ✓ | ✓ | ✗ | - | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| repo-setup 스킬 | 기본 (3시나리오 통과 2026-09-09, v0.6.0) | ✓ v0.6.0 (2026-09-12) | ✓ v0.6.0 | ✗ | ✓ v0.6.0 (2026-09-12 업로드 스크린샷 확인, 발동 미검증) | [Issue #6](https://github.com/yanos0218/AI/issues/6) |
| 블로그용 스킬 | 계획 (역할 구분 선행) | | | | | [Issue #7](https://github.com/yanos0218/AI/issues/7) |
| 사업기획용 스킬 | 계획 (요구사항 미정) | | | | | [Issue #8](https://github.com/yanos0218/AI/issues/8) |
| 이 저장소 CI (lint.yml + check-docs.sh) | 기본 (첫 Actions 실행 success, 2026-09-08) | 저장소 안에서만 | 동일 | 동일 | - | - |
| 성향 데이터 → 전역 지침 후보 | 초안 (`drafts/observations/`, `/insights` 후보 1건 → [C-53](#c-53)) | | | | | [Issue #9](https://github.com/yanos0218/AI/issues/9)/[C-53](#c-53), 월 점검 |
| GitHub 활용 (web·`@claude` Actions) | 결정 대기 | | | | | [C-18](#c-18) |

## 1. 완료

아래 46개는 2026-09-12에 검색·백업용 closed Issue(`task` 라벨)로도 이관됐다. 목록은 `gh issue list --state closed --label task`. 원본은 이 절이 계속 담당한다.

- [x] <a id="c-54"></a>C-54 Issues 사용 범위 확정 → [Issue #11](https://github.com/yanos0218/AI/issues/11)
- [x] <a id="c-34"></a>C-34 GitHub Issues 시험 종료 → [Issue #12](https://github.com/yanos0218/AI/issues/12)
- [x] <a id="c-17"></a>C-17 Claude.ai 웹 업로드 → [Issue #13](https://github.com/yanos0218/AI/issues/13)
- [x] <a id="c-10"></a>C-10 새 세션 훅·상태줄 확인 → [Issue #14](https://github.com/yanos0218/AI/issues/14)
- [x] <a id="c-53"></a>C-53 릴리즈 전 자격증명 점검 → [Issue #15](https://github.com/yanos0218/AI/issues/15)
- [x] <a id="c-25"></a>C-25 `/insights` Mac 첫 실행 → [Issue #16](https://github.com/yanos0218/AI/issues/16)
- [x] <a id="c-45"></a>C-45 플러그인화 검토 → [Issue #17](https://github.com/yanos0218/AI/issues/17)
- [x] <a id="c-01"></a>C-01 전역 지침 `base/claude-md/CLAUDE.md` 작성, Windows `~/.claude/CLAUDE.md`에 설치 → [Issue #18](https://github.com/yanos0218/AI/issues/18)
- [x] <a id="c-02"></a>C-02 dev-release 스킬 + references 3개 → [Issue #19](https://github.com/yanos0218/AI/issues/19)
- [x] <a id="c-03"></a>C-03 git-guardrails·statusline 훅, `settings.example.json`(권한 allow/deny·훅·상태줄), Windows 설치 → [Issue #20](https://github.com/yanos0218/AI/issues/20)
- [x] <a id="c-04"></a>C-04 VS Code 확장 선별 13개 + `base/vscode/` 부트스트랩 스크립트 → [Issue #21](https://github.com/yanos0218/AI/issues/21)
- [x] <a id="c-05"></a>C-05 Windows에 Claude Code CLI 네이티브 설치 → [Issue #22](https://github.com/yanos0218/AI/issues/22)
- [x] <a id="c-06"></a>C-06 공식 문서·커뮤니티 대비 검토표(README) → [Issue #23](https://github.com/yanos0218/AI/issues/23)
- [x] <a id="c-07"></a>C-07 dev-release 발동 테스트 3시나리오 → [Issue #24](https://github.com/yanos0218/AI/issues/24)
- [x] <a id="c-08"></a>C-08 GitHub 활용 현황 조사 + 선택지 정리(README "GitHub 활용") → [Issue #25](https://github.com/yanos0218/AI/issues/25)
- [x] <a id="c-23"></a>C-23 기본 영역/작업 영역 분리 → [Issue #26](https://github.com/yanos0218/AI/issues/26)
- [x] <a id="c-28"></a>C-28 버전·릴리즈 규칙 + 첫 컷 → [Issue #27](https://github.com/yanos0218/AI/issues/27)
- [x] <a id="c-15"></a>C-15 Mac mini 반영 → [Issue #28](https://github.com/yanos0218/AI/issues/28)
- [x] <a id="c-26"></a>C-26 claude.ai 메모리 검토 → [Issue #29](https://github.com/yanos0218/AI/issues/29)
- [x] <a id="c-18"></a>C-18 GitHub 활용 결정 → [Issue #30](https://github.com/yanos0218/AI/issues/30)
- [x] <a id="c-31"></a>C-31 Dependabot 알림 → [Issue #31](https://github.com/yanos0218/AI/issues/31)
- [x] <a id="c-32"></a>C-32 GitHub 2FA → [Issue #32](https://github.com/yanos0218/AI/issues/32)
- [x] <a id="c-38"></a>C-38 Actions 사용량 → [Issue #33](https://github.com/yanos0218/AI/issues/33)
- [x] <a id="c-42"></a>C-42 모듈 규칙 base/rules/docs-format.md 첫 모듈 추가 → [Issue #34](https://github.com/yanos0218/AI/issues/34)
- [x] <a id="c-11"></a>C-11 permissions.allow 보완 12개 + dev-release allowed-tools → [Issue #35](https://github.com/yanos0218/AI/issues/35)
- [x] <a id="c-44"></a>C-44 `tools/install.sh` → [Issue #36](https://github.com/yanos0218/AI/issues/36)
- [x] <a id="c-46"></a>C-46 `tools/test-skill.sh` → [Issue #37](https://github.com/yanos0218/AI/issues/37)
- [x] <a id="c-51"></a>C-51 시험 모델 기본 Sonnet → [Issue #38](https://github.com/yanos0218/AI/issues/38)
- [x] <a id="c-48"></a>C-48 Stop 훅 `session-end-check.sh`(이 저장소 전용) → [Issue #39](https://github.com/yanos0218/AI/issues/39)
- [x] <a id="c-49"></a>C-49 전역 지침 §5 조사 규칙·Sonnet 한 줄 승격, `[Unreleased]` → [Issue #40](https://github.com/yanos0218/AI/issues/40)
- [x] <a id="c-50"></a>C-50 조사 기록 운영 시작 → [Issue #41](https://github.com/yanos0218/AI/issues/41)
- [x] <a id="c-21"></a>C-21 월 점검 루틴 정의 → [Issue #42](https://github.com/yanos0218/AI/issues/42)
- [x] <a id="c-43"></a>C-43 월 점검에 대조·이력 항목 포함 → [Issue #43](https://github.com/yanos0218/AI/issues/43)
- [x] <a id="c-36"></a>C-36 세션 관찰 기록 → [Issue #44](https://github.com/yanos0218/AI/issues/44)
- [x] <a id="c-13"></a>C-13 개발용 스킬 `dev-workflow` → [Issue #45](https://github.com/yanos0218/AI/issues/45)
- [x] <a id="c-47"></a>C-47 전역 지침 §2 "규칙 이탈 금지" 한 줄 승격, Windows 설치, `[Unreleased]` → [Issue #46](https://github.com/yanos0218/AI/issues/46)
- [x] <a id="c-41"></a>C-41 config-changelog 훅 승격 → [Issue #47](https://github.com/yanos0218/AI/issues/47)
- [x] <a id="c-39"></a>C-39 경로 재구성 → [Issue #48](https://github.com/yanos0218/AI/issues/48)
- [x] <a id="c-40"></a>C-40 PROGRESS 운영 규칙 → [Issue #49](https://github.com/yanos0218/AI/issues/49)
- [x] <a id="c-29"></a>C-29 `tools/pack.sh` Windows 실패 → [Issue #50](https://github.com/yanos0218/AI/issues/50)
- [x] <a id="c-37"></a>C-37 전역 지침 수정안 승격 → [Issue #51](https://github.com/yanos0218/AI/issues/51)
- [x] <a id="c-12"></a>C-12 이 저장소 CI → [Issue #52](https://github.com/yanos0218/AI/issues/52)
- [x] <a id="c-33"></a>C-33 README 입구화 + 문서 규칙 → [Issue #53](https://github.com/yanos0218/AI/issues/53)
- [x] <a id="c-30"></a>C-30 GitHub 기능 전체 대비 사용 수준 검토 → [Issue #54](https://github.com/yanos0218/AI/issues/54)
- [x] <a id="c-24"></a>C-24 사용자 성향 데이터 활용 방안 조사 → [Issue #55](https://github.com/yanos0218/AI/issues/55)
- [x] <a id="c-35"></a>C-35 repo-setup 스킬 → [Issue #56](https://github.com/yanos0218/AI/issues/56)

## 2. 할 일 — 개발·설정

할 일은 GitHub Issues로 관리한다([C-54](#c-54), 2026-09-12). `gh issue list --state open --label task`로 확인. 작업 중 발견한 문제는 `bug` 라벨.

## 3. 할 일 — 배포·운영·비개발

§2와 같은 곳(Issues)에서 관리한다.

## 4. 결정 사항 (다시 묻지 말 것)

HANDOFF.md "결정 사항" 절이 원본. 여기서는 중복하지 않는다.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인 — README 검토표 "보류" 참고
- Code Review(관리형 PR 자동 리뷰) — Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
