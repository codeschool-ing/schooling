---
title: Staging that runs the way production will
version: 1
---

Lesson 4 built staging for the dynamic scan: a network made for one run, linkbox in one container
and ZAP in another. It started linkbox with `docker run` and its defaults, which means **the scan
tested a container that production should never run**: writable, with fourteen capabilities in
reach. A staging environment earns its name by matching what it stands in for, and a control that
breaks the application is better found by a nightly scan than by the first deployment.

@@FIGURE staging@@

### The change

Four flags join the `docker run` that starts linkbox, exactly the ones this lesson tested one at a
time. The new script, as `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own the way it runs everywhere, read-only and with no privileges, and ZAP's
# baseline scan against it from a second container. The scan only looks: it
# reads what the application answers and sends it nothing meant to break it.
# ZAP's own exit status is the verdict: a rule set to FAIL in
# ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
# could not finish breaks the build too.
set -uo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 \
  --cap-drop ALL --security-opt no-new-privileges \
  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -z -silent
case $? in
  0) exit 0 ;;
  2) exit 3 ;;
  *) exit 1 ;;
esac
```

What changed against lesson 7's version, as git shows it:

@@CAPTURE staging@@

**Only the comment and two lines of flags.** The scan itself, the network, the clean-up and the
mapping of ZAP's exit status to pass, warning or break are lesson 4's and lesson 7's, untouched.
The memory and process limits stay out, as the last section argued: staging lives for a minute.

### The nightly run

The dynamic scan is in the nightly list, so run that list by hand. Its first stage rebuilds the
image with no cache, as lesson 2 arranged:

@@CAPTURE nightly@@

**The same verdict as before the change: a warning for rule 10031**, the false positive lesson 4
decided from the response, and every other rule passing. That is the result that matters here.
linkbox ran read-only, as user 65532, with no capabilities and no way to gain any, for the whole
length of a scan that requested every page it could find, and nothing failed. **If one of the
flags had broken something, this is where it would have shown**, as a scan that could not reach
the application, which lesson 7 made a broken build rather than a quiet pass.

### Commit it

@@CAPTURE commit@@

The push runs `ci/stages`, which does not include the dynamic scan, so this run only proves the
change broke nothing else; the next nightly run is the one that exercises it. The pre-commit hook's
`INF` lines are lesson 6's secret scan, as on every commit.

### Where these flags go next

A flag in a script protects the containers that script starts. linkbox's real deployment, from
lesson 10, is not started by a script but by a Kubernetes manifest, and every flag of this lesson
has a field there:

| `docker run` | Kubernetes `securityContext` and pod spec |
|---|---|
| image's `USER`, checked | `runAsNonRoot: true` |
| `--read-only` | `readOnlyRootFilesystem: true` |
| `--tmpfs /tmp`, `--tmpfs /data` | `emptyDir` volumes mounted at `/tmp` and `/data` |
| `--cap-drop ALL` | `capabilities: {drop: ["ALL"]}` |
| `--security-opt no-new-privileges` | `allowPrivilegeEscalation: false` |
| Docker's default seccomp profile | `seccompProfile: {type: RuntimeDefault}` |
| `--memory`, `--pids-limit` | `resources.limits.memory`; a pid limit is set per node, by the kubelet |

The difference that matters is who checks. Here, the flags are present because the script says so,
and a different script could leave them out. In a cluster, lesson 10 makes the namespace refuse any
pod that leaves them out, whoever wrote the manifest.
