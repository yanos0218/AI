#!/usr/bin/env bash
# 실시간 세션 현황 초안(drafts/skills/live-status) 시험(Issue #213). 실제 claude 없이 가짜 목록과 가짜 실행 파일로 확인한다.
# 실제 화면 모양은 확인하지 못한다. 사용자가 VS Code 통합 브라우저에서 직접 본다.
#   bash tools/test-live-status.sh
# shellcheck disable=SC2034  # 변수는 chk의 eval 문자열 안에서 씀
set -u
cd "$(dirname "${0}")/.." || exit 1
PY="$(command -v python3 || command -v python)"
SK="drafts/skills/live-status"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
IS_WIN=0; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=1;; esac

# 파이썬 쪽 확인은 ASCII 키=0|1 줄로만 출력한다(Windows 파이프의 cp1252에서 한글 출력이 죽는 것을 피함)
pyout="$(IS_WIN="${IS_WIN}" "${PY}" -I - <<'PYEOF' 2>&1
import sys, os, json, time, threading, http.client, tempfile, stat
sys.path.insert(0, 'drafts/skills/live-status/scripts')
import live

def r(key, val):
    print('%s=%d' % (key, 1 if val else 0))

def ag(sid, status, name='n', cwd='/work/proj', started=1000, kind='interactive', pid=1):
    return {'pid': pid, 'cwd': cwd, 'kind': kind, 'startedAt': started, 'sessionId': sid, 'name': name, 'status': status}

def by(snap, sid_short):
    for s in snap['sessions']:
        if s['short_id'] == sid_short:
            return s

# 1. 상태 추적
s = live.State(); t0 = 1000000
s.update([ag('aaaaaaaa-1', 'idle')], None, t0)
x = by(s.snapshot(t0), 'aaaaaaaa')
r('idle_first', x['state'] == 'idle' and x['busy_since_ms'] is None)
s.update([ag('aaaaaaaa-1', 'busy')], None, t0 + 2000)
x = by(s.snapshot(t0 + 2000), 'aaaaaaaa')
r('busy_transition_exact', x['state'] == 'busy' and x['busy_since_ms'] == t0 + 2000 and x['busy_exact'] is True)
s.update([ag('aaaaaaaa-1', 'busy')], None, t0 + 4000)
x = by(s.snapshot(t0 + 4000), 'aaaaaaaa')
r('busy_since_kept', x['busy_since_ms'] == t0 + 2000)
s.update([ag('aaaaaaaa-1', 'idle')], None, t0 + 6000)
x = by(s.snapshot(t0 + 6000), 'aaaaaaaa')
r('idle_clears_busy_since', x['state'] == 'idle' and x['busy_since_ms'] is None)
s2 = live.State()
s2.update([ag('bbbbbbbb-1', 'busy')], None, t0)
x = by(s2.snapshot(t0), 'bbbbbbbb')
r('first_seen_busy_not_exact', x['state'] == 'busy' and x['busy_exact'] is False and x['first_seen_ms'] == t0)

# 1b. busy -> idle 전환 시각(내 차례가 된 시점), 처음부터 idle이면 없음, 다시 busy가 되면 지움
s7 = live.State()
s7.update([ag('77777777-1', 'idle')], None, t0)
r('idle_since_none_when_first_seen_idle', by(s7.snapshot(t0), '77777777')['idle_since_ms'] is None)
s7.update([ag('77777777-1', 'busy')], None, t0 + 2000)
r('idle_since_none_while_busy', by(s7.snapshot(t0 + 2000), '77777777')['idle_since_ms'] is None)
s7.update([ag('77777777-1', 'idle')], None, t0 + 9000)
r('idle_since_recorded_on_busy_to_idle', by(s7.snapshot(t0 + 9000), '77777777')['idle_since_ms'] == t0 + 9000)
s7.update([ag('77777777-1', 'idle')], None, t0 + 11000)
r('idle_since_kept_while_idle', by(s7.snapshot(t0 + 11000), '77777777')['idle_since_ms'] == t0 + 9000)
s7.update([ag('77777777-1', 'busy')], None, t0 + 13000)
r('idle_since_cleared_on_busy_again', by(s7.snapshot(t0 + 13000), '77777777')['idle_since_ms'] is None)

# 2. 사라짐은 연속 3번 안 보여야 끝남, 다시 나타나면 복귀하고 busy_since 유지
s3 = live.State()
s3.update([ag('cccccccc-1', 'idle')], None, t0)
s3.update([ag('cccccccc-1', 'busy')], None, t0 + 2000)
s3.update([], None, t0 + 4000); s3.update([], None, t0 + 6000)
x = by(s3.snapshot(t0 + 6000), 'cccccccc')
r('missing_twice_not_ended', x['state'] == 'busy')
s3.update([], None, t0 + 8000)
x = by(s3.snapshot(t0 + 8000), 'cccccccc')
r('missing_thrice_ended', x['state'] == 'ended' and x['ended_ms'] == t0 + 8000)
s3.update([ag('cccccccc-1', 'busy')], None, t0 + 10000)
x = by(s3.snapshot(t0 + 10000), 'cccccccc')
r('reappear_restores', x['state'] == 'busy' and x['ended_ms'] is None and x['busy_since_ms'] == t0 + 2000)
s3.update([], None, t0 + 12000); s3.update([], None, t0 + 14000); s3.update([], None, t0 + 16000)
s3.update([], None, t0 + 16000 + live.KEEP_ENDED_SEC * 1000 + 1)
r('ended_purged_after_keep', by(s3.snapshot(t0 + 99999999), 'cccccccc') is None)

