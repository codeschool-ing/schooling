---
title: Rewriting history, and recording a dead secret
version: 1
---

Git can rewrite history: replace a value in every commit that holds it, as if it had never been
committed. It sounds like the fix, and it is the step most often done first and in a hurry. **A
rewrite changes your copy of the history and no other copy**, and the copies are the problem.

### What a rewrite does

`git filter-repo` is the tool Git's own documentation recommends for this, in place of the older
`git filter-branch`. It refuses to run anywhere but a fresh clone, so that a mistake costs a clone
and not your work. Try it on a throwaway one, with a rule that replaces the token wherever it
appears. `uvx` runs the tool from PyPI without installing it:

```
ana@vm:~/linkbox$ git clone -q ~/linkbox ~/rewritten && cd ~/rewritten
ana@vm:~/rewritten$ echo "regex:lbx_[A-Za-z0-9]+==>REMOVED" > ~/replace.txt
ana@vm:~/rewritten$ uvx --from git-filter-repo==2.47.0 git-filter-repo --replace-text ~/replace.txt
NOTICE: Removing 'origin' remote; see 'Why is my origin removed?'
        in the manual if you want to push back there.
        (was /home/ana/linkbox)

Parsed 6 commitsHEAD is now at deab516 the token out of the code, and a token of their own for the tests

New history written in 0.08 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 0.18 seconds.
ana@vm:~/rewritten$ git log --oneline
deab516 the token out of the code, and a token of their own for the tests
166654d dependencies moved past their advisories, and composition analysis in the pipeline
f4a5d0c the security headers the baseline scan asked for, and the scan in the nightly run
23ffe39 static analysis in the pipeline, and the two findings it made fixed
4ef17f7 the pipeline takes a list: every push, and the nightly run
b6e2333 linkbox as it was handed over
ana@vm:~/rewritten$ git -C ~/linkbox log --oneline
cb77d44 the token out of the code, and a token of their own for the tests
19d0738 dependencies moved past their advisories, and composition analysis in the pipeline
d1186df the security headers the baseline scan asked for, and the scan in the nightly run
3afa289 static analysis in the pipeline, and the two findings it made fixed
ed9bbb4 the pipeline takes a list: every push, and the nightly run
3f932db linkbox as it was handed over
ana@vm:~/rewritten$ git show $(git rev-list --max-parents=0 HEAD):settings.py
import os

DATABASE = os.environ.get("LINKBOX_DB", "linkbox.db")
ADMIN_TOKEN = "REMOVED"
ana@vm:~/rewritten$ git -C ~/ci/linkbox.git grep -c lbx_7Rq2 main -- settings.py
main:settings.py:1
ana@vm:~/rewritten$ cd ~/linkbox && rm -rf ~/rewritten ~/replace.txt
```

Three things in that output are the whole argument.

**Every commit has a new hash.** `b6e2333` where your repository has `3f932db`, and so on down to
the newest. A commit's hash covers its content and its parent, so changing the first commit changes
every commit after it. Every clone, every fork, every open branch and every CI run that names a
commit now names one that the rewritten history does not have. Each of those people has to throw
their clone away and clone again, and a branch somebody forgot to rebase brings the old commits,
token included, straight back with its next push.

**The rewritten clone no longer knows where it came from.** filter-repo removed the `origin`
remote on purpose: pushing a rewritten history means a forced push, which is a decision to be made
by a person, after telling everybody who has a clone.

**The server still has the token**, because the rewrite happened in one clone and the server is
another. A forced push would replace the branches there, and still leaves the forks, the backups
and every laptop. On a hosted platform there is more: GitHub's documentation on removing sensitive
data says that cached views and the references of pull requests can keep the old commits reachable
until its support team removes them, and that forks are not affected at all. None of that was run
for this course.

### So it comes last, and often not at all

Once the value is revoked, the copies hold something that opens nothing. **Rewriting then buys
little**: a scanner stops reporting it, at the price of every clone. Rewriting is worth that price
when the thing committed cannot be revoked: personal data, a customer's file, the private key of
a certificate somebody else already trusts. Then the rewrite is part of limiting the damage, done
together with everybody who holds a copy, and it is still not a reason to skip the revocation.

linkbox's token was revoked in the last section. The history stays as it is.

### Recording the dead finding

The history scan still reports the token, and it will on every run for as long as the repository
exists. **A finding that has been handled has to be recorded as handled**, or the pipeline breaks
on it forever and somebody, one day, switches the stage off. gitleaks reads a file called
`.gitleaksignore` at the root of the repository: one fingerprint per line, and the findings it
names are left out of the report.

The fingerprint is the last line of the finding in the scan of the history, two sections back.
**Take it from your own output**, not from this page: it starts with the hash of your first commit,
which is not `3f932db`. Then write down, above it, why the finding is dead and since when, with the
date you rotated yours. Save it as `.gitleaksignore`:

```
# Findings that are dead: each one is a secret that was rotated, so the value
# in the history opens nothing any more. One fingerprint per line.
#
# The administration token committed with the first version of settings.py,
# revoked and replaced on 2026-10-12.
3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py:generic-api-key:4
```

```
ana@vm:~/linkbox$ gitleaks git --no-banner --no-color .
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
2:00AM INF 6 commits scanned.
2:00AM INF scanned ~9214 bytes (9.21 KB) in 285ms
2:00AM INF no leaks found
ana@vm:~/linkbox$ git add .gitleaksignore
ana@vm:~/linkbox$ git commit -q -m "the rotated token, recorded as a dead finding"
```

**The fingerprint names one finding, not a rule and not a file.** A new secret added to
`settings.py` tomorrow has a different commit in its fingerprint and is reported like any other.
That is the difference between this file and switching `generic-api-key` off, and it is why the
comment says what was done rather than "false positive": the finding was true, and the value is
dead because somebody killed it.
