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

---

## 0. 자산 현황 — 단계와 배포 상태

모든 자산(지침·스킬·훅·설정)은 아래 네 단계 중 하나에 있다. 단계는 **앞으로만** 간다. 뒤로 가야 하면(기본에서 문제 발견) 기본 영역은 그대로 두고 수정안을 `drafts/`에 만들어 다시 검증한다.

| 단계 | 뜻 | 있는 곳 |
| --- | --- | --- |
| 계획 | 하기로 했지만 파일이 없음 | 이 보드의 `C-NN` 항목만 |
| 초안 | 파일은 있지만 시험 전 | `drafts/` |
| 검증 | 시험 진행 중, 결과가 이 보드에 기록됨 | `drafts/` (시험 기록은 §1~§3 항목에) |
| 기본 | 시험 통과 + 사용자 반영 요청 → 승격 커밋 | `claude-md/`, `skills/<이름>/`, `scripts/`, `vscode/` |

"기본"이 되면 끝이 아니라 **배포**(어느 표면에 실제로 설치됐는가)와 **관리**(C-21 정기 점검 대상)가 따라온다. 배포 열은 표면별로 `✓` 설치됨 / `✗` 미설치 / `-` 해당 없음 / `?` 확인 필요.

| 자산 | 단계 | Windows | Mac mini | Linux | 웹(Claude.ai) | 다음 행동 |
| --- | --- | --- | --- | --- | --- | --- |
| 전역 지침 `claude-md/CLAUDE.md` | 기본 | ✓ v0.1.0 | ? (기존 파일 확인 필요) | ✗ | ✗ (Project instructions) | C-15/16/17 |
| dev-release 스킬 | 기본 (3시나리오 통과 2026-09-08) | ✓ v0.1.0 | ✗ | ✗ | ✗ (Release v0.1.0의 `dev-release.zip` 업로드) | C-15/16/17 |
| git-guardrails 훅 | 기본 | ✓ (새 세션 확인은 C-10) | ✗ | ✗ | - | C-10, C-15/16 |
| statusline 훅 | 기본 | ✓ (새 세션 확인은 C-10) | ✗ | ✗ | - | C-10, C-15/16 |
| `settings.example.json` (권한·훅·상태줄) | 기본 | ✓ (allow 보완은 C-11) | ✗ | ✗ | - | C-11, C-15/16 |
| `vscode/` 확장 목록·설정·설치 스크립트 | 기본 | ✓ | ✗ (Settings Sync가 주) | - | - | C-15 |
| baseline-guard 훅 (이 저장소 전용, `.claude/`) | 검증 (수동 15케이스 통과, 실제 세션 확인 전) | 저장소 안에서만 동작 | 동일 | 동일 | - | 새 세션에서 기본 영역 편집 시도해 프롬프트 확인 → 기본 |
| 개발용 스킬 (파일 관리·테스트 정의) | 계획 | | | | | C-13 |
| 블로그용 스킬 | 계획 (역할 구분 선행) | | | | | C-19 |
| 사업기획용 스킬 | 계획 (요구사항 미정) | | | | | C-20 |
| 이 저장소 CI (lint.yml + check-docs.sh) | 검증 (로컬 통과, 첫 Actions 실행 확인 전) | 저장소 안에서만 | 동일 | 동일 | - | push 후 `gh run list` 확인 → 기본 |
| 성향 데이터 → 전역 지침 후보 | 초안 (`drafts/observations/`, `drafts/claude-md/`) | | | | | C-25/26/27/36/37 |
| GitHub 활용 (web·`@claude` Actions) | 결정 대기 | | | | | C-18 |

## 1. 완료

