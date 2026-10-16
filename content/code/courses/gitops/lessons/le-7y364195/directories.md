---
title: Environments are directories, not branches
version: 1
---

**An obvious way to model environments in Git is one branch per environment**: a `staging` branch
and a `production` branch, with promotion as a merge from one to the other. It reads well on a
whiteboard and it fails in practice, for reasons that all come from what a merge does.

- **A merge carries everything.** Merging `staging` into `production` brings every commit on
  `staging`, including the ones that are staging-only on purpose: the extra debug logging, the test
  credentials' reference, the smaller replica count. Keeping those out means cherry-picking, and a
  history of cherry-picks is one nobody can read.
- **The branches drift.** Each branch accumulates its own fixes, and after a few months a diff
  between `staging` and `production` shows hundreds of lines, most of which nobody chose. The one
  difference that matters, the release being promoted, is lost among them.
- **What is different is invisible.** On a single branch, the difference between two environments
  is two files side by side that a reviewer can compare. On two branches it is a diff between
  branches that nobody runs.

**One branch, `main`, and one directory per environment** avoids all three. Promoting is a pull
request that changes production's directory to say what staging's already says, and its diff is
exactly the promotion. Every environment's present state is readable in one checkout, at one commit.
Both Argo CD and Flux are built for this layout: an Application or a Kustomization points at a path,
and every path follows `main`.
