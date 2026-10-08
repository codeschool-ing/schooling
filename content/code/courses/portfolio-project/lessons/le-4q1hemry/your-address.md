---
title: The address on every commit
version: 2
---

Every commit carries a name and an e-mail address, and pushing to a public repository publishes both,
permanently, in every clone. Ask loanbook's history who wrote it:

```
ana@laptop:~/loanbook$ git log --format='%an <%ae>' | sort | uniq -c
     20 Ana Lima <ana@example.org>
ana@laptop:~/loanbook$ git config user.email
ana@example.org
```

Twenty commits, one author, one address, taken from git's configuration at the moment of each commit.
`example.org` is a reserved domain, so this one reaches nobody; on your machine it is whatever you typed
the day you installed git, often a personal address you would not put on a public page.

Hosting sites offer a way out: a **no-reply address** that links commits to your account without exposing
a mailbox. On GitHub it has the shape `ID+username@users.noreply.github.com`, shown in the account's e-mail
settings, where an option also blocks pushes that would expose your real address. Set it before the first
push:

```
ana@laptop:~/loanbook$ git config user.email '12345678+ana-lima@users.noreply.github.com'
ana@laptop:~/loanbook$ git commit -q --allow-empty -m 'Check which address a commit carries'
ana@laptop:~/loanbook$ git log -1 --format='%an <%ae>'
Ana Lima <12345678+ana-lima@users.noreply.github.com>
ana@laptop:~/loanbook$ git reset -q --hard HEAD~1 && git config --unset user.email
```

The configuration changed, and the next commit carries the new address. The example ID and username here
are invented, so the commit was thrown away afterwards; yours come from your own settings page.

The history publishes one more thing, **when you worked**. Every commit has a date and time:

```
ana@laptop:~/loanbook$ git log --format=%ad --date=format:%a | sort | uniq -c | sort -rn
      5 Wed
      5 Mon
      4 Thu
      4 Fri
      2 Tue
```

loanbook's dates were written down by hand when its history was recorded for this course, so this pattern
describes nobody. On a real project it describes you, and some people prefer not to publish that their project was built between two and four in
the morning. There is no setting that hides it; knowing it is there is the point.
