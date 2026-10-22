#!/usr/bin/env python3
"""설치본 settings.json과 base/settings.example.json 병합·대조 (Issue #194).

  settings_merge.py install <설치본 settings.json> <base settings.example.json> [--dry-run]
  settings_merge.py check   <설치본 settings.json> <base settings.example.json>

규칙: 사용자가 직접 넣은 값은 지우지 않는다.
  - permissions의 목록(allow·ask·deny)은 합집합. 사용자 항목을 먼저 두고 없는 base 항목을 뒤에 붙인다.
  - hooks는 base 훅 스크립트를 가리키는 항목만 base 것으로 바꾸고, 그 밖의 사용자 훅은 남긴다.
  - env는 base 키만 덮고 사용자 키는 남긴다.
  - statusLine·model·effortLevel·modelSettings·$schema는 base 값으로 맞춘다(기본 모델 고정, Issue #187).
  - 값이 바뀌어 다시 쓸 때는 settings.json.bak.<시각>으로 먼저 백업한다.
"""
import collections
import io
import json
import os
import shutil
import sys
import time

OD = collections.OrderedDict
SCALAR_KEYS = ('$schema', 'statusLine', 'model', 'effortLevel', 'modelSettings')


def load(path):
    with io.open(path, encoding='utf-8') as f:
        return json.load(f, object_pairs_hook=OD)


def validate(cur):
    """직접 편집한 파일의 모양이 예상과 다르면 ValueError. 병합하다 오류를 내지 않고 이유를 알리기 위함."""
    def need(cond, msg):
        if not cond:
            raise ValueError(msg)
    need(isinstance(cur, dict), '최상위가 객체가 아님')
    if 'permissions' in cur:
        need(isinstance(cur['permissions'], dict), 'permissions가 객체가 아님')
        for k, v in cur['permissions'].items():
            need(not isinstance(v, (str, type(None))) or k == 'defaultMode', 'permissions.%s 형식이 이상함' % k)
    if 'hooks' in cur:
        need(isinstance(cur['hooks'], dict), 'hooks가 객체가 아님')
        for event, groups in cur['hooks'].items():
            need(isinstance(groups, list), 'hooks.%s가 목록이 아님' % event)
            for g in groups:
                need(isinstance(g, dict) and isinstance(g.get('hooks', []), list)
                     and all(isinstance(h, dict) for h in g.get('hooks', [])), 'hooks.%s 항목 형식이 이상함' % event)
    if 'env' in cur:
        need(isinstance(cur['env'], dict), 'env가 객체가 아님')


def script_name(command):
    """훅 명령의 소유 식별자. .claude/hooks/ 아래 스크립트면 그 이름, 아니면 명령 전체."""
    marker = '.claude/hooks/'
    c = command.replace('\\', '/')
    i = c.find(marker)
    if i < 0:
        return command
    rest = c[i + len(marker):].split()
    return rest[0].strip('"\'') if rest else command


def owned_names(base_hooks):
    names = set()
    for groups in base_hooks.values():
        for g in groups:
            for h in g.get('hooks', []):
                names.add(script_name(h.get('command', '')))
    return names


def merge_hooks(cur, base):
    owned = owned_names(base)
    out = OD()
    for event, groups in base.items():
        out[event] = list(groups)
    for event, groups in cur.items():
        kept = []
        for g in groups:
            mine = [h for h in g.get('hooks', []) if script_name(h.get('command', '')) not in owned]
            if mine:
                ng = OD(g)
                ng['hooks'] = mine
                kept.append(ng)
        if kept:
            out.setdefault(event, [])
            out[event] = out[event] + kept
    return out


def merge_permissions(cur, base):
    out = OD(cur)
    for k, v in base.items():
        if isinstance(v, list):
            have = list(out.get(k, []))
            out[k] = have + [x for x in v if x not in have]
        else:
            out[k] = v
    return out


