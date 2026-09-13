# GitHub 활용

Claude와 GitHub를 엮는 방법은 크게 넷이다. 아래는 **사용자 저장소 현황(2026-09-08 `gh`로 조사)**과 대조한 결과이며, 상태 표기는 위 검토표와 같다(**결정 필요**는 사용자 판단이 있어야 하는 것).

현황(2026-09-08 조사, AI 저장소는 2026-09-12에 예외로 바뀜 — 아래 표): 저장소 11개 전부 비공개, GitHub Free 플랜(브랜치 보호 불가 — Pro 필요). 이슈 0개(백로그는 각 저장소 `docs/PROGRESS.md`의 `P-NN`). PR은 kolo_pwa·kolo-api가 Dependabot뿐이고 OpenClaw만 Codex(OpenAI 클라우드 에이전트)가 만든 PR 18개 — 즉 사람이 브랜치→PR을 쓰는 습관은 없고 `main` 직접 push. Actions는 kolo_pwa(`test.yml` 경로 필터로 분 절약, `release.yml` 태그 push→Release)·OpenClaw(`lint.yml`, `release.yml`)에 있고 Release는 각각 30·42개.

| 방법 | 무엇을 해주나 | 상태 | 비고 |
| --- | --- | --- | --- |
| `gh` CLI를 Claude가 직접 사용 | PR·이슈·Actions 결과·Release 조회/생성. MCP보다 토큰이 적게 듦 | 반영 | `permissions.allow`에 `gh pr view`·`gh run list`·`gh release view` 사전 허용. dev-release가 `gh release create`·`gh run list`를 씀 |
| 태그 push → Release 자동 생성 | 릴리즈 노트 파일을 태그 전에 커밋하면 Actions가 Release를 만듦 | 반영 | kolo_pwa·OpenClaw에 이미 있음. dev-release §0이 워크플로 존재를 감지해 절차를 맞춤 |
| 이 저장소를 설정의 원본으로 | `~/.claude`를 기기마다 손으로 맞추지 않고 clone → 설치 스크립트 | 반영 | 커뮤니티 dotfiles 방식과 동일. Mac·Linux 반영은 `docs/PROGRESS.md` [Issue #28](https://github.com/yanos0218/AI/issues/28)/16 |
| **Claude Code on the web** (`claude.ai/code`) | 브라우저·폰에서 지시 → 클라우드 VM이 저장소를 clone해 작업 → PR 생성. `claude --cloud "..."`로 터미널에서 보내고 `--teleport`로 받아옴. PR의 CI 실패·리뷰 코멘트를 자동 수정(auto-fix)도 가능 | **결정 필요** | Pro/Max 가능, 별도 VM 비용 없음(플랜 한도 공유). OpenClaw에서 Codex로 하던 "클라우드가 PR 만들기"의 Claude 버전. 저장소 `CLAUDE.md`·`.claude/`는 적용되지만 `~/.claude`는 전달 안 됨 |
| **Claude Code GitHub Actions** (`@claude` 멘션) | 이슈·PR 코멘트에 `@claude ...`라고 쓰면 Actions 러너에서 Claude가 코드를 고치고 커밋·PR. `prompt`를 주면 일정(cron)·이벤트 자동 실행도 가능 | **결정 필요** | `/install-github-app`으로 5분 설치. 구독 토큰(`claude setup-token`)이면 API 과금 없이 플랜 한도 사용, 단 Actions 분은 소모(비공개 저장소 월 한도 있음). AI 저장소는 Issues를 쓰기 시작했지만(2026-09-12) PR 습관이 없어 지금은 이득이 작다 — PR 단위 작업이 자리 잡은 뒤 |
| PR 자동 리뷰 — Code Review(관리형) | PR마다 다중 에이전트가 검토해 인라인 코멘트 | 보류 | Team/Enterprise 전용, 건당 15~25달러. 개인은 로컬 `/code-review`(무료, 세션 한도) 또는 `/code-review ultra`(크레딧)로 대체 |
| 브랜치 → PR → merge 습관 | 위 두 "결정 필요" 항목의 전제. 리뷰 코멘트·auto-fix·`@claude`가 전부 PR 위에서 동작 | 습관 | kolo_pwa `CONTRIBUTING.md`가 GitHub Flow를 정해 뒀지만 1인이라 강제 안 함. 브랜치 보호는 Free 플랜에서 불가 |
| GitHub 이슈를 백로그로 | 커뮤니티는 `gh issue create`로 할 일을 만들고 `@claude`에 넘기는 흐름을 씀 | AI 저장소는 채택(2026-09-12) | 개인용 저장소는 문제(`bug`)+할 일(`task`) 통합, 진행 보드는 배포 표만. 다른 저장소는 여전히 `docs/PROGRESS.md` + `P-NN`. 기준은 `docs/repo-standard.md` 항목5 |
| 이 저장소 CI | markdownlint·shellcheck | 할 일 | `docs/PROGRESS.md` [Issue #52](https://github.com/yanos0218/AI/issues/52) |

추천 순서: PR 습관(브랜치에서 작업 → `gh pr create` → merge)을 먼저 한 저장소에서 시도하고, 그게 편하면 Claude Code on the web을 켠다. `@claude` Actions는 이슈를 쓰기 시작할 때.

## GitHub 기능 전체 대비 사용 수준 (2026-09-08)

"전부 써야 하나"에 대한 답은 **아니오**. 계정은 GitHub Free이고 저장소가 전부 비공개라 애초에 못 쓰는 기능이 있고, 1인 개발에서 커뮤니티가 공통으로 권하는 수준은 "main + 기능 브랜치, Conventional Commits, SemVer 태그, Actions로 테스트·배포, 나머지는 필요해질 때"다. 현재 사용 수준은 그 권장과 거의 일치한다.

| 기능 | 현재 | 판단 | 이유 |
| --- | --- | --- | --- |
| 저장소·커밋·push | 11개 저장소, Conventional Commits | 쓴다 | 백업·이력의 기본 |
| Releases·태그 | kolo_pwa 30, OpenClaw 42, 이 저장소 v0.1.0 | 쓴다 | 어느 기기에 어느 버전이 깔렸는지의 기준점. zip 첨부로 웹 업로드 산출물도 보관 |
| Actions | kolo_pwa test·release, OpenClaw lint·release | 쓴다 | 월 2,000분 한도. kolo_pwa처럼 경로 필터로 절약. 이 저장소는 [Issue #52](https://github.com/yanos0218/AI/issues/52) |
| Dependabot 알림 | kolo_pwa·kolo-api만 켜짐 | **켠다** | 무료, 저장소 Settings → Security 클릭 1회. AI·OpenClaw·Script·Etc는 꺼져 있음 |
| Dependabot 버전 업데이트 | kolo_pwa(actions만) | 유지 | 의존성 트리가 있는 저장소만 |
| PR | 사람이 만든 PR 없음(Codex·Dependabot뿐) | 필요할 때 | Claude 클라우드·`@claude`·리뷰 코멘트가 전부 PR 위에서 도니, 그걸 쓰기로 하면 같이 시작 |
| 이슈·마일스톤·라벨 | AI 저장소는 `task`/`bug` 라벨로 55건 관리(2026-09-12), 나머지 저장소는 이슈 0·마일스톤 0 | AI는 쓴다, 나머지는 보류 | AI는 할 일까지 Issue, `docs/PROGRESS.md`는 배포 표만. 나머지 저장소는 `P-NN` 파일 하나가 아직 더 빠름 |
| Projects(칸반) | 켜져 있으나 미사용 | 안 쓴다 | AI 저장소도 PROGRESS §0 표가 매트릭스 역할을 대신함, 토큰에 `read:project` 스코프도 없음 |
| Wiki·Discussions·Pages | 꺼짐 | 불가/불필요 | Free 비공개 저장소는 Wiki·Pages 불가. 문서는 `docs/`, 서비스는 NAS |
| 브랜치 보호·룰셋·CODEOWNERS | 없음 | **불가**(Pro 필요) | 대신 로컬 훅(`git-guardrails`)이 push 앞에서 확인. 두 번째 개발자가 오면 Pro($4/월) |
| Secret scanning·Code scanning | 없음 | 불가(Free 비공개) | 대신 `permissions.deny`로 `.env` 읽기·편집 차단, CLAUDE.md §7 |
| Codespaces | 미사용(월 120시간 무료) | 안 쓴다 | 브라우저 개발 환경은 Claude Code on the web이 같은 자리 |
| Copilot | 미사용 | 안 쓴다 | Claude가 그 역할 |
| Packages·Gists | 미사용 | 안 쓴다 | 배포 산출물이 없음 |
| Actions secrets·Environments | 0개 | 필요할 때 | `@claude` Actions를 켜면 토큰 1개가 처음 생김 |
| 2FA | 확인 불가(토큰 권한 부족) | **확인** | GitHub 필수화 대상. Settings → Password and authentication |

**효과가 나는 최소 수준**: (1) 커밋·push, (2) 태그·Release, (3) Actions로 테스트 — 이 셋은 이미 하고 있다. 그다음 한 단계는 PR인데, 이건 GitHub 자체 때문이 아니라 Claude 자동화(위 표의 "결정 필요" 2건)를 쓸 때 비로소 값어치가 생긴다.

## Claude Code on the web 켜기 (C-18 채택, 2026-09-09)

결정: `@claude` Actions는 보류하고, **Claude Code on the web**을 OpenClaw에서 먼저 쓴다. OpenClaw가 Codex 클라우드 PR을 쓰던 자리라 PR 흐름이 이미 있고, Actions 분을 쓰지 않으며, 폰에서 지시하고 PR의 CI 실패·리뷰 코멘트를 자동 수정(auto-fix)할 수 있다.

| 순서 | 무엇 | 누가 |
| --- | --- | --- |
| 1 | 터미널에서 `claude`를 열고 `/web-setup` 입력 — 로컬 `gh` 토큰을 claude.ai 계정에 연결하고 Default 환경을 만든다. `gh auth refresh -s workflow`를 먼저 해 두면 워크플로 파일 push도 됨. 브라우저로 하려면 claude.ai/code → Sign in with GitHub | 사용자 (대화형 명령이라 Claude가 대신 못 함) |
| 2 | auto-fix를 쓰려면 Claude GitHub App을 OpenClaw에 설치(claude.ai/code 온보딩에서 안내, 또는 github.com/apps/claude) | 사용자 |
| 3 | OpenClaw에 루트 `CLAUDE.md` 추가 — 클라우드 VM은 저장소의 CLAUDE.md만 읽고 `~/.claude`는 못 읽으므로, 확인 기준과 검사 명령을 저장소 안에 둔다. 초안은 브랜치 `chore/claude-md`(스크래치패드 클론), push·PR은 확인 후 | Claude(초안) → 사용자(승인) |
| 4 | 첫 작업: claude.ai/code에서 OpenClaw 선택 → Plan 모드로 작은 문서 작업 하나 → diff 확인 → Create PR → merge. 터미널에서는 `claude --cloud "작업 설명"`(현재 폴더가 OpenClaw 클론일 때) | 사용자 |
| 5 | 한 달 뒤 판단: PR 리뷰 부담, 세션 한도 소모, Codex 대비 품질 | 월 점검 |

주의: 클라우드 세션은 플랜 한도를 공유하고, 병렬 세션은 그만큼 더 쓴다. `--teleport`로 로컬에 가져오면 이후 작업은 로컬 문맥이다.

## Actions 제한과 방지

비공개 저장소는 한도가 있다(GitHub Free, 2026-09 기준). 초과하면 워크플로가 **실행되지 않고 실패**하고, 분은 월초에 리셋된다.

| 한도 | 값 | 초과하면 |
| --- | --- | --- |
| 월 실행 분 | 2,000분 (계정 전체 합산, Linux 기준. Windows 2배·macOS 10배 과금) | 그 달 남은 워크플로 전부 실패 |
| 아티팩트·패키지 저장 | 500MB | 업로드 실패 |
| 캐시 | 저장소당 10GB | 오래된 것부터 삭제 |
| job 실행 시간 | 6시간 | 강제 취소 |
| 동시 job | 20개 | 대기 |
| API(`GITHUB_TOKEN`) | 시간당 1,000회/저장소 | 403, 폴링 루프가 주범 |

방지 장치와 어디에 적용돼 있는지:

| 장치 | 효과 | 적용 |
| --- | --- | --- |
| 경로 필터 / docs-only 감지 | 문서만 바뀐 push에 무거운 테스트를 돌리지 않음 | kolo_pwa `test.yml` `detect-changes` 잡(Playwright 5~6분 절약) |
| `concurrency` + `cancel-in-progress` | 같은 브랜치에 연속 push 시 이전 실행 취소 | kolo_pwa, 이 저장소 |
| `push: branches: [main]` + `pull_request` | 브랜치 push와 PR이 같은 커밋을 두 번 돌리지 않음 | 이 저장소 |
| `timeout-minutes` (잡마다) | 멈춘 잡이 6시간짜리 청구가 되는 것을 막음 | kolo_pwa 5·15분, 이 저장소 5분 |
| 매트릭스 대신 순차 스텝 | VM 부팅 오버헤드 중복 방지 | kolo_pwa 브라우저 엔진 2종을 한 잡에서 |
| 아티팩트 안 올림, 캐시 최소 | 500MB 한도 | kolo 저장소 규칙(auto memory에 기록됨) |
| 폴링은 스크립트로, 15초 간격 | `gh run view` 타이트 루프가 API 한도를 소진하는 문제(Claude Code 알려진 버그) | kolo_pwa `scripts/wait-for-ci.sh`. 다른 저장소에서는 `gh run watch` |
| 월 사용량 확인 | 한도 근접을 미리 봄 | Settings → Billing and plans → Usage. `gh api users/<id>/settings/billing/actions`는 `user` 스코프 필요 |

현재 kolo_pwa·kolo-api가 최근 30일에 각각 100회 이상 실행됐다(`gh run list` 상한). 분 단위 실제 사용량은 Billing 페이지에서 봐야 한다([Issue #33](https://github.com/yanos0218/AI/issues/33)).

## 참고한 자료

- [GitHub Actions 사용 제한 공식](https://docs.github.com/en/actions/reference/limits)
- [Claude Code 공식 — GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [Claude Code 공식 — Code Review](https://code.claude.com/docs/en/code-review)
- [Claude Code 공식 — Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [GitHub 플랜 비교 공식](https://docs.github.com/en/get-started/learning-about-github/githubs-plans)
- [Rulesets Free 비공개 저장소 불가 — community](https://github.com/orgs/community/discussions/190190)
- [The Git Workflow That Actually Works for Solo Developers (2026)](https://dev.to/armorbreak/the-git-workflow-that-actually-works-for-solo-developers-2026-2mna)
- [Popit — GitHub로 프로젝트 관리하기](https://www.popit.kr/github%EB%A1%9C-%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8-%EA%B4%80%EB%A6%AC%ED%95%98%EA%B8%B0-part1-%EC%9D%B4%EC%8A%88-%EB%B0%9C%EA%B8%89-%EB%B6%80%ED%84%B0-%EC%BD%94%EB%93%9C%EB%A6%AC%EB%B7%B0%EA%B9%8C/)
- [Dale Seo — Claude Code GitHub Actions 사용법](https://daleseo.com/claude-code-action/)
- [Hyperithm — Claude Code 심화 활용법](https://tech.hyperithm.com/claude_code_guides_2)
- [doug-skinner/github-cli-claude-skill](https://github.com/doug-skinner/github-cli-claude-skill)
- [Dale Seo — CLAUDE.md 작성 가이드](https://daleseo.com/claude-code-claude-md/)
- [GeekNews — Claude Code로 좋은 결과 얻기](https://news.hada.io/topic?id=22425)
