---
name: feedback-markdown-formatting
description: Write markdown that already passes markdownlint (DavidAnson/markdownlint) instead of leaving violations for the user to flag
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dc19f6d-289d-4ce4-a69f-ba37a4def5c8
  modified: 2026-07-20T11:47:55.753Z
---

When writing or editing `.md` files in kolo_pwa (and by extension, other projects), follow markdownlint conventions from the start rather than accumulating violations that the user has to point out later.

**Why:** Across several editing sessions on `docs/PROGRESS.md`, `CHANGELOG.md`, `docs/nas-deployment.md`, and eventually the whole repo, dozens of MD022 (blank line around headings), MD032 (blank line around lists), and MD060 (table separator row must match the padded/compact style of the header row) violations built up. The user had to flag it twice ("아직 수정되지 않았는지 확인되고 있어") before a full repo-wide sweep actually caught everything, including files never previously checked (`docs/menus/*.md`, `.github/release-notes/*.md`, `README.md`).

**How to apply:**
- Headings: always a blank line before and after (unless at the very top of the file or immediately after another heading).
- Lists: always a blank line before the first item and after the last item, unless the preceding line is itself a list item or heading.
- Tables: the separator row (`|---|---|`) must match the padding style of the header/data rows. This repo's convention is padded cells (`| 날짜 | 작업자 |`), so the separator row must also be padded (`| --- | --- |`), not compact (`|---|---|`).
- Content inside fenced code blocks (```` ``` ````) is exempt — don't "fix" markdown syntax shown as a literal example.
- `.markdownlint.json` at the repo root has two intentional overrides: `MD024: {siblings_only: true}` (Keep a Changelog's format legitimately repeats "### Added"/"### Fixed" under different version headings) and `MD013: false` (this repo's docs use long single-line bullet entries by design, not 80-char wrapping — enabling MD013 would demand rewrapping nearly every substantive line). Don't reintroduce either check without the user asking.