def merge(cur, base):
    new = OD(cur)
    changed = []
    if 'permissions' in base:
        v = merge_permissions(cur.get('permissions', OD()), base['permissions'])
        if v != cur.get('permissions'):
            new['permissions'] = v
            changed.append('permissions')
    if 'hooks' in base:
        v = merge_hooks(cur.get('hooks', OD()), base['hooks'])
        if v != cur.get('hooks'):
            new['hooks'] = v
            changed.append('hooks')
    if 'env' in base:
        v = OD(cur.get('env', OD()))
        v.update(base['env'])
        if v != cur.get('env'):
            new['env'] = v
            changed.append('env')
    for k in SCALAR_KEYS:
        if k in base and cur.get(k) != base[k]:
            new[k] = base[k]
            changed.append(k)
    return new, changed


def extras(cur, base):
    """사용자 쪽에만 있는 항목 요약(정보용)."""
    msgs = []
    bp, cp = base.get('permissions', {}), cur.get('permissions', {})
    for k, v in cp.items():
        if isinstance(v, list):
            only = [x for x in v if x not in bp.get(k, [])]
            if only:
                msgs.append('permissions.%s 설치본에만 있음 %d개(사용자 추가이거나 base에서 빠진 항목)' % (k, len(only)))
    owned = owned_names(base.get('hooks', {}))
    n = sum(1 for gs in cur.get('hooks', {}).values() for g in gs for h in g.get('hooks', [])
            if script_name(h.get('command', '')) not in owned)
    if n:
        msgs.append('hooks 사용자 훅 %d개 보존 중' % n)
    top = sorted(set(cur) - set(base))
    if top:
        msgs.append('기기별 키: %s' % top)
    return msgs


def utf8_stdio():
    """Windows는 출력이 파이프일 때 cp1252·cp949 등으로 나가 한글에서 UnicodeEncodeError가 난다(CI windows-latest에서 확인).

    파이썬 3.6에는 reconfigure가 없어 스트림을 UTF-8 래퍼로 바꾼다(RHEL 8 계열 기본 3.6.8, Issue #202).
    """
    for name in ('stdout', 'stderr'):
        stream = getattr(sys, name)
        try:
            stream.reconfigure(encoding='utf-8')
        except AttributeError:
            setattr(sys, name, io.TextIOWrapper(stream.buffer, encoding='utf-8', errors=stream.errors,
                                                line_buffering=stream.line_buffering))


def main(argv):
    utf8_stdio()
    if len(argv) < 4 or argv[1] not in ('install', 'check'):
        sys.stderr.write(__doc__)
        return 2
    mode, dst, src = argv[1], argv[2], argv[3]
    dry = '--dry-run' in argv[4:]
    exists = os.path.exists(dst)
    try:
        base = load(src)
        cur = load(dst) if exists else OD()
        validate(cur)
    except ValueError as e:  # JSONDecodeError 포함
        print('  settings.json 병합 실패, 건너뜀: %s (%s)' % (e, dst))
        print('  → 파일을 고친 뒤(주석·끝 쉼표 없는 JSON) 다시 실행. 파일은 건드리지 않았음')
        return 3
    new, changed = merge(cur, base)
    if mode == 'check':
        for k in ('permissions', 'hooks', 'env') + SCALAR_KEYS:
            if k in base:
                print('  %-8s %s' % ('DIFF' if k in changed else 'same', k))
        for m in extras(cur, base):
            print('  정보     ' + m)
        return 1 if changed else 0
    if not changed and exists:
        print('  settings.json 병합: 변경 없음')
        return 0
    if dry:
        print('  (dry) settings.json 병합: ' + ', '.join(changed) + ' 갱신')
        return 0
    if exists:
        bak = '%s.bak.%s' % (dst, time.strftime('%Y%m%d%H%M%S'))
        shutil.copy2(dst, bak)
        print('  settings.json 백업: ' + bak)
    with io.open(dst, 'w', encoding='utf-8', newline='\n') as f:
        f.write(json.dumps(new, ensure_ascii=False, indent=2) + '\n')
    print('  settings.json 병합: ' + ', '.join(changed) + ' 갱신')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
