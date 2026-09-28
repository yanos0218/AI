# usage-dashboard 설치·구조·문제 해결

## 폴더 구조

스킬 폴더 하나에 기능 전체가 들어 있고, 기록은 스킬 밖(`~/.claude/usage-log/`)에 쌓인다. 스킬을 다시 설치해도 기록은 그대로다.

| 경로 | 역할 |
| --- | --- |
| `SKILL.md` | Claude가 읽는 사용 절차 |
| `references/setup.md` | 이 문서 |
| `scripts/usage.sh` | 입구<br>명령을 받아 켜짐 확인·잠금·브라우저 열기·로컬 서버를 맡고 집계는 `usage.py`에 넘김 |
| `scripts/usage.py` | 집계<br>대화 기록(`~/.claude/projects/**/*.jsonl`)에서 새 줄만 읽어 합계·요청·세션 시작 크기를 저장하고 화면을 만듦 |
| `scripts/dashboard.html` | 화면 틀<br>`render` 때마다 데이터를 넣어 `usage-log/dashboard.html`로 복사 |

스크립트는 Claude 없이도 돈다. 터미널에서 `bash <스킬 폴더>/scripts/usage.sh open`처럼 직접 실행해도 된다.

## 자동 기록 훅 등록

응답이 끝날 때마다 기록하려면 `~/.claude/settings.json`의 `hooks.Stop`에 아래를 넣는다. 켜짐 표시 파일(`usage-log/enabled`)이 없으면 훅은 바로 끝나므로 등록해 둬도 꺼진 동안 기록하지 않는다.

```json
{ "hooks": [ { "type": "command", "command": "bash <스킬 폴더>/scripts/usage.sh hook", "async": true, "timeout": 60 } ] }
```

- `async: true`라 응답을 기다리게 하지 않는다.
- `<스킬 폴더>`는 설치 위치의 절대 경로(예: `~/.claude/skills/usage-dashboard`).
- 세션 시작 크기 알림은 세션 시작 훅에서 `usage.sh check`를 부를 때만 동작한다.
- `settings.json` 수정은 사용자 확인 뒤에 한다.

## 저장 파일과 보관 기간

모두 `~/.claude/usage-log/`(설정 폴더를 바꿨으면 `$CLAUDE_CONFIG_DIR/usage-log/`) 아래에 있다.

| 파일 | 내용 | 보관 |
| --- | --- | --- |
| `hourly.json` | 시간·저장소·누가·모델별 토큰 합계 | 영구 |
| `starts.jsonl` | 세션 시작 크기 | 영구 |
| `requests.json` | 요청 단위 합계와 원인 단서, 요청 첫 80자 | 90일 |
| `details.json`·`details.js` | 요청 원문(최대 2천 자), 응답 앞부분, 도구 호출 요약(명령·경로), 결과 크기와 앞부분(단계마다 180자, 요청당 40단계) | 90일 |
| `tools.jsonl` | 2만 자 넘는 도구 결과의 도구 이름·크기 | 90일 |
| `state.json` | 대화 기록 파일별로 어디까지 읽었는지 | 계속 갱신 |
| `dashboard.html` | 화면 | `render` 때 새로 만듦 |
| `enabled` | 켜짐 표시 | `disable` 때 지움 |
| `error.log` | 훅·집계 오류 | 계속 누적 |

- 파일 전체 내용은 저장하지 않는다. 어떤 작업이 토큰을 썼는지 알아보는 데 필요한 만큼만 남긴다.
- 켜기 전 사용분은 Claude Code가 남겨 둔 대화 기록만큼만 채운다(`cleanupPeriodDays` 기본 30일).

## 문제 해결

| 증상 | 확인할 것 |
| --- | --- |
| 새 대화가 기록되지 않음 | `status`로 켜짐 확인. `settings.json`의 `hooks.Stop`에 위 명령이 있는지, 경로가 실제 스킬 위치인지 확인 |
| 화면이 예전 그대로 | `render` 뒤 브라우저 새로고침 |
| `serve`가 "띄우지 못했습니다" | 8765 포트를 다른 프로그램이 쓰는 중. `USAGE_PORT=8766 bash usage.sh serve`처럼 바꿔 실행 |
| "다른 기록 작업이 끝나지 않았습니다" | 다른 세션의 훅이 기록 중. 잠시 뒤 다시 실행. 1분 넘은 잠금은 자동으로 치운다 |
| "python이 없습니다" | `python` 또는 `python3`가 PATH에 있어야 한다. Windows는 스토어 별칭 `python3`보다 `python`을 먼저 쓴다 |
| 이상하게 동작함 | `usage-log/error.log` 마지막 줄을 본다 |