# 3. 모르는 상태, 정렬
s4 = live.State()
s4.update([ag('dddddddd-1', 'weird', name='d'), ag('eeeeeeee-1', 'idle', name='e'), ag('ffffffff-1', 'busy', name='f')], None, t0)
snap = s4.snapshot(t0)
r('unknown_status', by(snap, 'dddddddd')['state'] == 'unknown' and by(snap, 'dddddddd')['raw_status'] == 'weird')
r('sort_busy_unknown_idle', [x['state'] for x in snap['sessions']] == ['busy', 'unknown', 'idle'])

# 4. 개인정보: 전체 경로와 전체 세션 ID를 내보내지 않는다
s5 = live.State()
s5.update([ag('12345678-aaaa-bbbb-cccc-1234567890ab', 'busy', cwd='/Users/secret/project'),
           ag('87654321-aaaa-bbbb-cccc-1234567890ab', 'idle', cwd='C:\\Users\\secret\\winproj\\', pid=2)], None, t0)
body = json.dumps(s5.snapshot(t0))
r('no_full_path', 'secret' not in body and 'Users' not in body)
r('no_full_session_id', 'aaaa-bbbb' not in body and 'ab"' not in body)
r('folder_only', '"project"' in body and '"winproj"' in body)

# 5. 오류 상태
s6 = live.State()
s6.update([ag('99999999-1', 'busy')], None, t0)
s6.update(None, 'boom', t0 + 2000)
snap = s6.snapshot(t0 + 2000)
r('error_reported', snap['ok'] is False and snap['error'] == 'boom' and len(snap['sessions']) == 1)

# 5b. 서브에이전트 스캔(이 기기 파일 모양을 본뜬 가짜 폴더)
import shutil, calendar
fx = tempfile.mkdtemp()
os.environ['LIVE_CLAUDE_DIR'] = fx
now = time.time(); now_ms = int(now * 1000)
def iso(t):
    return time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime(t)) + '.%03dZ' % int((t % 1) * 1000)
def mk(proj, sid, aid, typ, title, start_ago, last_ago, finished=None, text='SECRET_PROMPT_TEXT', meta_raw=None, with_log=True, first_ts=True):
    d = os.path.join(fx, 'projects', proj, sid, 'subagents'); os.makedirs(d, exist_ok=True)
    meta = {'agentType': typ, 'description': title, 'spawnDepth': 1}
    if finished is not None:
        meta['finished'] = finished
    with open(os.path.join(d, 'agent-%s.meta.json' % aid), 'w', encoding='utf-8') as f:
        f.write(meta_raw if meta_raw is not None else json.dumps(meta, ensure_ascii=False))
    if not with_log:
        return
    j = os.path.join(d, 'agent-%s.jsonl' % aid)
    with open(j, 'w', encoding='utf-8') as f:
        first = {'type': 'user', 'message': {'content': text}}
        if first_ts:
            first['timestamp'] = iso(now - start_ago)
        f.write(json.dumps(first) + '\n')
        f.write(json.dumps({'type': 'assistant', 'timestamp': iso(now - last_ago), 'message': {'content': 'SECRET_REPLY_TEXT'}}) + '\n')
    os.utime(j, (now - last_ago, now - last_ago))
SA, SB, SZ = 'aaaaaaaa-1111-2222-3333-444444444444', 'bbbbbbbb-1111-2222-3333-444444444444', 'zzzzzzzz-1111-2222-3333-444444444444'
mk('-Users-x-AI', SA, 'run00001', 'researcher', '진행 중 조사', 360, 5)
mk('-Users-x-AI', SA, 'quiet001', 'general-purpose', '긴 실행', 540, 180)
mk('-Users-x-AI', SA, 'fin00001', 'researcher', '끝난 조사', 840, 540, True)
mk('-Users-x-AI', SA, 'old00001', 'Explore', '오래된 기록', 1560, 1200)
mk('-Users-x-AI', SA, 'outside1', 'Explore', '창 밖', 9000, 7200)
mk('-Users-x-OldProj', SZ, 'gone0001', 'researcher', '끝난 세션의 조사', 1200, 900, True)
mk('-Users-x-AI', SA, 'broken01', 'x', 'x', 10, 5, meta_raw='{not json')
mk('-Users-x-AI', SA, 'nolog001', 'Explore', '기록 파일 없음', 0, 0, with_log=False)
mk('-Users-x-AI', SA, 'nots0001', 'Explore', '첫 줄에 시각 없음', 0, 20, first_ts=False)
agents, unreadable = live.scan_subagents(now_ms)
ids = set(a['agent_id'] for a in agents)
r('scan_window_excludes_old', 'outside1' not in ids and 'run00001' in ids)
r('scan_unreadable_counted', unreadable == 1 and 'broken01' not in ids)
r('scan_no_log_uses_meta', 'nolog001' in ids)
r('scan_first_line_without_ts_falls_back', [a for a in agents if a['agent_id'] == 'nots0001'][0]['started_ms'] is not None)
rf = live.State()
rf.update([ag(SA, 'busy', name='ai-10', cwd='/Users/x/AI')], None, now_ms)
rf.update_agents(agents, unreadable)
snap = rf.snapshot(now_ms)
main = [s for s in snap['sessions'] if s['name'] == 'ai-10'][0]
kinds = dict((a['id'], (a['state'], a['exact'])) for a in main['agents'])
r('agent_running', kinds['run00001'] == ('running', True))
r('agent_quiet', kinds['quiet001'][0] == 'quiet')
r('agent_finished_exact', kinds['fin00001'] == ('ended', True))
r('agent_old_unfinished_ended_estimated', kinds['old00001'] == ('ended', False))
r('agent_order_running_first', [a['state'] for a in main['agents']][0] == 'running' and [a['state'] for a in main['agents']][-1] == 'ended')
gone = [s for s in snap['sessions'] if s['state'] == 'gone']
r('gone_session_shown_with_agents', len(gone) == 1 and gone[0]['agents'][0]['id'] == 'gone0001' and gone[0]['folder'] == 'Users-x-OldProj')
r('concurrent_counts_running_and_quiet', snap['concurrent'] == 4)   # 작업 중 3(run00001, nolog001, nots0001) + 조용함 1(quiet001)
r('agents_unreadable_exposed', snap['agents_unreadable'] == 1)
body = json.dumps(snap, ensure_ascii=False)
r('no_transcript_text', 'SECRET' not in body)
r('no_full_agent_or_session_id', SA not in body and 'run00001' in body and 'aaaaaaaa-1111' not in body)
# 부모 세션이 사라진 뒤: 방금까지 쓰던 것은 그대로, 오래 조용하면 끝남(추정)
rg = live.State()
rg.update([ag(SA, 'idle', name='ai-10')], None, now_ms)
for k in range(3):
    rg.update([], None, now_ms + (k + 1) * 2000)
