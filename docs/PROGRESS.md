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
> **크기 규칙 ([C-40](#c-40), 2026-09-08)**: 이 파일은 **열린 항목 + 최근 30일 완료**만 담는다. 그보다 오래된 완료 항목은 월 점검 때 `docs/progress/archive-YYYY-MM.md`로 옮긴다. 한 항목의 설명이 3줄을 넘으면 `docs/progress/C-NN.md`로 빼고 여기엔 한 줄 + 링크만. 작업 중 **발견한 문제**는 GitHub Issue로 열고 항목에 `#N`을 적는다([C-34](#c-34)). 열린 항목이 100개를 넘거나 병렬 세션을 쓰게 되면 beads 같은 에이전트용 트래커를 검토한다.

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
| 전역 지침 `base/claude-md/CLAUDE.md` | 기본 | ✓ v0.6.0 (2026-09-12) | ✓ v0.6.0 | ✗ | ✓ Project instructions (2026-09-12 사용자 업로드, 발동 미검증) | [C-16](#c-16) |
| dev-release 스킬 | 기본 (3시나리오 통과 2026-09-08, 0단계 미인증 시나리오 통과 2026-09-09) | ✓ v0.5.0 (2026-09-12) | ✓ v0.5.0 | ✗ | ✓ v0.6.0 (2026-09-12 사용자 업로드, 발동 미검증) | [C-16](#c-16) |
| git-guardrails 훅 | 기본 (새 세션 push 차단 확인 2026-09-08) | ✓ | ✓ | ✗ | - | [C-16](#c-16) |
| config-changelog 훅 | 기본 (임시 HOME 7케이스 통과, 2026-09-09) | ✓ v0.4.0 | ✓ | ✗ | - | [C-16](#c-16) |
| statusline 훅 | 기본 (터미널 CLI 전용, VS Code 패널엔 안 나옴) | ✓ 육안 확인 2026-09-12 | ✓ 설치 (VS Code 패널만 써서 표시 없음) | ✗ | - | [C-16](#c-16) |
| `settings.example.json` (권한·훅·상태줄) | 기본 | ✓ | ✓ (`model` 키 유지 병합) | ✗ | - | [C-16](#c-16) |
| `base/vscode/` 확장 목록·설정·설치 스크립트 | 기본 | ✓ v0.3.0 | ✓ 확장 13개 (2026-09-09, Settings Sync가 안 켜져 있어 `install.sh`로 설치. settings.json은 기존 것 유지) | - | - | - |
| baseline-guard·session-end-check 훅 (이 저장소 전용, `.claude/`) | 기본 (새 세션 차단 확인 2026-09-08 / 트리 상태 시험 2026-09-09) | 저장소 안에서만 동작 | 동일 | 동일 | - | - |
| dev-workflow 스킬 | 기본 (3시나리오 통과 2026-09-09, v0.5.0) | ✓ | ✓ | ✗ | ✓ v0.6.0 (2026-09-12 사용자 업로드, 발동 미검증) | [C-16](#c-16) |
| 모듈 규칙 `base/rules/docs-format.md` | 기본 (v0.5.0) | ✓ | ✓ | ✗ | - | [C-16](#c-16) |
| repo-setup 스킬 | 기본 (3시나리오 통과 2026-09-09, v0.6.0) | ✓ v0.6.0 (2026-09-12) | ✓ v0.6.0 | ✗ | ✓ v0.6.0 (2026-09-12 사용자 업로드, 발동 미검증) | [C-16](#c-16) |
| 블로그용 스킬 | 계획 (역할 구분 선행) | | | | | [C-19](#c-19) |
| 사업기획용 스킬 | 계획 (요구사항 미정) | | | | | [C-20](#c-20) |
| 이 저장소 CI (lint.yml + check-docs.sh) | 기본 (첫 Actions 실행 success, 2026-09-08) | 저장소 안에서만 | 동일 | 동일 | - | - |
| 성향 데이터 → 전역 지침 후보 | 초안 (`drafts/observations/`, `/insights` 후보 1건 → [C-53](#c-53)) | | | | | [C-27](#c-27)/53, 월 점검 |
| GitHub 활용 (web·`@claude` Actions) | 결정 대기 | | | | | [C-18](#c-18) |

## 1. 완료

- [x] <a id="c-17"></a>C-17 Claude.ai 웹 업로드 — `dist/` zip 3개(dev-release·dev-workflow·repo-setup) Skills 업로드 + Project instructions에 `base/claude-md/CLAUDE.md`, 사용자가 진행(2026-09-12). Claude는 웹을 볼 수 없어 발동은 미검증 — 웹에서 "버전 올려줘"로 dev-release가 뜨는지 사용자가 확인. 이후 CLAUDE.md를 고칠 때마다 다시 붙여넣어야 함(README "규칙을 고칠 때") (2026-09-12)
- [x] <a id="c-10"></a>C-10 새 세션 훅·상태줄 확인 — 훅 2개는 `claude -p` 새 세션 차단 확인(2026-09-08). 상태줄은 터미널 CLI 전용(VS Code 패널엔 안 나옴, 공식 문서 확인 2026-09-09) — Windows 터미널 `claude.exe`에서 `[Fable 5.1] System32 | ░ 0% | $0.00` 육안 확인(2026-09-12). Mac은 PATH에 CLI 없어도 VS Code 확장 내장 바이너리(`~/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude`)로 실행 가능 (2026-09-12)
- [x] <a id="c-53"></a>C-53 릴리즈 전 자격증명 점검 — 전역 §7 한 줄 + dev-release 0단계 승격(사용자 승인 2026-09-09), `check-install.sh` VS Code 확장 대조. 미인증 시나리오 발동 시험 통과, `test-skill.sh` 버그 2건 수정([#3](https://github.com/yanos0218/AI/issues/3)). 상세 [docs/progress/C-53.md](progress/C-53.md). Mac 재설치, Windows 미반영 (2026-09-09)
- [x] <a id="c-25"></a>C-25 `/insights` Mac 첫 실행 — `claude -p "/insights"`로 비대화형 동작 확인. 3세션 23메시지라 얕음. 제안 7개 중 채택 후보 1(릴리즈 전 `gh auth` 점검·토큰 붙여넣기 금지 → [C-53](#c-53)), 나머지는 기존 장치로 충분. 원자료 `drafts/observations/2026-09-09-insights-mac/`, 판정 `drafts/claude-md/2026-09-09-insights-candidates.md`. 다음 실행은 10월 점검 (2026-09-09)
- [x] <a id="c-45"></a>C-45 플러그인화 검토 — **보류.** 플러그인은 스킬·훅만 싣고 전역 지침·rules·permissions·statusLine은 못 실어 `install.sh`가 어차피 남음. 1인·3기기에선 설치 경로·버전이 둘로 늘기만 함. 근거·재검토 조건은 [docs/research/plugins.md](research/plugins.md) (2026-09-09)
- [x] <a id="c-01"></a>C-01 전역 지침 `base/claude-md/CLAUDE.md` 작성, Windows `~/.claude/CLAUDE.md`에 설치 (2026-09-08)
- [x] <a id="c-02"></a>C-02 dev-release 스킬 + references 3개 (2026-09-08)
- [x] <a id="c-03"></a>C-03 git-guardrails·statusline 훅, `settings.example.json`(권한 allow/deny·훅·상태줄), Windows 설치 (2026-09-08)
- [x] <a id="c-04"></a>C-04 VS Code 확장 선별 13개 + `base/vscode/` 부트스트랩 스크립트 (2026-09-08)
- [x] <a id="c-05"></a>C-05 Windows에 Claude Code CLI 네이티브 설치 (2026-09-08)
- [x] <a id="c-06"></a>C-06 공식 문서·커뮤니티 대비 검토표(README) (2026-09-08)
- [x] <a id="c-07"></a>C-07 dev-release 발동 테스트 3시나리오 — `claude -p` 새 세션으로 시험, C 시나리오 실패분 SKILL.md 수정 후 재통과 (2026-09-08)
- [x] <a id="c-08"></a>C-08 GitHub 활용 현황 조사 + 선택지 정리(README "GitHub 활용") (2026-09-08)
- [x] <a id="c-23"></a>C-23 기본 영역/작업 영역 분리 — 저장소 `CLAUDE.md`, `drafts/`, `.claude/hooks/baseline-guard.sh`(기본 영역 쓰기 확인 강제) (2026-09-08)
- [x] <a id="c-28"></a>C-28 버전·릴리즈 규칙 + 첫 컷 — `docs/versioning.md`·`CHANGELOG.md` 신설, `v0.1.0` 태그·push·GitHub Release(`dev-release.zip` 첨부) 완료 (2026-09-08)
- [x] <a id="c-15"></a>C-15 Mac mini 반영 — `tools/install.sh`로 설치(기존 `~/.claude/CLAUDE.md` 없어 백업 불필요), `check-install.sh` 일치, 상태줄 훅 샘플 입력으로 실행 확인. 설치 중 `python` 호출이 Mac에서 실패 → `tools/*.sh` 4개를 python3 우선으로 수정(983d6bb, [#2](https://github.com/yanos0218/AI/issues/2)). VS Code 확장 13개는 `base/vscode/install.sh`로 맞춤 (2026-09-09)
- [x] <a id="c-26"></a>C-26 claude.ai 메모리 검토 — 내보내기 확인. 웹=사업기획 용도, `claude-setup` 메모리의 경로가 낡음(사용자가 정정), 프로필에 비개발자·한국어·결론 먼저 추가 권장. C-20 산출물 단서 확보. 기록 `drafts/observations/2026-09-09-claude-ai-memory.md` (2026-09-09)
- [x] <a id="c-18"></a>C-18 GitHub 활용 결정 — Claude Code on the web을 OpenClaw에서 채택, `@claude` Actions 보류. **이 저장소 몫은 결정·절차(`docs/github.md`)까지.** 실행(`/web-setup`, OpenClaw `CLAUDE.md` PR, 첫 세션)은 OpenClaw 저장소 일 (2026-09-09)
- [x] <a id="c-31"></a>C-31 Dependabot 알림 — 사용자가 켬, `gh api`로 6개 저장소 전부 on 확인 (2026-09-09)
- [x] <a id="c-32"></a>C-32 GitHub 2FA — Enabled(패스키) 확인 (2026-09-09)
- [x] <a id="c-38"></a>C-38 Actions 사용량 — 9/1~9/8 총 $0.48 ≈ 60분(OpenClaw 35·kolo-api 18·AI 5·kolo_pwa 2), 월 환산 225분 = 한도의 11%. 청구 $0. docs-only 감지 추가 불필요 (2026-09-09)
- [x] <a id="c-42"></a>C-42 모듈 규칙 `base/rules/docs-format.md` 첫 모듈(문서 형식), `install.sh`가 `~/.claude/rules/`에 설치. `[Unreleased]` (2026-09-09)
- [x] <a id="c-11"></a>C-11 `permissions.allow` 보완 12개 + dev-release `allowed-tools`. `cd X && ls` 복합 명령 프롬프트는 allow로 못 막음(설계상) (2026-09-09)
- [x] <a id="c-44"></a>C-44 `tools/install.sh` — 멱등 설치·settings 병합·CLAUDE.md 백업. 임시 HOME에서 dry-run·설치·2회·백업·기기 키 유지 시험 통과 (2026-09-09)
- [x] <a id="c-46"></a>C-46 `tools/test-skill.sh` — 시나리오 D로 시험, Sonnet 기본 $0.21(Opus $0.53 대비) (2026-09-09)
- [x] <a id="c-51"></a>C-51 시험 모델 기본 Sonnet — test-skill.sh 기본값 (2026-09-09)
- [x] <a id="c-48"></a>C-48 Stop 훅 `session-end-check.sh`(이 저장소 전용) — 미커밋 변경이 있는데 PROGRESS·HANDOFF가 안 바뀌면 알림. 더러운/깨끗한 트리 시험 통과 (2026-09-09)
- [x] <a id="c-49"></a>C-49 전역 지침 §5 조사 규칙·Sonnet 한 줄 승격, `[Unreleased]` (2026-09-09)
- [x] <a id="c-50"></a>C-50 조사 기록 운영 시작 — `docs/research/README.md` 색인 7건 (2026-09-09)
- [x] <a id="c-21"></a>C-21 월 점검 루틴 정의 — `docs/monthly-check.md` 12항목(C-43 대조·이력, C-27 메모리 수집 포함). HANDOFF에 "마지막 점검일" (2026-09-09)
- [x] <a id="c-43"></a>C-43 월 점검에 대조·이력 항목 포함 — monthly-check.md 2·3번 (2026-09-09)
- [x] <a id="c-36"></a>C-36 세션 관찰 기록 — 규칙(저장소 CLAUDE.md)과 하루 파일 하나, 09-08·09-09 기록 (2026-09-09)
- [x] <a id="c-13"></a>C-13 개발용 스킬 `dev-workflow` — 요구사항 3가지 결정, 초안, 3시나리오 통과, 사용자 승인으로 `base/skills/` 승격·Windows 설치. 상세 [docs/progress/C-13.md](progress/C-13.md) (2026-09-09)
- [x] <a id="c-47"></a>C-47 전역 지침 §2 "규칙 이탈 금지" 한 줄 승격, Windows 설치, `[Unreleased]` (2026-09-09)
- [x] <a id="c-41"></a>C-41 config-changelog 훅 승격 — 사용자 승인, `base/hooks/` + `settings.example.json` PostToolUse 등록, Windows 설치, v0.4.0 (2026-09-09)
- [x] <a id="c-39"></a>C-39 경로 재구성 — 기본 영역을 `base/`, 도구를 `tools/`로. 훅·pack.sh·CI·문서 일괄 갱신, v0.3.0 (2026-09-08)
- [x] <a id="c-40"></a>C-40 PROGRESS 운영 규칙 — 열린 항목 + 최근 30일 완료만, 오래된 완료는 월별 아카이브, 상세는 파일, 문제는 Issue (2026-09-08)
- [x] <a id="c-29"></a>C-29 `tools/pack.sh` Windows 실패 — `zip` 없으면 python zipfile 폴백. 로컬 실행 확인 (2026-09-08)
- [x] <a id="c-37"></a>C-37 전역 지침 수정안 승격 — 확인 기준(로컬 커밋 묻지 않음, 배치=메시지 하나, 표준 미달 세션당 한 번 제안). 사용자 승인 후 `drafts/claude-md/` → `base/claude-md/`, v0.2.0 (2026-09-08)
- [x] <a id="c-12"></a>C-12 이 저장소 CI — `.github/workflows/lint.yml`(markdownlint·shellcheck·문서 상한), `.github/dependabot.yml`. 로컬에서 세 검사 통과, 첫 Actions 실행 결과는 push 후 확인 (2026-09-08)
- [x] <a id="c-33"></a>C-33 README 입구화 + 문서 규칙 — 230줄 README를 111줄로, 설치·검토표·GitHub은 `docs/`로 분리. 문서별 줄 수 상한을 CLAUDE.md에 정하고 `check-docs.sh`로 CI 검사 (2026-09-08)
- [x] <a id="c-30"></a>C-30 GitHub 기능 전체 대비 사용 수준 검토 — `docs/github.md` 표. 결론: 전부 쓸 필요 없음, 현재가 1인 권장 수준 (2026-09-08)
 — README "GitHub 기능 전체 대비 사용 수준" 표. 결론: 전부 쓸 필요 없음, 현재가 1인 권장 수준 (2026-09-08)
- [x] <a id="c-24"></a>C-24 사용자 성향 데이터 활용 방안 조사 — 로컬 세션 기록·auto memory·claude.ai 메모리·`/insights` 검토, 결론은 C-25~C-27 (2026-09-08)

## 2. 할 일 — 개발·설정

- [ ] <a id="c-52"></a>C-52 `claude plugin validate base/skills`를 검증 절차에 — 플러그인화 없이도 스킬 디렉터리 검사 통과 확인(2026-09-09, 2.1.266). 저장소 `CLAUDE.md` "검증" 절과 `tools/test-skill.sh` 앞단에 넣을지, CI는 `claude` 설치 비용 때문에 보류
- [ ] <a id="c-14"></a>C-14 Notification 훅 — 병렬 세션(`claude --bg`, worktree)을 실제로 쓰기 시작하면 추가. 그전엔 보류

## 3. 할 일 — 배포·운영·비개발

- [ ] <a id="c-16"></a>C-16 Linux(Rocky) 반영 — `bash tools/install.sh --dry-run` → `install.sh`([C-15](#c-15)와 동일). jq 없어도 상태줄은 python/node 폴백
- [~] <a id="c-34"></a>C-34 GitHub Issues 시험 시작 — 첫 Issue [#1](https://github.com/yanos0218/AI/issues/1)(복합 명령 승인 프롬프트), [#2](https://github.com/yanos0218/AI/issues/2)(tools python3, 열고 바로 닫음). 규칙: 작업 중 발견한 문제는 Issue, 계획·상태는 이 보드, 항목에 `#N`. 한 달 뒤(10월 점검) 유지 여부 판단 (2026-09-09)
- [x] <a id="c-35"></a>C-35 `repo-setup` 스킬 — 3/3 시나리오 통과(Script 클론 / 자체 표준 있는 저장소 → 빠진 칸만 / "배포해줘" 미발동) 후 사용자 승인으로 `base/skills/` 승격, Mac 설치, v0.6.0 (2026-09-09). **이 저장소 몫은 표준(`docs/repo-standard.md`)과 스킬까지.** Script·Etc 적용은 그 저장소 일 — 추천 순서는 [docs/progress/C-35.md](progress/C-35.md), 착수는 사용자 지시 시
- [ ] <a id="c-19"></a>C-19 블로그용 스킬 — 원본은 OpenClaw `core/definitions/modes/blog.md`·`core/playbooks/blog-*.md`(참조만). OpenClaw 원칙 "Claude Code가 블로그를 직접 쓰지 않는다"와 충돌하므로, 스킬화 전에 **역할 구분을 먼저 정리**(초안은 누가, 검수는 누가)
- [ ] <a id="c-20"></a>C-20 사업기획용 스킬 — 웹 메모리에서 산출물 단서 확보(구조화된 기획 문서·경쟁 분석 표·인력/일정 견적). 스킬은 "셋 중 무엇을 어떤 틀로"를 묻고 시작. 제품 세부는 스킬에 넣지 않음. 초안 착수는 사용자 지시 시
- [~] <a id="c-27"></a>C-27 auto memory 수집 — Windows 첫 수집 완료(`drafts/observations/memory-windows/`, 29개, 2026-09-09). Mac 수집 완료(`drafts/observations/memory-mac/`, 4개 — OpenClaw 맥락·릴리즈 절차·gh 설치, 2026-09-09). 전역 성향 추출은 월 점검 5번에서
- [ ] <a id="c-22"></a>C-22 사용량·비용 확인 습관 — 상태줄 `$`와 claude.ai 사용량 페이지. 시험 세션 4회에 약 2달러였음. 한 달 뒤 실제 사용량을 보고 모델/effort 기본값 재검토

## 4. 결정 사항 (다시 묻지 말 것)

HANDOFF.md "결정 사항" 절이 원본. 여기서는 중복하지 않는다.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인 — README 검토표 "보류" 참고
- GitHub 이슈를 백로그로 쓰기 — 커뮤니티 관례지만 사용자 저장소는 `docs/PROGRESS.md` + `P-NN`이 확정. 바꾸지 않음
- Code Review(관리형 PR 자동 리뷰) — Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
