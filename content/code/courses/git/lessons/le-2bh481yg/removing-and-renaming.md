---
title: Removing and renaming, so that Git knows
version: 1
---

Deleting or renaming a file is a change like any other, and it has to be staged like any other. The
difference is that the file is not there any more to `git add`, which is why Git has two commands of
its own.

## What a plain mv looks like to Git

Rename the stylesheet with the ordinary shell command, and Git sees two unrelated events:

```
ana@vm:~/site$ git add menu.html todo.txt && git commit -q -m "Add the menu and a to-do list"
ana@vm:~/site$ mv style.css site.css
ana@vm:~/site$ git status --short
 D style.css
?? site.css
ana@vm:~/site$ mv site.css style.css
ana@vm:~/site$ git mv style.css site.css
ana@vm:~/site$ git status --short
R  style.css -> site.css
ana@vm:~/site$ git rm todo.txt
rm 'todo.txt'
ana@vm:~/site$ git status --short
R  style.css -> site.css
D  todo.txt
ana@vm:~/site$ git commit -m "Rename the stylesheet and drop the to-do list"
[main 8317687] Rename the stylesheet and drop the to-do list
 2 files changed, 1 deletion(-)
 rename style.css => site.css (100%)
 delete mode 100644 todo.txt
```

Read it from the top. After a plain `mv`, the short status says `D style.css`, deleted, and
`?? site.css`, untracked. **Git does not watch renames; it compares what is there with what was
there.** One file vanished and a new one appeared. Both changes are unstaged, so a commit made now
would contain neither.

`git mv` does the rename and stages it in one step, and the status shows `R  style.css -> site.css`:
renamed, staged. `git rm` does the same for a deletion: it removes `todo.txt` from the disk and
stages the removal, which is `D` in the first column. The first column of the short status is the
staging area and the second is the working tree, so a letter on the left means *ready to commit*.

The commit summary says the rest: `delete mode 100644 todo.txt`, and `rename style.css => site.css
(100%)`. The percentage is how similar the two files are. **Git works renames out when it is asked**,
by comparing content, and a file that moved without changing is 100% similar to what it was.

## So is git mv necessary?

Not strictly. `git add` on the new name plus `git add` on the old one, which stages the deletion,
gives exactly the same commit, and Git reports the rename either way because it detects it from the
content. `git mv` and `git rm` are the short way to say *make this change and stage it*, and the one
thing to avoid is the plain `rm` followed by a commit that forgets the deletion: the file is gone
from your disk and still in the next commit.

## The history so far

```
ana@vm:~/site$ git log --oneline
8317687 Rename the stylesheet and drop the to-do list
be10e14 Add the menu and a to-do list
132c557 Open every day
11b9ca3 Open half an hour earlier
5d6d04f Give the heading its colour
6abda31 Add the home page
```

Six commits, each one small and each one about one thing. That is the habit this lesson is really
about. The commands are four — `status`, `add`, `commit`, and `rm`/`mv` for the changes you cannot
`add` — and the staging area is what lets each commit say one thing.
