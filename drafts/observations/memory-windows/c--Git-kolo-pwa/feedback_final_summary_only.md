---
name: feedback-final-summary-only
description: "don't narrate intermediate findings/conclusions mid-task; show only the final result, except points that genuinely need user confirmation"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 826f0ea2-f8c6-4d83-91ae-7eb7084cdacc
  modified: 2026-08-16T03:32:03.356Z
---

When working through a multi-step investigation or task, don't surface each sub-finding or intermediate conclusion as it's reached (e.g. "이건 확인했고, 이제 다음 걸 봅니다" style updates). Present the synthesized result once, at the end.

**Exception**: anything that genuinely needs the user's confirmation before proceeding — a risky/hard-to-reverse action, a design decision with real tradeoffs, a policy call (e.g. privacy scope for a new data-collection feature) — should still surface immediately, the same as before. This preference is about cutting narration noise, not about skipping checkpoints that need real sign-off.

**Why:** User explicitly asked for this (2026-08-16) after a multi-part reply that included interim per-question conclusions before the final wrap-up — they want the back-and-forth minimized to only what actually needs their input.

**How to apply:** When investigating (e.g. via a research subagent or multi-step Grep/Read exploration) and reporting back, hold findings until the full picture is ready, then give one coherent answer. When a plan or approval gate is genuinely required (ExitPlanMode, a destructive/high-blast-radius action, a policy tradeoff the user must weigh in on), still stop and ask — don't fold that into "just show the final result" either.
