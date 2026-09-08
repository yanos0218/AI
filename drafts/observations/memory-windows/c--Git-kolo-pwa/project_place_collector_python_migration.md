---
name: project-place-collector-python-migration
description: place-collector tool has been migrated from Node.js to Python (stdlib only) for maintainability
metadata: 
  node_type: memory
  type: project
  originSessionId: 0e1b7a55-7822-438d-932d-819734f26b43
  modified: 2026-08-04T06:07:39.554Z
---

`scripts/place-collector/` (standalone place-data collection pipeline, kakao/naver/MOIS/TourAPI → normalize → diff → validate → commit) was migrated from Node.js/ESM to Python on 2026-08-04, after all 4 sources and multiple regions/kinds were verified working in the Node version. The user asked for this purely for maintainability, not a functional need — the pipeline is just JSON API calls + diff/consensus logic, nothing Python's ecosystem does meaningfully better.

**Current state**: `collect.py` + `lib/*.py` (stdlib-only: `urllib`, `json`, `hashlib`, `math`, no pip packages). All `.mjs` files were deleted after the Python port was verified byte-for-byte equivalent (same region/kind re-run produced identical counts and dry-run output to the Node version). `.env`/`config.json`/`usage-state.json` are shared unchanged — only the runtime language changed.

**Two Windows-specific gotchas hit during the port** (relevant if this tool needs further local debugging):
1. Python's `zoneinfo.ZoneInfo('Asia/Seoul')` fails on Windows (`ModuleNotFoundError: No module named 'tzdata'` — Windows Python doesn't ship IANA tzdata by default). Fixed by using a fixed `timezone(timedelta(hours=9))` instead, since Korea has no DST — exactly equivalent, no dependency needed.
2. Windows console defaults to cp949, which mangles Korean text and crashes outright on the ⚠️ emoji. Fixed with `sys.stdout.reconfigure(encoding='utf-8')` at the top of `collect.py`.

**How to apply**: Run it as `python collect.py --regions ... --kinds ...` (see README.md) using the local Python at `C:\Users\yanos\AppData\Local\Programs\Python\Python312` (not on PATH, same pattern as [[project_local_node_available]]/[[project_local_java_available]]). Do not reintroduce Node.js for this tool — the migration is done, not still pending.
