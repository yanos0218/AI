#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit|Bash|PowerShell) 훅 — 전역용.
# Claude가 사용자 설정(~/.claude/CLAUDE.md, settings*.json, rules/, hooks/)을 건드리면
# ~/.claude/config-changelog.md 에 한 줄 남긴다: 시각 | 도구 | 대상 | 작업 폴더.
# 목적: 다른 저장소에서 작업하다 설정이 바뀌어도 "언제 무엇이" 바뀌었는지 남겨,
# 월 점검 때 base/로 승격할지 되돌릴지 정할 수 있게 한다. 막지는 않는다(막는 건 baseline-guard·git-guardrails).
set -u
input="$(cat)"
home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
log="$home/config-changelog.md"

tool="$(printf '%s' "$input" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
case "$tool" in
  Edit|Write|MultiEdit) text="$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)" ;;
  Bash|PowerShell)      text="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)" ;;
  *) exit 0 ;;
esac

# 감시 대상: 홈 아래 ~/.claude 의 CLAUDE.md·settings*.json·rules/·hooks/ 만.
# 프로젝트의 .claude/ 는 제외한다(그 층은 자유). 경로 구분자 / \ 모두, ~ 표기 포함.
pattern='(~|Users[/\\][^/\\ "]+|home[/\\][^/\\ "]+)[/\\]\.claude[/\\](CLAUDE\.md|settings[^/\\ "]*\.json|rules[/\\]|hooks[/\\])'
printf '%s' "$text" | grep -Eq "$pattern" || exit 0
# Bash/PowerShell 은 쓰기 성격의 명령일 때만
if [ "$tool" = Bash ] || [ "$tool" = PowerShell ]; then
  printf '%s' "$text" | grep -Eq '(>|sed[[:space:]]+-i|tee[[:space:]]|(^|[;&| ])(cp|mv|rm)[[:space:]]|Set-Content|Out-File|Copy-Item|Move-Item|Remove-Item|Add-Content)' || exit 0
fi

[ -f "$log" ] || printf '# 설정 변경 이력 (config-changelog 훅이 자동 기록)\n\n| 시각 | 도구 | 대상 | 작업 폴더 |\n| --- | --- | --- | --- |\n' > "$log"
short="$(printf '%s' "$text" | tr '\n' ' ' | cut -c1-160 | sed 's/|/\\|/g')"
printf '| %s | %s | %s | %s |\n' "$(date '+%Y-%m-%d %H:%M')" "$tool" "$short" "$(pwd)" >> "$log"
exit 0