- [x] C-01 전역 지침 `claude-md/CLAUDE.md` 작성, Windows `~/.claude/CLAUDE.md`에 설치 (2026-09-08)
- [x] C-02 dev-release 스킬 + references 3개 (2026-09-08)
- [x] C-03 git-guardrails·statusline 훅, `settings.example.json`(권한 allow/deny·훅·상태줄), Windows 설치 (2026-09-08)
- [x] C-04 VS Code 확장 선별 13개 + `vscode/` 부트스트랩 스크립트 (2026-09-08)
- [x] C-05 Windows에 Claude Code CLI 네이티브 설치 (2026-09-08)
- [x] C-06 공식 문서·커뮤니티 대비 검토표(README) (2026-09-08)
- [x] C-07 dev-release 발동 테스트 3시나리오 — `claude -p` 새 세션으로 시험, C 시나리오 실패분 SKILL.md 수정 후 재통과 (2026-09-08)
- [x] C-08 GitHub 활용 현황 조사 + 선택지 정리(README "GitHub 활용") (2026-09-08)
- [x] C-23 기본 영역/작업 영역 분리 — 저장소 `CLAUDE.md`, `drafts/`, `.claude/hooks/baseline-guard.sh`(기본 영역 쓰기 확인 강제) (2026-09-08)
- [x] C-28 버전·릴리즈 규칙 + 첫 컷 — `docs/versioning.md`·`CHANGELOG.md` 신설, `v0.1.0` 태그·push·GitHub Release(`dev-release.zip` 첨부) 완료 (2026-09-08)
- [x] C-12 이 저장소 CI — `.github/workflows/lint.yml`(markdownlint·shellcheck·문서 상한), `.github/dependabot.yml`. 로컬에서 세 검사 통과, 첫 Actions 실행 결과는 push 후 확인 (2026-09-08)
- [x] C-33 README 입구화 + 문서 규칙 — 230줄 README를 111줄로, 설치·검토표·GitHub은 `docs/`로 분리. 문서별 줄 수 상한을 CLAUDE.md에 정하고 `check-docs.sh`로 CI 검사 (2026-09-08)
- [x] C-30 GitHub 기능 전체 대비 사용 수준 검토 — `docs/github.md` 표. 결론: 전부 쓸 필요 없음, 현재가 1인 권장 수준 (2026-09-08)
 — README "GitHub 기능 전체 대비 사용 수준" 표. 결론: 전부 쓸 필요 없음, 현재가 1인 권장 수준 (2026-09-08)
- [x] C-24 사용자 성향 데이터 활용 방안 조사 — 로컬 세션 기록·auto memory·claude.ai 메모리·`/insights` 검토, 결론은 C-25~C-27 (2026-09-08)

## 2. 할 일 — 개발·설정

- [ ] C-09 미커밋 변경 커밋 — `skills/dev-release/SKILL.md`, `docs/PROGRESS.md`, `docs/HANDOFF.md`, README
- [ ] C-10 새 세션에서 상태줄·훅 실제 동작 확인 — `git push` 시도 시 확인 프롬프트, 하단 `[모델] 폴더 (브랜치) | ▓░ % | $`
- [ ] C-11 `permissions.allow` 보완 — C-07 시험에서 `python -m py_compile`이 막혔고, `cd X && ls`는 `Read(./.env)` deny 규칙과 겹쳐 승인 프롬프트가 뜸. 자주 쓰는 검사 명령을 allow에 추가하고 예시 파일에도 반영
- [ ] C-13 개발용 스킬(파일 관리, 테스트 방법 정의) — 참고 원본 kolo_pwa `docs/testing.md`(참조만). `skills/_template` 구조, 3시나리오 시험 후 완료
- [ ] C-29 `scripts/pack.sh`가 Windows Git Bash에서 실패 — `zip: command not found`(v0.1.0 컷 중 발견). 기본 영역 수정이므로 초안을 `drafts/scripts/pack.sh`에: `zip`이 없으면 `python -c zipfile`로 폴백(제외 규칙 동일). 이번 zip은 같은 규칙의 python 명령으로 임시 생성
- [ ] C-14 Notification 훅 — 병렬 세션(`claude --bg`, worktree)을 실제로 쓰기 시작하면 추가. 그전엔 보류

## 3. 할 일 — 배포·운영·비개발

