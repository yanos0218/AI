---
name: project-claude-config-roadmap
description: "claude-config(AI) 저장소의 목적, 배포 표면별 방식, VS Code 동기화 결정, 앞으로 추가할 스킬 계획"
metadata: 
  node_type: memory
  type: project
  originSessionId: d1d3662c-8db2-4c7f-b8d9-f1dd657ec8b2
  modified: 2026-09-08T12:35:38.582Z
---

이 저장소(github.com/yanos0218/AI, **비공개**)는 사용자의 개인용 Claude 설정 원본이다. 저장소를 가리지 않는 스킬(skills/), 전역 지침(claude-md/CLAUDE.md), 훅(scripts/hooks/), VS Code 부트스트랩(vscode/)만 둔다. 저장소 전용 규칙은 각 저장소 CLAUDE.md/.claude/skills에 있고 여기서는 참조만 한다([[feedback-reference-not-copy]]).

**Why:** 웹은 zip 업로드로만 스킬을 받고 CLAUDE.md·훅을 지원하지 않으며, Cowork는 `~/.claude/skills/`를 읽지 않는다. 하나의 원본에서 (1) `~/.claude` 복사(CLI·VS Code 확장), (2) pack.sh zip → 웹 업로드 두 갈래로 배포한다. Claude Design은 스킬·지침 모두 없음(디자인 시스템 첨부로 대체).

**결정 (2026-09-08):**
- git-guardrails 훅을 `~/.claude/settings.json`에 설치함(Windows). push·reset --hard·clean -f·--no-verify·npm publish 등은 auto 모드에서도 확인 프롬프트. Mac은 사용자가 별도 반영.
- VS Code 동기화는 내장 Settings Sync(GitHub 계정)를 주 수단으로, `vscode/`는 새 기기 부트스트랩·백업용. `extensions.txt`에서 openai.chatgpt와 실험 확장은 의도적으로 제외.
- `~/.claude/settings.json`에 `$schema` 추가.
- Windows에 Claude Code CLI 네이티브 설치(`~/.local/bin/claude.exe`, 사용자 PATH 추가). CLI와 VS Code 확장은 `~/.claude`를 공유하므로 설정은 한 번만.
- `~/.claude/settings.json`에 상태줄(`hooks/statusline.sh`, 컨텍스트 %·비용), `permissions.allow`(읽기 전용 git/gh/ls/테스트)·`deny`(.env, secrets, ~/.ssh) 추가. 원본은 `scripts/settings.example.json`. CLI는 Windows·Mac·Linux 모두 사용.
- 공식 문서 대비 검토표를 README에 둠. 보류: LSP 플러그인, 에이전트 팀, 샌드박스(Windows 미지원), Notification 훅(병렬 세션 시작하면 추가).
- VS Code 확장은 "실제 저장소 스택 + CI가 돌리는 도구"만 선별(13개, Error Lens 추가). Prettier/ESLint/GitLens는 저장소에 설정 파일이 생길 때까지 보류. 제거 대상 uninstall은 사용자가 직접(Settings Sync로 Mac에 전파되므로 swift 등 주의).

**계획 중인 다음 스킬** (원본은 저장소 `docs/PROGRESS.md` C-13/C-19/C-20, 여기는 요약):
- 개발용: 파일 관리, 테스트 방법 정의 — kolo_pwa `docs/testing.md`가 참고 원본(복사 금지, 참조만)
- 블로그용: OpenClaw `core/definitions/modes/blog.md`·`core/playbooks/blog-*.md`에 문체·포맷이 확정돼 있음. OpenClaw에서는 "Claude Code가 블로그를 직접 쓰지 않는다"가 원칙이라 전역 스킬화 전에 역할 구분을 사용자와 정리해야 함
- 사업기획용: 요구사항 미정

**How to apply:** 새 스킬은 skills/_template 구조로, 3가지 시나리오 시험 후 완료. 완료하면 이 메모리에서 항목을 지운다. 미해결: Mac mini `~/.claude/CLAUDE.md`·훅 반영은 사용자가 직접 진행하기로 함.
