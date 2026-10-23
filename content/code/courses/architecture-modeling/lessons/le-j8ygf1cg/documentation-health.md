---
title: How healthy is the documentation?
version: 1
---

**Individual owners keep individual pages alive; nobody sees the whole set unless somebody measures
it.** A handful of numbers, collected by a script from the repository, tell an architect where the
documentation is dying before readers stop trusting it.

## Five measures

| measure | how it is collected | Carcará, before | after one quarter |
| --- | --- | --- | --- |
| **pages with an owner** | a front-matter field on each page | 38% | 100% |
| **pages verified in the last 12 months** | a *last verified* date in the front matter | 22% (31 of 140) | 89% (57 of 64) |
| **broken internal links** | a link checker in CI | 47 | 0, and the check now fails the build |
| **significant requirements with a verification** | lesson 6's matrix, read by a script | 2 of 5 | 5 of 5 |
| **diagrams that show a retired element** | a list of retired names, searched for in diagram sources | 3 | 0 |

Two things in the table are worth noticing. First, **the number of pages fell from 140 to 64**: most
of the improvement came from deleting, which the last section of this lesson is about. Second, the
*verified* date is not the *edited* date. A page can be correct for years without an edit; what the
date records is that its owner **read it and confirmed it is still true**. That is the cheap act that
keeps trust, and it costs a minute.

## Review cadence follows volatility

Not every page needs the same rhythm. Carcará set three:

- **every quarter**: deployment and container views, the on-call map, anything about infrastructure,
  which changes fastest;
- **every year**: the arc42 introduction, cross-cutting concepts, the glossary, the quality goals;
- **never**: decision records and postmortems, which are records of a moment and are not updated, as
  lesson 5 and `architecture-role` lesson 8 both insist.

A small script lists the pages whose *verified* date is older than their cadence and opens a ticket
for each owner. The point is not the script; it is that **the reminder comes from a schedule, not
from somebody remembering**.

## What the numbers do not tell you

A page can be owned, recently verified and still useless, because nobody needs it or because it
answers a question nobody asks. The numbers find decay; they do not find irrelevance. For that, the
best signal is the one lesson 1 started with: **ask a reader to use the page and watch where they
get stuck**. Carcará does it once a year, with whoever joined most recently.
