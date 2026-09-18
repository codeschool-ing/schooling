---
title: What the four actually are
version: 1
---

Eleven lessons have gone by with hardly a product name in them. That was not an omission. The
relational model, `SELECT`, the joins, `GROUP BY`, transactions, indexes and the plan are one
subject, and the engine that runs them is a detail for almost all of it.

This lesson is about the rest — the places where the engine stops being a detail. There are four
of them here, and the first thing to get right is what each one **is**, because two of them are
not the kind of thing the other two are.

## PostgreSQL

A database server, developed since 1996 by a distributed group of contributors with no single
company behind it, under a permissive licence of its own. It is the strictest of the four about
what it will accept, the widest in what it can store, and the one with an extension mechanism that
other projects build on — PostGIS for geography, TimescaleDB for time series, `pgvector` for
embeddings are all Postgres with something loaded into it.

The name is said *post-gres-cue-ell*, and the project answers to `postgres` in every command you
type, which is what the rest of this lesson uses.

## MySQL

A database server, released in 1995, bought by Sun in 2008 and with Sun by Oracle in 2010. It is
dual-licensed: GPL for the community edition, and a commercial licence for the rest. It is the
engine behind an enormous amount of the web — WordPress, most shared hosting, a great deal of
what was built between 2000 and 2015 — and that installed base is the main reason you will meet
it.

## MariaDB

The fork of MySQL that the original authors started in 2009, when Oracle acquired Sun. It is GPL,
with no commercial edition of the engine, and for several years it was a drop-in replacement: the
same protocol, the same client, the same SQL. Fifteen years of separate development have moved
the two apart, and the section on the fork is about how far.

## SQLite

**Not a server.** It is a C library that your program links against, and the database is one file
on disk. There is no process to start, no port to connect to, no user to create. It is in the
public domain, it is the most widely deployed database in the world by an enormous margin — every
Android phone, every iPhone, every browser, most desktop applications — and it is the one whose
place in the list is most often misunderstood.

## The shape of the comparison

Three of the four are servers you talk to over a socket; one is a library inside your process. Two
of the servers share an ancestor and most of a dialect; the third does not.

| | PostgreSQL | MySQL | MariaDB | SQLite |
|---|---|---|---|---|
| what it is | server | server | server | library |
| first released | 1996 | 1995 | 2009 | 2000 |
| licence | PostgreSQL licence | GPL + commercial | GPL | public domain |
| stewarded by | no single owner | Oracle | MariaDB Foundation and MariaDB plc | no single owner |
| default storage engine | its own | InnoDB | InnoDB | its own |

Everything from here is what follows from that table. The versions this lesson was written
against are the ones in the transcripts: PostgreSQL 16.13, MySQL 8.0.46, MariaDB 10.11.14 and
SQLite 3.45.1, each running the shop from lesson 1.

There is a fifth engine you will meet in a corporate job, and it is different enough — in what it
costs, in how it is bought, and in what it does to the shape of a system — that it gets lesson 13
to itself.
