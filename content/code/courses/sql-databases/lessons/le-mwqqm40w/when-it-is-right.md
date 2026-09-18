---
title: When it is the right answer, and when it is inertia
version: 1
---

This lesson has spent most of its length on what Oracle costs and what is strange about it, so the
last section owes an honest account of the other side. Then the question everybody in a large
organisation eventually asks, which is whether to leave.

## What it is genuinely good at

**It has been doing this for a very long time, at a scale few things have.** The core banking
systems, the national tax systems, the telephone billing that has not stopped since the nineties.
That is not a marketing claim; it is an installed base with a track record, and for a system where
being wrong is a regulatory event, a track record is worth paying for.

**Read consistency without vacuum.** The undo design means a long report never blocks and never
sees a half-finished change, and there is no background process reclaiming dead row versions, which
is a real class of PostgreSQL operational work that does not exist here. `ORA-01555` is the price
of the design, and it is a smaller price than it sounds.

**Real Application Clusters.** Several machines opening one database, with failover between them,
is a shape the other engines in this course do not have. It is expensive and it is complex and for
a small number of systems it is the answer.

**The support contract is a thing you can call.** For an organisation whose risk register has a
line for "the database is down and nobody knows why", a vendor obliged to answer is part of what is
being bought. That is not a technical property and it is a real one.

**And the tooling around it is deep.** Where the packs are licensed, AWR, ASH and the advisors are
better than anything free, and the people who know them are very good at this.

## When it is inertia

**When the reason is that it is already there.** That is a real reason not to migrate this quarter
and it is not a reason to put the *next* system on it.

**When the requirements are ordinary.** A new service with a few hundred gigabytes, a few thousand
transactions a minute and no exotic need is a PostgreSQL service. Putting it on the corporate
Oracle because the licence exists is the licence deciding architecture again, in the direction that
grows the bill.

**When nobody can say which options are licensed.** An organisation that has lost track of that is
carrying a risk it is not measuring, and that is a reason to find out rather than to buy more.

## Migrating off

It is done, often, and it is a project with a budget rather than a weekend. What it costs is not
the tables — data moves — it is everything that grew around them.

| what moves | how hard |
|---|---|
| the schema and the data | tooling exists and this part is largely mechanical |
| ordinary SQL | mostly portable, and lesson 12's list is the diff |
| the dialect | `DUAL`, `ROWNUM`, `NVL`, `SYSDATE`, `(+)` outer joins — mechanical and tedious |
| **the empty string** | every place the application distinguished blank from absent, which Oracle never let it do |
| **PL/SQL packages** | rewritten, in the target's language or in the application. This is the project |
| the operational practice | the backups, the standby, the monitoring and the people, all replaced |

The middle two rows are the honest answer to "how long". A system with a thousand packages is a
system whose business logic has to be rewritten and re-tested, and there is no tool that does that
for you — the translators produce something that runs and nobody will sign for.

**There is an intermediate move that is often the real one:** stop adding to it. New services go on
something else, the Oracle system keeps what it has, and the surface shrinks over years rather than
in a migration. That is less satisfying and it is what usually happens.

## What this lesson leaves you with

Three things, and the first is the one to carry into an interview or a first week.

**The engine is not the subject.** Every lesson of this course applies to Oracle: the model, the
keys, the joins, the aggregates, the transactions, the indexes, the plan. Lesson 12 said the tools
change and the questions do not, and this lesson is the strongest case of it. The most different
engine in the list, and the difference was in the contract, the vocabulary and the operations
rather than in what a correct query is.

**Money is an engineering input here, out loud.** In most of this course the constraints were
technical. On Oracle a per-core licence and a separately-priced diagnostics pack decide where logic
lives, how many environments exist and what anybody is allowed to measure. Being able to read a
decision and see the contract underneath it is most of what makes somebody useful in that
building.

**And the query is still yours.** You will not choose the engine, you will not hold the
credentials, and you may not be allowed to run the report that would tell you which query is slow.
What you write, and whether you send it with bind variables inside a short transaction after
reading its plan, is entirely within your hands — and it is the part that decides most of what the
system does.
