# GitHub Issues 사용 범위 — "문제만" vs "task 포함"

[Issue #11](https://github.com/yanos0218/AI/issues/11) 검토에 쓴 조사. 채택 확정, 2026-09-12에 전면 실행 완료.

## 확인한 사실 (직접 실행)

- 이 저장소(`yanos0218/AI`, 개인 계정 저장소)에서 Issue Types API는 404 — 개인 계정 저장소에는 없음(2026-09-12, `gh api repos/yanos0218/AI/issues/types`).
- `gh issue create --type`은 CLI에 있지만 조직 계정 저장소 전용 기능이라 이 저장소엔 못 쓴다.
- Projects(칸반)는 현재 토큰에 `read:project` 스코프가 없어 바로 못 씀(`gh auth refresh -s read:project` 필요).

## 공식 문서

- [About issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues) — Issues는 "버그, 기능, 아이디어, 팀과 논의할 모든 것"을 추적하는 용도로 정의. bug 전용이 아니라 처음부터 범용.
- [Managing issue types in an organization](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-types-in-an-organization) — Issue Types(Bug/Feature/Task 분류)는 **조직 계정 전용**, 개인 계정엔 없음. 위 404로 확인.
- [Evolving GitHub Issues and Projects (GA)](https://github.com/orgs/community/discussions/154148) (2025-03-17 GA) — GitHub이 sub-issues·issue types·고급 검색을 정식 출시하며 Issues+Projects를 팀의 일반 작업 관리 도구로 밀고 있음. 개발자 반응: sub-issue 계층이 저장소 목록에서 잘 안 보이고, 여러 상위 이슈에 속하는 다중 부모가 안 되고, Projects 테이블에서 고급 검색이 안 먹힘 — "계층 구조는 아직 기본적" 이라는 평가가 많음.
- [Tips & tricks for using GitHub Projects for personal productivity](https://github.blog/developer-skills/github/tips-tricks-for-using-github-projects-for-personal-productivity/) (2022-07-21, GitHub 공식 블로그) — 개인 사용자에게 버그·작업을 구분하지 않고 하나의 목록으로 관리하라고 권장. **1년 넘은 글, 방향은 최근 공식 발표(위 GA)와 일치해 확인 필요 표시 안 함.**

## 커뮤니티

- [dev.to, azu, "Use GitHub issues for personal task manager"](https://dev.to/azu/use-github-issues-for-personal-task-manager-jig) (2021-01-09) — **1년 이상 지남, 확인 필요.** 다른 할 일 도구와 이중 관리가 번거로워 Issues 하나로 통일, 라벨·마일스톤·Projects만으로 충분했다는 결론. 최근 공식 방향과 결이 같아 참고용으로만 인용.
- [GitHub Issues vs Jira](https://nira.com/github-issues-vs-jira/), [Jira vs GitHub Issues](https://dev.to/ranjalir/jira-vs-github-issues-which-is-better-for-issue-tracking-e6) 등 비교글 — 1인·소규모 팀엔 GitHub Issues가 코드와 붙어 있어 충분하다는 평가가 공통적. 다만 "여러 단계로 나뉜 복잡한 작업 분해는 아직 Jira가 낫다"는 평가도 공통적 — sub-issue 기능이 기본적이라는 공식 커뮤니티 반응과 일치.

## 이 저장소에 적용할 때 남는 문제 (조사로도 안 풀리는 것)

커뮤니티·공식 모두 "Issues를 task까지 넓혀 써도 된다"는 쪽이지만, 이 저장소의 특수한 제약(세션 시작 시 로컬 문서만 읽기, 4단계 파이프라인·기기별 배포 매트릭스, git 커밋과 결합된 이력)은 일반적인 개인 작업 관리 사례엔 없는 조건이라 조사로 답이 안 나온다. 이 부분은 채팅 답변(2026-09-12)에서 별도로 분석.
