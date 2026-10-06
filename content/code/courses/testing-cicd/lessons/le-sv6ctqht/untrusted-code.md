---
title: Code you did not review, running with your secrets
version: 1
---

A pipeline runs code. Usually it is the team's own code, reviewed, plus actions and dependencies the
team chose. Two situations break that assumption, and both are where secrets have leaked from real
projects.

## Pull requests from forks

On a public repository, anybody can fork it, change the workflow or the tests, and open a pull
request. If the pipeline ran that pull request **with the repository's secrets**, a stranger could
write a test that prints them, or sends them somewhere. So hosted services do not: on GitHub
Actions, a workflow triggered by `pull_request` from a fork **receives no secrets** and its
`GITHUB_TOKEN` is read-only. GitLab treats merge requests from forks similarly by default. The
pipeline still runs, and can still check the change; it simply holds nothing worth taking.

## The trigger that gives them back

GitHub also offers `pull_request_target`, which runs in the context of the **base** repository, with
its secrets and a token that can write. It exists for jobs that need those powers on a pull request
from a fork, such as labelling it or posting a comment, and it is safe only as long as **the job never
checks out or runs the pull request's code**. A workflow that uses `pull_request_target` and then
checks out the head of the pull request and runs its tests has handed a stranger's code the
repository's secrets. GitHub's own security guidance names this pattern as dangerous, and the defence
is the simple rule: with `pull_request_target`, treat the pull request's contents as data, never as
code.

## Third-party actions and dependencies

Every action a job uses and every package it installs runs with the job's permissions and the
secrets given to the job. Lesson 6 section 04 pinned actions to commit hashes for this reason; the
same thinking applies to dependencies, which are pinned in `requirements-dev.txt`. Two more habits
limit the damage when something in that chain turns hostile:

- **Give secrets to the steps that need them**, as section 05 did, not to the whole workflow.
- **Keep jobs that hold secrets small.** A deploy job that only downloads an artifact and runs a
  deploy script runs very little third-party code; a deploy job that also installs and runs the whole
  test toolchain runs a great deal.

In the `devsecops` track, `secure-pipeline` lesson 16 hardens runners and actions in depth.
