---
title: What people are for
version: 1
---

Lesson 9 ended with a judge that passed a reply about express delivery to a customer who had asked
about standard delivery. Nothing measured so far can say whether that was a rare slip or the judge's
habit. Only a person reading the same replies can, and that is the job people do in an evaluation:
**not grading the traffic, but setting the standard the judge is measured against.**

The arithmetic decides it. A judge call costs a fraction of a cent and needs nobody; a person has
to read the question, the reply and every source before deciding, and that time comes out of somebody's
working day. People cannot grade a week. They can grade sixty replies carefully, and those sixty say how far
the judge that grades the week can be trusted.

Three things come out of a round of human labelling, and each is used later in the course:

- **A measure of the judge.** How often judge-1 agrees with people, and on which kinds of reply it
  does not. That is the last section of this lesson.
- **Reference labels.** Replies with an agreed verdict, kept by id, that every later version of the
  judge, of the prompt or of the model is checked against. Lesson 13 builds an evaluation set from
  them.
- **A better rubric.** People who disagree have found a question the rubric did not answer. Writing
  the answer down is the most useful thing a labelling round produces, and the next sections show it
  happening.

## Which replies people read

Lesson 9's three samples apply, with the numbers changed. A **uniform** sample when the labels will
measure the judge, so the measure is of the judge on ordinary traffic. A **targeted** sample, thumbs
down and refusals, when the point is to find failures to fix. Never the two mixed in one score.

This lesson uses neither, for a reason that matters more than the method. The people label the
**evaluation set's replies**: the thirty questions of lesson 8, answered once by each release, sixty
replies in all. A question in the set has an id that does not change, so a label written today still
names the same reply after the prompt, the model or the judge has changed. A label on a trace from
last Tuesday names a conversation that will never happen again.

The labels in this lesson, and the two people who wrote them, are written by the course. Ana is the
developer from every lesson so far; Bruno works on the shop's support team. What they disagree about
is chosen to show what two careful readers of a vague rubric do, and the numbers that follow are
computed from their labels exactly as they would be from real ones.

## What the people see

A person grading a reply sees what the judge sees: the question, the reply and the sources. The
platforms in lesson 6 call this an **annotation queue**: Langfuse and LangSmith both keep a list of
traces for people to grade, with the verdicts stored as scores on the trace. The same rules from
lesson 2 apply to the people as to the judge. They read what a customer typed, so they read it
redacted, and only as much of it as the grading needs.