rg.update_agents(agents, 0)
s2 = [s for s in rg.snapshot(now_ms + 6000)['sessions'] if s['name'] == 'ai-10'][0]
k2 = dict((a['id'], a['state']) for a in s2['agents'])
r('parent_gone_quiet_agent_ended', s2['state'] == 'ended' and k2['quiet001'] == 'ended' and k2['run00001'] == 'running')
live.SHOW_TITLES = False
agents2, _ = live.scan_subagents(now_ms)
rt = live.State(); rt.update_agents(agents2, 0)
r('titles_hidden_option', '진행 중 조사' not in json.dumps(rt.snapshot(now_ms), ensure_ascii=False))
live.SHOW_TITLES = True
# 큰 기록 파일은 첫 줄만 읽는다
big = os.path.join(fx, 'projects', '-Users-x-AI', SA, 'subagents')
mk('-Users-x-AI', SA, 'big00001', 'Explore', '큰 기록', 100, 1)
with open(os.path.join(big, 'agent-big00001.jsonl'), 'a', encoding='utf-8') as f:
    f.write(('x' * 1000 + '\n') * 5000)
os.utime(os.path.join(big, 'agent-big00001.jsonl'), (now - 1, now - 1))
t_start = time.time(); live.scan_subagents(now_ms); elapsed = time.time() - t_start
r('big_file_scan_fast', elapsed < 1.0)
r('iso_parse', live.iso_to_ms('2026-10-24T12:08:50.361Z') == calendar.timegm((2026, 10, 24, 12, 8, 50, 0, 0, 0)) * 1000 + 361 and live.iso_to_ms('nope') is None and live.iso_to_ms(None) is None)
r('missing_claude_dir_ok', (lambda: (os.environ.__setitem__('LIVE_CLAUDE_DIR', os.path.join(fx, 'nope')), live.scan_subagents(now_ms))[1])() == ([], 0))
os.environ['LIVE_CLAUDE_DIR'] = fx
shutil.rmtree(fx, ignore_errors=True)

# 5c. 토큰 사용량 요약과 /usage/ 연결
ux = tempfile.mkdtemp()
ul = os.path.join(ux, 'usage-log'); os.makedirs(ul)
os.environ['LIVE_CLAUDE_DIR'] = ux
now = time.time()
def hk(ago_h):
    return time.strftime('%Y-%m-%dT%H', time.localtime(now - ago_h * 3600))
def fam(i, o, cache=9999999):
    return {'sonnet': {'turns': 1, 'in': i, 'cache': cache, 'out': o}}
hourly = {hk(0): {'AI': {'main': fam(100, 10), 'sub:researcher': fam(20, 2)}},
          hk(1): {'AI': {'main': fam(200, 20)}, 'kolo': {'sub:Explore': fam(40, 4)}},
          hk(3): {'AI': {'main': fam(300, 30)}},
          hk(30): {'AI': {'main': fam(5000, 500)}}}
with open(os.path.join(ul, 'hourly.json'), 'w') as f:
    json.dump(hourly, f)
today = time.strftime('%Y-%m-%d', time.localtime(now))
exp5_main = 110 + 220 + 330; exp5_sub = 22 + 44
exp_today_main = sum(v for k, v in ((hk(0), 110), (hk(1), 220), (hk(3), 330), (hk(30), 5500)) if k.startswith(today))
u = live.usage_summary(now)
r('usage_not_enabled_flag_missing', u['available'] is True and u['enabled'] is False)
open(os.path.join(ul, 'enabled'), 'w').close()
u = live.usage_summary(now)
r('usage_enabled_flag', u['enabled'] is True)
r('usage_last5h_sums_in_plus_out_without_cache', u['last5h'] == {'main': exp5_main, 'sub': exp5_sub})
r('usage_today_sums_by_date', u['today']['main'] == exp_today_main)
r('usage_sub_types_top', u['sub_types_today'][0]['type'] in ('researcher', 'Explore') and all(isinstance(x['tokens'], int) for x in u['sub_types_today']))
os.remove(os.path.join(ul, 'hourly.json'))
r('usage_missing_file_not_available', live.usage_summary(now)['available'] is False)
with open(os.path.join(ul, 'hourly.json'), 'w') as f:
    f.write('{broken')
