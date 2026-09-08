---
name: project-local-gh-cli-available
description: GitHub CLI (gh) is installed and authenticated on this machine -- can check GitHub Actions CI status directly instead of asking the user to look
metadata: 
  node_type: memory
  type: project
  originSessionId: 155a27f9-56ec-4755-ae02-e55a197d06f5
  modified: 2026-08-02T03:29:18.216Z
---

`gh` (GitHub CLI) was installed via `winget install --id GitHub.cli` on
2026-08-01 and authenticated by the user (`gh auth login`, browser flow) for
account `yanos0218` with `repo`/`workflow` scopes. It's at
`C:\Program Files\GitHub CLI` — not on the default PATH used by the
Bash/PowerShell tool shells, so prepend it per-command, e.g.
`export PATH="/c/Program Files/GitHub CLI:$PATH"` (Bash) before `gh`.

Both `kolo_pwa` and `kolo-api` are private repos owned by this account, so
`gh run list`/`gh run view --log-failed` etc. work directly against either
repo's Actions runs (`cd` into the right repo first, or pass `-R owner/repo`).

**Why this matters:** before this, CI status could only be checked by asking
the user to look at the GitHub Actions tab and report back — a real friction
point across several turns in the 2026-08-01 session (see
[[feedback_full_workflow_expected]] for why CI-green confirmation matters
before deploying). Now this can be checked directly.

**How to apply:** When a push needs CI confirmation before the next step
(deploy, or building further commits on top), poll with `gh run list
--branch main --limit N --json status,conclusion,workflowName,headSha`
filtered by the exact commit SHA (`git rev-parse HEAD`) — use a generous
`--limit` (5-6+) before filtering by workflow name, since a narrow `--limit
1` can miss the run you want if another workflow (e.g. Markdown Lint)
completed more recently and sorts first. On failure, `gh run view <id>
--log-failed` or `--log | grep -A N "FAILED"` gets the actual error instead
of guessing. A `run_in_background: true` polling loop works and does trigger
a real completion notification — but if a notification seems slow/missing,
just re-run a one-off `gh run list` directly rather than waiting indefinitely
on trust alone; a stalled loop script is possible and worth verifying against
independently.
