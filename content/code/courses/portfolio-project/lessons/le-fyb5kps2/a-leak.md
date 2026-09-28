---
title: A password, committed and deleted
version: 1
---

Here is the mistake, made on purpose on a branch. Ana starts on e-mail reminders, one of lesson 6's cuts,
and puts the mail settings in a file. The password is invented for this example; no server has it.

```
ana@laptop:~/loanbook$ git switch -q -c reminders
ana@laptop:~/loanbook$ cat notify.py
SMTP_HOST = "smtp.example.org"
SMTP_USER = "loanbook@example.org"
SMTP_PASSWORD = "mR7vQ2xL9pT4wZ8k"
ana@laptop:~/loanbook$ git add notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Send a reminder the day a loan is due'
ana@laptop:~/loanbook$ git rm -q notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Remove the reminder for now'
ana@laptop:~/loanbook$ ls notify.py
ls: cannot access 'notify.py': No such file or directory
```

She commits it, notices, deletes the file and commits again. The file is gone from the working tree, and
`ls` says so. Now ask git where that string has been:

```
ana@laptop:~/loanbook$ git log --oneline -S mR7vQ2xL9pT4wZ8k
96350b2 Remove the reminder for now
6412966 Send a reminder the day a loan is due
ana@laptop:~/loanbook$ git show HEAD~1:notify.py | grep PASSWORD
SMTP_PASSWORD = "mR7vQ2xL9pT4wZ8k"
```

`git log -S` lists every commit that added or removed that exact text, and there are two: the one that
added it and the one that removed it. `git show HEAD~1:notify.py` prints the file **as it was in the
commit before**, password included. Deleting a file removes it from the next version, not from history,
and **history is what gets pushed**.

This is the whole problem in two commands. Anybody who clones the repository has every commit, and
automated programs scan public repositories for strings that look like keys within minutes of a push.
**A secret that reached a public repository has to be treated as known.**

On this branch nothing was pushed, so the fix is simple: the branch is thrown away, and with it both
commits:

```
ana@laptop:~/loanbook$ git switch -q main
ana@laptop:~/loanbook$ git branch -D reminders
Deleted branch reminders (was 96350b2).
ana@laptop:~/loanbook$ git log --all --oneline -S mR7vQ2xL9pT4wZ8k | wc -l
0
```

Zero commits in any branch contain the string. The commits still exist on this machine for a while, in
git's reflog, and nothing that is pushed will carry them.
