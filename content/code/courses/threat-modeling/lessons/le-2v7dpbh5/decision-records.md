---
title: Decision records
version: 1
---

The format for writing decisions down that software teams already use is the **architecture
decision record (ADR)**: a short file per decision, with its context, the decision, and its
consequences, kept in the repository and never edited after the fact. A new decision that changes
an old one is a new record that says which one it replaces. The `architecture-modeling` course
(lesson 5) teaches ADRs for design decisions; security decisions fit the same shape with three
additions.

| an ADR has | a security decision record adds |
|---|---|
| a title and an id | the threat or risk it decides, by id |
| the context | the estimate, and the decision: mitigate, eliminate, transfer or accept |
| the decision | the owner, by name |
| the consequences | a review date, and the triggers that bring it forward |

Vereda keeps two kinds, with two prefixes so they can be told apart in a list: **RA** for a risk
acceptance, **DR** for any other decision. The prefix is for people reading the folder; nothing in
the program that reads them depends on it.

### Front matter for the machine, prose for people

Each record starts with a few lines of **front matter**, the fields a program needs, between two
lines of `---`. The rest is prose for whoever reads it next:

```
---
id: RA-001
threat: T14
decision: accept
owner: daniel
decided: 2026-10-01
review by: 2027-04-01
---
```

The front matter makes the register queryable: a program can list every acceptance, every
decision by daniel, every review due this month, without anybody keeping a separate list in step.
The prose is what makes the decision understandable in a year, by somebody who was not in the room.

### Never edited, only superseded

A decision record describes what was decided on a date, with what was known then. **Editing it
later rewrites history**: the record no longer says what daniel signed. So a changed decision is a
new record, with a line saying *supersedes RA-001*, and the old one stays. The one field allowed to
change in place is a status, if the team keeps one, because it describes the present rather than
the decision.

git makes this cheap to check: `git log` on a decision file shows whether it was edited after it was
first committed, and by whom.
