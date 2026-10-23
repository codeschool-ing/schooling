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

@@CAPTURE pipeline@@

`workflows` passed second, and the other nine passed as they did in lesson 15. The local CI does not
run the workflow, and it does not need to: it reads it, which is the check that matters for a file
whose risk is in what it says.

### A regression, caught

A month later, somebody finds `env:` and `$TITLE` roundabout and puts the title back where it was.
On a branch:

@@CAPTURE regression@@

**The branch stops at the second stage**, with the finding and the line, before a test runs or an
image is built. The fix is the one the previous section made, and the stage will keep asking for it
on every branch that undoes it. Nothing reached the registry, because `push` never ran.

### What this stage cannot see

zizmor offline reads the files. It does not check that a pinned commit really belongs to the action
it names, which is the `impostor-commit` audit and needs GitHub's API; it does not know whether an
action version has a published advisory, which is `known-vulnerable-actions` and needs the same.
Run online in a job with a token, those two audits run as well. Neither it nor any scanner judges
the runner the workflow lands on, which is the subject of the next two sections.
