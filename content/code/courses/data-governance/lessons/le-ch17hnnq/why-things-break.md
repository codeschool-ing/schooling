---
title: Why data breaks between teams
version: 1
---

Inside one team, a change to a table is a conversation: the person who renames a column knows who
reads it, or can ask across the desk. Between teams — and between companies — nobody knows. The
analytics team reads the orders table; the finance team reads the analytics team's view; a partner
receives a file built from the finance team's report. Each step was built against what the step
before it looked like **on one particular day**.

Then something changes upstream, for a good reason, and one of three things happens downstream:

- **it fails loudly** — a column is gone, a query errors. This is the good case;
- **it carries on, wrong** — a column keeps its name and changes its meaning: a price that was in
  reais is now in centavos, a count of lines becomes a count of units. Every chart still renders;
- **it carries on, leaking** — a column is added to a shared view, and data nobody agreed to send
  starts leaving the company every morning.

The second and third are the ones that matter, and they have the same cause: **nobody wrote down what
was promised, so nothing could notice the promise had been broken.**

## Interoperability is an agreement

*Interoperability* is the ability of two systems to exchange data and use it correctly. The first half
is formats and protocols, and it is mostly solved: CSV, JSON, Parquet, HTTP. The second half —
**correctly** — is about meaning, and no format carries it on its own. `2026-06-30` is unambiguous; a
column called `items` is not.

A **data contract** is the written agreement between the team that produces a dataset and the teams
that consume it: what it contains, what each field means, how good and how fresh it will be, who owns
it, and what the consumer may do with it. This lesson writes one for a dataset Ipê sends to another
company, checks it automatically, and breaks it twice to see the check work.