- [ ] C-15 Mac mini 반영 — `scripts/hooks/*.sh` 복사, `settings.example.json`의 `permissions`/`hooks`/`statusLine` 합치기. 기존 `~/.claude/CLAUDE.md` 내용 확인 후 덮어쓰기. 사용자가 직접 진행
- [ ] C-16 Linux(Rocky) 반영 — C-15와 동일 절차. jq 없어도 상태줄은 python/node 폴백
- [ ] C-17 Claude.ai 웹 업로드 — `bash scripts/pack.sh` → Customize → Skills 업로드, Project instructions에 `claude-md/CLAUDE.md` 붙여넣기. 이후 CLAUDE.md를 고칠 때마다 다시 붙여넣어야 함(README "규칙을 고칠 때")
- [ ] C-34 GitHub Issues 사용 결정 — Issues는 **무료**(비공개 포함). 제안: 이 저장소에서 한 달 시험 — "작업 중 발견한 문제"(C-29 같은 것)만 Issue로, 계획·상태는 PROGRESS 유지, PROGRESS 항목에 `#N` 링크. 효과 있으면 다른 저장소로. `gh issue list/view`를 permissions.allow에 추가(C-11과 함께)
- [ ] C-35 저장소 표준 적용 — `docs/repo-standard.md` 체크리스트를 Script·Etc에 맞추고(다음에 열 때), 표준을 자동으로 맞춰 주는 `repo-setup` 스킬을 초안으로(계획). 전역 지침에 "세션당 한 번 제안" 줄 추가는 C-37에 포함
- [ ] C-36 세션 관찰 기록 — 세션 끝에 `drafts/observations/YYYY-MM-DD.md`에 요청·대화·작업 방식 관찰을 적고, 월 1회(C-21) 반복되는 것만 `drafts/claude-md/` 후보로. 첫 기록 2026-09-08 작성됨. 다른 저장소는 auto memory(`feedback_*`)가 같은 역할
- [ ] C-37 **전역 지침 수정안 결정** — `drafts/claude-md/CLAUDE.md`에 4가지: (1) 로컬 커밋은 묻지 않음, (2) 배치 = 메시지 하나, "진행해줘"면 끝까지 재확인 없음, (3) 저장소 표준 미달 세션당 한 번 제안, (4) §7 커밋 규칙 문구. 승인 시 기본 영역 승격 → 확인 기준이 바뀌므로 등급은 MAJOR 성격이나 v1.0.0 전이라 `v0.2.0`
- [ ] C-31 Dependabot 알림 켜기 — AI·OpenClaw·Script·Etc 저장소 Settings → Security → Dependabot alerts. 무료, 사용자가 클릭(외부 서비스 설정 변경이라 Claude가 대신 켜지 않음)
- [ ] C-32 GitHub 2FA 켜져 있는지 확인 — Settings → Password and authentication
- [ ] C-18 GitHub 활용 결정 — README "GitHub 활용" 표의 "결정 필요" 2건: (1) Claude Code on the web으로 PR 만들기(Codex 클라우드 PR 방식 대체), (2) `@claude` GitHub Actions 설치 여부. 둘 다 PR 단위 작업 습관이 전제
- [ ] C-19 블로그용 스킬 — 원본은 OpenClaw `core/definitions/modes/blog.md`·`core/playbooks/blog-*.md`(참조만). OpenClaw 원칙 "Claude Code가 블로그를 직접 쓰지 않는다"와 충돌하므로, 스킬화 전에 **역할 구분을 먼저 정리**(초안은 누가, 검수는 누가)
- [ ] C-20 사업기획용 스킬 — 요구사항 미정. 먼저 "어떤 산출물(시장 조사·경쟁 분석·사업계획서 초안 중 무엇)을 어떤 형식으로" 구체화 대화
- [ ] C-21 정기 점검 루틴 정의 — 월 1회: `claude --version` 업데이트 확인, 스킬 3시나리오 재시험, 메모리(`~/.claude/projects/*/memory`) 정리, README 검토표 갱신. 항목이 정해지면 HANDOFF에 "마지막 점검일"을 두고 세션 시작 시 제안만 받음
- [ ] C-25 `/insights` 실행 — 대화형 세션에서 `/insights`를 치면 최근 30일 로컬 세션을 분석해 마찰 지점과 CLAUDE.md 제안을 HTML로 보여줌(외부 전송 없음). Windows는 kolo_pwa 3세션뿐이라 결과가 얕을 수 있음. **Mac mini에서 실행**해야 OpenClaw 기록까지 반영됨. 결과에서 쓸 만한 제안은 `drafts/claude-md/`로
- [ ] C-26 claude.ai 메모리 검토 — Settings → Memory에서 Claude가 추론해 둔 "나에 대한 요약"을 읽고 틀린 것 삭제·빠진 것 추가. 전역 지침으로 옮길 가치가 있는 항목은 `drafts/claude-md/`에 후보로. 웹 대화 원문이 필요하면 Settings → Privacy → Export data
- [ ] C-27 kolo_pwa auto memory에서 전역 성향 추출 — `~/.claude/projects/c--Git-kolo-pwa/memory/` 23개 중 프로젝트 무관 항목(중간 보고 금지, 질문마다 명시 답변, 권한 상향 제안 금지, 스킬 프롬프트도 한국어, 완료 기준=실제 테스트+문서+CI 확인)이 `claude-md/CLAUDE.md`에 이미 있는지 대조하고, 없는 것만 후보로. Mac mini의 `~/.claude/projects/*/memory/`도 같은 방법으로
- [ ] C-22 사용량·비용 확인 습관 — 상태줄 `$`와 claude.ai 사용량 페이지. 시험 세션 4회에 약 2달러였음. 한 달 뒤 실제 사용량을 보고 모델/effort 기본값 재검토

## 4. 결정 사항 (다시 묻지 말 것)

HANDOFF.md "결정 사항" 절이 원본. 여기서는 중복하지 않는다.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인 — README 검토표 "보류" 참고
- GitHub 이슈를 백로그로 쓰기 — 커뮤니티 관례지만 사용자 저장소는 `docs/PROGRESS.md` + `P-NN`이 확정. 바꾸지 않음
- Code Review(관리형 PR 자동 리뷰) — Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
