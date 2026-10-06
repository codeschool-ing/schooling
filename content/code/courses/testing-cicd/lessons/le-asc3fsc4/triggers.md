---
title: What starts a run
version: 1
---

A **trigger** is the event that makes the CI start a run. The lab's hook has exactly one: a push to
`main`. A push to any other branch is received and ignored:

```
ana@laptop:~/shipquote$ git switch -q -c try-new-rounding && git push -u origin try-new-rounding 2>&1 | grep -E "^remote: ci|->"
remote: ci: try-new-rounding is not main, nothing to run        
 * [new branch]      try-new-rounding -> try-new-rounding
```

The branch reached the remote, and the hook said it had nothing to run. Whether that is right
depends on the team: some want every branch checked, so a problem shows up before anybody opens a
pull request; others save the runners for the branches that are about to merge.

## The events worth knowing

Hosted CI services offer the same small set of triggers under different names:

| event | runs when | typical use |
|---|---|---|
| push | commits reach a branch | check `main` after every merge |
| pull request | a pull request is opened or updated | check a change **before** it merges |
| tag | a tag is pushed | build and publish a release |
| schedule | a clock says so, written as cron | nightly contract tests (lesson 2), slow suites |
| manual | somebody presses a button or calls an API | a deploy, a one-off rebuild |
| another workflow | a pipeline calls this one | reuse one set of checks in several places |

## This repository's triggers

The repository this course is published from runs its checks on two events, and can be called by a
third:

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

  # The release calls this workflow rather than repeating its steps. A release
  # that ran "the same checks" written out a second time would be one edit away
  # from running different ones, and the edit nobody makes to both is exactly
  # the failure this repository keeps meeting.
  workflow_call:
```

`pull_request` to `main` checks every proposed change before it merges; `push` to `main` checks the
result after it merges, because two changes that each passed can still conflict once combined.
`workflow_call` lets another workflow run this one, and the release does exactly that:

```yaml
on:
  push:
    tags: ['v*']
```

A tag starting with `v` starts the release, and the release's first act is to call the same checks
as `main`. Lesson 6 reads both files in full; lesson 7 explains why a release is a tag.

## Narrowing a trigger

Running everything on every change gets expensive, so services let a trigger name the paths that
matter: a change only to `docs/` does not need the Go tests. It is useful and it has a trap that
this repository's own workflow documents. **A workflow filtered by paths that does not run reports
nothing at all**, and a required check that never reports blocks a merge forever. That is why this
repository decides inside the workflow, in a first job that compares the changed files and lets the
others skip themselves, which reports as *skipped*, a state a required check accepts. It also fails
open: when it cannot tell what changed, it runs everything, because a detector that guesses wrong
should waste a runner rather than skip a suite.
