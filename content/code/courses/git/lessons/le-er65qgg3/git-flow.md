---
title: Git Flow: develop, release and hotfix branches
version: 1
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

Here is a small ordering app kept that way: two features, a release 1.1, and a hotfix 1.1.1:

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
