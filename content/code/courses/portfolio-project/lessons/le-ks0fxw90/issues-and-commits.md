---
title: From a card to a commit
version: 1
---

A board earns its place in a portfolio when it is **connected to the code**. A reviewer reading a
commit can then follow it back to the card, and from the card to the reason the work was done. The
connection is one line at the end of a commit message:

```
ana@laptop:~/loanbook$ git log --format='%h %s%n%b' --grep='Closes #'
5e90846 Mark a loan overdue the day after it is due
Closes #5

2fb7c61 Refuse to lend an item that is already out
Two people could lend the same projector from two browsers, and the
list then showed it twice. A partial unique index allows one open loan
per item, so the database refuses the second one even when both
requests arrive together. The handler turns that refusal into a 409
with a sentence the page shows.

Closes #3
```

`git log --grep` lists the commits whose message matches a pattern, and these are the two in loanbook
that close an issue. On GitHub and GitLab, a commit or pull request that says **`Closes #3`** closes
issue 3 when it reaches the default branch, and each side links to the other: the issue shows the
commit that closed it, and the commit links to the issue.

For a portfolio this does three things. **It shows the work was planned**, not improvised: the card
existed before the code. **It keeps the discussion in one place**: if the issue says why the index
went in the database and not in the code, the commit message can be short and still be understood.
And **it gives the history an index**: a reviewer who wants to see how the one thing was built opens
issue 3 and has the commit, the test and the discussion in one click.

Use the keyword only on the commit that finishes the card. A commit that is part of the work can say
*refs #3* instead, which links without closing.
