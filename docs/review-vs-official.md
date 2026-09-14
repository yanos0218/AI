# 공식 문서·커뮤니티 대비 검토표

생산성·토큰·실수 방지·병렬 작업 관점에서 공식 문서(best-practices, costs, context-window, permissions, hooks, agent-view, worktrees)와 커뮤니티 설정을 대조한 결과. **반영**은 이 저장소에 들어간 것, **습관**은 설정이 아니라 쓰는 방식, **보류**는 이유가 있어 안 넣은 것.

| 분류 | 항목 | 상태 | 비고 |
| --- | --- | --- | --- |
| 실수 방지 | 되돌리기 어려운 명령 앞 확인 강제 | 반영 | `git-guardrails.sh`<br>PreToolUse 훅은 모든 권한 모드에서 먼저 실행됨 |
| 실수 방지 | 비밀 파일 읽기/편집 거부 | 반영 | `permissions.deny`: `.env`, `secrets/`, `~/.ssh` |
| 실수 방지 | 검증 없이 "됐다" 금지 | 반영 | CLAUDE.md §4. 공식: "Claude에게 돌릴 수 있는 검사를 주고 증거를 보이게 하라" |
| 실수 방지 | 계획 먼저(plan mode) | 습관 | 여러 파일 건드리거나 방향이 불확실하면 Shift+Tab. 한 문장으로 diff를 설명할 수 있으면 생략 |
| 실수 방지 | 같은 지적 두 번이면 `/clear` 후 더 나은 프롬프트로 | 습관 | 공식 "correcting over and over" 실패 패턴 |
| 토큰 | 상태줄에 컨텍스트 % 상시 표시 | 반영 | `statusline.sh`<br>70%/85%에서 색 바뀜. 컴팩션 전에 `/compact` 또는 `/clear` 판단 |
| 토큰 | 컴팩션 시 보존할 것 지정 | 반영 | CLAUDE.md §5<br>수정 파일·테스트 결과·미완료 체크리스트 |
| 토큰 | 대량 읽기는 서브에이전트로 | 반영 | CLAUDE.md §5 |
| 토큰 | CLAUDE.md 200줄 이하, 절차는 스킬로 | 반영 | 현재 60줄 |
| 토큰 | 작업 바뀌면 `/clear`, 곁가지 질문은 `/btw` | 습관 | 긴 세션의 한 줄 질문도 전체 컨텍스트를 다시 보냄 |
| 토큰 | 모델·effort 조절 | 습관 | 단순 작업은 `/effort` 낮추기, 서브에이전트는 Sonnet/Haiku. Fable은 thinking 끌 수 없음 |
| 토큰 | 안 쓰는 MCP 서버 끄기, CLI(`gh`) 우선 | 습관 | 현재 MCP 없음 |
| 생산성 | 안전한 읽기 명령 사전 허용 | 반영 | `permissions.allow`<br>Manual 모드에서 프롬프트 감소 |
| 생산성 | 세션 이름 붙이기 `/rename`, `--continue` | 습관 | 작업 단위로 세션을 브랜치처럼 |
| 생산성 | 반복 프롬프트는 스킬로, 매번 지켜야 하면 훅으로 | 반영 | 이 저장소의 존재 이유 |
| 생산성 | 코드 인텔리전스 플러그인(LSP) | 보류 | Java/Python 저장소에서 파일 탐색 줄여줌. 필요해지면 `/plugin`에서 언어별 설치 |
| 병렬 | worktree로 세션 격리 (`claude --worktree 이름`) | 습관 | 각 저장소 `.gitignore`에 `.claude/worktrees/` 추가 필요. kolo_pwa처럼 공유 파일(`CACHE_NAME`)이 있으면 그 저장소 규칙대로 머지는 순차 |
| 병렬 | 에이전트 뷰 (`claude agents`, `claude --bg "..."`) | 습관 | 백그라운드 세션은 자동으로 worktree에 격리되고 **브랜치를 자동 push**함(main엔 안 함)<br>git-guardrails가 확인을 요구하면 "Needs input"에 뜨므로 거기서 승인 |
| 병렬 | 서브에이전트 병렬 호출 | 습관 | 서로 독립인 영역을 한 메시지에서 동시에 |
| 병렬 | 에이전트 팀 | 보류 | 실험 기능, 토큰 약 7배. 개인 프로젝트 규모엔 과함 |
| 병렬 | 샌드박스 | 보류 | Windows 미지원(WSL2만). Mac/Linux에서는 `/sandbox`로 켜면 명령 승인이 더 줄어듦 |
| 알림 | 입력 대기 시 소리/알림 훅 | 보류 | 병렬 세션을 돌리기 시작하면 `Notification` 훅 추가 |

