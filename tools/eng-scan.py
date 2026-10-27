#!/usr/bin/env python3
"""대화 기록의 도구 호출 사이 진행 설명 중 영어 우세 블록 비율을 월별로 센다(Issue #222·#223 효과 측정).
  python3 tools/eng-scan.py [--examples N]
기준: 코드·링크를 뺀 뒤 한글×3 < 알파벳이고 알파벳 15자 이상이면 영어 우세. 서브에이전트 블록과 10MB 넘는 기록은 뺀다.
"""
import argparse, collections, glob, json, os, re

HANGUL = re.compile('[가-힣]')
STRIP = re.compile(r'```.*?```|`[^`]*`|\[[^\]]*\]\([^)]*\)|https?://\S+', re.S)

ap = argparse.ArgumentParser()
ap.add_argument('--examples', type=int, default=10, help='영어 우세 블록 예시를 몇 개 보일지')
args = ap.parse_args()

files = glob.glob(os.path.expanduser('~/.claude/projects/*/*.jsonl'))
total = collections.Counter()
english = collections.Counter()
skipped = 0
examples = []
for path in files:
    if os.path.getsize(path) > 10000000:
        skipped += 1
        continue
    with open(path, encoding='utf-8', errors='replace') as fh:
        for line in fh:
            if '"type":"assistant"' not in line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get('type') != 'assistant' or d.get('isSidechain'):
                continue
            content = d.get('message', {}).get('content')
            if not isinstance(content, list):
                continue
            month = str(d.get('timestamp', ''))[:7] or '날짜없음'
            for block in content:
                if block.get('type') != 'text' or not block.get('text', '').strip():
                    continue
                text = STRIP.sub(' ', block['text'])
                total[month] += 1
                ko = len(HANGUL.findall(text))
                la = len(re.findall('[A-Za-z]', text))
                if la >= 15 and ko * 3 < la:
                    english[month] += 1
                    examples.append((month, block['text'].strip().replace('\n', ' ')[:80]))

print('파일 %d개, 10MB 초과로 건너뜀 %d개' % (len(files), skipped))
print('월 | 텍스트 블록 | 영어 우세 | 비율')
for m in sorted(total):
    print('%s | %d | %d | %.1f%%' % (m, total[m], english[m], 100.0 * english[m] / total[m]))
all_total = sum(total.values())
if all_total == 0:
    raise SystemExit('검사한 텍스트 블록이 0개라 미검증')
print('합계 | %d | %d | %.1f%%' % (all_total, sum(english.values()), 100.0 * sum(english.values()) / all_total))
for m, e in examples[-args.examples:]:
    print('-', m, e)
