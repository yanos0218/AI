---
name: feedback-no-direct-docker-access
description: "SSH/Docker access to the NAS from this environment is unreliable (port 22 often times out) — user handles all docker exec/restart/nginx-reload commands themselves, just needs the exact command"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 826f0ea2-f8c6-4d83-91ae-7eb7084cdacc
  modified: 2026-08-17T04:27:05.259Z
---

Don't attempt to SSH into the NAS (`ssh admin@yanos0218.i234.me ...`) or probe port 22 (`Test-NetConnection ... -Port 22`) to check reachability before asking the user to run a docker/container command. This environment's SSH access to the NAS has repeatedly timed out (2026-08-17), and the user has explicitly said they'll run these commands themselves — asking them what command is needed, not for me to attempt it and report back.

**Why:** User corrected this twice in one session (2026-08-17): first after I hit an SSH timeout and asked them to run the restart manually, then again minutes later when I tried to probe port 22 "to check if it's back" before another docker step — "docker관련해서는 접근이 안되어서 내가 대신해준다고 했는데 계속 작업 방법에 대해 잊고 있네" (I already said I'd handle docker access myself since you can't reach it, and you keep forgetting this approach). This is distinct from [[feedback_privilege_boundaries]] (declining to grant standing SSH access) — this is about not even *attempting* transient reachability checks once the user has told me to just hand them the command.

**How to apply:** Whenever a step needs `docker exec`, `docker compose restart/up -d`, `nginx -t`/`nginx -s reload` inside a container, or any other NAS-side shell command — skip trying it myself (including reachability probes like `Test-NetConnection`/`ssh` to "see if it's back up") and go straight to giving the user the exact command to run and asking them to confirm when done. Don't re-litigate this per deploy; treat it as standing guidance for the rest of the project, not just the session it was said in.
