#!/usr/bin/env python3
"""문서 낡음 알림 훅 본체(Issue #219). doc-drift-check.sh가 `git commit`일 때만 부른다.

저장소 구조를 가정하지 않고 이번 커밋의 변경 목록에서 출발한다. 경고만 하고 커밋은 막지 않는다.
  1. 삭제·이름변경된 경로(디렉터리가 통째로 사라졌으면 폴더 단위)가 추적 중인 다른 .md에 남았는지(백틱·본문·상대 링크)
  2. 이번에 올리는 .md의 상대 링크 대상 파일이 있는지
  3. 이번에 올리는 CHANGELOG.md의 릴리즈된 버전 섹션에 "다음 컷"이 남았는지
제외는 CHANGELOG.md(옛 이름이 정당하게 남는 기록)와 node_modules·dist뿐이고 설정 옵션은 없다.
슬래시 없는 단순 이름은 산문과 겹쳐 오탐이 많아 보지 않는다. 오류는 조용히 통과시키고 hook-errors.log에만 남긴다.
파이썬 3.6에서도 돈다(Rocky Linux 8 기본 3.6.8).
"""
import json
import os
import posixpath
import re
import subprocess
import sys
from urllib.parse import unquote

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hooklib  # noqa: E402

HOOK = 'doc-drift-check'
EXCLUDE_NAMES = ('CHANGELOG.md',)
EXCLUDE_DIRS = ('node_modules', 'dist')
MAX_REPORT = 10
MAX_BYTES = 1000000

# git add·commit 호출. 따옴표·heredoc 안은 가린 사본에서 찾는다
GIT = re.compile(r'\bgit((?:\s+(?:-C\s+(?:"[^"]*"|\'[^\']*\'|\S+)|-c\s+\S+|--no-pager|--no-optional-locks))*)\s+(commit|add)\b([^\n;&|]*)')
OPT_C = re.compile(r'-C\s+("[^"]*"|\'[^\']*\'|\S+)')
ALL_FLAG = re.compile(r'(?:^|\s)(?:-[A-Za-z]*a[A-Za-z]*|--all)(?=\s|$)')
LINK = re.compile(r'\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)')
REFDEF = re.compile(r'^\s{0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s|$)')
SCHEME = re.compile(r'^[A-Za-z][A-Za-z0-9+.-]*:')
HEADING = re.compile(r'^##\s+\[?([^\]\s]+)')


def git(root, *args):
    p = subprocess.run(['git', '-c', 'core.quotepath=off', '-C', root] + list(args),
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=8)
    return p.stdout.decode('utf-8', 'replace') if p.returncode == 0 else ''


def native_path(p):
    """Git Bash가 쓰는 `/c/Users/...` 꼴을 윈도우 파이썬이 읽는 `C:/Users/...`로 바꾼다(윈도우 밖은 그대로)."""
    m = re.match(r'^/([A-Za-z])(?:/(.*))?$', p) if os.name == 'nt' else None
    return '%s:/%s' % (m.group(1).upper(), m.group(2) or '') if m else p


def parse_command(cmd):
    """(commit이 있는지, widen, -C 경로). widen=1은 commit -a, 2는 git add가 같은 명령에 있음."""
    masked = hooklib.mask_heredocs(hooklib.quote_mask(cmd))
    commit, widen, cdir = False, 0, ''
    for m in GIT.finditer(masked):
        if not hooklib.at_command_start(masked, m.start()):
            continue
        c = OPT_C.findall(cmd[m.start(1):m.end(1)])
        if c:
            cdir = c[-1].strip('"\'')
        if m.group(2) == 'add':
            widen = 2
        else:
            commit = True
            if widen == 0 and ALL_FLAG.search(m.group(3)):
                widen = 1
    return commit, widen, cdir


def name_status(out):
    t = out.split('\0')
    res, i = [], 0
    while i < len(t) and t[i]:
        s = t[i][0]
        if s in 'RC' and i + 2 < len(t):
            res.append((s, t[i + 1], t[i + 2]))
            i += 3
        elif i + 1 < len(t):
            res.append((s, t[i + 1], None))
            i += 2
        else:
            break
    return res


def excluded(path):
    parts = path.split('/')
    return parts[-1] in EXCLUDE_NAMES or any(p in EXCLUDE_DIRS for p in parts[:-1])


def read_lines(path):
    try:
        if os.path.getsize(path) > MAX_BYTES:
            return []
        with open(path, encoding='utf-8', errors='replace') as f:
            return f.read().split('\n')
    except OSError:
        return []


def link_targets(line):
    """한 줄의 상대 링크 대상들(코드 조각 안은 뺀다). 외부 주소·앵커·절대 경로·자리표시자는 뺀다."""
    plain = re.sub(r'`[^`]*`', '', line)
    raw = LINK.findall(plain)
    m = REFDEF.match(plain)
    if m:
        raw.append(m.group(1))
    out = []
    for t in raw:
        if SCHEME.match(t) or t.startswith(('#', '/')):
            continue
        t = unquote(re.split(r'[#?]', t)[0])
        if t and not any(ch in t for ch in '<{*$'):
            out.append(t)
    return out


def resolve(rel_file, target):
    p = posixpath.normpath(posixpath.join(posixpath.dirname(rel_file), target))
    return None if p.startswith('..') else p


def removed_dirs(root, removed):
    """사라진 파일이 직접 들어 있던 폴더 중 디스크에서 없어진 것(겹치면 가장 얕은 것).
    조상 폴더까지 올라가지 않는다. drafts/skills/x가 비어도 drafts/skills/를 가리키는 일반 설명은 낡은 게 아니다."""
    dirs = set(posixpath.dirname(p) for p in removed)
    dirs = set(d for d in dirs if d and not os.path.isdir(os.path.join(root, d)))
    return set(d for d in dirs if not any(o != d and d.startswith(o + '/') for o in dirs))


