#!/usr/bin/env python3
"""형식 검사 훅의 본체(Issue #141). format-guard.sh(PreToolUse)와 md-format-check.sh(PostToolUse)가 부른다.

  pre   gh issue·pr·release 작성·댓글·수정, git commit의 본문을 명령에서 꺼내 검사. 위반이면 exit 2
  post  Edit·Write로 .md에 새로 쓴 내용만 검사. 위반이면 exit 2(파일은 이미 저장됨, Claude가 이어서 고침)
  scan  과거 글 일괄 점검(오탐 측정용): scan <gh|release|commit|md> <파일...>

원칙
- 내용을 고치지 않는다. 통과시키거나 막기만 한다.
- 통과하면 아무것도 출력하지 않는다(모델 토큰 0). 막을 때 사유는 10줄 이내.
- 본문을 확실히 꺼내지 못하면 막지 않고 통과시킨 뒤 ~/.claude/format-guard.log에 한 줄 남긴다.
- 목록 줄과 표만 본다. 규칙 원문이 "목록 항목"이 대상이고, 목록 아닌 "근거: …" 같은 필드 줄이나
  일반 문단까지 보면 오탐이 절반이었다(2026-09-27 커밋 29개 실측).
"""
import datetime
import importlib.util
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
HOME = os.environ.get('CLAUDE_CONFIG_DIR') or os.path.expanduser('~/.claude')
LOG = os.path.join(HOME, 'format-guard.log')
MAX_LINES = 10


def load_cram(cwd):
    """목록 줄바꿈 판정은 check-cram.py를 그대로 쓴다. 같은 폴더(설치본) → 저장소 tools/ 순서로 찾는다.
    그 저장소에 예외 목록(.claude/cram-exceptions.txt)이 있으면 따른다."""
    for p in (os.path.join(HERE, 'check-cram.py'), os.path.join(HERE, '..', '..', 'tools', 'check-cram.py')):
        if os.path.isfile(p):
            exc = os.path.join(cwd or '.', '.claude', 'cram-exceptions.txt')
            saved = sys.argv
            sys.argv = [p, exc]   # check-cram.py는 불러올 때 argv[1]에서 예외 목록 경로를 읽는다
            try:
                spec = importlib.util.spec_from_file_location('check_cram', p)
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
            finally:
                sys.argv = saved
            return mod
    return None


# 이슈·PR·릴리즈 본문의 문장형 끝맺음(음슴체 규칙). 따옴표·백틱 안은 인용이라 지운 뒤 본다
ENDING = re.compile(r'(습니다|습니까|ㅂ니다|합니다|입니다|됩니다|십시오|한다|했다|된다|됐다|이다|였다|있다|없다|않는다|않았다)(?=[.!?]?\s*$|[.!?]\s)')
QUOTED = re.compile(r'`[^`]*`|"[^"]*"|“[^”]*”|\'[^\']*\'')
LIST = re.compile(r'^\s*(?:[-*]|\d+\.)\s+')
TRAILER = re.compile(r'^(Refs|Closes|Fixes|Co-Authored-By|Signed-off-by|BREAKING CHANGE)\b', re.I)


def check_text(text, kind, cram):
    """위반 줄 목록 [(줄번호, 종류, 내용)]. kind: gh·release·commit(게시 본문), md(파일)."""
    lines = text.split('\n')
    out, in_code, start = [], False, 0
    if kind == 'commit':
        start = 1                     # 제목 줄은 검사하지 않는다
    if kind == 'md' and lines and lines[0].strip() == '---':
        for i in range(1, len(lines)):  # YAML 머리말
            if lines[i].strip() == '---':
                start = i + 1
                break
    for i in range(start, len(lines)):
        raw = lines[i].rstrip('\r')
        t = raw.strip()
        if t.startswith('```'):
            in_code = not in_code
            continue
        if in_code or not t or t.startswith(('>', '<!--')) or (kind == 'commit' and TRAILER.match(t)):
            continue
        is_table = t.startswith('|')
        if cram and (is_table or LIST.match(raw)):   # 규칙 대상은 목록 항목과 표(일반 문단은 보지 않음)
            k = cram.check_table_row(raw) if is_table else cram.check_line(raw)
            if k:
                out.append((i + 1, '목록 줄바꿈', t))
                continue
        if kind in ('gh', 'release') and not t.startswith('|---'):
            plain = QUOTED.sub('', t)
            for seg in plain.split('<br>'):
                if ENDING.search(seg.strip()):
                    out.append((i + 1, '음슴체', t))
                    break
    return out


