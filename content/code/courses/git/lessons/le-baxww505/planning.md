---
title: Sprint planning
version: 1
---

**Sprint planning** opens every sprint. It takes a refined backlog in and sends two things out: a sprint
goal, and the sprint backlog, the tickets the team agrees it can finish. For a two-week sprint it usually
takes an hour or two.

## What it needs before it starts

- **A refined backlog.** Planning is not refinement. If the top tickets have no acceptance criteria, the
  meeting turns into lesson 16's questions asked under time pressure, and #35 happens again.
- **The team's recent velocity**, from lesson 16: roughly how much it has finished in recent sprints.
- **Capacity**: who is actually here. Holidays, a training day, somebody on support.

## Fitting the work to the people

The bakery's team finishes about 30 points in a normal sprint. This one is not normal:

| | days available of 10 |
|---|---|
| Ana | 10 |
| Bruno | 10 |
| Carla | 7, a three-day course |
| Diego | 8, two days on support |

That is 35 days out of 40, so about 26 points, and the team plans **about 22**. The gap is on purpose. A plan
filled to the last point breaks the first time something takes longer than estimated, and something always
does: a bug in production, a review that takes a day, a ticket that turns out not to be ready. Slack is what
lets the sprint goal survive a normal week.

## How it goes

1. **The product owner proposes the goal**: *customers can pay by Pix when they order ahead*.
2. **The team pulls tickets from the top** of the backlog that serve the goal, until capacity is reached.
   The developers decide how much fits, not the product owner and not a manager.
3. **Anything unclear is sent back**, not guessed at. A ticket that cannot be explained in planning cannot be
   started on Monday.

The result goes on the board. From here, the sprint's scope is protected (lesson 15), and the daily is where
the plan meets reality every morning.
