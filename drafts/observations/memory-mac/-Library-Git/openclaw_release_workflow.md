---
name: openclaw-release-workflow
description: "OpenClaw repo release policy from v3.22.0 onward — commit/push/PR only, tag+release only on separate request"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 56b7ca4f-49da-4edd-8e50-a6b1700becbb
  modified: 2026-08-30T08:59:48.727Z
---

For the OpenClaw repo (`yanos0218/OpenClaw`, local clone at `/Library/Git/OpenClaw`), from version v3.22.0 onward: only do commits, pushes, and PR creation/merge as part of normal work. Do NOT create a git tag or GitHub Release automatically, even after merging a version-bump PR.

**Why:** User explicitly said release (tag + GitHub Release) should only happen when they separately request it — merging a docs/version PR does not imply "cut a release."

**How to apply:** After merging any PR that bumps the README version, stop there. Only run `git tag vX.Y.Z`, `git push origin vX.Y.Z`, and `gh release create` when the user explicitly asks for a release in that conversation. See [[openclaw-context]] for the full release procedure once it's actually requested.
