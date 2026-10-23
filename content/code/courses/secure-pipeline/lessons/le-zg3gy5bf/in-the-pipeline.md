---
title: The image stage, the registry, and the next build
version: 1
---

Two stages join the pipeline after `build`. **`image` scans the image the run just built, and
`push` puts it in a registry, in that order**, so nothing reaches the registry that a check before
it refused. The registry is where lesson 10's cluster pulls from, and later lessons sign what is in
it (lesson 14) and describe it (lesson 13).

### A registry of your own

A registry is a server that stores images and answers Docker's pull and push requests. The
official one, `registry`, runs as a container. Start it once; `--restart=always` brings it back
after a reboot:

```
ana@vm:~/linkbox$ docker run -d --restart=always -p 127.0.0.1:5000:5000 --name registry registry:3.1.2
24d14b09a7ec5442e62c93a6dd8adc4bdf7c82816cb3fc48b1aeb42ea32e0776
ana@vm:~/linkbox$ curl -s http://localhost:5000/v2/_catalog
{"repositories":[]}
```

**It listens on `127.0.0.1` only, with no password and no TLS**, which is acceptable for a registry
that nothing outside this computer can reach and nothing else. Docker allows plain HTTP to
`localhost` without configuration for exactly this use. A registry shared by a team needs TLS and
authentication, both described in the registry's own documentation and neither set up here; a
hosted one (GitHub's, GitLab's, a cloud provider's) has both from the start.

### The two stages

The scan, with the rule of the last two sections. Save it as `ci/image.sh`:

```sh
# The image this run built, scanned before it goes anywhere. A high or
# critical vulnerability that already has a fixed version breaks the build.
# The rest, which no rebuild can fix yet, is counted in the log for whoever
# reviews the base image.
set -uo pipefail
image=linkbox:${CI_COMMIT:-dev}
trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$image" || exit 1
echo "everything else, fixed or not:"
trivy image --quiet "$image" | grep '^Total'
exit 0
```

`|| exit 1` matters more than it looks. Trivy exits with 1 both when it finds something and when it
fails to run, for example because the image does not exist, and **both have to break the build**:
lesson 7's rule that a scanner which did not run is not a pass. The second scan only counts, so its
status is ignored and the stage ends with `exit 0`.

The push. A run on any branch pushes the image under its commit; a run on `main` also moves the tag
`main`, which is what lesson 10's manifest names. Save it as `ci/push.sh`:

```sh
# The image, into the registry. It is the last stage, so nothing reaches the
# registry that a stage before it refused. A run on main also moves the tag
# main, which is what the cluster's manifest names.
set -euo pipefail
tag=localhost:5000/linkbox:${CI_COMMIT:-dev}
docker tag "linkbox:${CI_COMMIT:-dev}" "$tag"
docker push -q "$tag"
if [ "${CI_BRANCH:-}" = main ]; then
  docker tag "$tag" localhost:5000/linkbox:main
  docker push -q localhost:5000/linkbox:main
fi
```

And the list, with both at the end, as `ci/stages`:

```
secrets
test
sast
sca
build
image
push
```

### The first run

Commit the Dockerfile and the three files, and push. The `INF` lines are lesson 6's pre-commit hook
checking the commit for secrets:

```
ana@vm:~/linkbox$ git add Dockerfile ci
ana@vm:~/linkbox$ git commit -q -m "a two-stage image on a distroless base, scanned and pushed to the registry"
9:40AM INF 0 commits scanned.
9:40AM INF scanned ~1619 bytes (1.62 KB) in 361ms
9:40AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at f73b23a        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 9s        
remote: build: passed in 1s        
remote: image: passed in 1s        
remote: push: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   965e448..f73b23a  main -> main
```

**Seven stages, all passed, and the image stage took about a second**, because it reads the
database this machine already has. The log says what the gate looked at and what it only counted:

```
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/image.log

Report Summary

┌────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                     Target                     │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ linkbox:f73b23a (debian 13.7)                  │   debian   │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/blinker-1.9.0.dist-info/METADATA      │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/click-8.1.7.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/flask-3.1.3.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/gunicorn-22.0.0.dist-info/METADATA    │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/itsdangerous-2.2.0.dist-info/METADATA │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/jinja2-3.1.6.dist-info/METADATA       │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/markupsafe-2.1.3.dist-info/METADATA   │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/packaging-26.3.dist-info/METADATA     │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/werkzeug-3.1.9.dist-info/METADATA     │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

everything else, fixed or not:
Total: 162 (UNKNOWN: 0, LOW: 49, MEDIUM: 87, HIGH: 26, CRITICAL: 0)
ana@vm:~/linkbox$ curl -s http://localhost:5000/v2/linkbox/tags/list
{"name":"linkbox","tags":["f73b23a","main"]}
```

The summary has a row for each list Trivy read, the Debian database and one `METADATA` per package
in `/packages`, and **0 in every row**, because only fixable high and critical findings were asked
for. Below it, the count of everything: the same 162. The registry now holds the image twice, under
the commit and under `main`.

The stage's other way of breaking is worth seeing once. Ask it to scan an image that does not
exist, here by giving it a commit nobody built:

```
ana@vm:~/linkbox$ CI_COMMIT=0000000 bash ci/image.sh; echo "exit $?"
2026-10-23T09:40:50-03:00	FATAL	Fatal error	run error: image scan error: scan error: unable to initialize a scan service: unable to initialize artifact: unable to initialize container image: unable to find the specified image "linkbox:0000000" in ["docker" "containerd" "podman" "remote"]: 4 errors occurred:
	* docker error: unable to inspect the image (linkbox:0000000): Error response from daemon: No such image: linkbox:0000000
	* containerd error: failed to list images from containerd client: connection error: desc = "transport: Error while dialing: dial unix /run/containerd/containerd.sock: connect: permission denied"
	* podman error: unable to initialize Podman client: no podman socket found: stat podman/podman.sock: no such file or directory
	* remote error: GET https://index.docker.io/v2/library/linkbox/manifests/0000000: UNAUTHORIZED: authentication required; [map[Action:pull Class: Name:library/linkbox Type:repository]]


exit 1
```

**Trivy could not run, said so, and exited 1, and the stage passed that on.** Had `ci/image.sh` read
Trivy's output instead of its status, or ended with an unconditional `exit 0`, a renamed tag would
have turned the image check into a stage that passes every image forever.

### What the gate does with the old image

To see the stage break, put lesson 1's Dockerfile back on a branch of its own and push it. Every
stage before `image` passes, because nothing about the code changed. The table the scanner prints
is too wide for this page, so the lines of the table are filtered out of the push's output here, and
the second command prints the same findings one per line:

```
ana@vm:~/linkbox$ git switch -q -c old-base
ana@vm:~/linkbox$ git checkout main~1 -- Dockerfile
ana@vm:~/linkbox$ git commit -q -m "the single-stage image, to see what the gate says"
9:40AM INF 0 commits scanned.
9:40AM INF scanned ~140 bytes (140 bytes) in 201ms
9:40AM INF no leaks found
ana@vm:~/linkbox$ git push ci old-base 2>&1 | grep -v '[│├└┌]'
remote: run 2: old-base at e152fa6        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 9s        
remote: build: passed in 1s        
remote: image: FAILED in 49s, the end of image.log:        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      old-base -> old-base
ana@vm:~/linkbox$ trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --format json linkbox:$(git rev-parse --short HEAD) | jq -r '.Results[].Vulnerabilities[]? | "\(.PkgName) \(.InstalledVersion)  \(.VulnerabilityID)  \(.Severity)  fixed in \(.FixedVersion)"'
msgpack 1.1.2  GHSA-6v7p-g79w-8964  HIGH  fixed in 1.2.1
setuptools 70.3.0  CVE-2025-47273  HIGH  fixed in 78.1.1
urllib3 2.7.0  CVE-2026-97687  HIGH  fixed in 2.8.0
urllib3 2.7.0  CVE-2026-97689  HIGH  fixed in 2.8.0
```

**The image stage broke the build on four findings, and none of them is in linkbox's code or
dependencies.** They are the pip of `python:3.13`, found through pip's own list, the way the first section of
this lesson showed. The
image never reached the registry, because `push` comes after `image` and the run stopped.

### The next build

A scan answers for the day it ran. The image in the registry does not change, and the advisories
about it do: tomorrow's database knows things today's does not, and a base image that scans clean
today will not in a month. Two habits keep up with that, and lesson 2 already built the first.

**The nightly list rebuilds the image from nothing.** `ci/nightly` runs `rebuild`, a
`docker build --no-cache`, so everything the build fetches is fetched again even when no commit
changed. Read that stage with this lesson in mind, though: `--no-cache` rebuilds every layer and
reuses the base image already on the machine. Picking up a newer `distroless` or `slim` needs the
registry to be asked again, which `docker build --pull` does. Lesson 15 goes further and names the
base by digest, so that moving to a new base image is a commit somebody reviews.

**And what is running gets scanned again, not only what is being built.** The image a cluster
pulled last week was scanned last week. Lesson 13 keeps an SBOM of every image the pipeline
pushes, so that a new advisory can be checked against everything shipped in minutes, without
pulling a single image.
