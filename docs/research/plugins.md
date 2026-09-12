# 플러그인·개인 마켓플레이스 — 이 저장소를 플러그인화할 것인가 (C-45)

- 조사일: 2026-09-09 · 다시 볼 시점: 2026-10-09 (Claude Code 기능, 30일)
- 질문: `base/skills`·`base/hooks`를 플러그인으로 묶고 이 저장소를 개인 마켓플레이스로 만들면 `tools/install.sh`보다 나은가.
- 결론: **지금은 하지 않는다(보류).** 플러그인이 실을 수 있는 것은 스킬·훅(PreToolUse/PostToolUse)뿐이고, 전역 지침·rules·permissions·statusLine은 공식적으로 못 싣는다. 이 넷 때문에 `install.sh`는 어차피 남고, 그 `install.sh`가 스킬·훅 복사도 같은 실행에서 이미 한다. 플러그인을 더하면 설치 경로 둘·버전 둘(`plugin.json` + git 태그)·비공개 저장소 인증 설정(기기마다)·스킬 이름 접두사(`AI:dev-release`)가 생기는데, 얻는 것은 "`claude plugin update` 한 줄"뿐이다. 1인·3기기·낮은 갱신 빈도에서는 손해.

## 근거

| 사실 | 출처 | 직접 확인 |
| --- | --- | --- |
| 플러그인 구성요소: skills, commands, agents, hooks(`hooks/hooks.json`, `${CLAUDE_PLUGIN_ROOT}`), MCP, LSP, monitors, output styles, `settings.json` | [plugins-reference](https://code.claude.com/docs/en/plugins-reference) | — |
| 플러그인 `settings.json`은 `agent`·`subagentStatusLine` 두 키만 지원 → **permissions·statusLine 불가** | 위 문서 "Settings" 행 원문 | 로컬 `claude-code-settings.schema.json`에 `statusLine`·`subagentStatusLine` 별개 키 존재 |
| 플러그인 루트 `CLAUDE.md`는 로드되지 않음, `.claude/rules/` 미지원 | 위 문서 "Limitations" 절 | — |
| 사용자 `settings.json` 훅과 플러그인 훅은 **둘 다** 실행됨 → 이전하면 settings 쪽을 지워야 중복 실행 안 됨 | [hooks](https://code.claude.com/docs/en/hooks) | — |
| 플러그인 스킬은 `/plugin-name:skill-name` 접두사. description 자동 발동은 유지. 같은 이름의 `~/.claude/skills/`가 우선 | [plugins](https://code.claude.com/docs/en/plugins) | — |
| 마켓플레이스 = 저장소의 `.claude-plugin/marketplace.json`, 같은 저장소 안 `./경로` source 가능. 비공개 GitHub는 `gh auth`/SSH 자격증명 사용, 백그라운드 자동 갱신은 HTTPS면 credential helper 필요. 서드파티 마켓플레이스 자동 갱신은 기본 꺼짐 | [plugin-marketplaces](https://code.claude.com/docs/en/plugin-marketplaces), [discover-plugins](https://code.claude.com/docs/en/discover-plugins) | Mac `gh auth status` 로그인됨(https), ssh-agent 키 없음 |
| `version`을 적으면 그 문자열이 바뀔 때만 갱신, 생략하면 커밋 SHA마다 갱신 | plugin-marketplaces | — |
| `claude plugin` 하위 명령: details, disable, enable, eval, init, install(`--scope`), list, marketplace add/list/remove/update, prune, tag, uninstall, update, validate(`--strict`, `--json`) | — | **실행 확인** Mac, Claude Code 2.1.266 `claude plugin --help` |
| `claude plugin validate base/skills`는 플러그인 매니페스트 없이도 스킬 디렉터리 검사 가능 → "Validation passed". 스킬 폴더 하나(`base/skills/dev-release`)를 주면 매니페스트 없다고 실패 | — | **실행 확인** 2026-09-09 |
| Mac에 `claude` CLI가 PATH에 없지만 VS Code 확장이 바이너리를 내장함: `~/.vscode/extensions/anthropic.claude-code-<버전>-darwin-arm64/resources/native-binary/claude` | — | **실행 확인** `--version` → 2.1.266 |

## 다시 검토할 조건

- 스킬이 5개를 넘거나 다른 사람과 나눠 쓰게 될 때(마켓플레이스의 본래 용도).
- 플러그인이 permissions·CLAUDE.md·rules를 실을 수 있게 바뀔 때(공식 문서 "Limitations" 절 재확인).
- Claude.ai 웹 업로드([C-17](../PROGRESS.md#c-17))가 플러그인 동기화로 대체될 때 — 현재 `plugins/cache/.../synced/`는 claude.ai→Claude Code 방향만 확인(미검증).

## 영향

- [PROGRESS C-45](../PROGRESS.md#c-45) 닫음(보류 결론). 새 항목 [Issue #4](https://github.com/yanos0218/AI/issues/4): `claude plugin validate base/skills`를 로컬 검증 절차에 넣을지.
- HANDOFF: Mac에서도 확장 내장 바이너리로 CLI 명령 실행 가능 → [C-10](../PROGRESS.md#c-10)·[C-25](../PROGRESS.md#c-25) 문구 정정.
- [Issue #58](https://github.com/yanos0218/AI/issues/58)(옛 `docs/audit-2026-09.md`) S1은 "검토"로 두고 결론은 이 파일.
