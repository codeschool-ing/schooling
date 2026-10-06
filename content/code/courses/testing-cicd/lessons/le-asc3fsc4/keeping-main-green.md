---
title: Keeping main green
version: 1
---

A pipeline is only as useful as the team's habits around it. Three habits turn a CI server into
continuous integration, and each one answers a failure the lab has already shown.

## Check before merging, not only after

The lab's hook ran **after** each push reached `main`, so run 2 and run 4 left a broken `main` for a
while: anybody who pulled in between got a failing test. A hosted service checks a pull request
before it merges, and a repository can make that check **required**: the merge button stays
disabled until the named checks pass. Lesson 6 shows where that is set. This repository requires
its checks for exactly this reason, and its workflow is written so that a skipped job still
reports, because a required check that never reports blocks every merge.

## A red main is everybody's first problem

When `main` is red, every new branch starts from a broken base, and every new failure is hidden
behind the old one. The rule teams adopt is simple: **fixing `main` comes before any new work**,
and the quickest fix is usually a revert, as in section 07. The person whose change broke it is
the natural one to fix it, but anybody may revert; a revert is cheap to undo and a red `main`
is expensive to keep.

## Integrate small and often

The word *continuous* is the practice. A change that lives on a branch for three weeks integrates
three weeks of other people's changes at once, and when that run goes red nobody can tell which of
forty commits caused it. A change merged the day it was written is small, and its run, red or
green, is about that change. **Short-lived branches, merged daily**, are what make a CI result
point at a cause.

## What lesson 6 adds

Everything in this lesson ran on one laptop, with a hook of fifty lines. Lesson 6 moves the same
loop to the two services most teams use, GitHub Actions and GitLab CI: the matrix becomes a
`strategy`, the artifacts become uploads, the cache becomes a keyed action, and the trigger becomes
a pull request with a required check on it. The ideas carry over unchanged; only the file format is
new.
