---
title: Secrets first in the pipeline
version: 1
---

The server is where the check is enforced: the hook can be skipped and the platform's push
protection may not exist, but every push reaches the CI, and the CI holds every branch. **The stage
scans the whole history of the pushed commit**, not only the change, so a secret that arrived in a
merge, a rebase or a branch from somebody without the hook is found all the same.

### The stage

Save it as `ci/secrets.sh`:

```sh
# Secret scanning: every commit the repository holds, not only the files as
# they are now, because a secret deleted in a later commit is still in the
# history. A finding breaks the build. .gitleaksignore lists the findings
# that were rotated and are dead.
set -euo pipefail
gitleaks git --no-banner --no-color --redact --verbose .
```

`--redact` matters more here than anywhere else. **A CI log is read by everybody with access to the
project's builds, and is often kept longer than the code**, so a scanner that printed the secret
into it would publish it a second time, in a place nobody thinks of when the time comes to clean
up. `--verbose` keeps the file, the line and the commit, which is everything a person needs to act.

### Why it goes first

Save the new order as `ci/stages`:

```
secrets
test
sast
sca
build
```

Three reasons, in decreasing order of weight. A secret is the one finding whose answer never
depends on the rest of the run: whatever the tests say, a pushed secret is revoked. It is also the
cheapest stage, a fraction of a second for a history this size, as its log at the end of this
section shows, so putting it first costs the other stages nothing. And the later stages copy the repository into places that outlive the run: the image the
build stage makes contains every file of the checkout that `.dockerignore` does not exclude, and
an image is pushed to a registry from lesson 8 on. **A run that stops at `secrets` copies the
secret nowhere new.**

The stage has no warning level. Lesson 7 builds the distinction between findings that break the
build and findings that only warn, and a secret falls on one side of it with no argument: the
person who pushed it can act on it at once, by revoking it.

### The staging copy needs a token now

`settings.py` refuses to start without `LINKBOX_TOKEN`, and the image does not carry one, which is
right: an image is copied to registries and laptops, and a token baked into it would be another
copy of a secret. So the image, started bare, stops:

```
ana@vm:~/linkbox$ docker build -q -t linkbox:dev . && docker run --rm linkbox:dev 2>&1 | tail -n 5
sha256:efc899b7dd57ca52ce9432b1a77465ae44ac64a55b5bcf2d06a0c2087f3f3c1d
KeyError: 'LINKBOX_TOKEN'
[2026-10-23 05:00:28 +0000] [7] [INFO] Worker exiting (pid: 7)
[2026-10-23 05:00:28 +0000] [1] [ERROR] Worker (pid:7) exited with code 3
[2026-10-23 05:00:28 +0000] [1] [ERROR] Shutting down: Master
[2026-10-23 05:00:28 +0000] [1] [ERROR] Reason: Worker failed to boot.
```

The worker raised the same `KeyError` the tests did, and gunicorn gave up, which is the refusal
from two sections back working one level up. The dynamic scan of lesson 4 starts that image on a
network of its own, so it has to pass a token. **It makes one for the run, from the operating
system's random source, and nothing keeps it**: the container is removed when the scan ends, and
the token with it. Save it as `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own, and ZAP's baseline scan against it from a second container. The scan
# only looks: it reads what the application answers and sends it nothing
# meant to break it. A rule set to FAIL in ci/zap-rules.conf breaks the build.
set -euo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -I -z -silent
```

The value appears on the `docker run` command line, where another user of the same machine could
read it in the process list for the length of the scan. For a token that opens one container on a
network of its own, for a minute, that is acceptable; for a real one it would not be, and lesson 17
replaces values like this with ones the pipeline fetches at run time.

### The run

Commit the three files and push. The hook from the last section scans the commit on the way, and
says so:

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "secret scanning first in the pipeline, and a token for the staging copy"
2:00AM INF 0 commits scanned.
2:00AM INF scanned ~494 bytes (494 bytes) in 263ms
2:00AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at bd8e771        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 8s        
remote: build: passed in 1s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   19d0738..bd8e771  main -> main
```

The `secrets` stage passed, and its log says what that pass means:

```
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/secrets.log
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
2:00AM INF 8 commits scanned.
2:00AM INF scanned ~10040 bytes (10.04 KB) in 275ms
2:00AM INF no leaks found
```

**Eight commits scanned and nothing found**, because the one finding the history holds is recorded
as dead in `.gitleaksignore`. Had that file been missing, the run would have stopped at the first
stage, with the token's fingerprint in the log, redacted. From now on, every push to the server
reads the whole history before anything else runs.