def report(hits, where):
    msg = [f'[형식 검사] {where}에서 규칙 위반 {len(hits)}줄. 내용은 그대로 두고 아래 줄만 고친 뒤 같은 명령을 다시 실행할 것.']
    for n, k, t in hits[:MAX_LINES - 3]:
        msg.append(f'  {n}행 [{k}] {t[:90]}')
    if len(hits) > MAX_LINES - 3:
        msg.append(f'  … 외 {len(hits) - (MAX_LINES - 3)}줄')
    kinds = {k for _, k, _ in hits}
    if '목록 줄바꿈' in kinds:
        msg.append('  목록 줄바꿈: "주어: 설명"을 주어 줄 + 들여쓴 하위 bullet로, 표 안은 <br>. 코드 값(model: x 등)은 백틱으로 감쌀 것')
    if '음슴체' in kinds:
        msg.append('  음슴체: "~합니다/~한다." 대신 "~함/~됨/~확인"')
    msg.append('  오탐이라고 판단되면 고치지 말고 사용자에게 묻고, 승인받으면 명령 앞에 FORMAT_GUARD_SKIP=1을 붙인다')
    sys.stderr.write('\n'.join(msg[:MAX_LINES + 2]) + '\n')


def log(reason, cmd=''):
    try:
        with open(LOG, 'a', encoding='utf-8') as f:
            f.write(f"{datetime.datetime.now().isoformat(timespec='seconds')}\t{reason}\t{' '.join(cmd.split())[:100]}\n")
    except OSError:
        pass


# ---------- 명령에서 본문 꺼내기 ----------

GH = re.compile(r'\bgh\s+(issue|pr)\s+(create|comment|edit|close|review)\b|\bgh\s+release\s+(create|edit)\b')
GIT_COMMIT = re.compile(r'\bgit(?:\s+-C\s+\S+)?\s+commit\b')
ASSIGN = re.compile(r'''(?:^|[;&\s])([A-Za-z_][A-Za-z0-9_]*)=("([^"]*)"|'([^']*)'|([^\s;&|]+))''')
HEREDOC = re.compile(r'''<<-?\s*(['"]?)([A-Za-z_]+)\1''')


def expand(s, env):
    return re.sub(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)',
                  lambda m: env.get(m.group(1) or m.group(2), m.group(0)), s)


def heredoc_after(cmd, pos):
    """pos 뒤 첫 heredoc의 본문. 본문은 그 표시가 있는 줄의 다음 줄부터 끝 표시 줄 전까지."""
    m = HEREDOC.search(cmd, pos)
    if not m:
        return None
    nl = cmd.find('\n', m.end())
    if nl < 0:
        return None
    body = []
    for line in cmd[nl + 1:].split('\n'):
        if line.strip() == m.group(2):
            return '\n'.join(body)
        body.append(line)
    return None


def created_here(cmd, before, path, env):
    """같은 명령 안에서 cat > 파일 <<'EOF'로 막 만드는 본문 파일(훅은 명령 실행 전에 돌아 파일이 아직 없다)."""
    for m in re.finditer(r'cat\s*>\s*("([^"]+)"|\'([^\']+)\'|(\S+))\s*<<', cmd[:before]):
        if expand(m.group(2) or m.group(3) or m.group(4), env) == path:
            return heredoc_after(cmd, m.start())
    return None


def quoted_value(cmd, pos):
    """pos에서 시작하는 인수 하나. "…"(이스케이프 처리), '…', 따옴표 없는 단어. 실패하면 None."""
    while pos < len(cmd) and cmd[pos] in ' =':
        pos += 1
    if pos >= len(cmd):
        return None, pos
    q = cmd[pos]
    if q in '"\'':
        out, i = [], pos + 1
        depth = 0
        while i < len(cmd):
            c = cmd[i]
            if q == '"' and c == '\\' and i + 1 < len(cmd):
                out.append(cmd[i + 1] if cmd[i + 1] in '"\\$`' else c + cmd[i + 1])
                i += 2
                continue
            if q == '"' and cmd.startswith('$(', i):
                depth += 1
            elif q == '"' and c == ')' and depth:
                depth -= 1
            elif c == q and not depth:
                return ''.join(out), i + 1
            out.append(c)
            i += 1
        return None, pos
    m = re.match(r'[^\s;&|]+', cmd[pos:])
    return (m.group(0), pos + m.end()) if m else (None, pos)


