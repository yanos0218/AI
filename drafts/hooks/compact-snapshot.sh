#!/usr/bin/env bash
# PreCompact 훅(전역) — 컴팩션(대화 요약) 직전에 안전망 스냅샷을 저장한다.
# PreCompact는 차단(exit 2)·메시지만 가능하고 요약 내용 자체엔 개입 못 함(공식 문서 확인,
# https://code.claude.com/docs/en/hooks.md). 그래서 git 상태·최근 테스트 명령+결과·
# 미완료 TodoWrite 체크리스트를 따로 저장해두고, SessionStart(matcher: compact) 훅인
# compact-snapshot-show.sh가 컴팩션 직후 그 내용을 보여준다. (Issue #104)
set -u
input="$(cat)"
PY="$(command -v python3 || command -v python || true)"

get_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${input}" | jq -r ".${1} // empty" 2>/dev/null
  elif [[ -n "${PY}" ]]; then
    printf '%s' "${input}" | "${PY}" -c "import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('${1}') or '')
except Exception:
    print('')" 2>/dev/null
  fi
}

CWD="$(get_field cwd)"
TRANSCRIPT_PATH="$(get_field transcript_path)"
[[ -n "${CWD}" ]] || exit 0

SNAP_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/compact-snapshots"
mkdir -p "${SNAP_DIR}" 2>/dev/null

SLUG="$(printf '%s' "${CWD}" | tr -c 'A-Za-z0-9' '_')"
SNAP_FILE="${SNAP_DIR}/${SLUG}.md"

{
  echo "## 컴팩션 직전 스냅샷 ($(date '+%Y-%m-%d %H:%M:%S'))"
  echo
  echo "- 저장소: ${CWD}"
  echo

  if git -C "${CWD}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "### 수정된 파일"
    STATUS="$(git -C "${CWD}" status --porcelain 2>/dev/null)"
    if [[ -n "${STATUS}" ]]; then
      echo '```'
      echo "${STATUS}"
      echo '```'
    else
      echo "(변경 없음)"
    fi
    echo
  fi

  if [[ -n "${PY}" ]] && [[ -n "${TRANSCRIPT_PATH}" ]] && [[ -f "${TRANSCRIPT_PATH}" ]]; then
    "${PY}" - "${TRANSCRIPT_PATH}" <<'PYEOF'
import json, re, sys

sys.stdout.reconfigure(encoding="utf-8")
path = sys.argv[1]
TEST_RE = re.compile(
    r"\b(npm test|npm run test|pytest|python -m pytest|py_compile|"
    r"\./gradlew|markdownlint|shellcheck|go test|cargo test|npx jest|npx vitest)\b"
)

tool_uses = {}     # tool_use_id -> command
tool_results = {}  # tool_use_id -> result text (truncated)
order = []
last_todos = None

try:
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except Exception:
                continue
            content = (rec.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                btype = block.get("type")
                if btype == "tool_use" and block.get("name") in ("Bash", "PowerShell"):
                    cmd = (block.get("input") or {}).get("command", "") or ""
                    if TEST_RE.search(cmd):
                        tid = block.get("id")
                        tool_uses[tid] = cmd
                        order.append(tid)
                elif btype == "tool_use" and block.get("name") == "TodoWrite":
                    todos = (block.get("input") or {}).get("todos")
                    if isinstance(todos, list):
                        last_todos = todos
                elif btype == "tool_result":
                    tid = block.get("tool_use_id")
                    rc = block.get("content")
                    if isinstance(rc, list):
                        text = " ".join(b.get("text", "") for b in rc if isinstance(b, dict))
                    else:
                        text = str(rc or "")
                    tool_results[tid] = text[:300]
except Exception:
    pass

recent_ids = order[-5:]
if recent_ids:
    print("### 최근 테스트/빌드 명령")
    for tid in recent_ids:
        cmd = tool_uses[tid]
        res = tool_results.get(tid, "(결과 미포착)").replace("\n", " ")
        print(f"- `{cmd}`")
        print(f"  결과: {res}")
    print()

if isinstance(last_todos, list):
    pending = [t for t in last_todos if isinstance(t, dict) and t.get("status") != "completed"]
    if pending:
        print("### 미완료 체크리스트")
        for t in pending:
            print(f"- [{t.get('status', '?')}] {t.get('content', '')}")
        print()
PYEOF
  fi
} > "${SNAP_FILE}" 2>/dev/null

exit 0