r('usage_broken_file_not_available', live.usage_summary(now)['available'] is False)
with open(os.path.join(ul, 'hourly.json'), 'w') as f:
    json.dump({hk(0): {'AI': {'main': 'bad', 'x': {'sub:y': ['bad']}}}, hk(1): 5}, f)
r('usage_odd_shapes_do_not_crash', live.usage_summary(now)['available'] is True)
live.SHOW_USAGE = False
r('usage_off_option', live.usage_summary(now) == {'shown': False, 'enabled': False, 'available': False})
live.SHOW_USAGE = True
with open(os.path.join(ul, 'dashboard.html'), 'w', encoding='utf-8') as f:
    f.write('<!doctype html><html><head></head><body><h1>old</h1><script src="details.js"></script></body></html>')
with open(os.path.join(ul, 'details.js'), 'w') as f:
    f.write('window.DETAILS={};')
with open(os.path.join(ul, 'state.json'), 'w') as f:
    f.write('{"secret": "SECRET_STATE"}')
live.STATE = live.State()
srv2 = live.make_server(0)
port2 = srv2.server_address[1]
threading.Thread(target=srv2.serve_forever, daemon=True).start()
def get2(path, host=None):
    c = http.client.HTTPConnection('127.0.0.1', port2, timeout=5)
    c.putrequest('GET', path, skip_host=True)
    c.putheader('Host', host if host is not None else '127.0.0.1:%d' % port2)
    c.endheaders()
    resp = c.getresponse(); data = resp.read(); h = dict((k.lower(), v) for k, v in resp.getheaders())
    c.close()
    return resp.status, h, data
code, h, data = get2('/usage')
r('usage_redirect_slash', code == 301 and h.get('location') == '/usage/')
code, h, data = get2('/usage/')
r('usage_page_served_with_nav', code == 200 and b'<h1>old</h1>' in data and data.count(b'live') >= 0 and data.count(b'\xec\x8b\xa4\xec\x8b\x9c\xea\xb0\x84 \xed\x98\x84\xed\x99\xa9') == 1 and data.index(b'<body>') < data.index(b'<h1>'))
r('usage_csp_allows_self_script', "script-src 'self'" in h['content-security-policy'] and 'frame-ancestors' in h['content-security-policy'])
code, h, data = get2('/usage/details.js')
r('usage_js_served', code == 200 and 'javascript' in h['content-type'])
r('usage_other_files_404', all(get2(p)[0] == 404 for p in ('/usage/state.json', '/usage/hourly.json', '/usage/../state.json', '/usage/%2e%2e/state.json', '/usage/requests.json')))
r('usage_bad_host_403', get2('/usage/', 'evil.example:%d' % port2)[0] == 403)
code, h, data = get2('/api/state')
r('api_state_includes_usage', json.loads(data.decode('utf-8'))['usage']['shown'] is True)
live.SHOW_USAGE = False
r('usage_route_404_when_off', get2('/usage/')[0] == 404 and get2('/usage/details.js')[0] == 404)
live.SHOW_USAGE = True
os.remove(os.path.join(ul, 'dashboard.html'))
r('usage_missing_page_404', get2('/usage/')[0] == 404)
srv2.shutdown(); srv2.server_close()
shutil.rmtree(ux, ignore_errors=True)
os.environ.pop('LIVE_CLAUDE_DIR', None)

# 5e. 에이전트 팀(공식 문서 형식으로 만든 가짜 폴더)
tm = tempfile.mkdtemp()
os.environ['LIVE_CLAUDE_DIR'] = tm
r('teams_none_without_folder', live.scan_teams(0) == [])
os.makedirs(os.path.join(tm, 'teams', 'alpha')); os.makedirs(os.path.join(tm, 'tasks', 'alpha'))
with open(os.path.join(tm, 'teams', 'alpha', 'config.json'), 'w') as f:
    json.dump({'members': [{'name': 'lead', 'agentType': 'general-purpose'}, {'name': 'rev'}, 'junk']}, f)
for i, st in enumerate(['pending', 'in_progress', 'completed', 'completed', 'weird']):
    with open(os.path.join(tm, 'tasks', 'alpha', '%d.json' % i), 'w') as f:
        json.dump({'status': st, 'subject': 'SECRET-TITLE'}, f)
with open(os.path.join(tm, 'tasks', 'alpha', 'bad.json'), 'w') as f:
    f.write('{not json')
os.makedirs(os.path.join(tm, 'teams', 'broken'))
with open(os.path.join(tm, 'teams', 'broken', 'config.json'), 'w') as f:
    f.write('[1,2')