def resolve(value, cmd, pos, env, cwd):
    """인수 값을 실제 본문으로. $(cat 파일), $(cat <<'EOF' …), 파일 경로(file=True일 때)."""
    if value is None:
        return None
    v = value.strip()
    m = re.fullmatch(r'\$\(\s*cat\s+<<-?\s*[\'"]?([A-Za-z_]+)[\'"]?\s*\n(.*)\n\s*\1\s*\)', v, re.S)
    if m:
        return m.group(2)
    m = re.fullmatch(r'\$\(\s*cat\s+("([^"]+)"|\'([^\']+)\'|(\S+))\s*\)', v)
    if m:
        return read_file(expand(m.group(2) or m.group(3) or m.group(4), env), cwd)
    if '$(' in v or '`' in v:
        return None
    return expand(v, env)


def read_file(path, cwd):
    if re.search(r'\$\{?[A-Za-z_]', path):
        return None
    p = path if os.path.isabs(path) or re.match(r'^[A-Za-z]:[\\/]', path) else os.path.join(cwd or '.', path)
    if re.match(r'^/[a-zA-Z]/', p) and os.name == 'nt':
        p = p[1] + ':' + p[2:]          # Git Bash 경로 /c/... → C:/...
    try:
        with io.open(p, encoding='utf-8') as f:
            return f.read()
    except OSError:
        return None


def option_bodies(cmd, seg_start, seg_end, opts_text, opts_file, env, cwd):
    """구간 안의 옵션들에서 본문 목록. 하나라도 못 읽으면 None(모름)."""
    bodies = []
    pat = re.compile(r'(?<=\s)(' + '|'.join(re.escape(o) for o in opts_text + opts_file) + r')(?=[\s=])')
    for m in pat.finditer(cmd, seg_start, seg_end):
        opt = m.group(1)
        # "$(cat <<'EOF' … EOF)" — 본문 안의 괄호·따옴표 때문에 따옴표 추적이 틀어지므로 끝 표시 줄로 바로 자른다
        hd = re.match(r'[\s=]*"?\$\(\s*cat\s+<<-?\s*[\'"]?([A-Za-z_]+)[\'"]?[^\n]*\n', cmd[m.end():])
        if hd and opt in opts_text:
            body = heredoc_after(cmd, m.end())
            if body is None:
                return None
            bodies.append(body)
            continue
        raw, end = quoted_value(cmd, m.end())
        if opt in opts_file:
            path = resolve(raw, cmd, end, env, cwd) if raw and raw.startswith('$(') else (expand(raw, env) if raw else None)
            if path == '-':
                body = heredoc_after(cmd, end)
            else:
                body = read_file(path, cwd) if path else None
                if body is None and path:
                    body = created_here(cmd, m.start(), path, env)
        else:
            body = resolve(raw, cmd, end, env, cwd)
        if body is None:
            return None
        bodies.append(body)
    return bodies


def segment(cmd, start):
    """명령 한 덩어리의 끝(줄바꿈이나 && ; | 전, 따옴표·heredoc은 대략 건너뜀)."""
    i, q, depth = start, None, 0
    while i < len(cmd):
        c = cmd[i]
        if q:
            if c == '\\' and q == '"':
                i += 2
                continue
            if q == '"' and cmd.startswith('$(', i):
                depth += 1
            elif q == '"' and c == ')' and depth:
                depth -= 1
            elif c == q and not depth:
                q = None
        elif c in '"\'':
            q = c
        elif c == '\n' or cmd.startswith('&&', i) or cmd.startswith('||', i) or c in ';|':
            return i
        i += 1
    return len(cmd)


def heredoc_spans(cmd):
    """heredoc 본문 구간들. 그 안의 "gh issue …" 같은 글은 실행되는 명령이 아니라 데이터다."""
    spans = []
    for m in HEREDOC.finditer(cmd):
        nl = cmd.find('\n', m.end())
        if nl < 0:
            continue
        end = re.search(r'^\s*' + re.escape(m.group(2)) + r'\s*$', cmd[nl + 1:], re.M)
        spans.append((nl + 1, nl + 1 + (end.start() if end else len(cmd))))
    return spans


