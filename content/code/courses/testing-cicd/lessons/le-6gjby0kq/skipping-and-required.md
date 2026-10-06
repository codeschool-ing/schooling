---
title: Skipped jobs and required checks
version: 1
---

A pull request on 19 September 2026 changed course content and nothing else, and its run looks like
this:

```
ana@laptop:~$ curl -s $A/runs/35432460022 | jq -r "[.event, .head_branch, .conclusion] | @tsv"
pull_request	claude/wonderful-cray-nrgjb2	success
ana@laptop:~$ curl -s $A/runs/35432460022/jobs | jq -r ".jobs[] | [.name, .conclusion] | @tsv"
Changes	success
Browser	success
Go	success
Infra	skipped
```

`Infra` is **skipped**, and the run as a whole is a **success**. That combination is deliberate, and it
is what makes it safe to require the checks.

## Requiring a check

A repository can mark checks as **required**: a pull request cannot merge until each named check has
reported success. On GitHub this is a branch protection rule or a ruleset on `main`, set in the
repository's settings; on GitLab it is the merge request setting that pipelines must succeed. It is
what turns lesson 5 section 11's habit, check before merging, into something the platform enforces.

Required checks have one trap, and this repository's workflow explains it in a comment above its
`Changes` job. A check is satisfied by a report of success, **or of skipped**. But a whole workflow
that never starts sends no report at all, and a required check with no report keeps the pull request
waiting for ever. So:

| how a job is avoided | what the check reports | with the check required |
|---|---|---|
| `if:` on the job, decided at run time | skipped | the pull request can merge |
| `paths:` on the workflow's trigger | nothing, the workflow never ran | the pull request waits for ever |

That is why this repository runs its workflow on every pull request and lets a first job decide what
to skip. A path filter on the trigger would have been less YAML and a merge button that never turns
green on the day somebody changes only documentation.

## Skipped is not passed

A skipped check satisfies a requirement, and that is a decision somebody made about **which checks
a change can affect**. If the decision is wrong, a change slips through untested and the run is
green. This repository's `Changes` job errs on the side of running: a push to `main`, a release, and
any diff it cannot compute run everything. It is the same principle as lesson 2's skipped contract
test: **skipped is a statement about what did not happen**, and somebody should be able to say why
it was right that it did not.
