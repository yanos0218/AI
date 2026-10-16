"""measure-model.sh의 집계 — check(계속·다음 모델·중단 판정)와 report(모델별 표)."""
import glob, io, json, os, re, sys


def util(path):
    """probe 세션의 rate_limit_event에서 (5시간, 주간, 5시간 초기화 시각)을 읽는다."""
    for line in io.open(path, encoding='utf-8'):
        try: e = json.loads(line)
        except ValueError: continue
        if e.get('type') == 'rate_limit_event':
            w = (e.get('rate_limit_info') or {}).get('unifiedWindows') or {}
            f, s = w.get('five_hour') or {}, w.get('seven_day') or {}
            if 'utilization' in f:
                return f['utilization'], s.get('utilization'), f.get('resetsAt')
    return None


def runs(out):
    rows = []
    for line in io.open(os.path.join(out, 'runs.txt'), encoding='utf-8'):
        seq, model = line.split()
        a, b = util(os.path.join(out, f'probe-{int(seq) - 1}.jsonl')), util(os.path.join(out, f'probe-{seq}.jsonl'))
        rows.append({'seq': int(seq), 'model': model, 'before': a, 'after': b})
    return rows


def check(out, model, target):
    rows = runs(out); last = rows[-1]
    if not last['before'] or not last['after']:
        return 'stop 사용률을 읽지 못함(probe 결과 확인)'
    if last['before'][2] != last['after'][2]:
        return 'stop 5시간 창이 초기화됨 — 이 회차는 버리고 나중에 다시 측정'
    if (last['after'][1] or 0) >= 0.95:
        return f"stop 주간 사용률 {last['after'][1]:.0%} — 한도 보호를 위해 중단"
    mine = [r for r in rows if r['model'] == model]
    used = round((mine[-1]['after'][0] - mine[0]['before'][0]) * 100, 1)
    return f"{'next' if used >= float(target) else 'more'} {model} 누적 {used}%p (5시간 {last['after'][0]:.0%}, 주간 {last['after'][1]:.0%})"


def session(path, answers):
    tok = {'in': 0, 'out': 0, 'cache_read': 0, 'cache_write': 0}; turns = dur = 0; text = ''; seen = set()
    for line in io.open(path, encoding='utf-8'):
        try: e = json.loads(line)
        except ValueError: continue
        if e.get('type') == 'assistant' and e['message'].get('id') not in seen:
            seen.add(e['message'].get('id')); u = e['message'].get('usage') or {}
            tok['in'] += u.get('input_tokens', 0); tok['out'] += u.get('output_tokens', 0)
            tok['cache_read'] += u.get('cache_read_input_tokens', 0); tok['cache_write'] += u.get('cache_creation_input_tokens', 0)
        elif e.get('type') == 'result':
            turns, dur, text = e.get('num_turns', 0), e.get('duration_ms', 0) / 1000, e.get('result') or ''
    found = set(); false = 0
    for f, ln, rule in re.findall(r'(doc\d+\.md)\s*:\s*(\d+)\s*:\s*(\d+)', text):
        hit = [i for i, (af, al, ar) in enumerate(answers) if af == f and int(rule) == ar and abs(int(ln) - al) <= 1]
        if hit: found.add(hit[0])
        else: false += 1
    return tok, turns, dur, len(found), false


def report(out, answers_path):
    answers = json.load(io.open(answers_path, encoding='utf-8'))
    by = {}
    print('| 회차 | 모델 | 5시간 %p | 주간 %p | 토큰(입력/출력/캐시읽기/캐시쓰기) | 턴 | 초 | 정답 | 오답 |')
    print('| --- | --- | --- | --- | --- | --- | --- | --- | --- |')
    for r in runs(out):
        tok, turns, dur, found, false = session(os.path.join(out, f"run-{r['seq']}.jsonl"), answers)
        d5 = d7 = None
        if r['before'] and r['after'] and r['before'][2] == r['after'][2]:
            d5 = round((r['after'][0] - r['before'][0]) * 100, 1); d7 = round((r['after'][1] - r['before'][1]) * 100, 1)
        print(f"| {r['seq']} | {r['model']} | {d5} | {d7} | {tok['in']}/{tok['out']}/{tok['cache_read']}/{tok['cache_write']} | {turns} | {dur:.0f} | {found}/{len(answers)} | {false} |")
        b = by.setdefault(r['model'], {'n': 0, 'd5': 0.0, 'd7': 0.0, 'ok': 0, 'found': 0, 'false': 0, 'out': 0})
        b['n'] += 1; b['found'] += found; b['false'] += false; b['out'] += tok['out']
        if d5 is not None: b['ok'] += 1; b['d5'] += d5; b['d7'] += d7
    print('\n| 모델 | 회차 | 1회당 5시간 %p | 1회당 주간 %p | 1회당 출력 토큰 | 정답률 | 오답 합계 |')
    print('| --- | --- | --- | --- | --- | --- | --- |')
    for m, b in by.items():
        k = b['ok'] or 1
        print(f"| {m} | {b['n']} | {b['d5'] / k:.2f} | {b['d7'] / k:.2f} | {b['out'] // b['n']} | {b['found']}/{b['n'] * len(answers)} | {b['false']} |")
    print('\n- 각 회차 몫에는 뒤따르는 probe(Haiku 짧은 질문) 1회가 포함된다. 두 모델에 같은 크기로 들어간다.')


if __name__ == '__main__':
    if sys.argv[1] == 'check': print(check(sys.argv[2], sys.argv[3], sys.argv[4]))
    else: report(sys.argv[2], sys.argv[3])
