"""config-changelog 본체(Issue #144). Claude가 사용자 설정(~/.claude의 CLAUDE.md·settings*.json·rules/·hooks/)을
건드리면 ~/.claude/config-changelog.md에 한 줄 남긴다. 막지 않는 기록 훅이라 오류가 나면 조용히 통과한다."""
import datetime
import io
import os
import re

import hooklib as h

PROTECTED = re.compile(r'(~|\$\{?HOME\}?|Users[/\\][^/\\ "]+|home[/\\][^/\\ "]+)[/\\]\.claude[/\\](CLAUDE\.md|settings[^/\\ "]*\.json|rules[/\\]|hooks[/\\])')
# 명령을 ; && || | 줄바꿈으로 나눈 조각 단위로 본다. 보호 경로가 쓰기 명령과 같은 조각에, 그 뒤에 있을 때만 기록(Issue #173).
# 예전에는 둘이 명령 어디에든 따로 있기만 해도 기록해 128행 중 실제 설정 변경이 0건이었다
SEP = re.compile(r'\n|;|&&|\|\||\|')
# 쓰기 대상이 어디든 될 수 있는 명령과 리디렉션. 출력 버리기(>/dev/null, 2>&1)는 쓰기가 아니다
OPS = re.compile(r'sed\s+-i|(?<![\w-])tee\s|(?<![\w-])rm\s|Set-Content|Out-File|Add-Content|Remove-Item|(?<![0-9&<])>>?(?!\s*/dev/null)(?!&)')
# 복사·이동은 마지막 인자(목적지)만 쓰기 대상. 설정을 읽어 다른 곳에 복사하는 것은 기록하지 않는다
MOVES = re.compile(r'(?<![\w-])(cp|mv|install|Copy-Item|Move-Item)\s')


def writes_protected(text):
    src = h.mask_heredocs(text)   # heredoc 본문은 데이터라 명령으로 보지 않는다
    bare = h.quote_mask(src)      # 따옴표 안 기호는 명령으로 보지 않는다(길이가 같아 위치를 그대로 쓴다)
    start = 0
    for m in list(SEP.finditer(bare)) + [None]:
        end = m.start() if m else len(bare)
        seg_bare, seg_src = bare[start:end], src[start:end]
        mv = MOVES.search(seg_bare)
        if mv:
            args = seg_src[mv.end():].split()
            if args and PROTECTED.search(args[-1]):
                return True
        op = OPS.search(seg_bare)
        if op and PROTECTED.search(seg_src[op.start():]):
            return True
        start = m.end() if m else end
    return False
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
        if not writes_protected(text):
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
