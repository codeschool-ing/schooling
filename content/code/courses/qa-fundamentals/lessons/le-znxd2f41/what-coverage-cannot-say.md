---
title: What coverage cannot say
version: 1
---

**A coverage report is one of the most useful things a tester can read, and one of the most misread.**
It answers one question with great precision: *which parts of the code did these tests make run?* It is
routinely taken as an answer to another one: *is this code tested?* The previous two sections showed why
those differ. This one names the three things coverage cannot see, so you can say them when somebody
points at a percentage.

## 1. Whether the answer was right

A line runs whether or not the test checks its result. `cases.py` compares every result with an
expected price, so a wrong answer would print `FAIL`. Remove that comparison and print only the results,
and the report for `tickets.py` would be identical: the same lines run, the same 87%. **Coverage measures
execution, not checking.** A test suite that runs every line and checks nothing scores perfectly.

This is not hypothetical. Teams that are judged by a coverage number learn, quickly and often without
meaning to, to write tests that run code and assert little, because those are the cheapest way to move
the number. Lesson 22 is about that pattern in general.

## 2. Whether the right inputs were chosen

The sixty-one-year-old ran the line `half = True` after `if age > 60`, and coverage rose. Sixty would
have skipped it: for sixty the decision is false, the reduction is never given, and the test would have
failed. **Coverage counts that a line ran, not with which values.** Sixty-one satisfied it, and it had
no reason to ask for sixty; the whole defect is the difference between them.

Choosing values at the edges of a decision is a black-box habit, from lesson 6. White box tells you
which decisions exist; the values that test them well come from the rule.

## 3. Whether code is missing

The report describes the lines in the file. It has nothing to say about lines that should be in the file
and are not:

- no line checks that a time is written with two digits, so the 9:30 defect has no line to be uncovered;
- no line refuses a negative age, so `-5` is charged as a child and no report shows a gap;
- no line caps reductions at half, so the stacking defect lives in the absence of a line.

**Missing code is invisible to every coverage criterion**, from statements to paths, because all of them
measure the structure that exists. Defects of omission are found from the requirement, from the
questions the requirement leaves open, and from inputs nobody mentioned, which is to say from the
outside.

## What a coverage report is good for

Read the other way round, coverage is excellent: **a line that never ran is a line nobody tested**, with
certainty. That direction never lies. The `>>>>>>` beside `age > 60` was a true and useful finding, and it
cost nothing to get. Use coverage to find what has not been tested, never to prove what has.

The tools that measure coverage in a real project, how to run them on every change and how to read their
branch reports, are `testing-cicd` lesson 4. What this lesson gives you is the reading: a high
percentage is the absence of one kind of gap, and says nothing about the others.
