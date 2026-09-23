---
title: Choosing, and writing it down
version: 1
---

| | feature branches | trunk based | Git Flow |
|---|---|---|---|
| a branch lives | a few days | a few hours | features for days, releases for a week |
| work reaches `main` | when reviewed | at least daily | only when released |
| unfinished work | stays on its branch | merged, behind a flag | stays on its branch |
| fits | most teams, most products | frequent deploys, strong checks | numbered versions shipped to customers |
| the risk | branches that live too long | a broken `main` if checks are weak | ceremony, and merges done twice |

## The question that decides it

**How often does what is on `main` reach the people using it?**

- Many times a day, automatically: trunk based is the natural fit, and feature branches kept very
  short are the gentle way in.
- When somebody decides, a few times a week: feature branches.
- As numbered versions, with old ones still supported: Git Flow, or a lighter version of it with only
  release branches.

A new team with no strong reason should start with short feature branches. It is the shape every
hosting service is built around, it teaches review from the first day, and moving from it to trunk
based is a matter of making branches shorter.

## Write it down

The workflow is an agreement, and an agreement that is not written down is several agreements, one
per person. A short file in the repository, usually `CONTRIBUTING.md`, that answers five questions
saves more arguments than any tool:

1. Where does a branch start from, and what is it called?
2. How long should a branch live?
3. What has to happen before a pull request is merged: approvals, checks?
4. Which merge button: merge commit, squash or rebase?
5. How is a release made, and who makes it?

Those questions have come up in this course already: lesson 6's merge or rebase, lesson 8's buttons
and protected branches, lesson 7's tags. A workflow is those answers, chosen once, together.
