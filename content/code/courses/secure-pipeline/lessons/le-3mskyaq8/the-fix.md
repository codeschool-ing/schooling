---
title: The same workflow, fixed
version: 1
---

Each finding has a fix of a few characters, and none of them costs the workflow anything it
needed. **The job tests the change; it does not need to write anything, hold any secret, or run
code nobody reviewed with privileges nobody granted.** The fixed workflow, with every change in it
answering one finding from the previous section.

### Pin by commit, and check the pin

A pin is a commit hash, and the hash has to be the one the version names. `git ls-remote` asks a
repository what its tags point at, without cloning it:

@@CAPTURE ls-remote@@

Two things to read. **`v6` and `v6.1.0` name the same commit today**, which is the point of a
moving major tag: it follows the latest release, and it will name a different commit after the next
one. The pin is the hash beside `v6.1.0`. And an annotated tag would print a second line ending in
`^{}`, the commit the tag object points at, which is the one to pin; these two tags are lightweight,
so there is one line each. The version goes in a comment beside the hash, because a hash alone tells
the next reader nothing, and because the tools that propose updates, which lesson 18 sets up, read
that comment to know which release a pin stands for.

### The file

Save it as `.github/workflows/ci.yml`:

```yaml
# linkbox's tests on GitHub Actions, for a copy of the repository hosted
# there. Nothing in it runs with more than it needs: the token reads the
# code and nothing else, every action is pinned to a commit, and text that
# a pull request's author wrote reaches a shell only as data.
name: ci
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    name: tests
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          persist-credentials: false
      - uses: astral-sh/setup-uv@c771a70e6277c0a99b617c7a806ffedaca235ff9 # v9.0.0
      - name: Say which change this is
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: echo "testing $TITLE"
      - run: bash ci/test.sh
```

Line by line, against the findings:

| finding | the fix |
|---|---|
| `dangerous-triggers` | `pull_request` instead of `pull_request_target`, and no `ref:`: the checkout takes the commit the event names, with a read-only token |
| `excessive-permissions` | `permissions: contents: read` at the top, for every job; a job that needs more says so itself |
| `template-injection` | the title goes into `TITLE` under `env:`, and the script reads `$TITLE`, a value the shell never parses as code |
| `unpinned-uses` | both actions by full commit hash, with the version in a comment |
| `artipacked` | `persist-credentials: false`, so the token is not left in `.git/config` |
| `anonymous-definition`, `concurrency-limits` | a `name` for the job, and one run per branch at a time, the older one cancelled |

**`permissions` is declared in the file rather than left to the repository's settings**, because a
setting can be changed by anyone with admin rights and leaves no trace in a review, while a line in
the workflow is reviewed with the code. GitHub's documentation describes `GITHUB_TOKEN` as a token
created for each job and expiring when it ends, with the permissions the workflow grants; when the
file says nothing, the repository's or organisation's default applies.

The scan, both personas:

@@CAPTURE fixed@@

Nothing reported, and nothing suppressed. **This workflow was never executed**: the recording
machine cannot run GitHub's hosted runners, so what it would print on GitHub is not shown here.
What was checked is the file, which is where these mistakes live.

### What the file does not fix

The workflow runs only `ci/test.sh`. The rest of linkbox's pipeline needs the registry, the
scanners and the signing key of the local CI, and moving it to a hosted runner is a project of its
own, with the keys moving into the platform's secret store or, better, replaced by the federated
identity of lesson 17. The four controls above apply to it unchanged when it moves.
