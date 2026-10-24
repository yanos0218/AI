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
