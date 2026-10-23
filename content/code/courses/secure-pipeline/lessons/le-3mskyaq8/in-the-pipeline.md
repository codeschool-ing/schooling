---
title: Workflows checked on every push
version: 1
---

A workflow file is code that runs with credentials, so it gets what every other kind of code in
this repository gets: a check on every push that breaks the build when it finds something. The
stage is one line of zizmor. Save it as `ci/workflows.sh`:

```sh
# The workflows and the bots' settings under .github, audited by zizmor with
# no network: what it can judge from the files alone. Any finding it reports
# breaks the build.
set -euo pipefail
zizmor --quiet --offline .github
```

It reads all of `.github`, so the settings files that lesson 18 adds there for the update bots are
read too. And it goes second, right after `secrets`, because it takes a second and reads only text.
Save the list as `ci/stages`:

```
secrets
workflows
test
sast
sca
build
image
push
sbom
sign
```

### The run

Commit the workflow and the stage together, and push:

```
ana@vm:~/linkbox$ git add .github ci
ana@vm:~/linkbox$ git commit -q -m "the pipeline's own workflow hardened, and checked by zizmor on every push"
9:46AM INF 0 commits scanned.
9:46AM INF scanned ~1130 bytes (1.13 KB) in 219ms
9:46AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 5834f06        
remote: secrets: passed in 0s        
remote: workflows: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 10s        
remote: build: passed in 2s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 5s        
remote: sign: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   42b39e2..5834f06  main -> main
```

`workflows` passed second, and the other nine passed as they did in lesson 15. The local CI does not
run the workflow, and it does not need to: it reads it, which is the check that matters for a file
whose risk is in what it says.

### A regression, caught

A month later, somebody finds `env:` and `$TITLE` roundabout and puts the title back where it was.
On a branch:

```
ana@vm:~/linkbox$ git switch -q -c title-in-run
ana@vm:~/linkbox$ git diff | grep "^[-+] "
-        run: echo "testing $TITLE"
+        run: echo "testing ${{ github.event.pull_request.title }}"
ana@vm:~/linkbox$ git commit -q -am "print the title directly"
9:46AM INF 0 commits scanned.
9:46AM INF scanned ~67 bytes (67 bytes) in 255ms
9:46AM INF no leaks found
ana@vm:~/linkbox$ git push ci title-in-run
remote: run 2: title-in-run at c99af99        
remote: secrets: passed in 1s        
remote: workflows: FAILED in 0s, the end of workflows.log:        
remote:   error[template-injection]: code injection via template expansion        
remote:     --> .github/workflows/ci.yml:27:32        
remote:      |        
remote:   27 |         run: echo "testing ${{ github.event.pull_request.title }}"        
remote:      |         --- this run block     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ may expand into attacker-controllable code        
remote:      |        
remote:      = note: audit confidence → High        
remote:      = note: this finding has an auto-fix        
remote:      = help: audit documentation → https://docs.zizmor.sh/audits/#template-injection        
remote:           
remote:   1 findings (1 unsafe fixes): 0 informational, 0 low, 0 medium, 1 high        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      title-in-run -> title-in-run
```

**The branch stops at the second stage**, with the finding and the line, before a test runs or an
image is built. The fix is the one the previous section made, and the stage will keep asking for it
on every branch that undoes it. Nothing reached the registry, because `push` never ran.

### What this stage cannot see

zizmor offline reads the files. It does not check that a pinned commit really belongs to the action
it names, which is the `impostor-commit` audit and needs GitHub's API; it does not know whether an
action version has a published advisory, which is `known-vulnerable-actions` and needs the same.
Run online in a job with a token, those two audits run as well. Neither it nor any scanner judges
the runner the workflow lands on, which is the subject of the next two sections.
