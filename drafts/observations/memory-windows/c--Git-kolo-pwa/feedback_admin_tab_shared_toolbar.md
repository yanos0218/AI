---
name: feedback-admin-tab-shared-toolbar
description: every new admin-h6q2xk tab must default to hiding the shared 새로고침/토큰 지우기 toolbar unless it genuinely needs it
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a32cc0c8-cf14-46a9-8fa9-b2e4c9abd8f1
  modified: 2026-07-31T10:17:47.269Z
---

Every time a new tab is added to kolo_pwa's admin console (`admin-h6q2xk`), check whether the shared "새로고침"/"토큰 지우기" toolbar (`refreshBtn`/`logoutBtn`, hidden via the `hideSharedToolbar` check in `admin.js`'s `switchTab()`) is actually useful on that tab — default to hiding it, don't default to leaving it visible.

**Why:** the user has flagged this same inconsistency multiple times across different feature additions ("관리자 메뉴의 기능이 추가될 때마다 지적되는 부분") — logs and analytics tabs already hide the shared toolbar (they have their own 조회/refresh flow), but new tabs (e.g. the 장소 관리 tab, added 2026-07-31) shipped without this consideration and left the redundant shared toolbar visible. The specific reason redundancy exists can differ per tab — logs/analytics have their own dedicated refresh button, whereas 장소 관리 has no external data source at all (only this admin's own CRUD actions change place data, and create/update/delete already call `loadPlaces()` themselves) — but the visible symptom (an ambiguous, redundant 새로고침 button) is the same class of problem each time.

**How to apply:** when building or reviewing any new admin-console tab, explicitly ask "does the shared toolbar add anything here, or does this tab already refresh itself through its own actions/controls?" before shipping — don't wait for the user to point it out again. If the tab has no dedicated refresh mechanism of its own but the shared toolbar genuinely would help (e.g. a tab showing data that changes from outside this session), keep it visible; otherwise hide it by adding the tab to the `hideSharedToolbar` condition in `admin.js`.