## 반복 작업의 토큰 (2026-09-09 검토)

같은 일을 매번 대화로 다시 시키면 지시·탐색·재생성에 토큰이 든다. 비용이 큰 순서로 줄이는 방법:

| 방법 | 무엇을 줄이나 | 상태 |
| --- | --- | --- |
| **절차는 스킬로, 반복 명령은 스크립트로** | 매번 절차를 설명하고 Claude가 명령을 다시 짜는 비용. 오늘 `check-install.sh`·`pack.sh`가 그 예 | 반영. 스킬 시험도 스크립트로([Issue #37](https://github.com/yanos0218/AI/issues/37)) |
| **서브에이전트에 싼 모델** | 조사·로그 읽기·시험 세션은 Sonnet/Haiku로 충분. 발동 시험 4회에 약 2달러였음 | [Issue #38](https://github.com/yanos0218/AI/issues/38): 시험 스크립트 기본 `--model claude-sonnet-5`, 전역 지침 §5에 "서브에이전트는 Sonnet" |
| **작업 바뀌면 `/clear`** | 긴 세션에서 한 줄 질문도 전체 문맥을 다시 보냄. 이 세션은 30턴 넘게 이어짐 | 습관. HANDOFF·PROGRESS가 전환 비용을 줄이는 장치 |
| **`/effort` 낮추기** | 단순 편집·문서 갱신에 깊은 추론 불필요 | 습관 |
| **한 메시지에 여러 항목** | 턴마다 붙는 고정 비용 | 사용자가 이미 함 |
| **읽을 파일을 줄이기** | 문서 상한, HANDOFF 4줄, 조사 기록 재사용(Issues `research` 라벨) | 반영 |
| **프롬프트 캐시** | 같은 앞부분(CLAUDE.md·시스템)은 1시간 캐시로 재사용됨. CLAUDE.md를 세션 중 자주 바꾸면 캐시가 깨짐 | 자동. 기본 영역을 세션 중 고치지 않는 규칙이 여기도 도움 |
| **측정** | 상태줄 `$`, `/cost`, 월 1회 `/insights` | 반영·[Issue #16](https://github.com/yanos0218/AI/issues/16) |

## 참고한 자료

- [Claude Code 공식 — Best practices](https://code.claude.com/docs/en/best-practices)
- [Claude Code 공식 — CLAUDE.md와 메모리](https://code.claude.com/docs/en/memory)
- [Claude Code 공식 — Skills](https://code.claude.com/docs/en/skills)
- [Claude Code 공식 — VS Code 확장](https://code.claude.com/docs/en/vs-code)
- [Agent Skills 공식 — 작성 모범 사례](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [anthropics/skills](https://github.com/anthropics/skills)
- [Claude 도움말 — 스킬 사용](https://support.claude.com/en/articles/12512180-use-skills-in-claude)
- [Claude Design 시작하기](https://support.claude.com/en/articles/14604416-get-started-with-claude-design)
- [VS Code — Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [HumanLayer — Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Writing a CLAUDE.md that Claude actually follows](https://dev.to/peterverse180/writing-a-claudemd-that-claude-actually-follows-4llo)
- [mattpocock/skills — git-guardrails](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md)
- [claude-code-dotfiles](https://github.com/elizabethfuentes12/claude-code-dotfiles)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [josix/awesome-claude-md](https://github.com/josix/awesome-claude-md)
- [Dale Seo — CLAUDE.md 작성 가이드](https://daleseo.com/claude-code-claude-md/)
- [GeekNews — Claude Code로 좋은 결과 얻기](https://news.hada.io/topic?id=22425)
