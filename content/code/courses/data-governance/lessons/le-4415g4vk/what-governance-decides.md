---
title: What governance decides
version: 1
---

Eight lessons in, this course has built access rules, encryption, keys, pseudonyms, a
classification, a consent log, a request log, an inventory of AI systems. Each was somebody's
decision. **Data governance is the arrangement that says who makes those decisions, how, and how
anyone can tell they were made.** It is not a tool and not a department. It is the answer to "who
decided this, and where is it written?"

The usual reference is DAMA's *Data Management Body of Knowledge* (DMBOK), which places governance at
the centre of ten other areas — quality, metadata, security, architecture, and so on — and defines it
as the exercise of authority and control over the management of data. The useful distinction it
draws is between **governance**, which decides, and **management**, which carries the decisions out.
Choosing that CPFs are kept only as ciphertext was governance; lesson 5's `ALTER TABLE` was
management.

## Three questions this lesson answers with tables

- **Who answers for this data?** An owner per table, and a steward who looks after it. Section 3.
- **Is the data any good?** Measured, with rules that run and a history of every run. Sections 4 to 8.
- **What does it mean, and where did it come from?** Metadata kept beside the data, and lineage read
  from the database's own record. Sections 9 and 10.

The pattern is the same one the course has used since lesson 2: **a decision that lives in a table can
be queried, tested and audited; a decision that lives in a wiki page can only be believed.** Every
answer below ends up as rows somebody can `SELECT`.

## What it is not

Governance is not approval for everything. A programme where every new column waits three weeks for a
committee teaches people to keep data where the committee cannot see it — a spreadsheet, a private
bucket — and that data is worse governed than before. The aim is the opposite: decide the rules once,
make them checks that run on their own, and spend people's time on the cases the checks cannot
settle. Lesson 6's classification is the model: one row per column, written by whoever adds the
column, and a query that fails the deploy if nobody wrote it.
