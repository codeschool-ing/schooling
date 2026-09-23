---
title: Choosing what goes into a commit
version: 1
---

Two changes are waiting. The opening hours in `index.html` were edited, and `style.css` is new:

```
ana@vm:~/site$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	style.css

no changes added to commit (use "git add" and/or "git commit -a")
ana@vm:~/site$ git add style.css
ana@vm:~/site$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   style.css

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

ana@vm:~/site$ git commit -m "Give the heading its colour"
[main 5d6d04f] Give the heading its colour
 1 file changed, 1 insertion(+)
 create mode 100644 style.css
```

Only `style.css` was added, so only `style.css` went in. The status between the two commands shows
**both halves at once**: one change under *to be committed*, one under *not staged*. The commit took
the first and left the second exactly where it was, still modified, ready for a commit of its own.
That is the staging area doing the one job it exists for.

## Add copies the file as it is now

Here is the surprise almost everybody meets once. Ana adds `index.html`, then edits it again before
committing:

```
ana@vm:~/site$ git add index.html
ana@vm:~/site$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   index.html

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

ana@vm:~/site$ git diff
diff --git a/index.html b/index.html
index c48930c..307a574 100644
--- a/index.html
+++ b/index.html
@@ -1,2 +1,2 @@
 <h1>Padaria Sol</h1>
-<p>Bread from half past five.</p>
+<p>Bread from half past five, every day.</p>
ana@vm:~/site$ git diff --staged
diff --git a/index.html b/index.html
index c9de6c1..c48930c 100644
--- a/index.html
+++ b/index.html
@@ -1,2 +1,2 @@
 <h1>Padaria Sol</h1>
-<p>Bread from six in the morning.</p>
+<p>Bread from half past five.</p>
ana@vm:~/site$ git commit -m "Open half an hour earlier"
[main 11b9ca3] Open half an hour earlier
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

no changes added to commit (use "git add" and/or "git commit -a")
```

**The same file is in both lists.** `git add` copied `index.html` into the staging area as it was
at that moment: half past five. The edit that followed, *every day*, happened in the working tree
afterwards, and nothing told the staging area about it. The two `git diff` commands show the two
halves separately: `git diff` compares the working tree with the staging area, and
`git diff --staged` compares the staging area with the last commit. Lesson 3 reads diffs properly.

So the commit recorded half past five and not *every day*, and `git status` afterwards still shows
the file modified. **Add after the last edit, not before it.** Or run `git status` before every
commit, which catches this every time.

## Commit -a, and what it skips

`git commit -a` stages every change to a file Git already tracks, then commits. It saves typing, and
it has one blind spot:

```
ana@vm:~/site$ git status --short
 M index.html
?? menu.html
ana@vm:~/site$ git commit -am "Open every day"
[main 132c557] Open every day
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git status --short
?? menu.html
```

The edit to `index.html` went in. `menu.html` did not, because Git had never tracked it: `-a` only
picks up files that are already in the history. The `??` in the short status is *untracked*, and
` M` is *modified, not staged*. A new file always needs its own `git add`.

`-a` is fine when you know every change in the working tree belongs in one commit. It is exactly
wrong on the days you do not, which are the days the staging area was invented for.
