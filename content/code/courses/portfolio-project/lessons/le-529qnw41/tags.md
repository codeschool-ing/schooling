---
title: Marking a milestone in git
version: 1
---

A milestone that is only in your head cannot be found again. Git has a name for a commit you want to
find again: a **tag**. An annotated tag carries a message, and the message is where the milestone's
one-line description goes:

```
ana@laptop:~/loanbook$ git tag -a v0.2.0 -m 'The rules: one loan at a time, overdue after seven days'
ana@laptop:~/loanbook$ git tag -n
v0.1.0          The skeleton: list, lend and take back, end to end
v0.2.0          The rules: one loan at a time, overdue after seven days
```

`git tag -a` makes the annotated tag on the current commit, and `git tag -n` lists every tag with the
first line of its message. By the end of the project the list reads like a table of contents:

```
ana@laptop:~/loanbook$ git tag -n
v0.1.0          The skeleton: list, lend and take back, end to end
v0.2.0          The rules: one loan at a time, overdue after seven days
v0.3.0          Deployed: a container under systemd, behind Caddy
v1.0.0          First version worth showing
```

The names follow **semantic versioning**: `MAJOR.MINOR.PATCH`, with `0` as the major number while the
project is not yet the first version worth showing. `v1.0.0` is a statement that it is. Nobody checks
the numbers against a rule, but a reviewer who sees `v1.0.0` expects lesson 2's *finished*, and a
project that tags its first commit `v1.0.0` has spent the word early.

Tags also make comparisons easy. Everything that changed between *the rules hold* and *it is
deployed* is one command:

```
ana@laptop:~/loanbook$ git diff --stat v0.2.0 v0.3.0
 .gitignore                |  1 +
 Containerfile             |  8 +++++++
 app.py                    | 10 +++++++--
 deploy/Caddyfile          |  4 ++++
 deploy/loanbook.container | 15 +++++++++++++
 static/app.js             | 80 +++++++++++++++++++++++++++++++++++++++++++++++--------------------
 static/index.html         | 17 +++++++++------
 static/style.css          | 21 ++++++++++++++----
 test_app.py               |  5 +++++
 9 files changed, 124 insertions(+), 37 deletions(-)
```

That is the answer to *what did the deploy milestone cost?*, and it is lesson 21's evidence. On
GitHub or GitLab each tag can also become a **release**, a page with notes and downloads; for a
portfolio project, pushing the tags with `git push --tags` and writing two lines of notes on each is
plenty.
