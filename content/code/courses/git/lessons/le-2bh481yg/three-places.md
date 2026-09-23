---
title: Working tree, staging area and repository
version: 1
---

A repository starts as an ordinary folder. `git init` turns it into one:

```
ana@vm:~$ mkdir site && cd site
ana@vm:~/site$ git init
Initialized empty Git repository in /home/ana/site/.git/
ana@vm:~/site$ ls -a
.
..
.git
index.html
ana@vm:~/site$ ls .git
HEAD
branches
config
description
hooks
info
objects
refs
```

Nothing about `index.html` changed. What changed is the new directory beside it, `.git`, which
`ls` only shows when asked for hidden files with `-a`. **That directory is the repository.** Every
commit, every branch and every setting of this project lives inside it, and nowhere else. Copy the
folder and you copy the history; delete `.git` and the history is gone while the files stay exactly
as they are. You will never need to edit anything in there by hand, and lesson 1 already showed the
one time it is worth looking: the objects in it are commits, trees and file contents.

## Three places, not two

The obvious picture has two places: the files, and the saved versions. Git has a third in between,
and most of the confusion people have with Git comes from not knowing it is there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Three boxes from left to right: the working tree, which holds the files you edit; the staging area, which holds the next commit while it is being assembled; and the repository, which holds every commit. git add carries a change from the first to the second, and git commit carries everything staged into the third.\"><defs><marker id=\"tp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">working tree</text><text x=\"110\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the files you edit</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">staging area</text><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the next commit, being assembled</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">repository</text><text x=\"610\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every commit, in .git</text><path d=\"M203 75 L266 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><text x=\"235\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git add</text><path d=\"M453 75 L516 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><text x=\"485\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git commit</text><path d=\"M110 112 L110 150 L610 150 L610 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M360 112 L360 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"360\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">git status compares the three and tells you where each change is</text></svg>", "caption": "A change travels left to right in two steps. Between them it can be looked at, and left out."}
```

**The working tree** is the folder as you see it: the files your editor opens and your browser
loads. Git watches it and never changes it behind your back.

**The staging area** is the commit you are building. `git add` copies a file, as it is at that
moment, into it. Nothing is saved to the history yet. It is also called *the index*, which is the
name you will meet in older documentation and in some of Git's own messages.

**The repository** is the history. `git commit` takes whatever is in the staging area, all of it and
nothing else, and records it as a new commit.

## Why the middle step exists

Subversion, and most systems before Git, had no staging area: a commit took every change you had
made, unless you listed files one by one. The trouble is that a working tree rarely holds exactly one change. You fix the opening hours,
you start a new stylesheet, you leave a paragraph half-written, and then somebody asks you to commit
the fix. **The staging area is where you say which of those changes this commit is about.** The rest
stays in the working tree, untouched, for a later commit, or for none.

That is the reason, and it is worth holding on to, because the commands in this lesson only make
sense against it. `git add` does not mean *track this file forever*. It means *put this version of
this file into the next commit*.
