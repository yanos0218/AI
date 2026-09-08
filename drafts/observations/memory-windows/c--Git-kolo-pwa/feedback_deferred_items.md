---
name: feedback-deferred-items
description: "User's preference for how deferred/backlog work should be tracked and surfaced"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dc19f6d-289d-4ce4-a69f-ba37a4def5c8
  modified: 2026-07-20T08:48:44.878Z
---

When the user defers a feature or fix ("차후 진행", "나중에", "별도 작업으로"), record it in `docs/PROGRESS.md`'s consolidated "보류 항목" section (kolo_pwa) — but do not proactively remind the user about it in future sessions.

**Why:** Explicit instruction (2026-07-20, after deferring P-26 and several P-25 follow-ups — reviewer edit/delete, local/foreigner distinction, nickname spoofing protection, P-22c, DB password rotation): "당장할 것들이 아니니 매번 알려주지 않아도돼 - 다른 것들을 진행하는 과정중 필요하거나 중복되는 내용이라면 그때 알려줘." The user wants deferred items tracked durably (so nothing is lost) but not repeatedly surfaced — only bring one up if it becomes directly relevant or overlaps with whatever is being worked on right now.

**How to apply:** After adding a deferred item to the backlog doc, don't mention it again in status summaries or "what's next" suggestions unless: (a) the user asks what's deferred/pending, or (b) current work directly touches the same code/feature the deferred item concerns. Same spirit likely applies beyond kolo_pwa to other projects — treat "defer this" as "stop bringing it up," not "keep checking in about it."
