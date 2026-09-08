---
name: feedback-privilege-boundaries
description: "User declines to grant standing elevated access (SSH keys, PATs, etc.) even when it would reduce repetitive manual steps"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dc19f6d-289d-4ce4-a69f-ba37a4def5c8
  modified: 2026-07-22T03:01:04.416Z
---

User explicitly declined an offer to set up SSH key-based access to their Synology NAS (even a command-restricted key limited to `docker compose restart`/`up -d`) so that container restarts after backend deploys could be automated instead of requiring a manual step each time.

**Why:** "개발을 위해 권한을 풀기 시작하면 권한의 의미가 없어질 것 같아" — if permissions get loosened for development convenience, the whole point of having permission boundaries erodes. This is a considered security posture, not reluctance from lack of trust in a specific instance.

**How to apply:** Don't propose granting the agent new standing/persistent access (SSH keys, PATs, credential storage, expanded scopes, etc.) as a way to reduce friction or turn/token overhead in repetitive workflows, even with mitigations offered (scoped tokens, command-restricted keys). It's fine to point out where a manual step is the friction point in a workflow, but the resolution should be tooling/scripting improvements within existing access — not privilege expansion. If the user raises it themselves, that's different; don't reintroduce it unprompted after a decline like this one. See [[feedback_deferred_items]] for the related pattern of not proactively re-surfacing declined/deferred items.

Related instance: PAT-based GitHub Actions artifact download was also sidestepped earlier in the same conversation — user preferred installing local Java/Gradle to build things directly rather than granting API credential access, which fits the same underlying preference.
