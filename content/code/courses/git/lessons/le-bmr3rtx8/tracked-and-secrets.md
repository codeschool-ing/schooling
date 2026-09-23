---
title: Ignoring is not untracking, and a secret stays in the history
version: 1
---

Two mistakes with `.gitignore` are common enough to have their own section, and the second is
expensive.

## Adding a file to .gitignore after it was committed

`settings.local` was committed, then added to `.gitignore`. Somebody edits it:

```
ana@vm:~/site$ git status --short
 M settings.local
ana@vm:~/site$ git rm --cached settings.local
rm 'settings.local'
ana@vm:~/site$ git status --short
D  settings.local
ana@vm:~/site$ git commit -qm "Stop tracking local settings"
ana@vm:~/site$ git status --short
```

**`.gitignore` only applies to files Git is not already tracking.** The file was in the history, so
Git kept tracking it, and the edit shows up as ` M` like any other. To stop, **`git rm --cached`
removes it from the staging area and leaves it on your disk.** The next commit records the file's
removal from the project, and from then on the ignore rule applies: the last `git status` is empty.

Everybody who pulls that commit loses the file from their working tree, because for them it is an
ordinary deletion. For a local settings file that is usually what you want, but say so in the commit
message.

## A secret committed by mistake

A payment key was committed, and the next commit removed it:

```
ana@vm:~/site$ git log --oneline -2
f463511 Remove the payment key
dd37a3f Configure payments
ana@vm:~/site$ ls .env && git status --short
.env
ana@vm:~/site$ git show HEAD~1:.env
PAYMENT_KEY=sk_live_example_not_a_real_key
```

The file is on the disk and ignored now, and the working tree is clean. And `git show HEAD~1:.env`
prints the key, because **deleting a file does not change the commit that added it.** That commit is
in the history, in every clone, and on the shared copy if it was pushed. Lesson 1 said history cannot
be altered without it showing; here that guarantee works against you.

So the rule, in order:

1. **Treat the secret as public from the moment it was committed.** Revoke it and make a new one: a
   new password, a new key. This is the only step that actually fixes anything.
2. Then, if the commits were never pushed, rewrite them with lesson 4's tools before they are.
3. If they were pushed, tools exist to rewrite the whole history without the file, `git filter-repo`
   being the usual one. Every clone then has to be replaced, which is a team decision, and it still does
   not undo copies somebody already made.

GitHub and GitLab scan pushed commits for patterns that look like keys and warn about them, which
catches some of these within minutes. It does not change step 1.

**The prevention is the ignore list.** `.env` and files like it go into `.gitignore` before anybody
writes a secret into them.
