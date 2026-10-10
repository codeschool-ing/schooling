---
title: Testing in each event
version: 1
---

**Scrum's events are where the team talks, and each one has a moment where testing knowledge changes
the outcome.** A tester who treats them as meetings to sit through misses most of their value; one who
knows what to bring to each one does a good part of the job there.

## Sprint planning: questions before commitments

Planning is where the team decides what it can finish. It is also the cheapest moment in the whole sprint to
find out that a story is not understood, and the tester's job is to make that happen out loud:

- **ask lesson 2's four questions** of every story: who, doing what, under which conditions, how much is
  enough;
- **ask how it will be tested**, and let the answer change the estimate. "Wednesday half price for students"
  sounds small until somebody notices it changes every price case;
- **name the combinations**, lesson 6's habit: what happens when this story meets the ones already built?

At Cine Aurora's planning for the coupon feature, Lia asked whether a coupon combines with the Wednesday
reduction. Nobody knew. The story was split: coupons alone this sprint, the combination next sprint once
Joana had decided. That one question was worth more than a day of testing.

## Daily scrum: keeping testing visible

Fifteen minutes is short, and testing is easy to leave out of it. The habit worth having is to say what is
waiting to be tested and what testing has found, so that "done coding" does not get reported as "done". When
three stories are waiting for Lia on day seven, the daily scrum is where the team notices the mini-waterfall
forming and does something about it, for instance Rafael testing one of them himself.

## Sprint review: the product meets its users

The review is the event most like lesson 9's acceptance testing, and it happens every sprint. Célia sits in
on Cine Aurora's reviews, and her reactions are information that no test produces: *"at the counter we would
never type the day as three letters"* told the team more about the `Wed` input from lesson 6 than any test
had. In the quadrants of lesson 11, the review is Q3, and a tester can help it be one by preparing a short
tour of what changed and what is still uncertain.

## Retrospective: defects as evidence about the process

The retrospective is where lesson 1's prevention happens in Scrum. Every defect that escaped, or nearly
escaped, during the sprint is evidence about how the team works, and the question is lesson 2's: **why was
this possible?** At Cine Aurora's retrospective after the 9:30 Sunday, the answer was "nobody asked who types
the session times", and the action was a line in the planning checklist: for every new input, ask where it
comes from. Lesson 18 gives the retrospective a method for finding causes rather than culprits.

## Backlog refinement

Not one of the five events, but a practice almost every Scrum team has: an hour or two in each sprint to look
ahead at the stories coming next. For a tester it is the best hour of the sprint, because it is prevention at
its cheapest. A story refined with a tester in the room arrives at planning with its ambiguities already
found.
