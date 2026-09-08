---
name: feedback-popup-scroll-lock
description: any modal/popup added anywhere in this project must lock background scroll/interaction while open
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a32cc0c8-cf14-46a9-8fa9-b2e4c9abd8f1
  modified: 2026-07-31T11:02:30.661Z
---

Whenever a modal/popup dialog is added (in kolo_pwa's admin console `admin-h6q2xk`, the main PWA `app.js`, or kolo-api-adjacent tooling), lock the background page's scroll while it's open and restore it on close -- don't just toggle the overlay's `hidden` attribute and assume a `position: fixed` overlay is enough.

**Why:** the user explicitly flagged this ("팝업을 띄우는 화면에서는 백그라운드 화면이 컨트롤(스크롤포함)이 안되도록해줘") and asked it be remembered for all future popups, not just the one that prompted it. A `position: fixed` overlay stops clicks from reaching the background, but does nothing about wheel/touch/keyboard scroll on the body behind it -- scroll chaining lets the background keep scrolling once the modal's own content hits its scroll boundary.

**How to apply:** on modal open, set `document.body.style.overflow = 'hidden'`; on modal close, restore it (`= ''`). In kolo_pwa's admin console this is `lockBodyScroll()`/`unlockBodyScroll()` in `admin.js` (added 2026-07-31 alongside the place-edit modal, see `openPlaceForm()`/`closePlaceForm()`) -- reuse those two functions for any new modal in that file rather than re-solving it. If building a modal elsewhere in the codebase without those helpers already in scope, replicate the same pattern (lock on open, unlock on close, including the Escape-key and backdrop-click close paths).
