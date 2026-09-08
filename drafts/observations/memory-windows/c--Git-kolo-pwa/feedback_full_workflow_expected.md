---
name: feedback-full-workflow-expected
description: "kolo_pwa/kolo-api changes go all the way through the established pipeline (verify -> document -> version bump -> commit/push -> confirm CI green -> deploy), not stop at a local edit or an unverified push"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 155a27f9-56ec-4755-ae02-e55a197d06f5
  modified: 2026-08-03T11:24:59.088Z
---

For any code change in kolo_pwa (even a small one-line CSS/JS fix), complete the
full pipeline this repo has used throughout its history before considering the
work done — don't just make the local edit and stop.

The pipeline, inferred from the exhaustive history in `docs/admin-menu.md` and
`docs/PROGRESS.md` (every past fix follows this shape):

1. **Real local verification, not just static reasoning.** Run the actual test
   suite that covers the change (e.g. `node scripts/ci-run-admin-tests.mjs`
   against a local static server for admin console changes — [[project_local_node_available]]
   covers the Node/Playwright setup). If a bug's root cause suggests the
   existing tests wouldn't have caught it (e.g. checking `.hidden` IDL property
   instead of actual computed style), add/strengthen a regression test and
   prove it fails without the fix and passes with it.
2. **Document the change with a dated entry**, in `docs/PROGRESS.md` (the
   living board) and/or the feature's own design doc (e.g. `docs/admin-menu.md`)
   — what broke, why, the fix, and the verification performed. Match the
   existing entry style (`- [x] **title** (date) — context`, sub-bullets for
   cause/fix/verification).
3. **Bump `CACHE_NAME` in `deploy/nginx/html/service-worker.js`** for any
   frontend-affecting change, even files excluded from service-worker caching
   (confirmed via git history: a CSS-only fix inside `admin-h6q2xk/`, which is
   explicitly excluded from SW caching, still bumped `kolo-v72`) — it functions
   as a general release counter referenced throughout the docs, not strictly a
   cache-invalidation mechanism. Doc-only changes (no code touched) do NOT bump
   it.
4. Do **not** commit/push/deploy without being explicitly asked for a *new*
   thread of work — get everything else ready (working tree clean of temp
   artifacts, tests passing, docs updated) and stop there. But once the user
   has given the go-ahead for a batch of work (e.g. "둘 다 커밋/푸시" +
   "CI 그린 확인 후 배포 진행"), that authorization carries forward through
   follow-up "진행하던 내용 계속 진행해줘" prompts on the same thread — don't
   re-ask before every subsequent commit/push/deploy in that same batch,
   including fix-up commits needed to get CI green (2026-08-01: confirmed
   across a real multi-commit CI-debugging sequence in the same session).
5. **Before deploying, or before building a new commit on top of a pushed
   one, actually confirm CI finished green — don't just confirm it was
   triggered.** [[project_local_gh_cli_available]] covers how to check
   directly. 2026-08-01: a kolo-api push was assumed fine after triggering
   CI and moving on to write the next feature's code, but CI was still
   red (a real bug — see below); by the time it was checked, work had
   already stacked on top of the broken commit. Wait for the actual
   `conclusion` field (`success`/`failure`), not just `status: in_progress`
   or "the push succeeded."
6. **A red CI run is signal, not noise — read the actual failure log before
   assuming it's a flaky test or moving on.** 2026-08-01: a single feature
   (recording failed admin login attempts) took 4 failed CI runs before
   green, and every failure was a genuine, fixable bug once actually
   investigated via `gh run view <id> --log-failed`: (1) a real production
   bug — `@Transactional`'s default rollback-on-exception silently undid a
   database write that was supposed to survive the exception (fixed with
   `noRollbackFor`); (2) a JsonPath filter-projecting-a-null-field quirk in a
   test assertion; (3) `MockHttpServletResponse.getContentAsString()`'s
   ISO-8859-1 default corrupting Korean text in a test; (4) a pre-existing
   fragile test that assumed `$[0]` in a list response was always the
   newest row, which broke once a same-timestamp tie became possible. None
   of these would have been found by assuming "probably fine" and deploying.
7. **Use `scripts/wait-for-ci.sh <owner/repo> [ref]` instead of hand-writing a
   `gh run list`/`sleep` polling loop.** Added 2026-08-03 after writing that
   loop from scratch 15+ times in one session; it wraps
   `gh api repos/{repo}/commits/{sha}/check-runs` (all workflows for one exact
   commit — more reliable than `gh run list --branch`, which can grab the
   wrong run if the branch moved) and exits 0/1/3 for green/failed/timeout.
8. **After a backend deploy that needed a container restart (kolo-api), verify
   the live site actually works post-restart — don't stop at "CI was green
   before I deployed."** 2026-08-03: after a Spring Boot 4.1.0 jar deploy +
   user-performed `docker compose restart spring-api`, ran
   `scripts/verify-live.ps1` plus targeted hits on the specific
   endpoints/entities the change touched (`/api/places`, the full admin
   session login → login-history → logout flow) before calling the deploy
   done. CI green only proves the code works against CI's MariaDB at push
   time — it doesn't prove the specific running container came up clean.

**Why**: user feedback (2026-08-01) — after a session did steps None of the
above (just made local edits), the user noted "이전 프롬프트에서는 알아서
일사천리로 됐다면 지금은 로컬반영하고 끝나는 정도인것 같아" (previous
sessions went smoothly end-to-end; this one just stops at local changes).
Confirmed by inspecting actual git history (e.g. commit `693ffb6`, a CSS-only
admin console fix that still bumped `kolo-v72` and got a `docs/PROGRESS.md`
entry) that this full pipeline is the project's real, consistent convention,
not a one-off.

**How to apply**: Whenever making a code change to kolo_pwa (frontend static
files or backend), default to running this full pipeline without being asked
each step, then present the completed, verified, documented diff and ask about
commit/push rather than stopping after the edit.
