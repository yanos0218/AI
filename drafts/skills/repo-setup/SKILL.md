---
name: repo-setup
description: "GitHub 저장소가 최소 표준(문서 CI, 테스트 CI, CHANGELOG, 저장소 CLAUDE.md, Issues, 진행 보드, Dependabot, 비밀 차단, Actions 한도 방지)을 갖췄는지 대조하고, 빠진 것을 제안표로 보인 뒤 사용자가 고른 것만 만든다. 사용자가 '저장소 표준 맞춰줘', '이 저장소 기본 세팅 해줘', '뭐가 빠졌는지 봐줘', '새 저장소 만들었는데 뭘 넣어야 해?', 'CI 붙여줘'라고 하면 사용한다. 테스트 방법 자체를 정하는 것은 dev-workflow, 릴리즈는 dev-release가 담당한다."
allowed-tools: Bash(git status*) Bash(git log*) Bash(git ls-files*) Bash(gh repo view*) Bash(gh api repos/*) Bash(ls*)
---

# repo-setup

저장소마다 "있어야 하는 최소한"을 같은 기준으로 맞춘다. 기준 원본은 claude-config `docs/repo-standard.md`이며, `references/checklist.md`가 그 사본이 아니라 **판정 방법**이다.

## 0. 시작 전 확인 (필수)

- 저장소 `CLAUDE.md`·`CONTRIBUTING.md`·`docs/`에 자체 표준이 있으면 그쪽이 우선한다. 이 스킬은 빠진 칸만 채운다.
- `git ls-files`, `.github/`, `CHANGELOG.md`, `CLAUDE.md`, 진행 보드 파일, `.gitignore`를 본다. 원격이 있으면 `gh repo view`로 공개 여부·기본 브랜치, `gh api repos/<owner>/<repo>/vulnerability-alerts`로 Dependabot 알림 여부.
- **비밀 파일이 이력에 있는지** `git log --all --diff-filter=A --name-only -- '*.key' '*.pem' '.env*' 'id_rsa*'`로 확인한다. 있으면 다른 어떤 항목보다 먼저 사용자에게 알린다(재발급 + 이력 정리는 사용자 결정).

발견한 것을 한 줄로 알린 뒤 진행한다.

## 1. 절차

```text
저장소 표준 대조
- [ ] 1. §0 확인 결과 한 줄 (스택, 원격, 비밀 이력 여부)
- [ ] 2. references/checklist.md 9항목을 ✓/✗/-(해당 없음)로 판정한 표
- [ ] 3. ✗마다 제안: 무엇을 만들지, 최소 형태, 왜. 스택에 맞는 검사 명령은 dev-workflow의 references/testing-guide.md 표를 따른다
- [ ] 4. ★ 사용자 확인 ★ — 만들 항목을 고르게 한다. 고르지 않은 것은 만들지 않는다
- [ ] 5. 고른 것만 생성 → 로컬에서 검사 실행(markdownlint, shellcheck 등) → 커밋. push는 확인 후
- [ ] 6. 결과 보고 — 만든 파일, 실행한 검사와 출력, 남긴 ✗
```

## 2. 참고 자료

- `references/checklist.md` — 9항목의 판정 기준과 최소 형태. 2번 단계에서 읽는다.

## 하지 않는 것

- 사용자가 고르지 않은 파일을 만들지 않는다. "전부 만들어줘"라고 해도 비밀 이력 처리와 Dependabot 같은 저장소 설정 변경은 따로 확인한다.
- 다른 저장소의 워크플로·문서를 그대로 복사하지 않는다. 형식만 따르고 내용은 이 저장소 것.
- 테스트 프레임워크를 도입하지 않는다. 최소 검사(문법·린트)까지만.
- 활동이 없는 저장소(마지막 커밋 6개월 이상)는 "표준을 맞출지 보관할지"를 먼저 묻는다.
