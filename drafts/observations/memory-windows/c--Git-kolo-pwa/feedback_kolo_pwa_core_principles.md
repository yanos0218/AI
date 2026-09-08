---
name: feedback-kolo-pwa-core-principles
description: "kolo_pwa's 5 fixed design constraints to check every feature/scope decision against — target audience, offline support, PWA-only, phased language default, and cross-platform parity"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d7cae4fd-418c-4e63-ab18-74ccfb82c346
  modified: 2026-08-13T10:03:04.594Z
---

Every feature or scope decision in kolo_pwa (the consumer PWA, NOT the admin
console) must be checked against these 5 fixed constraints:

1. **Target audience is foreigners visiting or having visited Korea** — not
   Korean locals, not developers. Content, defaults, and UX should be judged
   by whether they help someone unfamiliar with Korea, not by what's
   convenient or familiar to a Korean user.
2. **Must support offline use, not just online.** Online-only is acceptable
   as a baseline, but any feature that *could* work offline (static content,
   on-device math, data already cacheable) should, since the target user may
   have no roaming/data while actually in Korea.
3. **Built as a PWA — browser-only capabilities.** No native app frameworks,
   SDKs, or OS-level APIs (e.g. Swift/MapKit, native URL schemes) are usable,
   even if a reference/prior version (kolo iOS) used them. This explicitly
   **excludes the admin console** (`admin-h6q2xk/`), which is an internal
   tool with different constraints and audience.
4. **Language default is phase-dependent.** During active development,
   Korean as the working default (prompts, in-progress content) is fine —
   see [[feedback_korean_prompts]]. But the actual shipped/production
   experience must default to each user's own language, not Korean — Korean
   being the default today is a development-phase artifact, not the
   intended end state.
5. **Platform parity — Android, iOS, and Web (Chrome/Edge/Safari) are all
   equally the product, not "mainly X with iOS quirks."** It's fine to cite
   a platform-specific technical fact (e.g. iOS Safari's tab/installed-PWA
   storage split, 7-day cache eviction) as justification for a design
   choice, but the resulting UX/messaging should stay platform-neutral
   unless the underlying capability genuinely doesn't exist elsewhere —
   don't let install prompts, offline messaging, etc. read as if the app
   were iOS-first with Android/other-browsers as an afterthought.

**Why**: user feedback (2026-08-06) — "개발 목적에 대해 계속 잊어버리는 것 같은데"
(you keep forgetting the point of this project), said after a design
discussion (taxi fare estimation) that drifted through several proposals
that didn't fit these constraints before landing on one that did:
- Kakao T native deep links → rejected, foreign users don't know Kakao/Naver
  and native URL schemes don't work on web anyway (constraints 1 + 3)
- MapKit/MKDirections (from a pasted Swift code sample) → doesn't run in a
  browser at all (constraint 3); user pointed out it was never even real
  iOS-app functionality, just another assistant's unverified speculation
- Self-hosted/public OSRM routing → real road data, but requires network
  every call → fails constraint 2 outright, and adds new infra that's hard
  to walk back later
- Landed on: on-device haversine distance + already-cached place
  coordinates + client-side fare math — satisfies all 4 (works for
  foreigners with no explanation needed, fully offline once the PWA's been
  opened once online, pure browser JS, no native/backend dependency)

**How to apply**: Before proposing or implementing any kolo_pwa feature,
check it against these four explicitly, not just against "does it work" —
the taxi phrase-card (copy-to-clipboard Korean phrases, no map deep link)
and the fare-estimate feature (haversine, not a routing API) are the
concrete precedents for what "fits" looks like. When a design instinct
reaches for a native-platform pattern, an always-online API, or an
admin-console shortcut, treat that as a signal to re-check against this
list before proceeding.
