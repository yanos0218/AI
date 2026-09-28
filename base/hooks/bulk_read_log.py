"""bulk-read-log 본체(Issue #144). 서브에이전트에 맡기지 않고 직접 실행한 대량 조회 명령을 기록만 한다.
기록 훅이라 오류가 나면 조용히 통과한다(기록 한 줄이 빠질 뿐)."""
import datetime
import io
import os
import re

import hooklib as h

PATTERN = re.compile(r'gh\s+issue\s+list[^\n]*--json[^\n]*(body|comments)|gh\s+api[^\n]*/(issues|comments)[^\n]*--jq'
                     r'|--limit\s+([2-9][0-9]|[0-9]{3,})|git\s+log[^\n]*-p[^\n]*--all')
HEADER = ('# 대량 조회 로그 (bulk-read-log 훅이 자동 기록)\n\n서브에이전트 위임 없이 직접 실행한, 대량 조회로 보이는 명령들. '
          '쌓인 개수가 session-start-check.sh 기준을 넘으면 다음 세션에서 알려준다. 검토 후 비운다(월 점검 3번과 같은 방식).\n\n'
          '| 시각 | 명령 | 작업 폴더 |\n| --- | --- | --- |\n')


def main():
    inp = h.read_input()
    if inp.get('agent_id'):          # 서브에이전트 안의 호출은 위임한 것이라 대상 아님(Issue #134)
        return
    cmd = h.command_of(inp)
    # 따옴표·heredoc 안의 글은 실행되는 명령이 아니므로 가리고 본다
    if not PATTERN.search(h.mask_heredocs(h.quote_mask(cmd))):
        return
    log = os.path.join(h.HOME, 'bulk-read-log.md')
    new = not os.path.isfile(log)
    with io.open(log, 'a', encoding='utf-8', newline='\n') as f:
        if new:
            f.write(HEADER)
        f.write(f"| {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')} | {h.one_line(cmd)} | {inp.get('cwd') or os.getcwd()} |\n")


if __name__ == '__main__':
    try:
        main()
    except Exception as e:  # 기록 훅: 실패해도 작업을 막지 않는다
        h.log_error('bulk-read-log', e)
