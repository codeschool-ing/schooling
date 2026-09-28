---
title: The evidence, from the history
version: 1
---

A retrospective written from memory is a story; one written from the history is a report. The repository
already holds most of what it needs. First, when each milestone was reached:

```
ana@laptop:~/loanbook$ git log --tags --no-walk --format='%ad %d' --date=short
2026-07-06  (HEAD -> main, tag: v1.0.0)
2026-06-29  (tag: v0.3.0)
2026-06-15  (tag: v0.2.0)
2026-06-05  (tag: v0.1.0)
```

Five weeks, inside the six of lesson 3's filter, and the dates are the plan's own. Then one milestone in detail, the one
with the project's point in it:

```
ana@laptop:~/loanbook$ git log --reverse --format='%ad %s' --date=short v0.1.0..v0.2.0
2026-06-09 Refuse to lend an item that is already out
2026-06-10 Test the loan rules
2026-06-11 Answer every error as JSON
2026-06-12 Say what to do when there is nothing to lend
2026-06-15 Mark a loan overdue the day after it is due
```

Lesson 5's task list estimated the two rules at **three and a half days**: two for the refusal, one and a
half for late loans. The milestone ran from the 9th to the 15th, **five working days**, and the log says
why: two of its five commits, *Answer every error as JSON* and *Say what to do when there is nothing to
lend*, were not in the estimate at all. They were *should* items that turned out to be needed before the
rules could be shown. The estimate for the rules was close; the estimate for the milestone was missing a
third of its work.

Finally, the size of what was built:

```
ana@laptop:~/loanbook$ git rev-list --count HEAD
20
ana@laptop:~/loanbook$ git diff --shortstat $(git rev-list --max-parents=0 HEAD) HEAD
 13 files changed, 473 insertions(+), 3 deletions(-)
ana@laptop:~/loanbook$ wc -l app.py static/app.js test_app.py
  166 app.py
   72 static/app.js
   56 test_app.py
  294 total
```

Twenty commits, under five hundred lines added across thirteen files, of which the program itself is
under three hundred. Numbers like these are worth one line in a retrospective, not more: they give the
reader a sense of scale, and they are true, because they came from the repository rather than from memory.
