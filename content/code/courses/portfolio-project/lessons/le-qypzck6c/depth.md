---
title: What depth looks like in a history
version: 1
---

Depth is not a feature count. It is the moment in a project where something went wrong or got hard
and the author decided what to do about it. A tutorial never has one, because the tutorial removed
them all before you arrived.

loanbook has one early. Here are the five commits between its first two milestones, lesson 7's tags:

```
ana@laptop:~/loanbook$ git log --oneline v0.1.0..v0.2.0
5e90846 Mark a loan overdue the day after it is due
946c9a3 Say what to do when there is nothing to lend
b7f4c5f Answer every error as JSON
55012ed Test the loan rules
2fb7c61 Refuse to lend an item that is already out
```

The log lists the newest first, so the oldest of the five is at the bottom, and it is the one a
tutorial would not contain. Here it is in full:

```
ana@laptop:~/loanbook$ git show --stat 2fb7c61
commit 2fb7c61d4803b708129010e93072f67369b02445
Author: Ana Lima <ana@example.org>
Date:   Tue Jun 9 10:10:00 2026 -0300

    Refuse to lend an item that is already out
    
    Two people could lend the same projector from two browsers, and the
    list then showed it twice. A partial unique index allows one open loan
    per item, so the database refuses the second one even when both
    requests arrive together. The handler turns that refusal into a 409
    with a sentence the page shows.
    
    Closes #3

 app.py        | 58 +++++++++++++++++++++++++++++++++++++++++++++-------------
 static/app.js |  3 ++-
 2 files changed, 47 insertions(+), 14 deletions(-)
```

Read what the message does. It names **a failure that really happened**: two browsers could lend the
same projector, and the list showed it twice. It names **the decision**: let the database refuse the
second loan through a partial unique index. It says **why there and not in the code**: the database
refuses even when both requests arrive together, which a check in Python, reading "available" twice,
would not. And it ties the change to the issue that asked for it.

A hiring manager who finds that commit has found the conversation they want to have with you. The
change itself is small, two files. The depth is in what the message says about how you think, and it
cost nothing but writing it down on the day.
