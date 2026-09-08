---
name: feedback-collector-scope-vs-insertability
description: "collection/comparison scope must never be narrowed to match a downstream system's current insert-time constraints"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e1b7a55-7822-438d-932d-819734f26b43
  modified: 2026-08-04T06:57:02.579Z
---

Don't scope a data-collection/comparison tool down to match what a downstream system (here, kolo-api) can currently *store* — those are two separate concerns. The user caught this in `scripts/place-collector/`: it was originally designed to collect nationwide (시도/구 level), but during implementation the region list got quietly narrowed to just the 4 neighborhoods kolo-api's `district` field currently whitelists. The user pushed back hard: "수집기는 정보를 수집하기 위한 기능이며... 왜 kolo-api와 연관성을 짓는 것일까?" — collection and comparison should show the full real picture regardless of what can be written today; only the final insert/commit step should be gated by the target system's current constraints.

**Why**: Conflating "can I structurally describe this" with "can the target system accept this right now" silently throws away information the user explicitly wanted visibility into, and narrows a tool's scope without ever being asked to.

**How to apply**: When building a pipeline that collects/normalizes/compares data before an optional write step, keep a clear `valid` (structurally sound) vs `insertable`/`writable` (also accepted by the current target-system constraints) distinction. Never let the target system's current whitelist/schema limits define the collection or comparison scope itself — only gate the actual write. See [[project_place_collector_python_migration]] for the tool this applies to.

Related, same tool, same session: the user also wants multi-step pipelines broken into explicit sequential decision points (see each stage's output before choosing to continue) rather than one call that does everything and reports back only at the end — applied here as `collect_stage`/`diff_stage`/commit as 3 separate actions (CLI: same run, printed in order; web UI: 3 separate buttons), plus always-visible remaining-quota info before/after each stage.
