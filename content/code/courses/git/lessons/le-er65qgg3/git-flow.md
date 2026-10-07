---
title: Git Flow: develop, release and hotfix branches
version: 2
---

Git Flow was described in 2010 for a particular kind of software: **products shipped as numbered
versions**, where version 1.1 is prepared, tested and released as a unit, and version 1.0 keeps
receiving fixes meanwhile. Desktop software, mobile apps waiting for a store's review, libraries.

## The lanes

- **`main`** holds only released versions. Every commit on it is a release, and is tagged.
- **`develop`** is where finished work collects for the next release.
- **`feature/…`** branches start from `develop` and merge back into it.
- **`release/…`** branches start from `develop` when a version is being prepared: only fixes go in,
  then it merges into `main`, gets its tag, and merges back into `develop`.
- **`hotfix/…`** branches start from `main` for an urgent fix to a released version, and merge into
  both `main` and `develop`.

Here is a small ordering app kept that way: two features, a release 1.1, and a hotfix 1.1.1. A short
program makes its history, and it is worth reading before running, because every block in it is one
of the lanes above being used:

```bash
#!/usr/bin/env bash
# make-app.sh: a small ordering app, kept the Git Flow way by Ana and Bruno.
# Every date and every name is written down, so the ids match the lesson's.
set -e
if [ -e ~/app ]; then
  echo "~/app already exists. Move it aside or delete it, then run this again." >&2
  exit 1
fi
mkdir ~/app && cd ~/app && git init -q -b main

when()  { export GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1"; }
ana()   { export GIT_AUTHOR_NAME='Ana Souza' GIT_COMMITTER_NAME='Ana Souza' \
                 GIT_AUTHOR_EMAIL=ana@example.com GIT_COMMITTER_EMAIL=ana@example.com; }
bruno() { export GIT_AUTHOR_NAME='Bruno Lima' GIT_COMMITTER_NAME='Bruno Lima' \
                 GIT_AUTHOR_EMAIL=bruno@example.com GIT_COMMITTER_EMAIL=bruno@example.com; }
commit() { git add -A && git commit -q -m "$1"; }
# finish BRANCH INTO: merge a finished branch, always with a merge commit
finish() { git switch -q "$2" && git merge -q --no-ff --no-edit "$1"; }

ana; when 2026-06-01T09:00:00-03:00
printf 'Padaria Sol ordering app\n' > README.md; commit 'Start the ordering app'
git tag -a v1.0 -m 'First release'
git switch -q -c develop

when 2026-06-03T10:00:00-03:00
git switch -q -c feature/basket develop
printf 'basket\n' > basket.txt; commit 'Add a basket'
when 2026-06-04T10:00:00-03:00
finish feature/basket develop; git branch -q -d feature/basket

bruno; when 2026-06-05T11:00:00-03:00
git switch -q -c feature/pickup develop
printf 'pickup\n' > pickup.txt; commit 'Let customers choose a pickup time'
when 2026-06-08T11:00:00-03:00
finish feature/pickup develop; git branch -q -d feature/pickup

ana; when 2026-06-09T09:00:00-03:00
git switch -q -c release/1.1 develop
sed -i 's/app/app, version 1.1/' README.md; commit 'Prepare release 1.1'
when 2026-06-10T09:00:00-03:00
finish release/1.1 main; git tag -a v1.1 -m 'Release 1.1'
finish release/1.1 develop; git branch -q -d release/1.1

bruno; when 2026-06-11T16:00:00-03:00
git switch -q -c hotfix/1.1.1 main
printf 'pickup, not before 06:00\n' > pickup.txt; commit 'Refuse pickup times before we open'
when 2026-06-11T17:00:00-03:00
finish hotfix/1.1.1 main; git tag -a v1.1.1 -m 'Release 1.1.1'
finish hotfix/1.1.1 develop; git branch -q -d hotfix/1.1.1
```

`finish` is the move Git Flow repeats: switch to the branch the work goes into and merge it there with
`--no-ff`, so that the merge commit shows where the work joined. The release and the hotfix are each
finished twice. Save the program as `~/make-app.sh`, the way you saved lesson 3's, and run it:

```bash
cd ~ && bash ~/make-app.sh && cd ~/app
```

Then ask what it made:

```
ana@vm:~/app$ git branch
* develop
  main
ana@vm:~/app$ git log --oneline --graph --all
*   59d24ca Merge branch 'hotfix/1.1.1' into develop
|\  
* \   28f0220 Merge branch 'release/1.1' into develop
|\ \  
| | | *   aea0ad6 Merge branch 'hotfix/1.1.1'
| | | |\  
| | | |/  
| | |/|   
| | * | e0d054e Refuse pickup times before we open
| | |/  
| | *   c912762 Merge branch 'release/1.1'
| | |\  
| | |/  
| |/|   
| * | f641244 Prepare release 1.1
|/ /  
* |   e601e60 Merge branch 'feature/pickup' into develop
|\ \  
| * | 8d10f6a Let customers choose a pickup time
|/ /  
* |   086b150 Merge branch 'feature/basket' into develop
|\ \  
| |/  
|/|   
| * e6d8bcd Add a basket
|/  
* 3e9c870 Start the ordering app
ana@vm:~/app$ git tag
v1.0
v1.1
v1.1.1
```

That is six branches' worth of work, three releases, and **six merge commits for two features, one
release and one fix**. Everything is traceable: each tag marks exactly what shipped, and `main` never holds
anything that was not released. The cost is equally visible: every release and every hotfix is merged
twice, the graph needs effort to read, and a developer has to remember which branch each kind of
change starts from.

## When it fits, and when it does not

It fits when **there really are versions**: when customers run 1.1 while 1.2 is being prepared, and a
fix to 1.1 must not wait for 1.2's features. It is heavy for a website or a web application that is
deployed many times a day, where there is no *version 1.1* in any meaningful sense — only whatever is
running now. Most web teams that adopted Git Flow in the 2010s have since moved to one of the two
simpler shapes, and the article that described it added a note in 2020 saying as much.

The lesson worth keeping is not the lanes. It is the question they answer: **how does your software
reach the people who use it?** A workflow that matches the answer feels light; one that does not
feels like ceremony.
