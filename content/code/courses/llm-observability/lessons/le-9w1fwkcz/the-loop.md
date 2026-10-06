---
title: The loop, closed
version: 1
---

Put the course's pieces in the order they would have run on Friday 2 October, if they had been in place:

1. **10:00.** 2026.10.1 goes out. It never passed lesson 15's gate, which would have stopped it on five
   broken cases.
2. **14:00.** The Wilson rule fires: refusals over the last six hours are surely above the baseline. The
   alert names the release and links to the traces of the refused replies.
3. **The traces** show the search keeping fewer chunks: in lesson 1's tree, the search span of a refused
   reply has `app.search.kept` at 0 and `app.search.floor` at 0.62.
4. **The production signals** of lesson 5 say who is affected: order questions most, refused nearly two
   times in three, with the thumbs following.
5. **The harvest** of lesson 13 turns the week's doubted questions into cases, among them the keyword
   phrasings and the order messages the set never had.
6. **The regression test** of lesson 14 compares a fix with production on the set, case by case: the floor
   put back fixes all five broken cases.
7. **The gate** of lesson 15 holds the fix to its budgets, and a person writes down why the cost may
   rise: production was cheap because it refused.
8. **2026.10.3 goes out**, and the panel of this lesson would show the share of refusals falling back to
   the baseline. The alert would resolve because the problem did.

Each step is a lesson, and none of them is optional. Without the alert, the team learns on Monday;
without the traces, it guesses at the cause; without the set, it cannot tell whether the fix fixed
anything; without the gate, the next release does the same thing again.

**And what none of it does** is the subject the course started from: a model's reply is not a stack
trace. A wrong answer delivered confidently looks like success on every panel here. The evaluations of
lessons 8 to 14, and the people of lesson 10 who say what the evaluations are worth, are the only part
of this system that reads what the assistant says. Everything else counts it.
