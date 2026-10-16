---
title: Where each shape is kept
version: 1
---

**Each shape has a kind of storage built around it, and the kind decides which questions are cheap to
ask.** This section names three, so you recognise them in an architecture diagram. Where another course
goes further it is named as it comes up, and none of the three is taught here.

## A relational database, for structured data

A **relational database** stores tables with declared schemas, and enforces them on every write:
types, required columns, uniqueness, the rule that a ride's `bike_id` names a bicycle that exists.
PostgreSQL and MySQL are the common servers. SQLite is the same idea in a single file, and it comes
inside Python, with one difference worth knowing: unless a table is declared `STRICT`, SQLite stores
a value of the wrong type instead of refusing it. You ask it questions in SQL, and the database works out how to answer them. This is
where Roda Livre's app keeps rides and payments, and it is the subject of `sql-databases`. The
warehouse, the database built for analysis rather than for running the app, is `warehouse-modeling`.

## A document store, for semi-structured data

A **document store** keeps JSON documents, grouped into collections, and does not require that two
documents in a collection have the same fields. MongoDB is the best-known example. It can find
documents by a field deep inside them, such as every ride whose `bike.battery` is below 20, without
anybody having flattened anything first. The price is the one from this lesson: nothing stopped a
document with `"battery": "58%"` from going in, so every query has to cope with it.

The line between the two is not sharp. PostgreSQL has a column type, `jsonb`, that holds a JSON
document inside a row of an ordinary table, so one database can keep a declared table and loose
documents side by side.

## Object storage, for anything at all

**Object storage** keeps files, called objects, under names called keys, and does not look inside
them. A photo, an email, a call recording, a JSON Lines file of a day's events, a Parquet file: to the
store they are all bytes with a name. Amazon S3 is the service that made the idea common, and every
large cloud has its own. It is cheap per gigabyte, it grows without anybody planning a disk, and it
cannot answer any question about what is inside an object. That is the job of whatever reads it.

That combination is why the raw zone from the previous section usually lives in object storage, and
why a **data lake** is mostly object storage with an agreement about where things go. The cloud services
are `cloud`; the formats that make a file in object storage fast to query, by storing it in columns,
are lesson 6.

## One company, all three

| kept in | at Roda Livre | the shape |
|---|---|---|
| a relational database | rides, payments, customers, the station list | structured |
| a document store, or `jsonb` columns | app events kept for the support team to search | semi-structured |
| object storage | raw event files, photos, emails, call recordings | anything, metadata beside it |

Most companies of any size have all three, and the data engineer's job runs between them: from the
objects and the documents into the tables, without losing the originals on the way.
