---
name: feedback-version-display-decision
description: "kolo_pwa's \"버전\" label stays as kolo-vXX (cache name) only -- don't propose combining it with the SemVer release tag"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dc19f6d-289d-4ce4-a69f-ba37a4def5c8
  modified: 2026-07-25T01:38:43.012Z
---

kolo_pwa's Support screen "버전" label shows the service worker's `CACHE_NAME` (e.g. `kolo-v63`), not the git release tag (`v1.13.0`). User explicitly considered and declined combining both (2026-07-25): "버전은 현재 상태를 유지하자."

**Why:** Two reasons surfaced during the discussion. (1) A release tag can't be auto-injected into this build-tool-free static site -- showing it would need a manually-updated constant at each release-cut commit, a new sync point *more* fragile than `CACHE_NAME` itself (which already needed a CI guard, `cache-name-check`, because bumping it by hand kept getting forgotten). (2) Showing both together risks reinforcing exactly the confusion [[project_kolo_pwa_versioning]]/`docs/versioning.md` already warns against: release tags are cut far less often than real deploys (this session: ~20 NAS deploys, 1 release cut), so a viewer could mistake the tag for being as precise/current as the cache name, when it isn't.

**How to apply:** If asked again to show a SemVer version in the running app UI, don't propose it fresh -- surface this history first. The decision is recorded in `docs/PROGRESS.md`'s 보류 항목 (deferred items) section too. Per [[feedback_deferred_items]], don't proactively re-raise this — only if the user asks or directly relevant work comes up.
