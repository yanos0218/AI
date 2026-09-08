---
name: project-local-java-available
description: "Java 21 (Temurin) and Gradle wrapper ARE available on this machine for kolo-api -- not on PATH by default; combined with local MariaDB (see project_local_mariadb_available), the real test suite runs locally now, not just compile-checks"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5dc19f6d-289d-4ce4-a69f-ba37a4def5c8
  modified: 2026-08-13T11:22:15.989Z
---

Found 2026-07-25 (same class of discovery as [[project_local_node_available]] for kolo_pwa): `C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot` has a working Java 21 JDK, not on the PATH this session's Bash tool inherits by default (`which java` fails until added). `kolo-api`'s `gradlew` wrapper works once Java is on PATH.

To use it: `export PATH="/c/Program Files/Eclipse Adoptium/jdk-21.0.11.10-hotspot/bin:$PATH"` (Bash) before `java`/`./gradlew`.

**What this enables:** `cd kolo-api && ./gradlew compileJava compileTestJava` runs locally and catches syntax/type errors before pushing -- confirmed working (first run took ~16s including Gradle daemon startup). This is a real upgrade over the prior assumption ("no local Java/Gradle, CI is the only verification for kolo-api") that earlier sessions' summaries repeatedly stated.

**Superseded 2026-08-13**: MariaDB is now also installed locally (no Docker needed — installed directly via winget) — see [[project_local_mariadb_available]]. The "full `./gradlew test` isn't possible locally" limitation below no longer applies; the real test suite runs locally now, not just compile-checks.

**How to apply:** Before pushing a kolo-api change, run the PATH export + `./gradlew test` (not just `compileJava compileTestJava`) as the real local check — see [[project_local_mariadb_available]] for starting the DB server first. CI remains the final gate, but shouldn't be the first place a DB-dependent bug is caught.
