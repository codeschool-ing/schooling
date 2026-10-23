---
title: In the pipeline, and again at the cluster's door
version: 1
---

The rules and their tests are committed. What is left is to run them on every push, and to decide
where in the list they go.

### The stage

Save it as `ci/policy.sh`:

```sh
# Policy as code: this project's own rules, in policy/, over the files that
# say how linkbox is built and how it runs. The rules' own tests run first,
# so a rule that has stopped refusing what it was written to refuse breaks
# the build before it is trusted to pass anything.
set -euo pipefail
conftest verify --no-color
conftest test --no-color --namespace docker Dockerfile
conftest test --no-color --namespace kubernetes k8s/
```

Three commands, and `set -e` stops at the first that fails. The tests come first for the reason the
previous sections gave: if a rule no longer refuses what it was written to refuse, its passes mean
nothing, and the build should break on that before it reports any. `--no-color` keeps escape codes
out of the log; in your own terminal, leave it off and a failure prints in red.

The stage reads three things in the repository and nothing else: no image, no network, no cluster.
It takes well under a second, so it belongs near the front of the list, after the two stages that
check for secrets and for unsafe workflow files and before anything is installed or built. A broken
rule should cost the author seconds, not the minutes the image stages take. The list, as
`ci/stages`:

```
secrets
workflows
policy
test
sast
sca
build
image
push
sbom
sign
```

Eleven stages, the full list lesson 1's figure showed. Run the stage on your machine first, the
same script the server runs (lesson 2):

```
ana@vm:~/linkbox$ bash ci/policy.sh

18 tests, 18 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped

3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
```

Commit it and push:

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "the policies on every push"
1:55AM INF 0 commits scanned.
1:55AM INF scanned ~448 bytes (448 bytes) in 172ms
1:55AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 8e4c80c        
remote: secrets: passed in 1s        
remote: workflows: FAILED in 0s, the end of workflows.log:        
remote:   bash: ci/workflows.sh: No such file or directory        
remote: run 1: failed, the logs are in ~/ci/runs/1/logs        
To /home/ana/ci/linkbox.git
   0979302..8e4c80c  main -> main