tt = live.scan_teams(0)
r('teams_reads_only_valid_team', len(tt) == 1 and tt[0]['name'] == 'alpha')
r('teams_members_tolerant', [m['name'] for m in tt[0]['members']] == ['lead', 'rev'] and tt[0]['members'][0]['type'] == 'general-purpose')
r('teams_task_counts', tt[0]['tasks'] == {'pending': 1, 'in_progress': 1, 'completed': 2, 'other': 1})
r('teams_no_task_text_exported', 'SECRET-TITLE' not in json.dumps(tt))
st = live.State(); st.update_teams(tt)
r('teams_in_snapshot', st.snapshot(1)['teams'][0]['name'] == 'alpha')
os.environ.pop('LIVE_CLAUDE_DIR', None)
shutil.rmtree(tm, ignore_errors=True)

# 5d. 토큰 대시보드 초안 템플릿(drafts/skills/usage-dashboard)
import re, io, subprocess
tpl = io.open('drafts/skills/usage-dashboard/scripts/dashboard.html', encoding='utf-8').read()
def lum(hx):
    hx = hx.lstrip('#'); c = [int(hx[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2])
def ratio(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
light = re.search(r':root\{--bg:(#\w+);--s1:(#\w+);.*?--ink3:(#\w+)', tpl, re.S)
dark = re.search(r'data-theme=dark\]\{--bg:(#\w+);--s1:(#\w+);.*?--ink3:(#\w+)', tpl, re.S)
r('usage_tpl_light_contrast', light is not None and ratio(light.group(3), light.group(2)) >= 4.5 and ratio(light.group(3), light.group(1)) >= 4.5)
r('usage_tpl_dark_contrast', dark is not None and ratio(dark.group(3), dark.group(2)) >= 4.5 and ratio(dark.group(3), dark.group(1)) >= 4.5)
r('usage_tpl_one_placeholder', tpl.count('__DATA__') == 1)
r('usage_tpl_has_headline', 'id="headline"' in tpl and 'function headline()' in tpl)
sizes = [float(x) for x in re.findall(r'font-size:([0-9.]+)px', tpl)]
r('usage_tpl_no_tiny_text', min(sizes) >= 12.0)
td = tempfile.mkdtemp()
sd = os.path.join(td, 'scripts'); os.makedirs(sd)
for fn in ('usage.py',):
    shutil.copy(os.path.join('base/skills/usage-dashboard/scripts', fn), sd)
shutil.copy('drafts/skills/usage-dashboard/scripts/dashboard.html', sd)
logd = os.path.join(td, 'log'); os.makedirs(logd)
with open(os.path.join(logd, 'hourly.json'), 'w') as f:
    json.dump({time.strftime('%Y-%m-%dT%H'): {'AI': {'main': {'sonnet': {'turns': 3, 'in': 5000, 'cache': 90000, 'out': 800}}}}}, f)
env = dict(os.environ); env['USAGE_LOG_DIR'] = logd; env['PYTHONIOENCODING'] = 'utf-8'
try:
    rc = subprocess.call([sys.executable, '-I', os.path.join(sd, 'usage.py'), 'render'], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
except OSError:
    rc = -1
page_path = os.path.join(logd, 'dashboard.html')
page = io.open(page_path, encoding='utf-8').read() if os.path.exists(page_path) else ''
r('usage_tpl_renders_with_base_script', rc == 0 and '__DATA__' not in page and 'function headline()' in page)
shutil.rmtree(td, ignore_errors=True)

# 6. HTTP
live.STATE = live.State()
live.STATE.update([ag('abcdef12-0000-0000-0000-000000000000', 'busy', name='web')], None, int(time.time() * 1000))
srv = live.make_server(0)
port = srv.server_address[1]
threading.Thread(target=srv.serve_forever, daemon=True).start()
def get(path, host=None, method='GET'):
    c = http.client.HTTPConnection('127.0.0.1', port, timeout=5)
    c.putrequest(method, path, skip_host=True)
    c.putheader('Host', host if host is not None else '127.0.0.1:%d' % port)
    c.endheaders()
    resp = c.getresponse(); data = resp.read(); h = dict((k.lower(), v) for k, v in resp.getheaders())
    c.close()
    return resp.status, h, data
code, h, data = get('/')
r('http_root_200_html', code == 200 and 'text/html' in h['content-type'] and b'<html' in data)
code, h, data = get('/api/state')
j = json.loads(data.decode('utf-8'))
r('http_state_json', code == 200 and j['ok'] is True and j['sessions'][0]['name'] == 'web' and j['sessions'][0]['short_id'] == 'abcdef12')
r('http_headers', h['cache-control'] == 'no-store' and "default-src 'none'" in h['content-security-policy'] and h['x-content-type-options'] == 'nosniff')
r('http_csp_allows_data_icon', 'img-src data:' in h['content-security-policy'] and "connect-src 'self'" in h['content-security-policy'])
r('http_localhost_host_ok', get('/api/state', 'localhost:%d' % port)[0] == 200)
r('http_bad_host_403', get('/api/state', 'evil.example:%d' % port)[0] == 403)
r('http_host_without_port_403', get('/api/state', '127.0.0.1')[0] == 403)
r('http_post_405', get('/api/state', method='POST')[0] == 405 and get('/api/state', method='PUT')[0] == 405)
r('http_unknown_404', get('/etc/passwd')[0] == 404 and get('/../live.py')[0] == 404)
r('bind_loopback_only', srv.server_address[0] == '127.0.0.1')
srv.shutdown(); srv.server_close()

# 7. 실제 실행 경로(가짜 실행 파일)는 비Windows에서만
if os.environ.get('IS_WIN') == '1':
    r('fetch_skipped_on_windows', True)
else:
    d = tempfile.mkdtemp()
    def fake(name, body):
        p = os.path.join(d, name)
        with open(p, 'w') as f:
            f.write('#!/usr/bin/env python3\n' + body)
        os.chmod(p, os.stat(p).st_mode | stat.S_IXUSR)
        return p
    os.environ['CLAUDE_BIN'] = fake('good', "import json\nprint(json.dumps([{'sessionId':'zz','name':'z','status':'idle','cwd':'/a/b','startedAt':1}]))\n")
    data, err = live.fetch_agents()
    r('fetch_ok', err is None and len(data) == 1)
    os.environ['CLAUDE_BIN'] = fake('exit1', "import sys\nsys.exit(1)\n")
    data, err = live.fetch_agents()
    r('fetch_exit1_error', data is None and err is not None)
    os.environ['CLAUDE_BIN'] = fake('garbage', "print('not json')\n")
    data, err = live.fetch_agents()
    r('fetch_garbage_error', data is None and err is not None)
    os.environ['CLAUDE_BIN'] = fake('dict', "print('{\"a\": 1}')\n")
    data, err = live.fetch_agents()
    r('fetch_dict_error', data is None and err is not None)
    os.environ['CLAUDE_BIN'] = os.path.join(d, 'missing')
    data, err = live.fetch_agents()
    r('fetch_missing_binary_error', data is None and err is not None)
    # 확장 폴더에서 가장 높은 버전을 숫자로 고른다(2.1.10 > 2.1.9)
    del os.environ['CLAUDE_BIN']
    home = tempfile.mkdtemp()
    for v in ('2.1.9', '2.1.10', '2.1.3'):
        b = os.path.join(home, '.vscode', 'extensions', 'anthropic.claude-code-%s-darwin-arm64' % v, 'resources', 'native-binary')
        os.makedirs(b)
        open(os.path.join(b, 'claude'), 'w').close()
    old = (os.environ.get('HOME'), os.environ.get('PATH'))
    os.environ['HOME'] = home; os.environ['PATH'] = '/nonexistent'
    found = live.find_claude()
    os.environ['HOME'] = old[0]; os.environ['PATH'] = old[1]
    r('find_highest_numeric_version', found is not None and '2.1.10' in found)
PYEOF
)"
py() { grep -q "^$1=1$" <<<"${pyout}"; }
if grep -qE "Traceback|Error" <<<"${pyout}"; then echo "--- 파이썬 시험 출력(진단)"; printf '%s\n' "${pyout}" | tail -15; fail=1; fi

echo "== 1. 상태 추적"
chk "처음 본 idle 세션"                                 'py idle_first'
chk "idle에서 busy가 되면 시각을 기록(정확)"             'py busy_transition_exact'
chk "busy가 이어지는 동안 시작 시각 유지"                'py busy_since_kept'
chk "다시 idle이 되면 busy 시각 초기화"                  'py idle_clears_busy_since'
chk "처음 본 순간부터 busy면 정확하지 않다고 표시"        'py first_seen_busy_not_exact'
chk "연속 2번 안 보여도 끝난 것으로 보지 않음(깜박임 방지)" 'py missing_twice_not_ended'
chk "연속 3번 안 보이면 끝남"                            'py missing_thrice_ended'
chk "다시 나타나면 복귀하고 busy 시각 유지"              'py reappear_restores'
chk "끝남은 보관 시간이 지나면 지워짐"                   'py ended_purged_after_keep'
chk "모르는 상태는 확인 불가로 분류하고 원문 보존"        'py unknown_status'
chk "정렬은 작업 중, 확인 불가, 쉬는 중, 끝남 순"         'py sort_busy_unknown_idle'
chk "목록 읽기 오류를 알리고 마지막 세션은 유지"          'py error_reported'

echo "== 2. 개인정보"
chk "전체 경로를 내보내지 않음(Windows 경로 포함)"        'py no_full_path'
chk "전체 세션 ID를 내보내지 않음(앞 8자만)"              'py no_full_session_id'
chk "폴더 이름만 내보냄"                                 'py folder_only'

echo "== 2b. 서브에이전트 스캔"
chk "30분 밖 기록은 제외하고 안은 포함"                   'py scan_window_excludes_old'
chk "깨진 meta는 읽지 못한 개수로만 알리고 계속 진행"       'py scan_unreadable_counted'
chk "기록 파일이 없으면 meta 시각으로 대신함"              'py scan_no_log_uses_meta'
chk "첫 줄에 시각이 없으면 대체 시각을 씀"                 'py scan_first_line_without_ts_falls_back'
chk "최근 활동이 있으면 작업 중"                          'py agent_running'
chk "활동이 90초 넘게 없으면 조용함(멈춤으로 단정 안 함)"   'py agent_quiet'
chk "finished가 true면 확실한 끝남"                       'py agent_finished_exact'
chk "finished 표시 없는 오래된 기록은 끝남(추정)"          'py agent_old_unfinished_ended_estimated'
chk "정렬은 작업 중이 위, 끝남이 아래"                     'py agent_order_running_first'
chk "목록에 없는 세션의 최근 서브에이전트는 종료된 세션으로 표시" 'py gone_session_shown_with_agents'
chk "지금 동시에는 작업 중과 조용함을 센다"                'py concurrent_counts_running_and_quiet'
chk "읽지 못한 기록 개수를 화면에 알림"                    'py agents_unreadable_exposed'
chk "대화 내용(기록 본문)을 내보내지 않음"                 'py no_transcript_text'
chk "전체 세션·에이전트 ID를 내보내지 않음"                'py no_full_agent_or_session_id'
chk "부모 세션이 사라지면 조용한 서브에이전트는 끝남"       'py parent_gone_quiet_agent_ended'
chk "작업 제목 숨김 옵션"                                  'py titles_hidden_option'
chk "큰 기록 파일도 빠르게 스캔(첫 줄만 읽음)"             'py big_file_scan_fast'
chk "시각 문자열 해석(파이썬 3.6 호환 직접 구현)"           'py iso_parse'
chk "설정 폴더가 없어도 오류 없이 빈 결과"                 'py missing_claude_dir_ok'

echo "== 2c. 토큰 사용량 연결"
chk "기록이 꺼져 있으면 꺼짐으로 알림"                      'py usage_not_enabled_flag_missing'
chk "켜져 있으면 켜짐"                                      'py usage_enabled_flag'
chk "최근 5시간은 입력+출력만 더함(캐시 읽기 제외)"          'py usage_last5h_sums_in_plus_out_without_cache'
chk "오늘 합계는 날짜로 가름"                               'py usage_today_sums_by_date'
chk "서브에이전트 종류별 상위를 줌"                          'py usage_sub_types_top'
chk "집계 파일이 없으면 기록 없음"                           'py usage_missing_file_not_available'
chk "깨진 집계 파일도 오류 없이 기록 없음"                    'py usage_broken_file_not_available'
chk "모양이 이상한 집계도 죽지 않음"                         'py usage_odd_shapes_do_not_crash'
chk "LIVE_SHOW_USAGE=0이면 요약을 끔"                        'py usage_off_option'
chk "/usage가 /usage/로 이동"                               'py usage_redirect_slash'
chk "/usage/가 기존 화면을 주고 맨 위에 돌아가는 줄을 한 번만 끼움" 'py usage_page_served_with_nav'
chk "사용량 화면용 보안 헤더(자기 스크립트만 허용, 프레임 금지)"  'py usage_csp_allows_self_script'
chk "details.js를 줌"                                       'py usage_js_served'
chk "허용 목록 밖 파일과 상위 경로는 404(state.json 등)"       'py usage_other_files_404'
chk "사용량 화면에도 Host 검사"                              'py usage_bad_host_403'
chk "/api/state에 사용량 요약이 들어감"                       'py api_state_includes_usage'
chk "끄면 /usage/도 404"                                    'py usage_route_404_when_off'
chk "화면 파일이 없으면 404"                                 'py usage_missing_page_404'

echo "== 2f. 에이전트 팀"
chk "팀 폴더가 없으면 빈 목록"                             'py teams_none_without_folder'
chk "읽을 수 있는 팀만 목록에 넣음"                         'py teams_reads_only_valid_team'
chk "구성원 모양이 달라도 오류 없이 읽음"                    'py teams_members_tolerant'
chk "공유 작업은 상태별 개수만 셈"                          'py teams_task_counts'
chk "작업 제목은 내보내지 않음"                            'py teams_no_task_text_exported'
chk "팀이 화면 데이터에 들어감"                            'py teams_in_snapshot'
chk "화면에 에이전트 팀 구역이 있음"                        'grep -q "에이전트 팀" "${SK}/scripts/live.html" && grep -q "teamlist" "${SK}/scripts/live.html"'

echo "== 2d. 토큰 대시보드 초안 템플릿(연결 화면)"
chk "보조 글자색 대비 4.5:1 이상(밝은 테마)"                'py usage_tpl_light_contrast'
chk "보조 글자색 대비 4.5:1 이상(어두운 테마)"              'py usage_tpl_dark_contrast'
chk "데이터 자리표시자가 하나만 있음"                       'py usage_tpl_one_placeholder'
chk "맨 위 한 문장 요약이 있음"                            'py usage_tpl_has_headline'
chk "글자 크기가 12px 아래로 내려가지 않음"                 'py usage_tpl_no_tiny_text'
chk "기본 usage.py로 렌더링되고 요약 함수가 들어감"          'py usage_tpl_renders_with_base_script'

echo "== 2e. 방금 끝남과 내 차례"
chk "처음부터 쉬는 중이면 끝난 시각 없음"                   'py idle_since_none_when_first_seen_idle'
chk "작업 중에는 끝난 시각 없음"                           'py idle_since_none_while_busy'
chk "작업 중에서 쉬는 중이 되면 그 시각을 기록"              'py idle_since_recorded_on_busy_to_idle'
chk "쉬는 동안 끝난 시각 유지"                             'py idle_since_kept_while_idle'
chk "다시 작업 중이 되면 지움"                             'py idle_since_cleared_on_busy_again'
chk "탭 아이콘(data:)을 허용하는 보안 헤더"                 'py http_csp_allows_data_icon'
chk "화면에 방금 끝남·내 차례 표시와 탭 아이콘 코드가 있음"   'grep -q "방금 끝남" "${SK}/scripts/live.html" && grep -q "내 차례" "${SK}/scripts/live.html" && grep -q "setIcon" "${SK}/scripts/live.html"'
chk "토큰 단위는 만·억(K·M 아님)"                          'grep -q "억" "${SK}/scripts/live.html" && ! grep -Eq "toFixed\\([^)]*\\) \\+ .(K|M)." "${SK}/scripts/live.html"'

echo "== 3. HTTP"
chk "루트가 화면(HTML)을 줌"                             'py http_root_200_html'
chk "/api/state가 상태 JSON을 줌"                        'py http_state_json'
chk "보안 헤더(no-store, CSP, nosniff)"                  'py http_headers'
chk "Host localhost는 허용"                              'py http_localhost_host_ok'
chk "다른 Host 이름은 403(DNS rebinding 방지)"           'py http_bad_host_403'
chk "포트 없는 Host는 403"                               'py http_host_without_port_403'
chk "POST·PUT은 405"                                     'py http_post_405'
chk "없는 경로와 상위 경로는 404"                        'py http_unknown_404'
chk "127.0.0.1에만 묶임"                                 'py bind_loopback_only'

echo "== 4. claude 실행 경로"
if [[ "${IS_WIN}" = 1 ]]; then
  echo "  건너뜀  Windows 러너는 가짜 실행 파일을 파이썬이 직접 실행할 수 없어 생략(실제 기기에서 확인)"
else
  chk "정상 출력을 읽음"                                 'py fetch_ok'
  chk "종료 코드 1이면 오류로 알림"                      'py fetch_exit1_error'
  chk "JSON이 아니면 형식 변경 오류로 알림"              'py fetch_garbage_error'
  chk "목록이 아닌 JSON이면 오류로 알림"                 'py fetch_dict_error'
  chk "실행 파일이 없으면 오류로 알림"                   'py fetch_missing_binary_error'
  chk "확장 폴더에서 가장 높은 버전을 숫자로 고름"        'py find_highest_numeric_version'
fi

echo "== 5. 화면 파일"
chk "외부 주소를 부르지 않음"                            '! grep -Eq "(src|href)=\"https?://|url\(https?://|fetch\(.https?://" "${SK}/scripts/live.html"'
chk "innerHTML을 쓰지 않음(세션 이름은 글자로만 넣음)"    '! grep -q "innerHTML" "${SK}/scripts/live.html"'
chk "상태 글자 네 가지가 있음"                           'grep -q "작업 중" "${SK}/scripts/live.html" && grep -q "쉬는 중" "${SK}/scripts/live.html" && grep -q "확인 불가" "${SK}/scripts/live.html" && grep -q "끝남" "${SK}/scripts/live.html"'
chk "색 말고 모양도 함께 씀"                             'grep -q "▶" "${SK}/scripts/live.html" && grep -q "⏸" "${SK}/scripts/live.html"'
chk "탭이 다시 보이면 즉시 갱신"                         'grep -q "visibilitychange" "${SK}/scripts/live.html"'
if command -v node >/dev/null 2>&1; then
  "${PY}" -I -c "
import re,io,sys
s=io.open('${SK}/scripts/live.html',encoding='utf-8').read()
io.open('${T}/live.js','w',encoding='utf-8').write(re.search(r'<script>(.*)</script>',s,re.S).group(1))"
  chk "자바스크립트 문법 검사(node --check)"             'node --check "${T}/live.js" >/dev/null 2>&1'
else
  echo "  건너뜀  node가 없어 자바스크립트 문법 검사 생략"
fi

echo "== 6. 켜고 끄기(live.sh)"
chk "live.sh 문법"                                       'bash -n "${SK}/scripts/live.sh"'
if [[ "${IS_WIN}" = 1 ]]; then
  echo "  건너뜀  Windows 러너는 서버 시작·종료 시험을 생략(실제 기기에서 확인)"
else
  cat > "${T}/fakeclaude" <<'FEOF'
#!/usr/bin/env python3
import json
print(json.dumps([{"pid": 1, "cwd": "/a/shellproj", "kind": "interactive", "startedAt": 1, "sessionId": "shsh1234-0", "name": "shell-test", "status": "busy"}]))
FEOF
  chmod +x "${T}/fakeclaude"
  LP="$("${PY}" -I -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")"
  export CLAUDE_BIN="${T}/fakeclaude" LIVE_PORT="${LP}" LIVE_POLL_SEC=0.3 CLAUDE_CONFIG_DIR="${T}/cfg"
  out="$(bash "${SK}/scripts/live.sh" start 2>&1)"; rc=$?
  chk "start: 켜지고 주소를 알림"                        '[[ "${rc}" = 0 && "${out}" == *"http://127.0.0.1:${LP}/"* ]]'
  sleep 1
  chk "켜진 서버가 가짜 세션을 보여 줌"                   'curl -s -m 3 "http://127.0.0.1:${LP}/api/state" | grep -q "shell-test"'
  chk "status: 켜져 있음"                                'bash "${SK}/scripts/live.sh" status | grep -q "켜져 있음"'
  out="$(bash "${SK}/scripts/live.sh" start 2>&1)"
  chk "start 두 번째: 이미 켜져 있다고 알림"              '[[ "${out}" == *"이미 켜져"* ]]'
  bash "${SK}/scripts/live.sh" stop >/dev/null 2>&1
  sleep 1
  chk "stop: 꺼짐"                                       'bash "${SK}/scripts/live.sh" status | grep -q "꺼져 있음"'
fi

echo
[[ "${fail}" = 0 ]] && echo "결과: 통과" || echo "결과: 실패 항목 있음"
exit "${fail}"
