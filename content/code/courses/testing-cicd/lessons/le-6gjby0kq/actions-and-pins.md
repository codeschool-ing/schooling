---
title: Actions, and pinning them to a commit
version: 2
---

An **action** is a step somebody packaged for reuse: check out the code, install Python, upload a
file. You refer to it as `owner/repository@ref`, and GitHub downloads that repository at that ref
and runs it inside your job, **with your job's permissions and secrets in reach**. That last part is
why the ref matters.

There are three ways to write it:

| form | example | what it points at |
|---|---|---|
| a branch | `actions/checkout@main` | whatever the branch holds at that moment |
| a tag | `actions/checkout@v7` | whatever the tag was last moved to |
| a commit | `actions/checkout@9c091bb…` | one exact tree, forever |

A branch and a tag can be moved by whoever controls the action's repository. If that repository is
compromised, every workflow pointing at the tag runs the new code on its next run, with access to
whatever that workflow can reach. **A commit hash cannot be moved.** That is why `shipquote`'s
workflow, like this repository's, pins every action to a full commit and writes the version beside
it as a comment: the hash for the machine, the comment for the person deciding whether it is old.

## This repository checks its own pins

The repository that publishes this course has a tool for exactly this, `tools/check-actions`, and
runs it in CI. With `-offline` it checks the pinning half without fetching anything. You do not need
to type this one; it runs in that repository, not in `shipquote`:

```
ana@laptop:~/schooling$ go run ./tools/check-actions -offline
· the runtimes were not read: -offline
16 action use(s) across the workflows, every one pinned to a commit and carrying the version it was cut from
```

Sixteen uses of an action across the repository's workflows, every one pinned to a commit with its
version beside it. Without `-offline`, the tool also fetches each pinned action's own `action.yml`
and checks that it does not declare a JavaScript runtime GitHub has deprecated, because a pin keeps
the code fixed while the platform under it moves.

## The cost of pinning

Pins do not update themselves, so somebody has to move them. Teams usually let a bot propose the
updates as pull requests, Dependabot or Renovate, which change the hash and the comment together and
run the CI on the result. A pin that nobody updates is safe and slowly gets old; the tool above
answers *is it pinned*, and the bots answer *is it current*. In the `devsecops` track,
`secure-pipeline` treats the supply chain of a pipeline in depth, and pinning is its starting point.
