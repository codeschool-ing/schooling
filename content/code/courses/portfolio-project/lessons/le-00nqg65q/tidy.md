---
title: Tidying before you push
version: 1
---

Sometimes the second change arrives after the commit. You commit the fix, then notice the test's
name says *borrower* where everything else says *name*. A commit called *rename test* would work, and
it would put a small, meaningless line in the story. Git has a better tool for a correction to the
commit before: a **fixup**.

```
ana@laptop:~/loanbook$ git commit -q -a --fixup HEAD
ana@laptop:~/loanbook$ git log --oneline -3
9d7148f fixup! Refuse a borrower made of spaces
d853271 Refuse a borrower made of spaces
be0bfbb Fit the table on a phone
ana@laptop:~/loanbook$ GIT_SEQUENCE_EDITOR=true git rebase -q -i --autosquash HEAD~2
ana@laptop:~/loanbook$ git log --oneline -3
cab5367 Refuse a borrower made of spaces
be0bfbb Fit the table on a phone
a087fae Label every field and announce what happened
```

`git commit --fixup HEAD` makes a commit whose subject is `fixup!` followed by the subject it
corrects. `git rebase -i --autosquash` then folds every fixup into its target, and the history is one
commit again, with the corrected test inside it. The `GIT_SEQUENCE_EDITOR=true` in front is only there
because this was recorded by a script: at a keyboard, the rebase opens an editor showing the plan,
with the fixup already moved into place, and you save and close it.

Notice the hash changed, from `cf70c92` to `73606e4`. **Rebasing rewrites commits**, and that gives
the one rule of tidying: **only rewrite what nobody else has.** Commits on your machine that you have
not pushed are yours to tidy. Commits already pushed to a branch somebody else might have pulled are
not, and a portfolio project's `main` on GitHub is such a branch, since a reviewer may have cloned it.
Tidy on your machine; push when it reads well; after that, correct with new commits.

The same tool squashes a run of small experimental commits into one before pushing, which is how a
history of *try this*, *no*, *try that* becomes the single commit that says what worked.
