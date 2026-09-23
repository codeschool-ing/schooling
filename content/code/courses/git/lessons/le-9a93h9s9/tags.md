---
title: Tags, and cleaning up the shared copy
version: 1
---

A branch is a name that moves. **A tag is a name that does not**: it marks one commit for good, which
is exactly what a release needs. *Version 1.0 is this commit* should be true next year as well.

```
ana@vm:~/site$ git tag -a v1.0 -m "The site as it went live"
ana@vm:~/site$ git tag
v1.0
ana@vm:~/site$ git show v1.0 --no-patch
tag v1.0
Tagger: Ana Souza <ana@example.com>
Date:   Mon Sep 21 12:00:00 2026 -0300

The site as it went live

commit ce540461c19b2c235a2d3248ee8f3f3f082dd590
Author: Ana Souza <ana@example.com>
Date:   Mon Sep 21 11:00:00 2026 -0300

    Say which days we open
ana@vm:~/site$ git push origin v1.0
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 169 bytes | 169.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new tag]         v1.0 -> v1.0
```

`git tag -a v1.0 -m "…"` made an **annotated tag**: a small object of its own, with a tagger, a date
and a message, pointing at a commit. `git show v1.0 --no-patch` prints the tag first and the commit it
names after it. A tag made without `-a` and `-m` is a *lightweight* tag, a bare name for a commit with
nothing else recorded; annotated tags are the ones to use for releases, because they say who made
the release and when.

**Tags are not pushed with `git push`.** It sends branches. `git push origin v1.0` sends one tag, and
`git push --tags` would send every tag you have. Once a tag is on the shared copy, treat it as
permanent: people and machines build releases from it, and moving it would give the same version
number to two different commits. If a release was wrong, make a new one, `v1.0.1`.

The names are free text, but nearly everybody uses **semantic versioning**: `v` and three numbers,
*major.minor.patch*. The last one goes up for a fix, the middle one for something new that breaks
nothing, and the first when something that used to work no longer does. Lesson 11 connects this to
commit messages.

## Deleting a branch on the shared copy

Lesson 5 deleted branches in your own repository. A branch that was pushed also exists on `origin`,
and deleting it there is a separate push:

```
ana@vm:~/site$ git push -u origin autumn-menu
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      autumn-menu -> autumn-menu
branch 'autumn-menu' set up to track 'origin/autumn-menu'.
ana@vm:~/site$ git push origin --delete autumn-menu
To /home/ana/remotes/site.git
 - [deleted]         autumn-menu
```

`git push origin --delete autumn-menu` removed the branch from the shared copy — `- [deleted]`. It
did not touch Ana's own `autumn-menu`, which `git branch -d` would delete as in lesson 5. Hosting
services usually offer to do this with a button the moment a pull request is merged, which is lesson
8's subject.

## The five commands

- `git clone <address>`: your own complete copy, with `origin` set up.
- `git push`: send your commits; `-u` the first time for a new branch; rejected if you are behind.
- `git fetch`: bring other people's commits in and update `origin/…`, changing nothing of yours.
- `git pull`: fetch, then bring `origin/…` into your branch, by merge or by rebase as configured.
- `git tag -a`: a permanent name for a commit, pushed on its own.
