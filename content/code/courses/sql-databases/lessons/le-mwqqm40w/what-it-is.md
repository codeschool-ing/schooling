---
title: The shape of it, and the words it uses
version: 1
---

Oracle's vocabulary is older than most of the industry's and it does not line up with the words
this course has been using. Two of the mismatches cause real confusion, and both are worth getting
straight before anything else.

## An instance is not a database

In PostgreSQL or MySQL, "the database" is loosely both the running server and the files it keeps.
Oracle separates them, and the separation is load-bearing.

**The database** is the files on disk: the data, the control files, the redo logs. It holds
everything and runs nothing.

**The instance** is the running program: a block of shared memory and a set of background
processes. It holds no data and is what starts and stops.

An instance opens a database. Normally one instance opens one database; with Real Application
Clusters, several instances on several machines open **the same** database at once, which is
Oracle's clustering story and one of the separately-priced options in the next section.

## A database contains databases

Since 21c the separation goes one level further and is no longer optional. A **container
database** holds a root — the engine's own tables, shared — and some number of **pluggable
databases**, each of which is what a PostgreSQL user would call a database. A pluggable database
can be unplugged from one container and plugged into another as a unit.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"Two boxes side by side. On the left, a box labelled the instance, memory and processes, containing one box for the shared memory and one for the background processes, with a note that it starts and stops, holds no data, and that one instance serves the whole container. An arrow marked opens points from it to the right-hand box, labelled the container database, files on disk. Inside that box a wide strip across the top is the root, holding the engine's own tables shared by all, and below it three equal boxes named payroll, billing and claims, each labelled a pluggable database. A note says each one plugs out and into another container whole, and a second note says one licence pays for the machine under all of this, not for a database on it.\"><text x=\"14\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the INSTANCE: memory and processes</text>\n<rect x=\"14\" y=\"40\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect>\n<rect x=\"32\" y=\"60\" width=\"184\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"124\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the shared memory</text>\n<rect x=\"32\" y=\"120\" width=\"184\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"124\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the background processes</text>\n<text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">starts and stops. Holds no data.</text>\n<text x=\"14\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">One serves the whole container.</text>\n<path d=\"M234 115 L296 115\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M286 109 L296 115 L286 121\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"265\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">opens</text>\n<text x=\"306\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the CONTAINER DATABASE: files on disk</text>\n<rect x=\"306\" y=\"40\" width=\"400\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n<rect x=\"322\" y=\"60\" width=\"368\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"506\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the root: the engine's own tables, shared by all</text>\n<rect x=\"322\" y=\"116\" width=\"116\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"380\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payroll</text>\n<text x=\"380\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a pluggable db</text>\n<rect x=\"448\" y=\"116\" width=\"116\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"506\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">billing</text>\n<text x=\"506\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a pluggable db</text>\n<rect x=\"574\" y=\"116\" width=\"116\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"632\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">claims</text>\n<text x=\"632\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a pluggable db</text>\n<text x=\"506\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each one plugs out and into another container whole</text>\n<text x=\"306\" y=\"254\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">One licence pays for the machine under all of this, not for a database on it.</text></svg>", "caption": "Oracle's two words for what other engines call one thing. The instance is the running program; the database is what is on disk; and since 21c a database is a container with pluggable databases inside it."}
```

The reason this matters to somebody who will never administer one is in the second note on that
drawing: **the licence is bought for the machine, not for the database on it.** Three applications
in three pluggable databases in one container is a very different cost from the same three on
three servers. That is a licensing decision wearing an architecture diagram, and the next section
is about how often that happens here.

## What a schema is

In Oracle, **a schema is a user.** Creating the user `PAYROLL` creates the schema `PAYROLL`, and
its tables are `PAYROLL.EMPLOYEES`. There is no separate `CREATE SCHEMA` step that means anything
different, and there is no per-database namespace below that level as there is in PostgreSQL,
where one database holds many schemas and a schema is not a login.

The practical consequence is that **connecting as a user puts you in a namespace**, and the same
table name means different tables to different users. Synonyms exist to paper over this —
`CREATE SYNONYM employees FOR payroll.employees` — and a corporate schema usually has a lot of
them.

## The editions, which is where the cost starts

| edition | what it is |
|---|---|
| Express Edition (XE) | free, including in production, and capped: Oracle publishes limits on user data, memory and CPU threads that put it firmly in the learning-and-small-application range |
| Standard Edition 2 (SE2) | a real edition with a hard limit on the size of the server, and without most of the separately-priced options |
| Enterprise Edition (EE) | everything, licensed per processor, with the options priced on top |

Almost every corporate Oracle system is Enterprise Edition. XE exists and is genuinely free, which
makes it the right thing to install if you want to try any of this — and it is not what the
organisation is running.

## A word about versions

The release names have changed direction more than once: 8i and 9i for *internet*, 10g and 11g for
*grid*, 12c through 19c for *cloud*, and the current line is 23ai. **19c is the one to expect in
the field**, because it is the long-term support release of the 12c line and an enormous number of
systems standardised on it.

That matters for a reason lesson 12 already made: a feature's availability depends on the version
in front of you, and advice found online about Oracle spans twenty-five years of releases without
always saying which.
