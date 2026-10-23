---
title: A workflow the way it is often written
version: 1
---

Suppose linkbox is mirrored to GitHub, and somebody writes a workflow so that every pull request
runs the tests. The first version tends to look like the one below, and each line in it is there
for a reason that sounded good at the time: `pull_request_target` because the tests of a fork's pull
request "would not get the secrets otherwise", `write-all` because a step once failed for lack of a
permission, the head commit of the pull request because "that is the code to test", and the title in
the log because it is helpful to see. Nothing in it is a typo. **This file is shown so it can be
taken apart; do not use it.**

```yaml
# linkbox's tests on GitHub Actions, written the way a first version
# often is. Every line of it works.
name: ci
on:
  pull_request_target:
permissions: write-all
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - uses: astral-sh/setup-uv@v9
      - name: Say which change this is
        run: echo "testing ${{ github.event.pull_request.title }}"
      - run: bash ci/test.sh
```

### A scanner for workflows

**zizmor** is a static analyser for GitHub Actions: it reads workflow files the way Bandit read
`app.py` in lesson 3, and knows the mistakes that recur in them. It is a Python tool, installed like
Bandit, at an exact version:

@@CAPTURE install@@

`--offline` keeps it from calling GitHub's API, which some of its audits use to check whether a
pinned commit really belongs to the action it names; the rest work from the file alone. `--quiet`
drops its progress lines. Saved as `.github/workflows/ci.yml` and scanned:

@@CAPTURE careless@@

### The findings, one by one

**`dangerous-triggers`.** `pull_request_target` runs the workflow in the context of the base
repository: with a token that can write and with access to the repository's secrets, even when the
pull request comes from a fork. It exists for jobs that label or comment on a pull request and never
run its code. **Combined with a checkout of the pull request's own head**, which is what `ref:` asks
for here, it runs a stranger's code, including their version of `ci/test.sh`, with the base
repository's privileges. The plain `pull_request` trigger runs a fork's code with a read-only token
and no secrets, which is what testing someone else's change needs.

**`template-injection`.** `${{ … }}` is expanded by the platform before the shell sees the script,
so the pull request's title becomes part of the script's text. A title is anything its author typed.
**Text that somebody outside the team wrote must reach a shell as data**, in an environment
variable, where the shell treats it as a value and never as code. zizmor marks this one with high
confidence and offers a fix that does exactly that.

**`unpinned-uses`, twice.** `actions/checkout@v6` names a tag, and lesson 12's tj-actions incident is
what a moved tag does. A full commit hash cannot be moved.

**`artipacked`.** `actions/checkout` writes the job's token into `.git/config` by default, so later
steps, and anything that uploads the workspace, can read it. `persist-credentials: false` keeps it
out. Its confidence is low, because whether it matters depends on what later steps do.

@@FIGURE triggers@@

### What the default persona left out

The summary says three findings were suppressed. zizmor has **personas**: the default, `regular`,
reports what is worth acting on with few false positives, and `auditor` reports everything it
noticed. The same file under `auditor`, findings only:

@@CAPTURE auditor@@

The extra three are `excessive-permissions`, which is `write-all`, an `anonymous-definition`, a job
with no `name`, and `concurrency-limits`, nothing stopping two runs of the same branch at once.
**`write-all` is the one that matters**, and the regular persona did not report it here. The tool's
default is tuned to stay quiet, the same trade lesson 7 made for the pipeline's gates, so the first
read of a new workflow is worth doing as an auditor. The fixed file in the next section passes under
both.
