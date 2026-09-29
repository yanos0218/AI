"""훅 공통 모듈(Issue #144). 셸 입구(*.sh)가 대상일 때만 파이썬 본체(*.py)를 부르고, 본체가 이 모듈을 쓴다.

왜 파이썬인가
- 셸 훅은 입력 JSON 원문 전체를 문자열로 훑어서, 명령이 아닌 설명(description) 글이나 따옴표·heredoc 안의
  글에도 반응했다. 여기서는 JSON을 정확히 읽고 명령을 덩어리로 나눠 실제 명령 자리만 본다.
- Rocky Linux 3.9에서도 돌도록 3.8 문법만 쓴다(match 문, X | Y 타입 표기 금지).

명령 나누기(segment·heredoc_spans·at_command_start)는 base/hooks/format_check.py(Issue #141)와 같은 규칙이다.
format_check.py가 이 모듈을 쓰도록 합치는 일은 Issue #164(2026-09-29 기본 반영 때는 동작 변화를 피하려고 미룸).
"""
import datetime
import io
import json
import os
import re
import sys

HOME = os.environ.get('CLAUDE_CONFIG_DIR') or os.path.expanduser('~/.claude')
ERROR_LOG = os.path.join(HOME, 'hook-errors.log')

try:  # Windows 기본 출력 인코딩(cp949)이면 한글 출력에서 죽는다(2026-09-27~28 두 번 겪음)
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except (AttributeError, ValueError):
    pass


def read_input():
    raw = sys.stdin.buffer.read().decode('utf-8', errors='replace')
    return json.loads(raw or '{}')


def tool_input(inp):
    return inp.get('tool_input') or {}


def command_of(inp):
    return tool_input(inp).get('command') or ''


def path_of(inp):
    ti = tool_input(inp)
    return ti.get('file_path') or ti.get('notebook_path') or ''


def log_error(hook, err):
    try:
        with io.open(ERROR_LOG, 'a', encoding='utf-8') as f:
            f.write(f"{datetime.datetime.now().isoformat(timespec='seconds')}\t{hook}\t{type(err).__name__}: {err}\n")
    except OSError:
        pass


def decision(kind, reason):
    """PreToolUse 결정 JSON(kind: ask·deny)."""
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': kind,
                                             'permissionDecisionReason': reason}}, ensure_ascii=False))


def one_line(text, n=160):
    """표 한 칸에 넣을 짧은 글. 글자 단위로 잘라 한글이 깨지지 않는다."""
    return ' '.join(text.split())[:n].replace('|', '\\|')


# ---------- 명령 나누기 ----------

HEREDOC = re.compile(r'''<<-?\s*(['"]?)([A-Za-z_]+)\1''')
SEPS = ('\n', ';', '&&', '||', '|', '$(', '(', '`')


def heredoc_spans(cmd):
    """heredoc 본문 구간들."""
    spans = []
    for m in HEREDOC.finditer(cmd):
        nl = cmd.find('\n', m.end())
        if nl < 0:
            continue
        end = re.search(r'^\s*' + re.escape(m.group(2)) + r'\s*$', cmd[nl + 1:], re.M)
        spans.append((nl + 1, nl + 1 + (end.start() if end else len(cmd) - nl - 1)))
    return spans


def quote_mask(text):
    """따옴표 안 글자를 공백으로 바꾼 사본(길이 같음). 따옴표 안의 > 같은 기호를 명령으로 보지 않기 위해.
    단 큰따옴표 안의 $( … )와 ` … `는 실제로 실행되는 명령이라 가리지 않는다
    (echo "$(gh issue list --limit 100)"를 놓친 대조 시험 결과, 2026-09-28)."""
    out, q, i = list(text), None, 0
    while i < len(text):
        c = text[i]
        if q == '"' and (text.startswith('$(', i) or c == '`'):
            close, depth, j = (')', 1, i + 2) if c == '$' else ('`', 1, i + 1)
            while j < len(text) and depth:
                if close == ')' and text.startswith('$(', j):
                    depth += 1
                    j += 1
                elif text[j] == close:
                    depth -= 1
                j += 1
            i = j                        # 명령 부분은 그대로 둔다
            continue
        if q:
            if q == '"' and c == '\\' and i + 1 < len(text):
                out[i] = out[i + 1] = ' '
                i += 2
                continue
            if c == q:
                q = None
            else:
                out[i] = ' ' if c != '\n' else '\n'
        elif c in '"\'':
            q = c
        i += 1
    return ''.join(out)


def mask_heredocs(text):
    out = list(text)
    for a, b in heredoc_spans(text):
        for i in range(a, b):
            if out[i] != '\n':
                out[i] = ' '
    return ''.join(out)


def at_command_start(cmd, pos):
    """pos가 명령 자리인지: 앞이 줄 시작이나 ; && || | $( ( ` 이고 그 사이에는 변수 대입·sudo·env만 있다."""
    head = cmd[:pos]
    cut = max((head.rfind(s) + len(s) for s in SEPS if s in head), default=0)
    return re.fullmatch(r'\s*(?:(?:[A-Za-z_][A-Za-z0-9_]*=(?:"[^"]*"|\'[^\']*\'|\S*)|sudo|env|time|command)\s+)*',
                        head[cut:]) is not None


def command_words(cmd, pattern):
    """정규식 pattern이 heredoc 본문과 따옴표 밖에서, 명령 자리에 나온 위치들."""
    masked = mask_heredocs(quote_mask(cmd))
    return [m for m in re.finditer(pattern, masked) if at_command_start(masked, m.start())]