```

Every stage passed, `policy` among them, and each line of its log is in the run's directory like any
other stage's.

### A change the pipeline refuses

The admission policy from lesson 10 is the cluster's last check on every Deployment. Suppose
somebody is debugging a refused deployment late in the day and changes the binding to `Warn`, so
that a refusal becomes a message and the deployment goes through. They mean to put it back. On a
branch:

```
ana@vm:~/linkbox$ git switch -q -c debug-admission
ana@vm:~/linkbox$ sed -i 's/validationActions: \["Deny"\]/validationActions: ["Warn"]/' k8s/admission.yaml
ana@vm:~/linkbox$ git diff --unified=0
diff --git a/k8s/admission.yaml b/k8s/admission.yaml
index fbd2608..6ea106d 100644
--- a/k8s/admission.yaml
+++ b/k8s/admission.yaml
@@ -32 +32 @@ spec:
-  validationActions: ["Deny"]
+  validationActions: ["Warn"]
ana@vm:~/linkbox$ git commit -q -am "admission: warn while debugging"
1:55AM INF 0 commits scanned.
1:55AM INF scanned ~30 bytes (30 bytes) in 178ms
1:55AM INF no leaks found
ana@vm:~/linkbox$ git push ci debug-admission
remote: run 2: debug-admission at b892ec2        
remote: secrets: passed in 1s        
remote: workflows: FAILED in 0s, the end of workflows.log:        
remote:   bash: ci/workflows.sh: No such file or directory        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      debug-admission -> debug-admission
```

The run stopped at `policy`, before the tests, the build or anything that takes time, and the last
lines of the log name the file, the rule and the fix. Without this stage the change would have been
reviewed as a one-word diff in a YAML file, and the cluster would have gone on accepting every
Deployment, the policy still installed and listed by `kubectl` as though it worked.

Throw the branch away:

```
ana@vm:~/linkbox$ git switch -q main
ana@vm:~/linkbox$ git branch -D debug-admission
Deleted branch debug-admission (was b892ec2).
```

### One rule, checked twice

The policy refuses images from outside `localhost:5000`, and so does lesson 10's admission policy
on the cluster. The same decision is written in two languages, Rego and CEL, and checked in two
places. **That is not duplication to remove; the two checks guard different doors.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"sp-l19-twice\" aria-label=\"Two doors for one rule. A developer's commit goes to the repository, where the pipeline's policy stage runs conftest over the files and refuses the push before anything is built. Any request to the cluster, from the pipeline or from a laptop running kubectl apply, reaches the API server, where the admission policy refuses the object before it is stored. The pipeline sees the commit and the review; admission sees every object, however it arrived.\"><defs><marker id=\"sp-l19-twice-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l19-twice-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l19-twice-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"40\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a developer</text><rect x=\"170\" y=\"40\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the repository</text><text x=\"235.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a commit</text><rect x=\"335\" y=\"32\" width=\"170\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pipeline: policy stage</text><text x=\"420.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">conftest over the files</text><path d=\"M135 63 L168 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-paper-dim)\"></path><path d=\"M300 63 L333 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-paper-dim)\"></path><text x=\"420\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">sees: the commit, its review, its author</text><rect x=\"15\" y=\"170\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"75.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a laptop</text><rect x=\"335\" y=\"162\" width=\"170\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><text x=\"420.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">ValidatingAdmissionPolicy (CEL)</text><rect x=\"560\" y=\"170\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"632.5\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">stored and scheduled</text><path d=\"M505 193 L558 193\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-paper-dim)\"></path><path d=\"M505 63 L530 63 L530 140 L420 140 L420 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-phosphor)\"></path><text x=\"538\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">deploys</text><path d=\"M135 193 L333 193\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l19-twice-ah-amber)\"></path><text x=\"234\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">kubectl apply, outside the pipeline</text><text x=\"420\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sees: every object, however it arrived</text></svg>", "caption": "The pipeline stops the author early and cheaply. The cluster stops everybody, including whoever went around the pipeline."}
```

| | the pipeline (conftest) | the cluster (admission) |
|---|---|---|
| when it runs | on every push, before anything is built | on every create or update of a Deployment |
| what it sees | the files in the commit, as written | the object as it reaches the API server, including anything added on the way |
| what it cannot see | a `kubectl apply` from a laptop, a manifest that never went through the repository, an object changed on the cluster by hand | the review: who changed the rule and why, and which commit it came from |
| who it stops | the author of the change, with the message in their own pipeline | anybody and anything with access to the cluster, including a compromised pipeline |
| what a failure costs | seconds, and a fix in the same branch | a failed deploy, noticed at deploy time |

The pipeline is the early check: cheap, specific, and aimed at the person who can fix the problem.
The cluster is the last one: it holds even when the pipeline was skipped, misconfigured or
subverted, which is lesson 16's subject. Neither replaces the other. A rule enforced only in CI is a
convention anybody with `kubectl` can ignore; a rule enforced only at admission is one that every
developer meets for the first time at deploy time, too late to be cheap.

Keeping the two in step is the cost. A rule changed in one place and not the other is a gap that
looks like coverage. Two habits keep it honest. Change both in the same commit, which works because
linkbox's repository holds both. And let the pipeline check the admission policy's own settings, as
the last two rules in `policy/kubernetes.rego` do, so the cluster's check cannot be weakened without
the pipeline saying so.

Gatekeeper runs OPA itself as an admission controller, so the same Rego could serve both doors.
That is a reasonable choice on a larger platform. This course keeps CEL at the cluster because it is
built into Kubernetes and needs nothing installed; Gatekeeper is described here from its
documentation and was not installed.