def needle_regex(files, dirs):
    alts = []
    for n in sorted(set(files) | set(d if '/' in d else d + '/' for d in dirs), key=len, reverse=True):
        alts.append(re.escape(n) + ('' if n.endswith('/') else r'(?![A-Za-z0-9_\-]|\.[A-Za-z0-9])'))
    if not alts:
        return None
    return re.compile(r'(?<![A-Za-z0-9_.\-/])(?:\.{1,2}/)*(?:' + '|'.join(alts) + ')')


def stale_references(root, removed):
    removed = [p for p in removed if not os.path.exists(os.path.join(root, p))]
    dirs = removed_dirs(root, removed)
    files = set(p for p in removed if '/' in p and not any(p.startswith(d + '/') for d in dirs))
    rx = needle_regex(files, dirs)
    if rx is None:
        return []
    found, seen = [], set()
    tracked = git(root, 'ls-files', '-z', '--', '*.md').split('\0')
    for rel in tracked:
        if not rel or excluded(rel) or not os.path.isfile(os.path.join(root, rel)):
            continue
        for n, line in enumerate(read_lines(os.path.join(root, rel)), 1):
            hit = None
            m = rx.search(line)
            if m:
                hit = m.group(0) + re.match(r'[A-Za-z0-9_./\-]*', line[m.end():]).group(0).rstrip('.')   # 폴더만 사라졌어도 문서에 적힌 경로 전체를 보인다
            else:
                for t in link_targets(line):
                    r = resolve(rel, t)
                    if r and (r in files or r in dirs or any(r.startswith(d + '/') for d in dirs)):
                        hit = t
                        break
            if hit and (rel, n) not in seen:
                seen.add((rel, n))
                found.append('%s:%d → %s' % (rel, n, hit))
    return found


def ignored(root, rel):
    """.gitignore 대상(실행하면 생기는 파일)은 저장소에 없어도 깨진 링크로 보지 않는다. kolo_pwa 수집기 README 사례."""
    p = subprocess.run(['git', '-C', root, 'check-ignore', '-q', '--', rel], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=8)
    return p.returncode == 0


def broken_links(root, md_paths):
    found = []
    for rel in md_paths:
        if excluded(rel):
            continue
        fenced = False
        for n, line in enumerate(read_lines(os.path.join(root, rel)), 1):
            if line.lstrip().startswith(('```', '~~~')):
                fenced = not fenced
                continue
            if fenced:
                continue
            for t in link_targets(line):
                r = resolve(rel, t)
                if r and not os.path.exists(os.path.join(root, r)) and not ignored(root, r):
                    found.append('%s:%d → %s' % (rel, n, t))
    return found


def next_cut_phrases(root, md_paths):
    found = []
    for rel in md_paths:
        if posixpath.basename(rel) != 'CHANGELOG.md':
            continue
        released = False
        for n, line in enumerate(read_lines(os.path.join(root, rel)), 1):
            h = HEADING.match(line)
            if h:
                released = h.group(1).lower() != 'unreleased'
            elif released and '다음 컷' in line:
                found.append('%s:%d' % (rel, n))
    return found


def main():
    inp = hooklib.read_input()
    cwd = inp.get('cwd') or os.getcwd()
    commit, widen, cdir = parse_command(hooklib.command_of(inp))
    if not commit:
        return
    base = os.path.join(cwd, native_path(cdir)) if cdir else cwd
    root = git(base, 'rev-parse', '--show-toplevel').strip()
    if not root:
        return
    changes = name_status(git(root, 'diff', '--cached', '--name-status', '-z', '-M'))
    if widen:
        changes += name_status(git(root, 'diff', '--name-status', '-z', '-M'))
    removed = [a for s, a, b in changes if s in 'DR']
    md = set(b or a for s, a, b in changes if s in 'AMRC' and (b or a).endswith('.md'))
    if widen == 2:
        md |= set(p for p in git(root, 'ls-files', '--others', '--exclude-standard', '-z').split('\0') if p.endswith('.md'))
    md = sorted(p for p in md if os.path.isfile(os.path.join(root, p)))

    sections = []
    for title, items in (('이번 커밋에서 사라진 경로가 남은 문서', stale_references(root, removed) if removed else []),
                         ('이번에 올리는 문서의 링크 대상이 없음', broken_links(root, md)),
                         ('릴리즈된 CHANGELOG 섹션에 "다음 컷" 문구가 남음', next_cut_phrases(root, md))):
        if items:
            shown = items[:MAX_REPORT]
            more = '\n  … 외 %d건' % (len(items) - MAX_REPORT) if len(items) > MAX_REPORT else ''
            sections.append('- %s (%d건)\n  %s%s' % (title, len(items), '\n  '.join(shown), more))
    if not sections:
        return
    body = '[문서 낡음 경고] 이번 커밋과 문서가 어긋난 곳이 있습니다. 같은 커밋에서 고치거나, 의도한 것이면 무시하세요(경고만 하고 커밋은 막지 않음).\n' + '\n'.join(sections)
    print(json.dumps({'systemMessage': '[문서 낡음 경고] %d가지 항목, 자세한 내용은 Claude에게 전달됨' % len(sections),
                      'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'additionalContext': body}}, ensure_ascii=False))


if __name__ == '__main__':
    try:
        main()
    except Exception as e:  # 경고용 훅이라 오류가 나도 커밋 흐름을 막지 않는다
        hooklib.log_error(HOOK, e)
    sys.exit(0)
