---
title: Review, as the platform sees it
version: 1
---

This section is the mechanics: what the buttons record. Lessons 13 and 14 are the part that is harder
than the buttons — what to say in a review, and how to take one.

## Comments on lines

A reviewer reads the *files changed* tab and **comments on a specific line of the diff**. The comment
stays attached to that line, and when the author pushes a change to it, the service shows the
comment as *outdated* and keeps the thread. Most services also let a reviewer propose an exact
replacement for a line, which the author can accept with one click, making a commit.

## A review ends with a verdict

On GitHub, a reviewer finishes with one of three:

- **Comment** — remarks, with no verdict either way.
- **Approve** — this can be merged as it is.
- **Request changes** — this should not be merged until something is addressed.

GitLab and Bitbucket have the same ideas under slightly different names. What matters is that the
verdict is **recorded, with a name and a time**, next to the change it applies to.

## Rules the repository can enforce

The main branch of a team repository is usually **protected**: settings on the hosting service that
Git itself knows nothing about. The common ones:

- nobody pushes to `main` directly; every change arrives through a pull request;
- a pull request needs one or two approvals before the merge button works;
- the checks have to pass;
- `git push --force` to `main` is refused outright, which is lesson 7's warning turned into a lock.

Some repositories also name owners for parts of the code, in a file called `CODEOWNERS`, so that a
change to the payments code automatically asks the payments people to review it.

**None of this is Git.** A clone of the repository has none of these rules, and the same commits could
be pushed to a repository with none. The protection lives on the server, which is exactly why the
shared copy is where a team puts it.
