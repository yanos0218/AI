---
name: openclaw-context
description: "What OpenClaw is, where it lives, and the AI's role boundaries when working on it"
metadata: 
  node_type: memory
  type: project
  originSessionId: 56b7ca4f-49da-4edd-8e50-a6b1700becbb
  modified: 2026-08-30T09:00:04.603Z
---

OpenClaw is a Telegram-bot automation system running on this Mac mini (M4) that auto-processes dump analysis and blog writing. Repo: `yanos0218/OpenClaw`, local clone at `/Library/Git/OpenClaw`. Full operating rules live in `CONTEXT.md` at the repo root — read it before doing OpenClaw work in a fresh session.

Key boundary: AI may edit scripts, playbooks, definitions, fix bugs, and change NAS-doc structure. AI must NOT write blog posts, analyze dumps directly, or touch `~/.openclaw/workspace/` directly — that's the live pipeline's job, not the AI's.

As of 2026-08-30, the repo moved from a `MAJOR.MINOR` version scheme to full SemVer (`MAJOR.MINOR.PATCH`), starting at v3.22.0, and added `CHANGELOG.md` (Keep a Changelog format). This was merged via PR #10. See [[openclaw-release-workflow]] for the release policy going forward.

**Why this matters:** merges to `main` here affect a live production automation system, not just docs — treat merge/tag/release actions with the same caution as touching a production deploy.
