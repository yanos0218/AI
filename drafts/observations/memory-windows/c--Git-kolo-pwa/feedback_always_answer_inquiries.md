---
name: feedback-always-answer-inquiries
description: "every question the user embeds in a message must get an explicit direct answer, not just an implementation response"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e1b7a55-7822-438d-932d-819734f26b43
  modified: 2026-08-04T10:07:17.574Z
---

When the user asks a question (even embedded inline inside a longer message that also contains instructions or other content), give it an explicit, direct answer — don't just proceed to implementation/action and let the answer be implied by what you built.

**Why**: The user said outright: "문의한 것은 꼭 답변을 줘야 내가 이해하거나 결정할 수 있어" (you must always answer what I asked, so I can understand or decide) — after noticing a question they'd asked earlier in a multi-part message went unaddressed while I acted on the other parts.

**How to apply**: Before responding, re-scan the user's message for every `?`-marked or implicitly-interrogative clause, not just the ones that look like the "main" request. If a question surfaces a real product/design trade-off, give your actual opinion/recommendation with reasoning — don't dodge into "here are some options" when they asked "what do you think?" or "isn't X true?". If a question was answered by a prior action's *outcome* rather than in words, still say so explicitly in the reply ("yes — confirmed by X").
