---
title: Fresh, persistent and self-hosted runners
version: 1
---

A workflow says what to run; a **runner** is the machine that runs it. Everything the previous
sections fixed assumes something about that machine: that the job cannot read another job's files,
that nothing a job leaves behind is there for the next one, and that the job's reach on the network
is what you expect. **Whether those assumptions hold depends on who runs the machine and how long it
lives.** This section is taught from GitHub's and GitLab's documentation; none of it was run.

### Ephemeral and persistent

| | an ephemeral runner | a persistent runner |
|---|---|---|
| lifetime | one job, then destroyed | many jobs, often for months |
| what a job leaves behind | nothing reaches the next job | files, caches, processes and credentials stay on disk |
| who can poison it | nobody after the job ends | any job that ran on it, for every job after |
| cost | a machine started per job | a machine kept warm |

GitHub's hosted runners are ephemeral: GitHub's documentation describes each job as running on a
fresh virtual machine that is discarded afterwards. A **persistent** runner is a machine somebody
registered once and keeps: a build server in a cupboard, a virtual machine in a company's cloud
account. It is faster, because its caches are warm, and that is exactly the problem. **A job that
can write to the disk can leave something for the next job**: a modified tool on the `PATH`, a
poisoned dependency cache, a process that waits. The next job, perhaps the release, runs on top of
it.

### Self-hosted runners and public repositories

GitHub's documentation recommends using self-hosted runners only with **private** repositories, and
gives the reason: on a public repository anybody can fork it and open a pull request, and a workflow
that runs on pull requests then runs a stranger's code on your machine, inside your network. With
`pull_request` the token is read-only and the secrets are withheld, which protects the repository;
it does not protect the machine the code runs on, or anything that machine can reach.

Three arrangements, from the documentation, if a self-hosted runner is needed at all:

- **Ephemeral self-hosted runners.** GitHub's runner can be registered with `--ephemeral`, so it
  takes one job and unregisters; something outside it then has to create a fresh one per job, which
  is what the Kubernetes operator Actions Runner Controller does.
- **Separate runner groups.** Runners are assigned to groups, and a group to the repositories and
  workflows allowed to use it, so the machine that deploys is never one a pull request can land on.
- **Approval for outside contributors.** Repository settings can require a maintainer's approval
  before a workflow runs for a first-time or outside contributor's pull request.

GitLab has the same distinction in its own words: shared runners that GitLab runs for every
project, and project or group runners that the project registers; its documentation gives the same
warning about runners that run code from forks.

### This course's runner

The local CI of this course is a persistent, self-hosted runner, the most trusting arrangement in the
table. It runs every branch that reaches `~/ci/linkbox.git`, as Ana, on Ana's laptop, and every run
leaves its checkout in `~/ci/runs`. That is acceptable for one person's laboratory, where the only
person who can push is the person who owns the machine. **It would not be acceptable the day a second
person could push**, and the next section says how much a job on this machine can do.
