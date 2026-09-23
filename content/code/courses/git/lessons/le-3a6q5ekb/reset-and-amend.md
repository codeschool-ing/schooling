---
title: Reset and amend: rewriting what you have not shared
version: 1
---

Revert keeps the history and adds to it. The other two commands in this section **change the
history itself**, which is exactly why they come with a rule: use them only on commits that are still
yours alone, not yet pushed anywhere. Lesson 7 is where commits start leaving your machine.

## Amend: fix the commit you just made

A typo in a message, a file you forgot to add. `--amend` replaces the last commit with a corrected one:

```
ana@vm:~/site$ git commit -m "Close on Sundys"
[main 4edd100] Close on Sundys
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git commit --amend -m "Close on Sundays"
[main 2dcd0dd] Close on Sundays
 Date: Mon Sep 21 11:05:00 2026 -0300
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline -2
2dcd0dd Close on Sundays
c28977c Revert "Take rye bread off until the flour arrives"
```

`4edd100` is gone from the log and `2dcd0dd` has taken its place. **An amended commit is a new commit
with a new id**, not an edited one, because the message is part of what the id is computed from. That
is harmless while nobody else has `4edd100`, and exactly the problem revert avoided once somebody
does.

## Reset: move the branch back

Ana tried two colours for the heading, committed both, and likes neither. `git reset` moves the branch
back to an earlier commit, and its three modes decide what happens to the work in the commits it
steps past.

```
ana@vm:~/site$ git log --oneline -3
9ed17a3 Try red
7f8aee6 Try a darker orange
2dcd0dd Close on Sundays
ana@vm:~/site$ git reset --soft HEAD~1
ana@vm:~/site$ git status --short
M  style.css
ana@vm:~/site$ git log --oneline -2
7f8aee6 Try a darker orange
2dcd0dd Close on Sundays
```

**`--soft` moves the branch and nothing else.** *Try red* is no longer in the log, and its change is
waiting in the staging area, `M` in the first column, ready to be committed again, perhaps with a
better message.

```
ana@vm:~/site$ git reset HEAD~1
Unstaged changes after reset:
M	style.css
ana@vm:~/site$ git status --short
 M style.css
ana@vm:~/site$ git diff
diff --git a/style.css b/style.css
index 773418d..6395b65 100644
--- a/style.css
+++ b/style.css
@@ -1 +1 @@
-h1 { color: darkorange; }
+h1 { color: firebrick; }
```

**The default, called `--mixed`, also empties the staging area.** One more commit is gone from the
branch, and all of the changes — both colours, which amount to one change of `darkorange` into
`firebrick` — are now unstaged edits in the working tree.

```
ana@vm:~/site$ git reset --hard
HEAD is now at 2dcd0dd Close on Sundays
ana@vm:~/site$ git status --short
ana@vm:~/site$ git log --oneline -2
2dcd0dd Close on Sundays
c28977c Revert "Take rye bread off until the flour arrives"
```

**`--hard` also resets the working tree.** Given no commit, it resets to the current one and throws
away every uncommitted change: the file is back to `darkorange` and the status is empty. This is the
dangerous one. It overwrites files without asking, and like `git restore`, what was never committed
is gone.

| mode | the branch | the staging area | the working tree |
|---|---|---|---|
| `--soft` | moves | kept | kept |
| `--mixed`, the default | moves | reset | kept |
| `--hard` | moves | reset | reset |

The commits reset stepped past are not deleted. They are on no branch, and the next section is how
to find them.
