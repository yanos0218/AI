---
name: feedback-data-correction-workflow
description: "Validated pattern for large-scale real-world data correction tasks in kolo_pwa (e.g. the 26-place business-name/hours/menu audit) -- tiered research, artifact-based presentation, staged AskUserQuestion decisions, then batch-apply"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 155a27f9-56ec-4755-ae02-e55a197d06f5
  modified: 2026-08-03T11:25:33.148Z
---

For tasks that mean correcting many records of real-world data at once (2026-08-02/03:
23 places' business names/hours/menus, sourced from scratch across 4 rounds), this
staged loop was used repeatedly across the same session without the user ever
objecting to the shape of it — treat it as validated, not just what happened once:

1. **Split research across parallel background agents**, grouped by a natural
   axis (district, in this case) rather than one agent doing everything serially.
   Each agent gets an explicit no-fabrication instruction and is told to report
   "확인 안됨" rather than guess when a source is missing or weak.
2. **Compile findings into an Artifact**, not a chat wall of text, once there's
   real content to review (candidate names/hours/menus with confidence tiers:
   high/mid/low, and sourced citations). The same file path gets redeployed
   across rounds as the investigation deepens (kept one stable favicon per
   distinct topic, e.g. 📋 for the name audit, 🍽️ for the menu-cleanup pass).
3. **Classify by confidence/category before asking anything** (e.g. "found a
   confirmed real business" vs "found a candidate but district doesn't match"
   vs "found nothing at all") -- then ask the user to set *policy* per category
   via `AskUserQuestion` (e.g. "apply the confident ones, hold the risky ones")
   rather than asking about each of 20+ individual records one at a time.
4. **Apply via the live admin API directly** (once the user shares/has already
   shared the token for the batch) rather than only handing back a list for the
   user to type into the admin console UI by hand -- then sync the local
   `places.json` reference snapshot, document in `docs/PROGRESS.md`, and follow
   the standard commit/CI pipeline ([[feedback-full-workflow-expected]]).
5. **When swapping an entity's identity (e.g. renaming a place to a different
   real business), audit every field that encodes the old identity, not just
   the obviously visible ones.** This session's concrete miss: a name/hours/
   coordinate swap left `mapLinks.queryName` (map search text) and
   `signatureMenus` (menu items) still describing the *old*, now-incorrect
   business -- caught late, during an unrelated follow-up task, not immediately.
   Grep for the old identity across the whole record before considering a
   rename finished.
6. **When a research round turns up that the underlying task doesn't scale**
   (e.g. "AI research cost grows linearly with record count"), it's fine to
   surface cheaper alternatives (official APIs, crowdsourced reports) as
   *ideas for later* without being asked, then only pursue whichever the user
   actually picks — don't build the alternative unprompted.

**Why**: this exact loop ran ~5 times in the 2026-08-02/03 session (initial
26-place audit, round 2 replacement search, menu/fact cleanup, plus the smaller
Dependabot/Spring-Boot investigation using the same "investigate → report →
user decides scope → execute" shape) and the user engaged with every
AskUserQuestion prompt directly, picking recommended options most of the time
without requesting a different process.

**How to apply**: default to this shape the next time asked to fix/verify a
batch of real-world content records (not just places -- could be any dataset
of many similarly-structured real-world facts), rather than either (a) trying
to resolve everything in one silent pass, or (b) asking about every record
individually in chat.
