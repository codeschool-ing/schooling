---
title: Why grade a sample
version: 1
---

A rule costs nothing, so lesson 8 ran it on every reply. A judge is a model call per reply per
criterion, with the reply, the question and every source in its prompt. Running it on everything is
possible, and this lesson does it once, to have the truth to compare samples against:

```
ana@lab:~/obs$ python grade_sample.py uniform --share 1.0
uniform: 1221 of 1221 replies graded for relevance
  2026.09.4   604/789  pass  76.6%   95% between 73.5% and 79.4%
  2026.10.1   269/432  pass  62.3%   95% between 57.6% and 66.7%
```

Over the whole week, **judge-1 passed 76.6% of the replies for relevance under the old release, and
62.3% under the new one**. That is the number a team wants, and the intervals beside it are narrow
because nearly eight hundred and four hundred replies went into them.

It took 1,221 judge calls to get it. The last section of this lesson prices them; the short version is
that grading every reply on one criterion costs about a quarter of what serving it cost, and every
criterion adds another quarter. A team that grades everything on three criteria nearly doubles the
bill for its assistant.

So the question becomes: **how few replies can be graded and still give a number worth having?** Two
things decide it. Which replies are chosen decides whether the number is **unbiased**, an estimate of
the week rather than of some corner of it. How many decides how **sure** it is. The next two sections
take them in turn.

There is a third reason to sample that has nothing to do with money. The judge reads what customers
typed. Every reply it grades is one more copy of a conversation sent to one more model, and lesson 2's
rules apply to it: a sample is less text in fewer places.
