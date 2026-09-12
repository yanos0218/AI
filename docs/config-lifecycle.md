# 설정 유지·변경 이력 — 다른 저장소에서 작업해도 기본이 흔들리지 않게

질문: 새 작업을 하다 보면 Claude 설정이 바뀔 수 있는데, 기본은 유지하면서 바뀐 것은 기록해 두거나 모듈처럼 붙였다 뗄 수 없나?
답: Claude Code가 이미 **층(layer)** 구조라서 대부분 가능하고, 빠진 것은 "이력"뿐이라 훅 하나로 채운다.

## 1. 설정은 세 층이고, 각 층은 서로 덮어쓰지 않는다

| 층 | 파일 | 누가 바꾸나 | 이 저장소에서의 취급 |
| --- | --- | --- | --- |
| **기본** (모든 프로젝트) | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/hooks/`, `~/.claude/skills/` | 사람 (이 저장소 `base/`에서 설치) | 원본은 `base/`. 여기서만 고치고 재설치한다 |
| **모듈** (모든 프로젝트, 주제별) | `~/.claude/rules/<주제>.md` | 사람 또는 Claude(요청 시) | 기본 CLAUDE.md를 건드리지 않고 규칙을 파일 단위로 붙였다 뗀다. 원본은 `base/rules/`(예정, [Issue #34](https://github.com/yanos0218/AI/issues/34)) |
| **프로젝트** (그 저장소만) | 저장소 `CLAUDE.md`, `.claude/settings.json`, `.claude/settings.local.json`(gitignore), 저장소 `.claude/skills/` | Claude와 사람 | 자유롭게 바뀌어도 기본에 영향 없음 |

핵심 사실 두 가지:

- 작업 중 "항상 허용"을 눌러 쌓이는 권한은 **그 저장소의 `.claude/settings.local.json`**에 기록된다(kolo_pwa에 실제로 있음). 기본 `~/.claude/settings.json`은 건드리지 않는다.
- Claude가 교정을 스스로 기억하는 auto memory는 `~/.claude/projects/<저장소>/memory/`에 저장소별로 쌓이고, 기본 CLAUDE.md에는 쓰지 않는다.

즉 "기본이 바뀌는" 경우는 사실상 하나다 — Claude나 사람이 `~/.claude/` 아래 파일을 **직접 편집**할 때.

## 2. 그래서 필요한 것은 "이력"과 "대조"

| 장치 | 무엇 | 상태 |
| --- | --- | --- |
| `config-changelog` 훅 | Claude가 `~/.claude/{CLAUDE.md, settings*.json, rules/, hooks/}`를 편집하면 `~/.claude/config-changelog.md`에 시각·도구·대상·작업 폴더를 한 줄 기록. 막지 않고 남기기만 | 기본 `base/hooks/config-changelog.sh` (v0.4.0), `settings.example.json`의 PostToolUse에 등록 |
| `tools/check-install.sh` | 설치본과 `base/` 대조(DIFF/MISSING), `rules/` 목록, 프로젝트별 `settings.local.json`에 쌓인 권한 목록, 변경 이력 꼬리 20줄 | 사용 가능 |
| 월 점검 ([Issue #42](https://github.com/yanos0218/AI/issues/42)) | 위 둘의 출력을 보고 결정: 여러 저장소에 반복된 권한 → `base/settings.example.json` 승격, 좋은 변경 → `base/`에 반영 후 재설치, 나쁜 변경 → 재설치로 되돌림 | 규칙 |

"보내준다"는 요구는 이 훅의 로그 파일 + `check-install.sh`가 해결한다. 기기마다 로그가 남고, 점검 때 `drafts/observations/`로 복사하면 저장소에 모인다. 실시간으로 어딘가에 전송하는 방식(메일·웹훅)은 외부 서비스 쓰기라 보류.

## 3. 검토했지만 지금은 안 쓰는 방법

| 방법 | 장점 | 안 쓰는 이유 |
| --- | --- | --- |
| dotfiles + 심링크(stow/chezmoi)로 `~/.claude`를 저장소에 직접 연결 | 편집 즉시 `git status`에 드러남 | Windows 심링크는 관리자/개발자 모드 필요, `~/.claude`에 런타임 데이터(세션·캐시)가 섞여 선별 링크 관리가 필요. 커뮤니티도 "파일 단위 선별"을 권함. 기기 3대가 되면 재검토 |
| managed settings(`C:\Program Files\ClaudeCode\managed-settings.json`)로 기본을 잠금 | 사용자·프로젝트 설정이 절대 덮어쓸 수 없음 | 고칠 때마다 관리자 권한. 1인 환경에서는 훅 + 대조로 충분 |
| `~/.claude` 자체를 git 저장소로 | 모든 변경이 커밋 | 세션 기록·메모리 등 민감·대용량 파일이 섞임 |

## 참고

- [Claude Code 공식 — .claude 디렉터리](https://code.claude.com/docs/en/claude-directory), [메모리·rules](https://code.claude.com/docs/en/memory)
- [Manage Claude Code config with dotfiles and GNU Stow](https://yurikoval.com/blog/manage-ai-config-with-dotfiles.html), [chezmoi로 여러 기기 동기화](https://www.frxiaobei.com/en/posts/2026/04/chezmoi-claude-code/), [vsbuffalo/dotfiles — claude-code.md](https://github.com/vsbuffalo/dotfiles/blob/main/docs/claude-code.md)
