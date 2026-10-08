---
title: Why grade a sample
version: 2
---

A rule costs nothing, so lesson 8 ran it on every reply. A judge is a model call per reply per
criterion, with the reply, the question and every source in its prompt. Running it on everything is
possible, and this lesson does it once, to have the whole week to compare samples against:

```
ana@dev:~/obs$ python grade_sample.py uniform --share 1.0
uniform: 275 of 275 replies graded for relevance in 25.6 min, 0 verdicts unreadable
  2026.09.4    58/134  pass  43.3%   95% between 35.2% and 51.7%
  2026.10.1    48/141  pass  34.0%   95% between 26.7% and 42.2%
```

Over the whole week, **the judge passed 43.3% of the replies for relevance under the old release, and
34.0% under the new one.** Those are low numbers, and part of the reason is the judge rather than the
replies. It failed every one of the 88 refusals, including the ones to questions the documents do not
answer, where a refusal is the right reply: the rubric asks whether a reply addresses the question, and
says nothing about what a refusal does. And it failed replies that are plainly right, such as "shipping
is free on orders over R$ 40" to the question "when is shipping free". Lesson 10 puts numbers on how far
this judge can be trusted. Here the question is what grading costs and how much of it is needed, and
those answers do not depend on the judge being good.

It took **25.6 minutes** of this machine's processor to grade 275 replies on one criterion, about five
and a half seconds each, one at a time. The last section prices it; the short version is that each
judgement cost more than the reply it judged.

So the question becomes: **how few replies can be graded and still give a number worth having?** Two
things decide it. Which replies are chosen decides whether the number is **unbiased**, an estimate of
the week rather than of some corner of it. How many decides how **sure** it is. The next two sections
take them in turn.

There is a third reason to sample that has nothing to do with money. The judge reads what customers
typed. Every reply it grades is one more copy of a conversation sent to one more model, and lesson 2's
rules apply to it: a sample is less text in fewer places.
