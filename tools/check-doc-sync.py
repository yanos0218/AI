#!/usr/bin/env python3
"""문서 갱신 누락 검사(Issue #192). tools/check-docs.sh가 부른다(CI와 커밋 전 검사 공용, 파이썬 한 번 호출).

  1. 존재 대조  파일이 README·operating-flow에 언급되는지 (새 도구·훅·스킬·에이전트·문서를 추가하고 안내를 빼먹는 것)
  2. 깨진 참조  문서 속 백틱 경로가 실제로 있는지 (파일을 지우거나 이름을 바꾸고 참조를 남기는 것)
  3. 개수 대조  README·operating-flow가 적은 훅·스킬·에이전트·권한 개수가 실제와 같은지
  (2번에는 저장소 CLAUDE.md의 @import가 가리키는 파일이 있는지도 들어 있다)

고치지 않고 위반을 한 줄씩 출력한 뒤 종료 코드 1로 끝낸다. 3.8 문법만 쓴다(Rocky Linux 3.9, Windows 기본 인코딩 cp949 대비 UTF-8 출력).
"""
import glob
import io
import json
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except (AttributeError, ValueError):
    pass

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
problems = []


def read(path):
    try:
        with io.open(path, encoding='utf-8') as f:
            return f.read()
    except OSError:
        return ''


def names(pattern):
    return sorted(glob.glob(pattern))


readme = read('README.md')
flow = read('docs/operating-flow.md')

# 1. 존재 대조
for f in names('tools/*.sh'):
    if os.path.basename(f) not in readme:
        problems.append('README에 없음: %s (README 도구 표에 한 줄 추가)' % f)
for f in names('base/hooks/*.sh'):
    b = os.path.basename(f)
    if b not in readme and b not in flow:
        problems.append('README·operating-flow에 없음: %s (훅 목록이나 훅 시점 표에 추가)' % f)
for d in names('base/skills/*/'):
    n = os.path.basename(d.rstrip('/'))
    if not n.startswith('_') and n not in readme:
        problems.append('README에 없음: base/skills/%s (스킬 목록에 추가)' % n)
for f in names('base/agents/*.md'):
    n = os.path.basename(f)[:-3]
    if n not in readme:
        problems.append('README에 없음: base/agents/%s.md (에이전트 목록에 추가)' % n)
for f in names('docs/*.md'):
    if 'docs/' + os.path.basename(f) not in readme:
        problems.append('README 문서 목록에 없음: %s' % f)

# 2. 깨진 참조. 옛 파일 이름이 정당하게 남는 기록 문서(변경 이력·보관 조사·결정 모음)는 뺀다
HISTORICAL = ('CHANGELOG.md', 'docs/decisions.md')
SKIP_DIRS = ('docs/research/', 'tools/test-fixtures/', 'node_modules/', 'dist/')
PATH = re.compile(r'`((?:tools|base|docs|drafts|\.claude|\.github)/[A-Za-z0-9_./-]+\.(?:sh|py|md|json|yml|jsonc|txt))`')
docs = ['README.md', 'CLAUDE.md'] + names('docs/*.md') + ['drafts/README.md']
for f in docs:
    if f in HISTORICAL or not os.path.isfile(f):
        continue
    in_code = False
    for n, line in enumerate(read(f).split('\n'), 1):
        if line.lstrip().startswith('```'):
            in_code = not in_code
            continue
        if in_code:
            continue
        for m in PATH.finditer(line):
            p = m.group(1)
            if '<' in p or '*' in p or '.local.' in p or p.startswith(SKIP_DIRS):   # *.local.*은 저장소마다 생기는 gitignore 파일
                continue
            if not os.path.exists(p):
                problems.append('깨진 참조: %s:%d `%s`' % (f, n, p))

# 2-2. CLAUDE.md의 @import가 가리키는 파일이 있는지. 없으면 조용히 로드가 끊겨 HANDOFF가 세션에 안 들어온다(Issue #191)
for n, line in enumerate(read('CLAUDE.md').split('\n'), 1):
    m = re.match(r'^@(\S+)$', line.strip())
    if m and not os.path.exists(m.group(1)):
        problems.append('깨진 import: CLAUDE.md:%d @%s' % (n, m.group(1)))

# 3. 개수 대조(문구가 바뀌어 패턴이 안 맞으면 조용히 건너뛴다)
def count_check(label, text, pattern, actual, where):
    m = re.search(pattern, text)
    if m and int(m.group(1)) != actual:
        problems.append('개수 불일치: %s %s개로 적었는데 실제는 %d개 (%s)' % (label, m.group(1), actual, where))


hooks = len(names('base/hooks/*.sh'))
skills = len([d for d in names('base/skills/*/') if not os.path.basename(d.rstrip('/')).startswith('_')])
agents = len(names('base/agents/*.md'))
count_check('전역 훅', readme, r'전역 훅 (\d+)개', hooks, 'README')
count_check('훅 셸 입구', flow, r'셸 입구 (\d+)개', hooks, 'docs/operating-flow.md')
count_check('스킬', flow, r'base/skills/\]\([^)]*\) (\d+)개', skills, 'docs/operating-flow.md')
count_check('에이전트', flow, r'base/agents/\]\([^)]*\) (\d+)개', agents, 'docs/operating-flow.md')
try:
    perm = json.loads(read('base/settings.example.json')).get('permissions') or {}
    m = re.search(r'허용 (\d+)·차단 (\d+)', flow)
    if m and (int(m.group(1)), int(m.group(2))) != (len(perm.get('allow') or []), len(perm.get('deny') or [])):
        problems.append('개수 불일치: 권한 허용·차단 %s·%s개로 적었는데 실제는 %d·%d개 (docs/operating-flow.md)'
                        % (m.group(1), m.group(2), len(perm.get('allow') or []), len(perm.get('deny') or [])))
except ValueError:
    problems.append('base/settings.example.json이 JSON이 아님')

for p in problems:
    print('doc-sync ' + p)
if problems:
    print('doc-sync %d건. 해당 문서를 같은 커밋에서 고칠 것' % len(problems))
    sys.exit(1)
print('ok  doc-sync (존재·참조·개수 대조)')
