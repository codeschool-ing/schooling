---
title: What the assistant does when a limit is reached
version: 1
---

A limit decides when calls stop. **What the client sees when they stop** is a separate decision, and
leaving it undecided is how a budget becomes an error page.

## Refuse clearly, and say what happens next

The looping account in the previous section was refused 567 times. For an integration that is right:
it receives an error with a status that says *budget exhausted*, distinct from a failure, and a time
when the budget resets. A program can stop on that, or at least log it, and a person reading the log
knows what happened. An error that says only "something went wrong" makes the integration retry, and a
retry against a spent budget is the loop again, now costing nothing and fixing nothing.

For a person in the chat the same refusal has to be words: the assistant cannot answer more today, a
person on the team will, and here is how to reach them. **A limit that is reached silently looks like
a broken product**, and the person tries again, which is the one thing that cannot help.

## Degrade before refusing

Between full service and none there are steps, and a budget can choose them:

- **a cheaper model** for the rest of the day, for questions a smaller model answers well enough;
- **a shorter `max_tokens`**, accepting terser replies;
- **the help centre's own page** instead of a generated answer, where the question matches one.

Each is worse than full service and better than nothing, and each is a decision to write down before
the day it is needed, with who may switch it on.

## The alert is for a person, and it says what to do

The alert at 80% in the previous section is only worth sending if somebody receives it and knows what
to look at. It names the ceiling and the time; the useful next line is the account spending fastest,
which `budget.py`'s table already sorts out. Lesson 22 builds the monitoring this belongs in, and
lesson 24 the response when it fires.

## Write the numbers down

Every limit in this lesson is a number somebody chose: 60 tokens, 100,000 a day, R$ 20,00. **None of
them is correct**, and all of them are better than none. What makes them defensible is a note beside
each saying why it is that number, what traffic it was set against, and when it will be looked at
again, so that the next person who raises one knows what they are trading.
