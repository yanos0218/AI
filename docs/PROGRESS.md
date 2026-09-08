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
| 전역 지침 `base/claude-md/CLAUDE.md` | 기본 | ✓ v0.4.0+미릴리즈 1줄 | ? (기존 파일 확인 필요) | ✗ | ✗ (Project instructions) | [C-15](#c-15)/16/17 |
| dev-release 스킬 | 기본 (3시나리오 통과 2026-09-08) | ✓ v0.1.0 | ✗ | ✗ | ✗ (Release v0.1.0의 `dev-release.zip` 업로드) | [C-15](#c-15)/16/17 |
| git-guardrails 훅 | 기본 (새 세션 push 차단 확인 2026-09-08) | ✓ | ✗ | ✗ | - | [C-10](#c-10), [C-15](#c-15)/16 |
| config-changelog 훅 | 기본 (임시 HOME 7케이스 통과, 2026-09-09) | ✓ v0.4.0 | ✗ | ✗ | - | [C-15](#c-15)/16 |
| statusline 훅 | 기본 | ✓ (표시 확인은 [C-10](#c-10), 사용자) | ✗ | ✗ | - | [C-10](#c-10), [C-15](#c-15)/16 |
| `settings.example.json` (권한·훅·상태줄) | 기본 | ✓ (allow 보완은 [C-11](#c-11)) | ✗ | ✗ | - | [C-11](#c-11), [C-15](#c-15)/16 |
| `base/vscode/` 확장 목록·설정·설치 스크립트 | 기본 | ✓ v0.3.0 | ✗ (Settings Sync가 주) | - | - | [C-15](#c-15) |
| baseline-guard 훅 (이 저장소 전용, `.claude/`) | 기본 (새 세션에서 `base/` Edit 차단 확인 2026-09-08) | 저장소 안에서만 동작 | 동일 | 동일 | - | - |
| dev-workflow 스킬 | 기본 (3시나리오 통과 2026-09-09, 미릴리즈) | ✓ | ✗ | ✗ | ✗ | [C-15](#c-15)/16/17 |
| 블로그용 스킬 | 계획 (역할 구분 선행) | | | | | [C-19](#c-19) |
| 사업기획용 스킬 | 계획 (요구사항 미정) | | | | | [C-20](#c-20) |
| 이 저장소 CI (lint.yml + check-docs.sh) | 기본 (첫 Actions 실행 success, 2026-09-08) | 저장소 안에서만 | 동일 | 동일 | - | - |
| 성향 데이터 → 전역 지침 후보 | 초안 (`drafts/observations/`) | | | | | [C-25](#c-25)/26/27/36 |
| GitHub 활용 (web·`@claude` Actions) | 결정 대기 | | | | | [C-18](#c-18) |

## 1. 완료

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

- [~] <a id="c-10"></a>C-10 새 세션 훅·상태줄 확인 — 훅 2개는 `claude -p` 새 세션으로 검증 완료(2026-09-08): baseline-guard가 `base/` Edit을, git-guardrails가 `git push`를 확인 요구로 막음. **상태줄은 대화형 세션에서만 보이므로 사용자가 새 세션을 열어 하단 표시를 확인**하면 완료
- [ ] <a id="c-11"></a>C-11 `permissions.allow` 보완 — C-07 시험에서 `python -m py_compile`이 막혔고, `cd X && ls`는 `Read(./.env)` deny 규칙과 겹쳐 승인 프롬프트가 뜸. 자주 쓰는 검사 명령을 allow에 추가하고 예시 파일에도 반영. 스킬 `allowed-tools` 프런트매터로 dev-release의 `git tag`·`gh release view` 사전 승인도 같이(검토 S7)
- [ ] <a id="c-44"></a>C-44 `tools/install.sh` — 멱등 설치 스크립트: base/ → ~/.claude 복사, settings.json에 permissions·hooks·statusLine 키 병합(기기별 키 유지), 끝에 `check-install.sh`. Mac·Linux 반영(C-15/16)은 이 스크립트로. 검토 P1
- [ ] <a id="c-45"></a>C-45 플러그인화 검토 — base/skills+hooks를 `.claude-plugin/plugin.json`+`hooks/hooks.json`으로 묶고 이 저장소를 개인 마켓플레이스로(`claude plugin install`/`update`). CLAUDE.md·permissions·statusLine은 못 실으므로 install.sh와 병행. Mac 설치 때 이득 판단. 검토 S1
- [ ] <a id="c-46"></a>C-46 `tools/test-skill.sh <스킬> <시나리오 폴더>` — 시나리오 저장소의 `.claude/skills/`에 초안을 넣고 `claude -p`로 돌린 뒤 Skill 호출·최종 답변을 추출. 오늘 손으로 두 번 한 절차의 스크립트화. 검토 P6
- [ ] <a id="c-48"></a>C-48 Stop 훅(이 저장소 전용) — 세션 종료 시 PROGRESS·HANDOFF가 이번 세션에 수정됐는지 `git diff --name-only`로 보고 안 됐으면 한 줄 알림. 소음이면 끔. 검토 S2
- [ ] <a id="c-49"></a>C-49 전역 지침 수정안 — §5에 조사 규칙(공식 우선·날짜·직접 실행 검증·출처·`docs/research/` 기록)과 "서브에이전트·시험 세션은 Sonnet" (`drafts/claude-md/CLAUDE.md`). 승인 시 `[Unreleased]`. 규칙 본문은 `docs/research.md`
- [ ] <a id="c-50"></a>C-50 조사 기록 운영 — `docs/research/README.md` 색인 신설(소급 7건). 새 조사는 규칙대로 파일 추가, "다시 볼 시점" 지난 것은 월 점검 때 재조사
- [ ] <a id="c-51"></a>C-51 시험·서브에이전트 모델 기본값 — `tools/test-skill.sh`(C-46)에 `--model claude-sonnet-5` 기본, 발동 시험 1회 비용 절반 이하 목표. 실제 비용은 시험 결과의 `cost`로 기록
- [ ] <a id="c-14"></a>C-14 Notification 훅 — 병렬 세션(`claude --bg`, worktree)을 실제로 쓰기 시작하면 추가. 그전엔 보류

## 3. 할 일 — 배포·운영·비개발

- [ ] <a id="c-15"></a>C-15 Mac mini 반영 — `base/hooks/*.sh` 복사, `settings.example.json`의 `permissions`/`hooks`/`statusLine` 합치기. 기존 `~/.claude/CLAUDE.md` 내용 확인 후 덮어쓰기. 사용자가 직접 진행
- [ ] <a id="c-16"></a>C-16 Linux(Rocky) 반영 — C-15와 동일 절차. jq 없어도 상태줄은 python/node 폴백
- [ ] <a id="c-17"></a>C-17 Claude.ai 웹 업로드 — `bash tools/pack.sh` → Customize → Skills 업로드, Project instructions에 `base/claude-md/CLAUDE.md` 붙여넣기. 이후 CLAUDE.md를 고칠 때마다 다시 붙여넣어야 함(README "규칙을 고칠 때")
- [ ] <a id="c-34"></a>C-34 GitHub Issues 사용 결정 — Issues는 **무료**(비공개 포함). 제안: 이 저장소에서 한 달 시험 — "작업 중 발견한 문제"(C-29 같은 것)만 Issue로, 계획·상태는 PROGRESS 유지, PROGRESS 항목에 `#N` 링크. 효과 있으면 다른 저장소로. `gh issue list/view`를 permissions.allow에 추가(C-11과 함께)
- [ ] <a id="c-35"></a>C-35 저장소 표준 적용 — `docs/repo-standard.md` 체크리스트를 Script·Etc에 맞추고(다음에 열 때), 표준을 자동으로 맞춰 주는 `repo-setup` 스킬을 초안으로(계획). 전역 지침에 "세션당 한 번 제안" 줄 추가는 C-37에 포함
- [ ] <a id="c-36"></a>C-36 세션 관찰 기록 — 세션 끝에 `drafts/observations/YYYY-MM-DD.md`에 요청·대화·작업 방식 관찰을 적고, 월 1회(C-21) 반복되는 것만 `drafts/claude-md/` 후보로. 첫 기록 2026-09-08 작성됨. 다른 저장소는 auto memory(`feedback_*`)가 같은 역할
- [ ] <a id="c-38"></a>C-38 Actions 월 사용량 확인 — Settings → Billing → Usage에서 분·저장소 사용량. kolo_pwa·kolo-api가 30일 100회 이상 실행. 2,000분의 절반을 넘으면 kolo-api `build.yml`에도 docs-only 감지 추가
- [ ] <a id="c-42"></a>C-42 모듈 규칙 `base/rules/` 도입 — 기본 CLAUDE.md를 건드리지 않고 주제별 규칙 파일을 `~/.claude/rules/`에 붙였다 떼는 구조. 첫 후보가 생기면(관찰·auto memory에서 반복된 것) 폴더와 설치 명령 추가
- [ ] <a id="c-43"></a>C-43 월 점검(C-21)에 추가: `bash tools/check-install.sh` 실행 → DIFF는 base 반영/재설치 결정, `settings.local.json`에 2개 저장소 이상 반복된 권한은 `base/settings.example.json` 승격, `config-changelog.md`는 `drafts/observations/`로 복사
- [ ] <a id="c-31"></a>C-31 Dependabot 알림 켜기 — AI·OpenClaw·Script·Etc 저장소 Settings → Security → Dependabot alerts. 무료, 사용자가 클릭(외부 서비스 설정 변경이라 Claude가 대신 켜지 않음)
- [ ] <a id="c-32"></a>C-32 GitHub 2FA 켜져 있는지 확인 — Settings → Password and authentication
- [ ] <a id="c-18"></a>C-18 GitHub 활용 결정 — README "GitHub 활용" 표의 "결정 필요" 2건: (1) Claude Code on the web으로 PR 만들기(Codex 클라우드 PR 방식 대체), (2) `@claude` GitHub Actions 설치 여부. 둘 다 PR 단위 작업 습관이 전제
- [ ] <a id="c-19"></a>C-19 블로그용 스킬 — 원본은 OpenClaw `core/definitions/modes/blog.md`·`core/playbooks/blog-*.md`(참조만). OpenClaw 원칙 "Claude Code가 블로그를 직접 쓰지 않는다"와 충돌하므로, 스킬화 전에 **역할 구분을 먼저 정리**(초안은 누가, 검수는 누가)
- [ ] <a id="c-20"></a>C-20 사업기획용 스킬 — 요구사항 미정. 먼저 "어떤 산출물(시장 조사·경쟁 분석·사업계획서 초안 중 무엇)을 어떤 형식으로" 구체화 대화
- [ ] <a id="c-21"></a>C-21 정기 점검 루틴 정의 — 월 1회: `claude --version` 업데이트 확인, 스킬 3시나리오 재시험, 메모리(`~/.claude/projects/*/memory`) 정리, README 검토표 갱신. 항목이 정해지면 HANDOFF에 "마지막 점검일"을 두고 세션 시작 시 제안만 받음
- [ ] <a id="c-25"></a>C-25 `/insights` 실행 — 대화형 세션에서 `/insights`를 치면 최근 30일 로컬 세션을 분석해 마찰 지점과 CLAUDE.md 제안을 HTML로 보여줌(외부 전송 없음). Windows는 kolo_pwa 3세션뿐이라 결과가 얕을 수 있음. **Mac mini에서 실행**해야 OpenClaw 기록까지 반영됨. 결과에서 쓸 만한 제안은 `drafts/claude-md/`로
- [ ] <a id="c-26"></a>C-26 claude.ai 메모리 검토 — Settings → Memory에서 Claude가 추론해 둔 "나에 대한 요약"을 읽고 틀린 것 삭제·빠진 것 추가. 전역 지침으로 옮길 가치가 있는 항목은 `drafts/claude-md/`에 후보로. 웹 대화 원문이 필요하면 Settings → Privacy → Export data
- [ ] <a id="c-27"></a>C-27 auto memory 수집 — 월 점검 때 각 기기의 `~/.claude/projects/*/memory/*.md`를 `drafts/observations/memory-<기기>/`로 복사(검토 P5). kolo_pwa auto memory에서 전역 성향 추출 — `~/.claude/projects/c--Git-kolo-pwa/memory/` 23개 중 프로젝트 무관 항목(중간 보고 금지, 질문마다 명시 답변, 권한 상향 제안 금지, 스킬 프롬프트도 한국어, 완료 기준=실제 테스트+문서+CI 확인)이 `base/claude-md/CLAUDE.md`에 이미 있는지 대조하고, 없는 것만 후보로. Mac mini의 `~/.claude/projects/*/memory/`도 같은 방법으로
- [ ] <a id="c-22"></a>C-22 사용량·비용 확인 습관 — 상태줄 `$`와 claude.ai 사용량 페이지. 시험 세션 4회에 약 2달러였음. 한 달 뒤 실제 사용량을 보고 모델/effort 기본값 재검토

## 4. 결정 사항 (다시 묻지 말 것)

HANDOFF.md "결정 사항" 절이 원본. 여기서는 중복하지 않는다.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인 — README 검토표 "보류" 참고
- GitHub 이슈를 백로그로 쓰기 — 커뮤니티 관례지만 사용자 저장소는 `docs/PROGRESS.md` + `P-NN`이 확정. 바꾸지 않음
- Code Review(관리형 PR 자동 리뷰) — Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
