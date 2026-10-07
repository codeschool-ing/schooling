---
title: Presenting a diagnosis the client owns
version: 1
---

**A diagnosis is handed over so that the people who own the problem can decide what to do about
it; the consultant recommends, and the owner chooses.** Lívia can be right about the logistics
team's releases and still fail, if the way she presents it leaves Henrique defending his team
instead of deciding.

## The written note

Lívia's note on 29 May followed lesson 2's shape for a proposal, at one page:

> **What we asked.** Why do logistics releases break route planning, and what would stop it?
>
> **What we found.** 7 of 23 releases this year were followed by a route-planning incident. In 5 of
> the 7, one service changed a table that the route planner and the zone service both read, and the
> other service broke. The table has no named owner, and the two services are first tested together
> in staging, after merging. None of the 7 incidents involved a timeout between the services.
>
> **What this means.** A message broker would not have prevented any of the 7. Clear ownership of
> the shared data, and testing the two services together before merging, would have prevented at
> least 5.
>
> **Options**, for the team to choose from:
> 1. Name an owner for the shared table, and require that owner's review on any change to it. Days,
>    not weeks. Prevents most schema breaks; does not remove the coupling.
> 2. Option 1, plus a contract test run on every pull request that checks both services against the
>    table's current shape. About two weeks. Finds the break before merge.
> 3. Give each service its own data, kept in step by events, which is the broker idea done for the
>    right reason. About a quarter. Removes the coupling; costs the most, and needs the zone service
>    team's time.
>
> **My recommendation** is option 2 now, and option 3 considered next quarter if the coupling keeps
> costing time. The decision is the team's.

## Why it is written that way

- **Facts first, interpretation second, recommendation last**, and labelled. A reader who disagrees
  with the recommendation can still accept the findings, which keeps the conversation going.
- **No names attached to incidents.** The note does not say whose change broke what. The contract
  said this was not an evaluation, and the pattern was in the system, not in a person: Weinberg's
  law, but about how people work together rather than about who failed.
- **The requested solution is treated fairly.** Option 3 is the broker, for the reason it would
  actually help. Henrique's instinct was not wrong; it was aimed at a symptom. **Saying where the
  client's idea fits is what lets them accept a diagnosis that started somewhere else.**
- **"The decision is the team's"** is not modesty. It is the contract's second line, and the team
  that chooses option 2 is the team that will make it work.

## When the client disagrees

Henrique's first reaction, at the halfway check-in, was "but the zone service team will never agree
to an owner". That was not a rejection of the diagnosis; it was the people problem stating itself.
Lívia did not argue. She asked what would make the zone service team agree, and Henrique said "if
the question didn't come from us". So the request for an owner went to both teams' leads together,
with the incident count attached, from Lívia. Lesson 9 is about the kind of conversation that
follows when two teams disagree over who owns something.

**A consultant who wins the argument with the client has usually lost the engagement.** If the
owner, having heard the diagnosis, chooses differently, the consultant writes down what was
recommended and why, and helps with whatever was chosen. The written note is the record; the
relationship is what gets the next call.
