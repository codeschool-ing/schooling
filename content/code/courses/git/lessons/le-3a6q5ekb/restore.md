---
title: Restore: throw away a change you have not committed
version: 1
---

**`git restore` puts a file back the way it was**, and it only ever touches the working tree and the
staging area. No commit is created, moved or removed, which makes it the safest of the three commands
in this lesson and the one to reach for first.

## A change that went wrong

Somebody typed `9.00` for a loaf of bread. It has not been staged:

```
ana@vm:~/site$ git diff --stat
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git restore menu.html
ana@vm:~/site$ git status --short
```

`git restore menu.html` copied the file back from the staging area, which still held the version of
the last commit, and the empty `git status --short` says the working tree is clean again.

**This is the one undo in Git that cannot be undone.** The edit was never staged or committed, so
Git never had a copy of it, and there is nothing to recover it from. That is harmless for a typo and
painful for an afternoon of work. Before restoring a file you have been editing for a while, a quick
`git diff` shows what you are about to lose.

## Taking a file out of the staging area

`--staged` moves the other way: it takes a change out of the staging area and leaves it in the working
tree. This is the undo for a `git add` you did not mean:

```
ana@vm:~/site$ git add menu.html
ana@vm:~/site$ git status --short
M  menu.html
ana@vm:~/site$ git restore --staged menu.html
ana@vm:~/site$ git status --short
 M menu.html
```

The `M` moved from the first column to the second: staged, then not staged. **The edit itself is
still in the file**, untouched. `restore --staged` only changes what the next commit would contain.
It is the command lesson 2's `git status` suggested, *use "git restore --staged <file>..." to
unstage*, and now you know what it means.

## Bringing back an older version

Name a commit with `--source` and the file comes back as it was there:

```
ana@vm:~/site$ git restore --source=HEAD~3 menu.html
ana@vm:~/site$ cat menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Rye bread, 1.35</p>
ana@vm:~/site$ git status --short
 M menu.html
ana@vm:~/site$ git restore menu.html
```

The menu from three commits ago, rye bread and its old price included, is back in the working tree,
and `git status` shows it as an ordinary modification. You could commit it, which would record
*"the menu as it was on Wednesday"* as a new change on top of the history. Here it was not wanted,
so a plain `git restore` put the current version back.

Lesson 3's `git show HEAD~3:menu.html` printed the same file. **`show` prints an old version;
`restore --source` puts it back on the disk.** Same question, and one of them changes something.
