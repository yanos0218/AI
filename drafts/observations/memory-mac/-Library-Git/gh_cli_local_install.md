---
name: gh-cli-local-install
description: "gh CLI is installed to ~/.local/bin on this Mac mini, not via Homebrew, and needs GH_TOKEN for auth"
metadata: 
  node_type: memory
  type: project
  originSessionId: 56b7ca4f-49da-4edd-8e50-a6b1700becbb
  modified: 2026-08-30T08:59:56.658Z
---

This Mac mini has no Homebrew and no system-wide `gh` CLI. `gh` v2.98.0 was manually downloaded from the GitHub releases page (macOS arm64 zip) and installed to `~/.local/bin/gh`, which is NOT on the default PATH — export it first: `export PATH="$HOME/.local/bin:$PATH"`.

`gh auth login --with-token` fails with this account's classic PAT ("missing required scope 'read:org'"). The working approach is to export `GH_TOKEN=<token>` as an env var and call `gh` commands directly (e.g. `gh pr create`, `gh pr merge`, `gh api`) — this bypasses the login scope validation entirely and works fine for repo/PR operations.

**Why:** Non-interactive session couldn't run browser-based `gh auth login`; user provided a classic PAT (note "openclaw") instead.

**How to apply:** In this environment, always prefix `gh` invocations with the PATH export, and use `GH_TOKEN` env var rather than `gh auth login` for authentication. See [[openclaw-context]] for the repo this was used on.
