---
title: Writing the decision down
version: 1
---

**A decision nobody wrote down gets made again, by somebody who does not know why it was made the
first time.** A year after Roda Livre chooses where its tables live, a new engineer will look at the
choice and see only its costs, because the reasons were in a meeting. Either they undo it and
rediscover the reasons the hard way, or they leave it alone and nobody can tell whether it still
makes sense.

The cure is short. Michael Nygard proposed it in a 2011 post, *Documenting Architecture Decisions*:
an **architecture decision record**, or ADR, a page of text for each significant decision, kept in the
same repository as the code it affects. Here is the one Davi and Ana wrote after the matrix:

```localised
# 3. Analytical tables live in a PostgreSQL server we run

Status: accepted, 8 October 2025
Decided by: Davi, Ana. Consulted: Marta, Caio.

## Context
Marta needs station counts before the 09:30 and 16:00 van runs, from data
at most two hours old. A year of dock readings is under 4 GB.
The team is two people. Davi has run PostgreSQL for six years; nobody here
has run a managed warehouse.
Scored with weights for a team of two: PostgreSQL we run 36, managed
warehouse 35, Parquet in storage 33. With weights for a year of growth the
managed warehouse wins, 39 to 31.

## Decision
Keep the analytical tables in a PostgreSQL server we run, separate from
the app's database. Keep the raw files as Parquet, so the tables can be
rebuilt elsewhere.

## Consequences
Good: it uses what the team knows, and there is no charge per query.
Bad: about ten hours a month of upkeep, and Davi is on call for it.
Bad: room to grow scored lowest; a second city would test it.

Revisit when a second city signs, when a query Marta needs takes more
than a minute, or when upkeep passes twenty hours in a month.
```

## The parts, and why each is there

- **A number and a title that states the decision.** "Analytical tables live in a PostgreSQL server
  we run" is findable and says the outcome; "Database discussion" is neither.
- **A status.** Proposed, accepted, or superseded. An ADR is not edited once it is accepted. When the
  decision changes, a new record says so and the old one is marked *superseded by 9*, so the history
  of the reasoning survives.
- **The context**: the facts that were true when the decision was made. This is the part that ages,
  and it is why the record is worth keeping. A reader in 2027 can see that the team was two people
  and the data was 4 GB, and judge whether that is still the case.
- **The decision**, in one or two sentences, in the active voice.
- **The consequences, bad ones included.** A record that lists only advantages is a sales pitch, and
  the next engineer will distrust all of it. Writing down that Davi is on call is what makes the cost
  visible to the person who will one day pay it.

The last line is not in Nygard's original, and it is the most useful habit to add: **the conditions
that would reopen the decision**. It turns "revisit some day" into something a person can check. Two
of the three conditions are measurements, which makes it the same kind of promise as an SLO: when the
query passes a minute, the question comes back by itself.

The record took twenty minutes to write. `architecture` and `tech-strategy` go further into keeping
decisions alive across a larger team; for two people, a numbered file per decision in the pipeline's
repository is enough.
