"""config-changelog 본체(Issue #144). Claude가 사용자 설정(~/.claude의 CLAUDE.md·settings*.json·rules/·hooks/)을
건드리면 ~/.claude/config-changelog.md에 한 줄 남긴다. 막지 않는 기록 훅이라 오류가 나면 조용히 통과한다."""
import datetime
import io
import os
import re

import hooklib as h

PROTECTED = re.compile(r'(~|Users[/\\][^/\\ "]+|home[/\\][^/\\ "]+)[/\\]\.claude[/\\](CLAUDE\.md|settings[^/\\ "]*\.json|rules[/\\]|hooks[/\\])')
# 쓰기 성격의 명령. > 는 따옴표 밖에서만 보고, 출력 버리기(>/dev/null, 2>&1)는 쓰기가 아니다
WRITES = re.compile(r'sed\s+-i|tee\s|(^|[;&|\s])(cp|mv|rm)\s|Set-Content|Out-File|Copy-Item|Move-Item|Remove-Item|Add-Content')
REDIRECT = re.compile(r'(?<![0-9&])>>?(?!\s*/dev/null)(?!&)')
HEADER = '# 설정 변경 이력 (config-changelog 훅이 자동 기록)\n\n| 시각 | 도구 | 대상 | 작업 폴더 |\n| --- | --- | --- | --- |\n'


def main():
    inp = h.read_input()
    tool = inp.get('tool_name') or ''
    if tool in ('Edit', 'Write', 'MultiEdit'):
        text = h.path_of(inp)
        if not PROTECTED.search(text):
            return
    elif tool in ('Bash', 'PowerShell'):
        text = h.command_of(inp)
        if not PROTECTED.search(h.mask_heredocs(text)):
            return
        bare = h.mask_heredocs(h.quote_mask(text))
        if not (WRITES.search(text) or REDIRECT.search(bare)):
            return
    else:
        return
    log = os.path.join(h.HOME, 'config-changelog.md')
    new = not os.path.isfile(log)
    with io.open(log, 'a', encoding='utf-8', newline='\n') as f:
        if new:
            f.write(HEADER)
        f.write(f"| {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')} | {tool} | {h.one_line(text)} | {inp.get('cwd') or os.getcwd()} |\n")


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        h.log_error('config-changelog', e)
