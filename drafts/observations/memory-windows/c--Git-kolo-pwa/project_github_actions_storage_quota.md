---
name: project-github-actions-storage-quota
description: "yanos0218's GitHub account has only 500MB free Actions storage; kolo-api's CI easily blew through it twice — check before adding any CI caching/artifacts"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0e1b7a55-7822-438d-932d-819734f26b43
  modified: 2026-08-06T03:19:17.711Z
---

The `yanos0218` GitHub account is on the free tier: only **500MB** total Actions storage (artifacts + caches combined, shared across all repos). kolo-api's CI hit 100% twice:

1. First incident: `actions/upload-artifact` for the built jar had no `retention-days` set (or too long), so old jars piled up.
2. Second incident (2026-08-06), after the first fix was already in place: `gradle/actions/setup-gradle@v6`'s own cache (`gradle-home-v2`, keyed by commit SHA) was never addressed — it doesn't self-prune except a 7-days-unused eviction, and this repo pushes almost daily, so that eviction condition never triggers. Grew to 107 cache entries / ~857MB on its own, on top of a jar-artifact backlog from before the first fix. Fixed by adding `cache-disabled: true` to the setup-gradle step in `kolo-api/.github/workflows/build.yml`.

Also discovered: GitHub's storage-quota check reads a **usage figure recalculated only every 6-12 hours** — a build can fail with "quota exhausted" even seconds after everything was actually deleted. Because nothing downloads kolo-api's CI jar automatically (NAS deploy always does a fresh local build via `scripts/build-and-deploy-spring-api.ps1` — see [[project_local_java_available]]), the jar-upload step now has `continue-on-error: true` so this false failure doesn't mask a real build/test failure.

**Why**: This is a real, narrow, easy-to-recreate account-level constraint. A well-intentioned future change ("let's cache X to speed up CI", "let's keep build artifacts longer for debugging") would silently reintroduce this exact incident, and the fix lives in code comments/CHANGELOG that a fresh session won't necessarily read before proposing such a change.

**How to apply**: Before adding *any* new `actions/cache`, `actions/upload-artifact`, or enabling caching in a setup-* action (Gradle, Node, etc.) in either kolo-api or kolo_pwa's workflows, check current usage first: `gh api repos/yanos0218/<repo>/actions/cache/usage` and `gh api "repos/yanos0218/<repo>/actions/artifacts?per_page=100"`. Remember the usage figure itself lags 6-12h behind actual deletions, so a fresh "quota exhausted" failure right after a cleanup is expected, not a sign the cleanup didn't work.
