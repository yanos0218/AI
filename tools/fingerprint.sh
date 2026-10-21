#!/usr/bin/env bash
# 기기 지문(Issue #186) — 같은 지침인데 기기·세션마다 반응이 다를 때, 반응에 영향을 주는 값을 10여 줄로 찍는다.
# 기기마다 실행해 출력을 diff로 비교한다. 아무것도 고치지 않고, 세션 시작 때 자동으로 돌리지 않는다(토큰 소비 방지).
#   bash tools/fingerprint.sh > fp-이 기기.txt      다른 기기에서: bash tools/fingerprint.sh | diff fp-이 기기.txt -
# 공개 저장소 Issue에 붙여도 되도록 사용자명·호스트명·경로·환경변수 값·토큰은 출력하지 않는다(키 이름과 개수만).
set -u
# 현재 작업 폴더가 속한 저장소(없으면 그 폴더)의 CLAUDE.md·memory를 본다
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
PY="$(command -v python3 || command -v python)"
[[ -n "${PY}" ]] || { echo "python3 또는 python이 필요함"; exit 1; }

CLI="PATH에 없음"
if command -v claude >/dev/null 2>&1; then CLI="$(claude --version 2>/dev/null | head -n 1)"; fi

EXT="없음"
for d in "${HOME}"/.vscode/extensions/anthropic.claude-code-*; do
  [[ -d "${d}" ]] && EXT="$(basename "${d}" | sed 's/^anthropic\.claude-code-//')"
done

"${PY}" -I - "${CLAUDE_HOME}" "${ROOT}" "${CLI}" "${EXT}" "$(uname -sm)" <<'PY'
import glob, hashlib, io, json, os, re, sys

home, root, cli, ext, osname = sys.argv[1:6]


def sha(path):
    try:
        with io.open(path, 'rb') as f:
            data = f.read()
    except OSError:
        return '없음'
    return '%s(%d줄)' % (hashlib.sha256(data).hexdigest()[:12], data.count(b'\n'))


def lines(path):
    try:
        with io.open(path, encoding='utf-8') as f:
            return [x.rstrip('\n') for x in f]
    except OSError:
        return []


def count(pattern):
    return len(glob.glob(os.path.join(home, pattern)))


ver = lines(os.path.join(home, '.claude-config-version'))
settings = {}
try:
    with io.open(os.path.join(home, 'settings.json'), encoding='utf-8') as f:
        settings = json.load(f)
except (OSError, ValueError):
    pass
perm = settings.get('permissions') or {}
slug = re.sub(r'[^A-Za-z0-9]', '-', root)
memory = len(glob.glob(os.path.join(home, 'projects', slug, 'memory', '*.md')))

rows = [
    ('기기 OS', osname),
    ('설치 버전', ver[1] if len(ver) > 1 else '없음'),
    ('설치 기본영역 해시', (ver[2][:12] if len(ver) > 2 else '없음')),
    ('전역 지침', sha(os.path.join(home, 'CLAUDE.md'))),
    ('rules 파일', ' '.join(sorted(os.path.basename(p) for p in glob.glob(os.path.join(home, 'rules', '*.md')))) or '없음'),
    ('훅·스킬·에이전트 수', '%d·%d·%d' % (count('hooks/*.sh'), count('skills/*/SKILL.md'), count('agents/*.md'))),
    ('settings model', settings.get('model', '(키 없음)')),
    ('settings modelSettings', json.dumps(settings.get('modelSettings', '(키 없음)'), ensure_ascii=False, sort_keys=True)),
    ('settings effortLevel', settings.get('effortLevel', '(키 없음)')),
    ('settings env 키', ' '.join(sorted((settings.get('env') or {}).keys())) or '없음'),
    # settings보다 우선하는 환경변수. 모델 이름·수준 값이라 그대로 출력한다
    ('모델 환경변수', ' '.join('%s=%s' % (k, os.environ[k]) for k in ('ANTHROPIC_MODEL', 'ANTHROPIC_DEFAULT_MODEL', 'CLAUDE_CODE_EFFORT_LEVEL', 'CLAUDE_CODE_SUBAGENT_MODEL') if os.environ.get(k)) or '미설정'),
    ('권한 허용·차단 수', '%d·%d' % (len(perm.get('allow') or []), len(perm.get('deny') or []))),
    ('CLI 버전', cli),
    ('VS Code 확장 버전', ext),
    ('저장소 CLAUDE.md', sha(os.path.join(root, 'CLAUDE.md'))),
    ('auto memory 파일 수', str(memory)),
]
for k, v in rows:
    print('%s = %s' % (k, v))
PY
