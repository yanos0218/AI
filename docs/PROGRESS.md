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

## 1. 완료

- [x] C-01 전역 지침 `claude-md/CLAUDE.md` 작성, Windows `~/.claude/CLAUDE.md`에 설치 (2026-09-08)
- [x] C-02 dev-release 스킬 + references 3개 (2026-09-08)
- [x] C-03 git-guardrails·statusline 훅, `settings.example.json`(권한 allow/deny·훅·상태줄), Windows 설치 (2026-09-08)
- [x] C-04 VS Code 확장 선별 13개 + `vscode/` 부트스트랩 스크립트 (2026-09-08)
- [x] C-05 Windows에 Claude Code CLI 네이티브 설치 (2026-09-08)
- [x] C-06 공식 문서·커뮤니티 대비 검토표(README) (2026-09-08)
- [x] C-07 dev-release 발동 테스트 3시나리오 — `claude -p` 새 세션으로 시험, C 시나리오 실패분 SKILL.md 수정 후 재통과 (2026-09-08)
- [x] C-08 GitHub 활용 현황 조사 + 선택지 정리(README "GitHub 활용") (2026-09-08)

## 2. 할 일 — 개발·설정

- [ ] C-09 미커밋 변경 커밋 — `skills/dev-release/SKILL.md`, `docs/PROGRESS.md`, `docs/HANDOFF.md`, README
- [ ] C-10 새 세션에서 상태줄·훅 실제 동작 확인 — `git push` 시도 시 확인 프롬프트, 하단 `[모델] 폴더 (브랜치) | ▓░ % | $`
- [ ] C-11 `permissions.allow` 보완 — C-07 시험에서 `python -m py_compile`이 막혔고, `cd X && ls`는 `Read(./.env)` deny 규칙과 겹쳐 승인 프롬프트가 뜸. 자주 쓰는 검사 명령을 allow에 추가하고 예시 파일에도 반영
- [ ] C-12 이 저장소 CI — markdownlint + shellcheck를 GitHub Actions로 (kolo_pwa `test.yml`의 경로 필터 방식 참고, 복사 금지). Actions 분은 문서 변경만이라 소액
- [ ] C-13 개발용 스킬(파일 관리, 테스트 방법 정의) — 참고 원본 kolo_pwa `docs/testing.md`(참조만). `skills/_template` 구조, 3시나리오 시험 후 완료
- [ ] C-14 Notification 훅 — 병렬 세션(`claude --bg`, worktree)을 실제로 쓰기 시작하면 추가. 그전엔 보류

## 3. 할 일 — 배포·운영·비개발

- [ ] C-15 Mac mini 반영 — `scripts/hooks/*.sh` 복사, `settings.example.json`의 `permissions`/`hooks`/`statusLine` 합치기. 기존 `~/.claude/CLAUDE.md` 내용 확인 후 덮어쓰기. 사용자가 직접 진행
- [ ] C-16 Linux(Rocky) 반영 — C-15와 동일 절차. jq 없어도 상태줄은 python/node 폴백
- [ ] C-17 Claude.ai 웹 업로드 — `bash scripts/pack.sh` → Customize → Skills 업로드, Project instructions에 `claude-md/CLAUDE.md` 붙여넣기. 이후 CLAUDE.md를 고칠 때마다 다시 붙여넣어야 함(README "규칙을 고칠 때")
- [ ] C-18 GitHub 활용 결정 — README "GitHub 활용" 표의 "결정 필요" 2건: (1) Claude Code on the web으로 PR 만들기(Codex 클라우드 PR 방식 대체), (2) `@claude` GitHub Actions 설치 여부. 둘 다 PR 단위 작업 습관이 전제
- [ ] C-19 블로그용 스킬 — 원본은 OpenClaw `core/definitions/modes/blog.md`·`core/playbooks/blog-*.md`(참조만). OpenClaw 원칙 "Claude Code가 블로그를 직접 쓰지 않는다"와 충돌하므로, 스킬화 전에 **역할 구분을 먼저 정리**(초안은 누가, 검수는 누가)
- [ ] C-20 사업기획용 스킬 — 요구사항 미정. 먼저 "어떤 산출물(시장 조사·경쟁 분석·사업계획서 초안 중 무엇)을 어떤 형식으로" 구체화 대화
- [ ] C-21 정기 점검 루틴 정의 — 월 1회: `claude --version` 업데이트 확인, 스킬 3시나리오 재시험, 메모리(`~/.claude/projects/*/memory`) 정리, README 검토표 갱신. 항목이 정해지면 HANDOFF에 "마지막 점검일"을 두고 세션 시작 시 제안만 받음
- [ ] C-22 사용량·비용 확인 습관 — 상태줄 `$`와 claude.ai 사용량 페이지. 시험 세션 4회에 약 2달러였음. 한 달 뒤 실제 사용량을 보고 모델/effort 기본값 재검토

## 4. 결정 사항 (다시 묻지 말 것)

HANDOFF.md "결정 사항" 절이 원본. 여기서는 중복하지 않는다.

## 5. 보류·기각

- 에이전트 팀, 샌드박스(Windows 미지원), LSP 플러그인 — README 검토표 "보류" 참고
- GitHub 이슈를 백로그로 쓰기 — 커뮤니티 관례지만 사용자 저장소는 `docs/PROGRESS.md` + `P-NN`이 확정. 바꾸지 않음
- Code Review(관리형 PR 자동 리뷰) — Team/Enterprise 전용. 개인은 로컬 `/code-review`로 대체
