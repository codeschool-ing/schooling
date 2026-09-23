---
title: Switching, and what happens to your files
version: 1
---

**`git switch` moves `HEAD` to another branch, and changes the working tree to match that branch's
commit.** That second half is the part to understand, because it is the only time Git rewrites your
files as a side effect.

```
ana@vm:~/site$ git switch opening-hours
Switched to branch 'opening-hours'
ana@vm:~/site$ cat .git/HEAD
ref: refs/heads/opening-hours
ana@vm:~/site$ git commit -qam "Open on Sundays from seven"
ana@vm:~/site$ git log --oneline -2
9677eef Open on Sundays from seven
6555c9b Link the menu from the home page
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ cat index.html
<h1>Padaria Sol</h1>
<p>Bread from half past five.</p>
<p><a href="menu.html">See the menu</a></p>
```

`HEAD` now says `opening-hours`, and the commit about Sunday hours went onto that branch only. Back on
`main`, `index.html` says *half past five* and nothing about Sundays, because `main` still points at
the commit before. **The file on disk is whatever the branch you are on says it is.** Switch back and
the Sunday line reappears; nothing was lost, only swapped.

`git switch -c name` creates a branch and switches to it in one step, which is how most branches are
made in practice. You will see it in the next section.

## Changes you have not committed come with you

An uncommitted edit belongs to the working tree, not to any branch. So when nothing conflicts, it
travels:

```
ana@vm:~/site$ git status --short
 M style.css
ana@vm:~/site$ git switch opening-hours
Switched to branch 'opening-hours'
M	style.css
ana@vm:~/site$ git status --short
 M style.css
ana@vm:~/site$ git switch main
Switched to branch 'main'
M	style.css
```

The edit to `style.css` was there before the switch and after it, and Git listed it on each switch
(`M	style.css`) so it does not go unnoticed. The two branches have the same `style.css`, so carrying the
edit across could not damage anything.

## And when it would lose them, Git refuses

Now an uncommitted edit to `index.html`, the one file the two branches disagree about:

```
ana@vm:~/site$ git switch opening-hours
error: Your local changes to the following files would be overwritten by checkout:
	index.html
Please commit your changes or stash them before you switch branches.
Aborting
```

**Git will not overwrite a change it has no copy of.** Switching would have replaced `index.html` with
`opening-hours`' version and thrown the edit away, so it stops and says so, and nothing changes.
Commit the edit, or restore it, and the switch goes through. (*Stash*, which the message suggests, is
a third way: it puts changes aside temporarily. Committing is simpler and just as quick, and a
commit shows up in the log, where a stash is easy to forget.)

This is why lesson 2 said a clean working tree is the state to be in before you change branch: it is
never refused, and nothing comes with you by surprise.
