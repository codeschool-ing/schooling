---
title: Choosing, and how rarely you will
version: 1
---

Start with the part nobody says out loud: **most developers never choose a database engine.** You
join a company and it is already there, with ten years of data in it. The useful skill is knowing
what the one in front of you does, rather than which one you would have picked.

So this section has two halves. The choice, for the few times it is yours, and what to do when it
is not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Three questions down the left, each leading right to an answer. One writer and one machine leads to SQLite, with a note to write STRICT on every table. Something pointing at them — the team, the hosting, the application — leads to MySQL or MariaDB, noted as real reasons. Anything else leads to PostgreSQL, noted that having no strong reason for another is the reason. Below, highlighted: not a reason, it is faster, because the gap is smaller than one missing index.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The choice, for the few times it is yours. Read it top to bottom and stop at the first yes.</text><rect x=\"14\" y=\"46\" width=\"346\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one writer, one machine?</text><path d=\"M364 63 L384 63 L384 63 L404 63\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M404 63 L397 59 L397 67 Z\" fill=\"var(--phosphor)\"></path><rect x=\"408\" y=\"46\" width=\"180\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">SQLite</text><text x=\"498\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">and STRICT on every table</text><rect x=\"14\" y=\"108\" width=\"346\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"125\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">something points at them: team, hosting, application?</text><path d=\"M364 125 L384 125 L384 125 L404 125\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M404 125 L397 121 L397 129 Z\" fill=\"var(--phosphor)\"></path><rect x=\"408\" y=\"108\" width=\"180\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"125\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">MySQL / MariaDB</text><text x=\"498\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">these are real reasons</text><rect x=\"14\" y=\"170\" width=\"346\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"187\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">anything else</text><path d=\"M364 187 L384 187 L384 187 L404 187\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M404 187 L397 183 L397 191 Z\" fill=\"var(--phosphor)\"></path><rect x=\"408\" y=\"170\" width=\"180\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"187\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"498\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">no strong reason for another is the reason</text><rect x=\"14\" y=\"232\" width=\"574\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">not a reason: \"it is faster\" — the gap is smaller than one missing index</text><text x=\"14\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Most developers never choose. You join a company and it is already there, with ten years of data in it.</text><text x=\"14\" y=\"302\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The useful skill is knowing what the one in front of you does.</text></svg>", "caption": "Three questions, and most people answer none of them because the engine was chosen years before they arrived."}
```

## When it is yours

**SQLite when there is one writer and one machine.** A desktop or mobile application, a
command-line tool with state, a test suite, an embedded device, a read-heavy site on a single
server, a dataset you ship. Write `STRICT` on every table and keep money in cents. Stop when a
second machine needs to write.

**PostgreSQL when you have no strong reason for anything else.** The strictness sections are the
argument: it refuses the bad insert, refuses the ambiguous `GROUP BY`, keeps decimals exact,
compares text the way you wrote it, and puts DDL inside your transactions. Every one of those is a
class of bug that cannot reach production. It also has the widest set of types — arrays, `jsonb`,
ranges, geometry through PostGIS — and the extension mechanism the others do not have.

**MySQL or MariaDB when something points at them.** The team knows them. The hosting is cheaper or
is the only thing on offer. The application you are deploying — WordPress, a great deal of PHP
software — is written for them. Galera or Group Replication is the shape you need. These are real
reasons and they are the reasons most MySQL systems exist.

**And a reason that is not one:** *"it is faster."* Benchmarks between these engines on ordinary
application workloads are close enough that the difference is smaller than one missing index, and
lesson 9 is where those live. Somebody's benchmark from 2012 is the least useful input to this
decision.

## When it is not yours

Which is most of the time, and the questions are short:

**Which engine and which version.** `SELECT version()` on PostgreSQL, `SELECT VERSION()` on MySQL
and MariaDB, `SELECT sqlite_version()` on SQLite. The version decides whether window functions and
CTEs exist, whether `RETURNING` does, and half the advice you will find online.

**What is `sql_mode`, on MySQL or MariaDB.** Two lines of output that tell you whether the engine
refuses a bad value and an ambiguous `GROUP BY`, or accepts both. This is the single highest-value
question in the list.

**What is the collation.** Whether `UNIQUE` on an address means what you think, and whether a
comparison you are about to write is case-sensitive.

**Whether foreign keys are enforced at all.** They always are on PostgreSQL and MySQL's InnoDB. On
SQLite they are **off by default** — `PRAGMA foreign_keys = ON` per connection, and a database
that has been written to without it may already contain rows that point at nothing.

Four questions, four commands, and they change how you read every table in the schema.

## What carries, whatever the answer

Look back at what this lesson actually found. The differences were real and none of them was about
the subject of this course. The relational model did not move. A join did not move. `GROUP BY`
moved only in how strictly it is policed. Transactions kept their meaning; indexes kept theirs;
the plan kept its.

> **The engine decides what is refused, how text is compared, and how it is operated. It does not
> decide what a correct query is.** Lessons 1 to 11 are the same subject on all four, and on the
> fifth as well.

That is the same point lesson 11 made about ORMs, one layer down. The mapper is not a way to avoid
knowing SQL, and the engine is not a way to avoid knowing the model. **The tools change; the
questions do not.**

There is a fifth engine, and it does not belong in this comparison — not because it lacks the
features, but because what it costs and how it is bought change the shape of the systems built on
it. Lesson 13 is about Oracle and the world it sits in.
