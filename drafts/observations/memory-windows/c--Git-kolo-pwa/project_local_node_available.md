---
name: project-local-node-available
description: Node.js IS installed on this machine (not on PATH) -- can run the real Playwright test suite locally instead of relying only on CI
metadata: 
  node_type: memory
  type: project
  originSessionId: 5dc19f6d-289d-4ce4-a69f-ba37a4def5c8
  modified: 2026-07-24T10:53:18.898Z
---

Node.js v24 is installed at `C:\Program Files\nodejs` (`node.exe`, `npm.cmd`, `npx.cmd`) but is not on the PATH used by the Bash/PowerShell tool shells in this environment -- `which node`/`Get-Command node` fail even though it's present. Playwright's browsers (chromium/webkit) are also already cached under `%LOCALAPPDATA%\ms-playwright`.

To use it: prepend to PATH per-command, e.g. `export PATH="/c/Program Files/nodejs:$PATH"` (Bash) before `node`/`npm`/`npx`. `npx --yes playwright@1 --version` works for ephemeral installs, but ESM scripts that `import 'playwright'` (like `scripts/ci-run-browser-tests.mjs`) won't resolve it via npx's own cache or `NODE_PATH` -- ESM ignores `NODE_PATH`. Workaround that worked: copy `playwright` + `playwright-core` from the npx cache (`%LOCALAPPDATA%\npm-cache\_npx\<hash>\node_modules\`) into a `node_modules` folder next to a copy of the script (e.g. in the scratchpad dir), then run `node` from there.

**Why this matters:** [[feedback_deferred_items]] and earlier sessions' summaries repeatedly concluded "no node/npm on this machine, tests are CI-only" and skipped local verification of JS changes to `kolo_pwa`. That was wrong -- the real browser test suite (`tests/test.html` via `scripts/ci-run-browser-tests.mjs`) can and should be run locally before deploying JS/CSS changes, not just `node --check` for syntax. Also applies to `npx markdownlint-cli2` for doc lint checks, which had likewise been assumed unavailable.

**How to apply:** Before deploying a `kolo_pwa` frontend change, serve the repo root (`python -m http.server 8080`, checking/killing any zombie process on that port first) and run the Playwright-based test suite locally via the PATH+node_modules-copy workaround above, rather than deploying on `node --check` syntax validation alone or waiting for CI.

**2026-07-24 follow-up:** built this into a proper `git push`-time check instead of a manual step — `scripts/pre-push-check.sh` (installs Playwright once into `~/.cache/kolo-pwa-pre-push`, outside the repo, then reuses it) wired up via `.githooks/pre-push`. Documented in `docs/testing.md` §1-1. Committing the hook file alone doesn't activate it (git only reads `.git/hooks/` by default, which isn't version-controlled) -- the user still needs to run `git config core.hooksPath .githooks` once per clone themselves (never ran this myself: git config changes are the user's call, not something to do proactively).
