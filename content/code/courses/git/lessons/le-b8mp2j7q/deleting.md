---
title: Listing and deleting branches
version: 1
---

A merged branch has done its job. Its commits are part of `main` now, and the name is only clutter.
Before deleting anything, two ways to look:

```
ana@vm:~/site$ git switch -c experiment
Switched to a new branch 'experiment'
ana@vm:~/site$ git commit -qam "Try purple"
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ git branch -v
  experiment    0704fcd Try purple
* main          d340360 Merge branch 'menu-prices'
  menu-prices   59ec506 Charge 0.95 for French bread
  opening-hours 9677eef Open on Sundays from seven
ana@vm:~/site$ git branch --merged
* main
  menu-prices
  opening-hours
ana@vm:~/site$ git branch -d menu-prices opening-hours
Deleted branch menu-prices (was 59ec506).
Deleted branch opening-hours (was 9677eef).
ana@vm:~/site$ git branch -d experiment
error: the branch 'experiment' is not fully merged.
If you are sure you want to delete it, run 'git branch -D experiment'
ana@vm:~/site$ git branch -D experiment
Deleted branch experiment (was 0704fcd).
ana@vm:~/site$ git branch
* main
```

`git branch -v` adds each branch's commit and message, which is usually enough to remember what a
branch was for. **`git branch --merged` lists the branches whose commits are all already in the one
you are on**, and those are the ones that are safe to delete. `experiment` is missing from it:
*Try purple* was committed there and never merged.

## -d refuses, -D does not

`git branch -d` deleted the two merged branches and said which commit each had pointed at. On
`experiment` it refused: **the branch is not fully merged**, so deleting the name would leave *Try
purple* on no branch at all. Git names the way through, `-D`, and `-D` did it.

What was actually deleted, in both cases, is a name. **Deleting a branch never deletes a commit.** The
merged branches' commits are still in `main`'s history, and *Try purple* is still in the repository,
reachable through the reflog of lesson 4 for weeks, as `Deleted branch experiment (was 0704fcd)` so
helpfully printed. `git switch -c experiment 0704fcd` would bring it straight back.

That is also why `-d` is worth using by default and `-D` only on purpose: `-d` checks, for free, the
one thing you would want checked.

## You cannot delete the branch you are on

Git refuses that too, for the obvious reason that `HEAD` would then name nothing. Switch away first.
And the names you delete are only yours: a branch on the shared copy, which lesson 7 introduces, is
deleted separately.

## The four commands

- `git branch` lists; `-v` adds commits; `--merged` shows what is safe to delete.
- `git switch name` moves to a branch; `-c` creates it first.
- `git merge name` brings a branch into the one you are on.
- `git branch -d name` deletes a merged branch; `-D` deletes any.
