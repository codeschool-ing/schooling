---
title: Merge or rebase, and the one rule
version: 1
---

Both commands bring work together, and both end with the same files. What differs is the history
they leave, and that difference decides when each is safe.

**Merge adds.** It keeps every existing commit exactly as it was and adds one that joins them. Nothing
anybody else has is changed.

**Rebase rewrites.** It replaces your branch's commits with new ones, with new ids. The old ones are
still in your repository, on no branch, findable in the reflog of lesson 4, but they are no longer
your branch.

## The rule

> **Never rebase commits that somebody else already has.**

It is the same rule lesson 4 gave for `reset` and `--amend`, and for the same reason. If Bruno has
`788a11d` and you replace it with `6e29a2d`, his copy and yours now hold two different commits that
make the same change. The next time you share work, both come together, and Git sees two histories
that disagree about what happened. Somebody ends up sorting out duplicate commits by hand, usually
without understanding why they appeared.

So the practice that most teams settle on is simple:

- **Rebase your own branch, before sharing it**, to bring it up to date with `main` and keep the
  history straight. Until you push, nobody else has those commits, and rewriting them hurts nobody.
- **Merge anything that is shared.** Once a branch is on the shared copy, bring `main` into it with a
  merge, or merge it into `main`, and let the history show the fork.

Lesson 7 is where *shared* starts to mean something concrete, with `git push`, and it shows `git pull
--rebase`, which applies exactly this rule to the commits you have not pushed yet.

## Which one should a team use?

It is a genuine choice with a genuine trade-off, and teams argue about it:

- A **merged** history is truthful about when work happened in parallel, and never rewrites anything.
  It is also noisier, with a merge commit for every branch.
- A **rebased** history reads as a clean line and is easier to search with `git log`.
  It also records an order that is partly fiction: work that happened in parallel looks sequential.

Neither is wrong. What matters is that a team picks one and writes it down, and lesson 9 is where that
decision is made as part of a workflow. The rule above holds under either choice.
