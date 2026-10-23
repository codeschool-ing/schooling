---
title: A workflow the way it is often written
version: 1
---

Suppose linkbox is mirrored to GitHub, and somebody writes a workflow so that every pull request
runs the tests. The first version tends to look like the one below. Each line in it is there
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

```
ana@vm:~$ uv tool install zizmor==1.31.1
Resolved 1 package in 754ms
Downloading zizmor (9.1MiB)
 Downloaded zizmor
Prepared 1 package in 688ms
Installed 1 package in 2ms
 + zizmor==1.31.1
Installed 1 executable: zizmor
ana@vm:~$ zizmor --version
zizmor 1.31.1
```

`--offline` keeps it from calling GitHub's API, which some of its audits use to check whether a
pinned commit really belongs to the action it names; the rest work from the file alone. `--quiet`
drops its progress lines. Saved as `.github/workflows/ci.yml` and scanned:

```
ana@vm:~$ cd linkbox && mkdir -p .github/workflows
ana@vm:~/linkbox$ zizmor --quiet --offline .github; echo "exit status $?"
help[artipacked]: credential persistence through GitHub Actions artifacts
  --> .github/workflows/ci.yml:11:9
   |
11 |         - uses: actions/checkout@v6
   |  _________^
12 | |         with:
13 | |           ref: ${{ github.event.pull_request.head.sha }}
   | |________________________________________________________^ does not set persist-credentials: false
   |
   = note: audit confidence → Low
   = note: this finding has an auto-fix
   = help: audit documentation → https://docs.zizmor.sh/audits/#artipacked

error[dangerous-triggers]: use of fundamentally insecure workflow trigger
 --> .github/workflows/ci.yml:5:3
  |
5 |   pull_request_target:
  |   ^^^^^^^^^^^^^^^^^^^ pull_request_target is almost always used insecurely
  |
  = note: audit confidence → Medium
  = help: audit documentation → https://docs.zizmor.sh/audits/#dangerous-triggers

error[template-injection]: code injection via template expansion
  --> .github/workflows/ci.yml:16:32
   |
16 |         run: echo "testing ${{ github.event.pull_request.title }}"
   |         --- this run block     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ may expand into attacker-controllable code
   |
   = note: audit confidence → High
   = note: this finding has an auto-fix
   = help: audit documentation → https://docs.zizmor.sh/audits/#template-injection

error[unpinned-uses]: unpinned action reference
  --> .github/workflows/ci.yml:11:15
   |
11 |       - uses: actions/checkout@v6
   |               ^^^^^^^^^^^^^^^^^^^ action is not pinned to a hash (required by blanket policy)
   |
   = note: audit confidence → High
   = help: audit documentation → https://docs.zizmor.sh/audits/#unpinned-uses

error[unpinned-uses]: unpinned action reference
  --> .github/workflows/ci.yml:14:15
   |
14 |       - uses: astral-sh/setup-uv@v9
   |               ^^^^^^^^^^^^^^^^^^^^^ action is not pinned to a hash (required by blanket policy)
   |
   = note: audit confidence → High
   = help: audit documentation → https://docs.zizmor.sh/audits/#unpinned-uses

8 findings (3 suppressed, 2 unsafe fixes): 0 informational, 1 low, 0 medium, 4 high
exit status 14
```

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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l16-triggers\" aria-label=\"Two triggers compared for a pull request from a fork. With pull_request the workflow runs the fork's code with a read-only token and no secrets. With pull_request_target it runs with a token that can write and with the repository's secrets; checking out the pull request's head then runs the fork's code with those privileges.\"><defs></defs><rect x=\"200\" y=\"15\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pull_request</text><rect x=\"460\" y=\"15\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pull_request_target</text><text x=\"20\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">code that runs</text><rect x=\"200\" y=\"65\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the fork's code</text><rect x=\"460\" y=\"65\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the fork's code, if checked out</text><text x=\"20\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token</text><rect x=\"200\" y=\"111\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read-only</text><rect x=\"460\" y=\"111\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">can write</text><text x=\"20\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">secrets</text><rect x=\"200\" y=\"157\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">withheld</text><rect x=\"460\" y=\"157\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">available</text><text x=\"320\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">right for running tests</text><text x=\"585\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">right only for labels and comments</text></svg>", "caption": "pull_request_target is meant for jobs that never run the pull request's code; checking that code out is what turns it into a stranger's code with the repository's keys."}
```

### What the default persona left out

The summary says three findings were suppressed. zizmor has **personas**: the default, `regular`,
reports what is worth acting on with few false positives, and `auditor` reports everything it
noticed. The same file under `auditor`, findings only:

```
ana@vm:~/linkbox$ zizmor --quiet --offline --persona auditor .github | grep -E "^(error|warning|help|info)\["
help[artipacked]: credential persistence through GitHub Actions artifacts
error[excessive-permissions]: overly broad permissions
error[dangerous-triggers]: use of fundamentally insecure workflow trigger
error[template-injection]: code injection via template expansion
error[unpinned-uses]: unpinned action reference
error[unpinned-uses]: unpinned action reference
info[anonymous-definition]: workflow or action definition without a name
help[concurrency-limits]: insufficient job-level concurrency limits
```

The extra three are `excessive-permissions`, which is `write-all`, an `anonymous-definition`, a job
with no `name`, and `concurrency-limits`, nothing stopping two runs of the same branch at once.
**`write-all` is the one that matters**, and the regular persona did not report it here. The tool's
default is tuned to stay quiet, the same trade lesson 7 made for the pipeline's gates, so the first
read of a new workflow is worth doing as an auditor. The fixed file in the next section passes under
both.
