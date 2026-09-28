---
title: Writing the cut down
version: 1
---

A cut nobody knows about looks like something you forgot. A cut that is written down looks like a
decision, and decisions are lesson 1's second proof. So every cut goes in two places.

**In the README, for strangers.** loanbook's README has a short section for what is not there yet:

```
ana@laptop:~/loanbook$ sed -n '/^## Not yet/,/^## Licence/p' README.md
## Not yet

E-mail reminders, a screen for adding equipment, and a history of past loans.
Each one waited because the first version was worth showing without it.

## Licence
```

It is two sentences. It tells a reviewer that the absence of reminders is known, and that it was a
choice about the first version rather than a limit of the author.

**Beside the decision, with its cost.** The larger cuts deserve a line in the README's *decisions*
section, lesson 16, and each line has the same shape: *what was decided, and what it costs*. For
accounts: *the borrower is a name typed in; the cost is that anybody who can open the page can lend*.

That second half is the part people leave out, and it is the part that matters. **A decision with no
cost reads as a claim that there was no trade-off**, and every reviewer knows there always is one.
Naming the cost yourself does two things: it shows you saw it, and it takes the question away from
the interviewer, who would otherwise ask it in lesson 20 as if you had not.
