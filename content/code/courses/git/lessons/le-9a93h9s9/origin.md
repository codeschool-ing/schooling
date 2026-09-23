---
title: A remote, and the first push
version: 1
---

A **remote** is another copy of the repository that yours knows the address of. In a team it is the
shared copy on GitHub, GitLab or a company server. This lesson uses one on the same machine, in
`~/remotes`, so that every command can be shown working with no account and no network. Git treats
a folder on your disk and a URL on the internet the same way; only the address changes.

## A shared repository has no working tree

```
ana@vm:~$ git init --bare ~/remotes/site.git
Initialized empty Git repository in /home/ana/remotes/site.git/
```

`--bare` makes a repository with no working tree: just what is inside `.git`, with nobody editing
files in it. **That is what a shared repository is.** Nobody works *in* it; everybody works in their
own copy and sends commits to it. GitHub's copies of your repositories are bare repositories too.

## Naming it, and sending the first commits

```
ana@vm:~/site$ git remote add origin ~/remotes/site.git
ana@vm:~/site$ git remote -v
origin	/home/ana/remotes/site.git (fetch)
origin	/home/ana/remotes/site.git (push)
ana@vm:~/site$ git push -u origin main
Enumerating objects: 27, done.
Counting objects: 100% (27/27), done.
Delta compression using up to 4 threads
Compressing objects: 100% (24/24), done.
Writing objects: 100% (27/27), 2.78 KiB | 711.00 KiB/s, done.
Total 27 (delta 2), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

`git remote add origin <address>` gives the address a short name. **`origin` is only a convention**,
the name `git clone` uses for the copy it came from, and the one almost every team uses for the
shared copy. `git remote -v` lists the remotes and the address used for fetching and pushing.

`git push -u origin main` sends the branch `main` to `origin`. The output is worth reading once:

- the first six lines are Git **packing the objects** — commits, trees and file contents — that the
  other side does not have yet. Nothing to act on.
- `* [new branch]  main -> main` says a branch called `main` now exists on `origin`, and points
  where yours does.
- `branch 'main' set up to track 'origin/main'` is what `-u` did. From now on, **`main` knows which
  branch on which remote it goes with**, so a plain `git push` or `git pull` needs no names. You only
  need `-u` the first time you push a branch.

## Cloning

Bruno joins. He does not create anything; he clones the shared copy. Here his copy is a second folder
on the same machine, which is why the prompt still says `ana`:

```
ana@vm:~$ mkdir bruno && cd bruno
ana@vm:~/bruno$ git clone ~/remotes/site.git
Cloning into 'site'...
done.
ana@vm:~/bruno$ cd site
ana@vm:~/bruno/site$ git config user.name "Bruno Lima"
ana@vm:~/bruno/site$ git config user.email "bruno@example.com"
ana@vm:~/bruno/site$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```

`git clone` made a folder named after the repository, copied every commit into it, named the source
`origin` and checked out `main`. Then Bruno told Git who he is **in this repository only**, with no
`--global` — the per-repository setting lesson 1 described, doing exactly the job it was for.

`git branch -a` lists the remote-tracking branches too. **`remotes/origin/main` is Bruno's record of
where `origin`'s `main` was when he cloned.** It is not a branch he works on; it is a bookmark that
Git moves when he talks to `origin`, and the next section is about how easily it goes out of date.
