---
title: When a push is rejected
version: 1
---

Ana commits a change to the opening days. Meanwhile, without her knowing, Bruno commits and pushes a
change to the stylesheet. Ana pushes:

```
ana@vm:~/site$ git push
To /home/ana/remotes/site.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '/home/ana/remotes/site.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

**Rejected, and for a good reason.** `origin`'s `main` now points at Bruno's commit, which Ana does not
have. If Git accepted her push, it would have to move `origin`'s `main` to her commit, and Bruno's
commit, which is not in her history, would drop off the branch. **A push only moves a branch forward**;
it never throws away commits that are already there. *Fetch first*, says the short reason, and the
hints say the same at length.

This is not an error to get around. It is Git protecting Bruno's work from Ana's push.

## Pull, and the question it asks

Following the hint:

```
ana@vm:~/site$ git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), 288 bytes | 288.00 KiB/s, done.
From /home/ana/remotes/site
   eab2026..34c7644  main       -> origin/main
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint: 
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint: 
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
```

The fetch worked: `eab2026..34c7644  main -> origin/main` is Bruno's commit arriving. Then Git
**stopped and asked**. Ana's `main` and `origin/main` have diverged, each with a commit the other lacks,
and there are two ways to join them — the two ways of lesson 6. Git will not choose one silently, so
it names three settings and three options, and refuses until it is told.

- `--no-rebase`, or `pull.rebase false`: **merge** `origin/main` into `main`, with a merge commit.
- `--rebase`, or `pull.rebase true`: **rebase** your unpushed commits on top of `origin/main`.
- `--ff-only`: only accept the case with nothing to join, and refuse otherwise.

## Pull with rebase, then push

```
ana@vm:~/site$ git pull --rebase
Successfully rebased and updated refs/heads/main.
ana@vm:~/site$ git push
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 420 bytes | 420.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
   34c7644..ce54046  main -> main
ana@vm:~/site$ git log --oneline -3
ce54046 Say which days we open
34c7644 Give paragraphs more room
eab2026 Charge 2.60 for cheese rolls
```

`--rebase` replayed Ana's one unpushed commit on top of Bruno's, and the push went through with the
ordinary `34c7644..ce54046` of a branch moving forward. The history is one straight line: prices,
paragraphs, opening days.

**This is lesson 6's rule applied automatically.** The only commit rewritten was Ana's own, which
nobody else had yet; Bruno's was left exactly as it was. That is why many teams set
`git config --global pull.rebase true` once and never think about it again, and why it is a safe
default. The others prefer merges, and `pull.rebase false` gives them that. Either is fine; not
choosing is what the hint is refusing to allow.

**Never force a rejected push to make it go through.** `git push --force` exists, and it does exactly
what the rejection prevented: it moves the remote branch to your commit and drops the commits you did
not have. It has legitimate uses on a branch that is only yours, and none on a branch you share.
