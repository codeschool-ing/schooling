---
title: Keeping the habit
version: 1
---

Nobody decides to stop coding. **It stops one cancelled afternoon at a time**, because every other
demand on an architect's week has a person attached to it and the code does not. This section is
about keeping the habit on purpose: protecting the time, choosing the work, being reviewed like
everybody else, and noticing the signs that the calibration of the first section has drifted.

## Protect the time, or it goes

Renata's two half-days a week did not survive her first month in the role. Every one of them was
the obvious slot for a meeting somebody else needed, and each meeting was more urgent than a fix
nobody was waiting for. By the end of the second month she had written no code at all.

What worked was treating the time as a commitment with a name on it. She blocked Tuesday and
Thursday mornings in her calendar, as "Pairing with Payments" and "Platform tooling", told the
people who book her time what they were for, and moved them rather than deleting them when
something urgent did come up. **Two mornings, about eight hours, are a fifth of a working week**,
and that is enough. The aim is calibration, not output: a fifth of a week kept every week does more than a
whole week once a quarter, because the instrument drifts between readings.

A small company can make it easier still. Some architects at Carreto's size spend one sprint in
four inside a team, as a member with the team's tech lead in charge of their work. Others keep the
weekly half-days and add a week embedded with a team whenever a large change starts. The form
matters less than the regularity.

## Choose work you can finish

The previous section's rule decides what to pick: work that is useful, that nobody waits for, and
that fits two half-days a week. In practice Renata keeps a short list, agreed with the tech leads:

- one **small fix** at a time, from a team's backlog, chosen with that team;
- the **fitness functions and tooling** she owns, which always have something to improve;
- a **spike or a skeleton** when a design of hers is about to be built;
- a standing **pairing slot** that rotates between teams, a few weeks with each.

**Finishing is part of the point.** A change that reaches production goes through the tests, the
review, the pipeline and the monitoring, and each of those is part of what a design costs. A branch
abandoned after three weeks teaches the first half-day and nothing after it.

## Be reviewed like everybody else

An architect's code goes through the team's review, follows the team's standards and can be
rejected. This is easy to say and easy to get wrong in both directions. A team that waves the
architect's pull requests through is not reviewing; an architect who argues every comment from the
authority of the title has turned the review into a test of rank.

Renata's third pull request in Payments was reviewed by Ícaro. He asked her to rename two functions
to match the module's conventions and pointed out that she had added a test with a sleep in it,
which the team had agreed to stop doing a year earlier. Both were right. She fixed them, and said so
in the review thread.

**That exchange did more for the team than her code did.** Ícaro saw that review is about the code
and not the person, and that it applies upwards. The team saw that the conventions they wrote bind
the architect too. And Renata learnt about a team agreement that no document recorded, which is
calibration of another kind: knowing how the team works, not just how the code does.

## The signs of drift

Calibration fails silently, so it helps to know what drift looks like from outside. These are the
signs Renata keeps written at the top of her notes, as questions to ask herself once a month:

- **Can I run the system on my own machine today?** Not in principle — today, from a clean
  checkout. If the local setup has moved on without her, so has the code.
- **Do I know how long the build and the tests take?** If the answer is a number from last year, it
  is probably wrong, and every design priced on it is mispriced.
- **Is my estimate close to the team's?** A team that consistently says two or three times what the
  architect says is either padding or calibrated. Lesson 14 showed how to find out which: ask what
  would make it take that long.
- **Are my review comments about design, or only about style?** Comments on naming and formatting
  are what is left when the reviewer no longer understands what the change does to the system.
- **When did I last ship something?** A month is fine. A quarter is a warning. A year is the
  architect of lesson 17 who draws boxes nobody builds.

None of the five needs a metric or a dashboard. They are questions for an honest ten minutes, and
the answer to most of them is "go and change something small this week".

## What changes with seniority, and what does not

As Carreto grows, Renata will code less. An architect working across fifteen teams cannot pair with
each of them in a rotation that comes round before the calibration fades, and the role will lean
further towards the enterprise level of lesson 4. That is expected, and it is not a failure.

What should not change is that the amount stays above zero, and that it stays in the code the
decisions are about. **An architect who codes a little in the real system stays calibrated; one who
codes a lot in side projects does not.** A weekend project in a new language is good for the
architect's curiosity, and it says nothing about how long the Payments test suite takes this month.

The habit also outlasts the role. The engineers who learn from an architect who pairs, takes review
comments and fixes small bugs are learning that seniority does not mean leaving the code, and some
of them will be architects themselves. Lesson 16 draws the boundaries between the architect, the
tech lead and the senior engineer. This lesson's argument is that keeping a hand in the code is one
of the things all three have in common.
