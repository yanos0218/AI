---
name: feedback-release-cadence
description: "승격 제안과 릴리즈 컷을 묶어 제안하지 말 것 — 2026-09-09 하루에 v0.1.0→v0.4.0이 된 뒤 사용자가 빈도를 지적"
metadata:
  type: feedback
---

승격(초안 → base/)을 제안할 때 "승인하시면 vX.Y.Z로 컷"을 붙이지 않는다. 승격은 `[Unreleased]`에 쌓고, 컷은 (a) 다른 기기·웹 설치 직전 (b) 월 점검 (c) 사용자의 명시적 요청 때만.

**Why:** 2026-09-08~09 승격 하나마다 컷을 제안했고 사용자는 묶음을 통째로 승인했다. 하루 만에 v0.4.0이 됐지만 Mac·Linux·웹에는 아무것도 설치되지 않아 번호만 앞서갔다. 사용자가 "버전 정의에 따라 진행되는 게 맞나?"라고 지적. 등급(MINOR)은 규칙대로였으나 빈도가 `docs/versioning.md` "모이면 컷"에 어긋났다.

**How to apply:** 컷은 dev-release 스킬 절차대로 사용자가 요청할 때만. 제안문에 버전 번호를 넣지 않는다. 관련: [[project-claude-config-roadmap]]
