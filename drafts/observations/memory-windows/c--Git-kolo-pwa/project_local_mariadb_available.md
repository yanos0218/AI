---
name: project-local-mariadb-available
description: Local MariaDB 12.3 is installed and running for kolo-api tests — run the real test suite locally before pushing instead of relying on CI as the first check
metadata: 
  node_type: memory
  type: project
  originSessionId: 826f0ea2-f8c6-4d83-91ae-7eb7084cdacc
  modified: 2026-08-13T13:24:25.349Z
---

MariaDB Server (12.3.2, via `winget install MariaDB.Server`) is installed
at `C:\Program Files\MariaDB 12.3\`. Installed 2026-08-13 specifically so
`./gradlew test` for kolo-api can run against a real database locally,
matching `.github/workflows/build.yml`'s `mariadb:11` service container —
not just `compileJava`/`compileTestJava` as before (see
[[project_local_java_available]], now superseded for the "can't run real
tests locally" part).

**Why**: user feedback (2026-08-13) — "로컬에서 테스트가 먼저 되어야 운영서버에서
테스트하면 위험해" (local tests need to come first, testing against the live/CI
path first is risky). Directly prompted by a real incident earlier the same
session: a P-92 commit passed local `compileJava`/`compileTestJava` but a
6-test failure (`MariaDbDataTruncation` — a test-fixture string exceeded a
`VARCHAR(32)` column) only surfaced in CI against real MariaDB, requiring a
second commit to fix. Installing MariaDB locally closes that gap.

**Current state — the silent winget install does NOT set up a Windows
service or root password**, so it needs manual steps each machine restart:

1. Start the server (foreground process, or background it):
   `& "C:\Program Files\MariaDB 12.3\bin\mariadbd.exe" --console`
2. First-time-only setup already done, don't repeat: `kolo_test` database
   created, `kolo`/`kolo` user (matches
   `kolo-api/src/test/resources/application-test.yml` exactly — url
   `jdbc:mariadb://localhost:3306/kolo_test`), root password set to `root`
   (matches CI's `MARIADB_ROOT_PASSWORD`). This state persists in
   `C:\Program Files\MariaDB 12.3\data\` across restarts — only the running
   `mariadbd.exe` process itself needs restarting, not the setup.
3. Then from `c:\Git\kolo-api`: `export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-21.0.11.10-hotspot"; export PATH="$JAVA_HOME/bin:$PATH"; export SPRING_PROFILES_ACTIVE=test; ./gradlew test`
   — confirmed working end-to-end (142/142 passed locally, including
   `/tmp/kolo-test-media`/`/tmp/kolo-test-logs` paths from
   `application-test.yml`, which resolved fine under Git Bash on Windows
   despite looking Unix-specific).

**How to apply**: before pushing any kolo-api change, run the real
`./gradlew test` locally (server must be running first, per step 1) instead
of stopping at `compileJava`/`compileTestJava` — CI is still the final gate,
but shouldn't be the *first* place a real DB-dependent bug is caught anymore.
If `mariadbd.exe` isn't running (check via `mariadb.exe -u root -proot -e
"SELECT 1"` or just try the test run and see if it fails to connect), start
it per step 1 before assuming a test failure is a real code bug.

**Caveat found 2026-08-13 (P-92 Phase 6 backend work)**: unlike CI's
fresh-container-per-run, this local DB persists between runs. Most tests are
fine (this codebase's convention is `UUID.randomUUID()`-based ids/districts
per test specifically to stay isolated regardless of what else is in the
table — see `PlaceControllerTest`'s `testDistrict()`/`testProvince()`
helpers). But a couple of pre-existing tests use fixed, non-UUID keys
(`AnalyticsControllerTest.recordView_sameRouteTwice_incrementsToTwo` posts to
the literal route `/favorites`; `AdminLogControllerTest.tail_missingFile_returnsEmptyList`
checks a fixed log filename) — these can fail locally purely from repeated
local runs accumulating state, even against a *freshly recreated* `kolo_test`
database within the same session (confirmed: failed again on a second
`./gradlew test` run right after a from-scratch `DROP DATABASE`/`CREATE
DATABASE`). Verified via `./gradlew test --tests
"com.kolo.api.place.PlaceControllerTest"` (scoped to just the changed area)
that this wasn't a real regression from the situation-filter change that
prompted this discovery.

**How to apply (added)**: if a local `./gradlew test` failure is in a test
using a fixed/hardcoded key rather than a generated UUID, don't treat it as
a real regression without checking CI first — it's more likely local-run
pollution than a real bug. To reset cleanly: `mariadb.exe -u root -proot -e
"DROP DATABASE kolo_test; CREATE DATABASE kolo_test CHARACTER SET utf8mb4;
GRANT ALL PRIVILEGES ON kolo_test.* TO 'kolo'@'localhost'; GRANT ALL
PRIVILEGES ON kolo_test.* TO 'kolo'@'127.0.0.1'; FLUSH PRIVILEGES;"` plus
`rm -rf /tmp/kolo-test-media /tmp/kolo-test-logs` — but this alone doesn't
guarantee the fixed-key tests pass every single run, since state can also
accumulate *within* one run across test classes that share a cached Spring
context. Scoping to the specific changed test class (`--tests
"com.kolo.api.place.PlaceControllerTest"`, etc.) is the more reliable way to
verify a specific change didn't break anything, when the full-suite run
shows one of these known-fragile tests failing.