def at_command_start(cmd, pos):
    """pos가 명령 자리인지: 앞이 줄 시작·; && || | $( 이고 그 사이에는 변수 대입만 있다.
    echo "gh issue …"나 python 문자열 안의 글은 명령이 아니다(2026-09-28 실사용 오탐)."""
    head = cmd[:pos]
    cut = max(head.rfind(s) + len(s) for s in ('\n', ';', '&&', '||', '|', '$(', '(')) if any(s in head for s in ('\n', ';', '&&', '||', '|', '$(', '(')) else 0
    return re.fullmatch(r'\s*(?:[A-Za-z_][A-Za-z0-9_]*=(?:"[^"]*"|\'[^\']*\'|\S*)\s+)*', head[cut:]) is not None


def targets(cmd, cwd):
    """(종류, 본문 목록 또는 None) 목록."""
    env = {}
    for m in ASSIGN.finditer(cmd):
        env[m.group(1)] = m.group(3) if m.group(3) is not None else (m.group(4) if m.group(4) is not None else m.group(5))
    spans = heredoc_spans(cmd)
    real = lambda p: at_command_start(cmd, p) and not any(a <= p < b for a, b in spans)  # noqa: E731
    out = []
    for m in GH.finditer(cmd):
        if not real(m.start()):
            continue
        end = segment(cmd, m.start())
        kind = 'release' if m.group(3) else 'gh'
        if kind == 'release':
            b = option_bodies(cmd, m.start(), end, ['--notes', '-n'], ['--notes-file', '-F'], env, cwd)
        else:
            b = option_bodies(cmd, m.start(), end, ['--body', '-b', '--comment', '-c'], ['--body-file', '-F'], env, cwd)
        out.append((kind, b))
    for m in GIT_COMMIT.finditer(cmd):
        if not real(m.start()):
            continue
        end = segment(cmd, m.start())
        b = option_bodies(cmd, m.start(), end, ['-m', '--message'], ['-F', '--file'], env, cwd)
        if b is not None and b:
            b = ['\n\n'.join(b)]      # -m 여러 개는 문단으로 이어 붙는다
        out.append(('commit', b))
    return out


# ---------- 모드 ----------

def mode_pre(inp):
    cmd = (inp.get('tool_input') or {}).get('command') or ''
    if not (GH.search(cmd) or GIT_COMMIT.search(cmd)):
        return 0
    # 명령 맨 앞에 붙인 경우만 인정한다. 본문 글 안에 이 문구가 있어도 통과시키면 안 된다(2026-09-28 실사용에서 발견)
    if re.search(r'(?:^|[;&|\n])\s*FORMAT_GUARD_SKIP=1\s+(?:gh|git)\b', cmd):
        log('사용자 승인 통과(SKIP)', cmd)
        return 0
    cwd = inp.get('cwd') or os.getcwd()
    cram = load_cram(cwd)
    hits_all = []
    for kind, bodies in targets(cmd, cwd):
        if bodies is None:
            log(f'본문을 꺼내지 못해 통과({kind})', cmd)
            continue
        for body in bodies:
            hits_all += check_text(body, kind, cram)
    if hits_all:
        report(hits_all, '게시할 본문')
        return 2
    return 0


def mode_post(inp):
    ti = inp.get('tool_input') or {}
    path = ti.get('file_path') or ''
    if not path.lower().endswith('.md'):
        return 0
    if 'edits' in ti:
        text = '\n'.join(e.get('new_string', '') for e in ti['edits'])
    else:
        text = ti.get('content') if 'content' in ti else ti.get('new_string', '')
    if not text:
        return 0
    cram = load_cram(inp.get('cwd') or os.path.dirname(path))
    hits = check_text(text, 'md', cram)
    if hits:
        report(hits, f'{os.path.basename(path)}에 새로 쓴 내용')
        return 2
    return 0


def mode_scan(kind, files):
    cram = load_cram(os.getcwd())
    n = 0
    for f in files:
        with io.open(f, encoding='utf-8') as fh:
            for ln, k, t in check_text(fh.read(), kind, cram):
                print(f'{f}:{ln}: [{k}] {t[:110]}')
                n += 1
    return 1 if n else 0


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    if mode == 'scan':
        return mode_scan(sys.argv[2], sys.argv[3:])
    try:
        inp = json.loads(sys.stdin.read() or '{}')
        return mode_pre(inp) if mode == 'pre' else mode_post(inp) if mode == 'post' else 0
    except Exception as e:  # 검사기 오류가 작업을 막지 않게, 통과시키고 기록만
        log(f'검사기 오류 {type(e).__name__}: {e}')
        return 0


if __name__ == '__main__':
    sys.exit(main())
