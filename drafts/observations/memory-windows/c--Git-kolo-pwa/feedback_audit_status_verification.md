---
name: feedback-audit-status-verification
description: "when reporting which kolo-audit findings were fixed vs skipped, verify each one precisely (grep/code check) instead of reconstructing from memory of the session's own work"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1b90d0be-97b9-4c02-b75d-f0fa6bcdb2a4
  modified: 2026-08-25T04:31:17.949Z
---

When summarizing the outcome of a kolo-audit batch (or any large multi-item review), verify each finding's fixed/unfixed status by directly checking the code (grep for the specific pattern/line the finding cited), not by mentally reconstructing "roughly how many I think I did." Reconstructing from memory across a long session with many similar-sounding fixes is unreliable in both directions — under- or over-counting.

**Why:** During the P-149 kolo-audit (2026-08-25), after applying findings across two repos, the closing summary claimed "중간 13건 중 8건 조치 / 낮음 9건 중 2건 조치" (implying 5 medium + 7 low unaddressed). When the user asked what to do about the "leftover" items, re-checking each finding one by one against the actual code (grep for `concurrency`/`cancel-in-progress`, `subwayMapAlt`, etc.) revealed the true count was only 1 medium + 5 low unaddressed — the rest had already been fixed but weren't credited correctly in the summary. The user had to ask a clarifying question to catch this; a careless recap nearly caused legitimate fixes to look outstanding (or could have caused genuinely-outstanding items to be skipped if the miscounting had gone the other way).

**How to apply:** Before writing a "here's what's fixed / here's what's left" summary after a large batch of findings, re-derive the list by checking the actual repo state (grep the specific file:line or pattern each finding named) rather than trusting a running mental tally kept across many tool calls. This matters most when: (a) the batch spans many files/repos, (b) the session is long enough that earlier parts of the work are out of recent context, (c) some findings were explicitly *not* fixed (e.g., judged low-value or a false positive) and need to stay distinguishable from findings that *were* fixed but just forgotten in the recap.
