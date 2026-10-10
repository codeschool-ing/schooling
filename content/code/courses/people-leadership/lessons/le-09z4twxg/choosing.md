---
title: How Caju chose, and why the choice follows the job
version: 1
---

The right format is the one whose incidental measurements matter least for this job and whose real
measurements matter most. **That means starting from the job, not from the format the company has
always used**, which is how most technical interviews are chosen.

## What Agenda's E2 role needed

The second must from lesson 14 was: writes tests as a matter of course. Underneath it was the work in
the first-six-months paragraph: owning the reminder service, fixing time-zone bugs, building
confirmations with two other engineers. Renata listed what the technical interview needed to show:

- how the person approaches an unfamiliar codebase;
- whether they write tests without being asked;
- how they talk through a decision with a colleague.

Live coding showed none of these well. A take-home showed the second, and the first if the exercise
came with existing code, and not the third. Pairing showed all three, at the cost of measuring comfort
with observation.

## What Caju does

Caju's technical interview for this role is a ninety-minute pairing session on a small, prepared copy
of a service shaped like the reminder service, with a bug in it and a feature to add. Yara runs it.
The candidate gets the repository and a one-page description two days before, and is told they may
read it, run it, and look anything up, before and during.

Three details make it work:

1. **Real tools.** The candidate uses their own editor, or the one Caju offers, with the internet
   available. Nobody at Caju writes code without documentation, so the interview does not either.
2. **The problem is told in advance.** This removes most of the cold-start pressure that live coding
   measures, and it means the session measures how they work, not how fast they recover from surprise.
3. **Yara pairs, she does not watch.** She is briefed to answer every question, to suggest when the
   candidate is stuck for more than a few minutes, and to score on the rubric afterwards, not during.

The rubric, written the way lesson 15 described, has three rows: approach to the existing code,
testing, and collaboration. "Fixed the bug" is not one of them, because a candidate who fixes it
silently and without a test shows less of what the job needs than one who talks through the cause,
writes a failing test first and runs out of time before the fix.

## Why not a take-home as well

Some companies use both, and Renata considered it. She decided against it for this role because the
pairing session already showed what a take-home would add, and a take-home would have added hours of
unpaid work for every candidate at that stage, fifteen of them in lesson 14's funnel. **Each extra
stage has to earn its cost to candidates, not only to the company.**

For a different role, the answer might be different. A role where the person will mostly work alone
on long problems might be better served by a short, paid take-home and a conversation about it. The
point is that the format follows the job.

## Your task

For a role you know, list the three things the technical interview most needs to show, the way Renata
did. Then, for each of the three formats, mark which of the three things it shows and what incidental
thing it also measures. Choose a format, and write one sentence on why its incidental measurement
matters least for that role.
