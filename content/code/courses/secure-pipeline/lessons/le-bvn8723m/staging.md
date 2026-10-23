---
title: Staging that runs the way production will
version: 1
---

Lesson 4 built staging for the dynamic scan: a network made for one run, linkbox in one container
and ZAP in another. It started linkbox with `docker run` and its defaults, which means **the scan
tested a container that production should never run**: writable, with fourteen capabilities in
reach. A staging environment earns its name by matching what it stands in for, and a control that
breaks the application is better found by a nightly scan than by the first deployment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"sp-l09-staging\" aria-label=\"One run of the dynamic-scan stage. A network is made for the run. linkbox starts on it read-only, with no capabilities and no new privileges, and ZAP's baseline scan requests its pages from a second container. ZAP's exit status becomes the stage's: 0 passes, 2, a warning, becomes 3, and anything else, including a scan that could not reach the application, becomes 1 and breaks the build.\"><defs><marker id=\"sp-l09-staging-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"400\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a network for this run only</text><rect x=\"35\" y=\"60\" width=\"360\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">linkbox:&lt;commit&gt;</text><text x=\"215.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read-only, no capabilities</text><rect x=\"35\" y=\"175\" width=\"360\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ZAP baseline, -z -silent</text><text x=\"215.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zaproxy/zap-stable:2.17.0</text><path d=\"M215 173 L215 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><text x=\"222\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests every page it finds</text><text x=\"500\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ZAP exits</text><text x=\"650\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the stage exits</text><rect x=\"445\" y=\"55\" width=\"110\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><rect x=\"590\" y=\"55\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"647.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passed</text><path d=\"M555 78 L588 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><rect x=\"445\" y=\"121\" width=\"110\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><rect x=\"590\" y=\"121\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"647.5\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">warning</text><path d=\"M555 144 L588 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><rect x=\"445\" y=\"187\" width=\"110\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">anything else</text><rect x=\"590\" y=\"187\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"647.5\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">build broken</text><path d=\"M555 210 L588 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><line x1=\"397\" y1=\"203\" x2=\"425\" y2=\"203\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"425\" y1=\"78\" x2=\"425\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><path d=\"M425 78 L443 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><path d=\"M425 144 L443 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><path d=\"M425 210 L443 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path></svg>", "caption": "The same scan as lesson 4, against a container started the way production starts it."}
```

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

```
ana@vm:~/linkbox$ git diff ci/dast.sh
diff --git a/ci/dast.sh b/ci/dast.sh
index 685912a..4bba5ea 100644
--- a/ci/dast.sh
+++ b/ci/dast.sh
@@ -1,14 +1,17 @@
 # Dynamic analysis: the image this run built, started on a network of its
-# own, and ZAP's baseline scan against it from a second container. The scan
-# only looks: it reads what the application answers and sends it nothing
-# meant to break it. ZAP's own exit status is the verdict: a rule set to FAIL
-# in ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
+# own the way it runs everywhere, read-only and with no privileges, and ZAP's
+# baseline scan against it from a second container. The scan only looks: it
+# reads what the application answers and sends it nothing meant to break it.
+# ZAP's own exit status is the verdict: a rule set to FAIL in
+# ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
 # could not finish breaks the build too.
 set -uo pipefail
 net=linkbox-staging-$$
 docker network create "$net" >/dev/null
 trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
 docker run -d --rm --name "$net-app" --network "$net" \
+  --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 \
+  --cap-drop ALL --security-opt no-new-privileges \
   -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
 sleep 2
 docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
```

**Only the comment and two lines of flags.** The scan itself, the network, the clean-up and the
mapping of ZAP's exit status to pass, warning or break are lesson 4's and lesson 7's, untouched.
The memory and process limits stay out, as the last section argued: staging lives for a minute.

### The nightly run

The dynamic scan is in the nightly list, so run that list by hand. Its first stage rebuilds the
image with no cache, as lesson 2 arranged:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/nightly
rebuild: passed in 16s
dast: WARNING in 21s, the end of dast.log:
  PASS: Sub Resource Integrity Attribute Missing [90003]
  PASS: Charset Mismatch [90011]
  PASS: Application Error Disclosure [90022]
  PASS: WSDL File Detection [90030]
  PASS: Loosely Scoped Cookie [90033]
  WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
  	http://linkbox-staging-19276-app:8000/search?q=ZAP (200 OK)
  FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
pipeline passed with 1 warning(s)
```

**The same verdict as before the change: a warning for rule 10031**, the false positive lesson 4
decided from the response, and every other rule passing. That is the result that matters here.
linkbox ran read-only, as user 65532, with no capabilities and no way to gain any, for the whole
length of a scan that requested every page it could find, and nothing failed. **If one of the
flags had broken something, this is where it would have shown**, as a scan that could not reach
the application, which lesson 7 made a broken build rather than a quiet pass.

### Commit it

```
ana@vm:~/linkbox$ git commit -q -am "staging runs the image read-only, as nobody, with no capabilities"
9:24AM INF 0 commits scanned.
9:24AM INF scanned ~483 bytes (483 bytes) in 262ms
9:24AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 9b4047a        
remote: secrets: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 2s        
remote: sca: passed in 10s        
remote: build: passed in 0s        
remote: image: passed in 3s        
remote: push: passed in 0s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   cd24a71..9b4047a  main -> main
```

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
