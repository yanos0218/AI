#!/usr/bin/env python3
"""base/rules/docs-format.md의 목록 줄바꿈 규칙 위반(콜론·em-dash 크램)을 찾는다.
tools/check-cram.sh가 이 파일을 호출한다 — 직접 실행하지 않는다."""
import re
import sys

exceptions_path = sys.argv[1] if len(sys.argv) > 1 else None
try:
    with open(exceptions_path, encoding='utf-8') as f:
        exceptions = {line.strip() for line in f if line.strip() and not line.startswith('#')}
except (FileNotFoundError, TypeError):
    exceptions = set()

colon_pat = re.compile(r'^(\s*(?:[-*]|\d+\.)\s+|\s*)(\*\*[^*]+\*\*|`[^`]+`|[^\s:][^:]{0,40}?)\s*[:：]\s+\S')
enum_hint = re.compile(r'(\d\s*(개|종|가지|건)|둘|셋|넷|다섯|\([0-9]\)|\([a-z]\))')
link_pat = re.compile(r'\[[^\]]*—[^\]]*\]\(')


def paren_depth_at(s, idx):
    depth = 0
    in_code = False
    for i in range(idx):
        c = s[i]
        if c == '`':
            in_code = not in_code
        elif not in_code:
            if c == '(':
                depth += 1
            elif c == ')':
                depth = max(0, depth - 1)
    return depth


def in_backtick(s, idx):
    return s[:idx].count('`') % 2 == 1


def in_link_title(s, idx):
    """em-dash가 마크다운 링크 텍스트 [저자 — 제목](url) 안에 있는지."""
    return bool(link_pat.search(s)) and any(
        m.start() < idx < m.end() for m in link_pat.finditer(s)
    )


def check_line(stripped):
    t = stripped.strip()
    if not t or t.startswith(('#', '>', '|', '```')):
        return None
    if t in exceptions:
        return None
    for m in re.finditer(r'\s—\s', stripped):
        idx = m.start()
        if paren_depth_at(stripped, idx) > 0 or in_backtick(stripped, idx) or in_link_title(stripped, idx):
            continue
        if len(t) > 25:
            return 'emdash'
        break
    m = colon_pat.match(stripped)
    if m:
        colon_idx = stripped.find(':', m.start(2))
        if colon_idx == -1:
            colon_idx = stripped.find('：', m.start(2))
        if colon_idx != -1 and paren_depth_at(stripped, colon_idx) == 0 and not in_backtick(stripped, colon_idx) and len(t) > 25:
            after = stripped[colon_idx + 1:]
            if after.count(',') + after.count('·') >= 1 or enum_hint.search(t):
                return None
            return 'colon'
    return None


def main():
    hits = 0
    code_state = {}
    for raw in sys.stdin:
        raw = raw.rstrip('\n')
        if not raw:
            continue
        parts = raw.split('\t', 3)
        if len(parts) != 4:
            continue
        path, lineno, is_added, content = parts
        in_code = code_state.get(path, False)
        if content.strip().startswith('```'):
            code_state[path] = not in_code
            continue
        if in_code or is_added != '1':
            continue
        kind = check_line(content)
        if kind:
            hits += 1
            print(f"{path}:{lineno}: [{kind}] {content.strip()[:120]}")

    if hits:
        print(f"\n{hits}건 발견. 진짜 크램이면 라벨/설명을 줄바꿈하고, 나열·필드-값 등 예외면:")
        print("  tools/check-cram.sh --add-exception <file> <line-number>")
        sys.exit(1)
    sys.exit(0)


if __name__ == '__main__':
    main()
