---
title: Status, add, commit
version: 1
---

Three commands do nearly all the work, and one of them only reads. **`git status` is the one to type
whenever you are unsure**, because it never changes anything and it always says where things stand.

In a repository with no commits and one new file:

```
ana@vm:~/site$ git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	index.html

nothing added to commit but untracked files present (use "git add" to track)
```

*Untracked* means Git sees the file and has never been asked to keep it. It will stay untracked, and
out of every commit, until somebody adds it. Notice the last line: Git is telling you what to do
next, in words. Most `git status` output does.

## Add, then look again

```
ana@vm:~/site$ git add index.html
ana@vm:~/site$ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   index.html
```

The same file has moved to *Changes to be committed*. That heading is the staging area. Git also
tells you how to take it back out, with `git rm --cached`; lesson 4 is about taking things back, and
there is a newer command for it that you will see in the next output.

## Commit

```
ana@vm:~/site$ git commit -m "Add the home page"
[main (root-commit) 6abda31] Add the home page
 1 file changed, 2 insertions(+)
 create mode 100644 index.html
ana@vm:~/site$ git status
On branch main
nothing to commit, working tree clean
```

Four lines, each worth reading once:

- `[main (root-commit) 6abda31]` is the branch the commit went onto, the fact that it is the first
  commit of the repository, which is what *root* means, and its short id.
- `Add the home page` is the message, repeated back.
- `1 file changed, 2 insertions(+)` counts what the commit changed: one file, two new lines.
- `create mode 100644 index.html` says a file entered the history for the first time. The number is
  the file's permissions, which Git records; `100644` is an ordinary file that nobody runs.

Then `git status` again, and the three places agree: **working tree clean** means every file on disk
matches the last commit, and there is nothing staged. That is the state to be in before you switch
to other work, and the state lesson 5 recommends before you change branch.

## The message is not optional

`-m` put the message on the command line. Leave it off and Git opens the editor you chose in lesson 1
and waits for you to write one. Close the editor with nothing written and Git cancels the commit.
Lesson 11 is about what a good message says; for now, one line saying why is enough.
