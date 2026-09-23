---
title: The reflog: getting back what reset took
version: 1
---

Ana has changed her mind: red was right after all. The commit *Try red* is no longer on any branch,
and `git log` cannot see it, because the log follows parents back from where you are and nothing
points at it any more.

**The reflog is a list of every place `HEAD` has been**, kept by your repository for your own use:

```
ana@vm:~/site$ git reflog -6
2dcd0dd HEAD@{0}: reset: moving to HEAD
2dcd0dd HEAD@{1}: reset: moving to HEAD~1
7f8aee6 HEAD@{2}: reset: moving to HEAD~1
9ed17a3 HEAD@{3}: commit: Try red
7f8aee6 HEAD@{4}: commit: Try a darker orange
2dcd0dd HEAD@{5}: commit (amend): Close on Sundays
```

Read it from the bottom up and it is the last few minutes of this lesson. The amend. The two colour
commits, `7f8aee6` and `9ed17a3`. Then three resets, each moving `HEAD` somewhere. **`HEAD@{3}` is
where `HEAD` was three moves ago**, and that is *Try red*, the commit reset stepped past.

Every entry names a commit, so any of them can go back to `git reset`:

```
ana@vm:~/site$ git reset --hard HEAD@{3}
HEAD is now at 9ed17a3 Try red
ana@vm:~/site$ git log --oneline -3
9ed17a3 Try red
7f8aee6 Try a darker orange
2dcd0dd Close on Sundays
ana@vm:~/site$ cat style.css
h1 { color: firebrick; }
```

*Try red* is back on the branch, with *Try a darker orange* under it, and the stylesheet on disk says
`firebrick` again. Nothing was rebuilt. The commit had been there the whole time, simply with nothing
pointing at it.

## What the reflog keeps, and what it cannot

**It keeps commits.** Anything that was ever committed, amended away, reset past or left behind on a
deleted branch can be found in it for weeks. By default an entry is kept for 90 days, or 30 when it
names a commit no branch leads to any more, like *Try red*; and a commit is only really removed
after nothing, reflog included, refers to it.

**It cannot keep what was never committed.** The `9.00` that `git restore` threw away at the start of
this lesson is not in it, and neither is anything `reset --hard` overwrote in the working tree. That
is the practical argument for committing small and often, even on a branch nobody else will see:
**a commit is a thing Git can give back to you, and an unsaved edit is not.**

**It is yours alone.** The reflog lives in your repository and is never shared. Bruno's reflog knows
where his `HEAD` has been and nothing about yours.

## Which one, then

- A change you have not committed and do not want: `git restore`.
- A commit other people already have: `git revert`.
- A commit only you have: `git commit --amend` for the last one, `git reset` for more.
- Something reset took, that you want back: `git reflog`, then `git reset` to the entry.

Reach for them in that order of safety, and when unsure, run `git status` and `git log --oneline`
first.
