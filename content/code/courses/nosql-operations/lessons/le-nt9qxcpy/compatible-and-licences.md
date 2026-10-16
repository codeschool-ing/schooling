---
title: Compatible is not the same engine, and the licence is part of the product
version: 1
---

Two facts about a managed offer are easy to miss on its pricing page. **"Compatible with MongoDB"
or "compatible with Cassandra" describes a protocol, not a database**, and the licence of the
software underneath decides who is allowed to sell it as a service at all. The licence history of
two of this course's three products changed in the last decade for exactly that reason.

## A protocol in front of another engine

Amazon DocumentDB accepts MongoDB drivers and answers MongoDB commands. Azure Cosmos DB offers an
API for MongoDB and one for Apache Cassandra. Amazon Keyspaces accepts Cassandra drivers and CQL.
**None of the three runs the software this course ran.** Each is the provider's own storage engine
with a translation layer in front, built to look like the original from the client's side.

That is a legitimate design, and it has a consequence you plan for: the translation covers most of
the language and not all of it. Each of these services publishes a page of **supported and
unsupported operators, commands and features**, and that page is the documentation to read before
anything else. An aggregation stage the translation lacks, an index type it does not build, a
consistency level it does not offer, a server-side setting that has no equivalent: each one is
found either in that list before the migration, or in production after it. The behaviour under
load also differs, because the engine underneath is different; what lessons 16 to 19 said about
compaction and tombstones describes Cassandra, and a Cassandra-compatible service may have neither
in the same form.

The services run by each product's maker, MongoDB Atlas, Redis Cloud and DataStax Astra DB, are
built on the product itself, which is the strongest argument for them when compatibility matters.

## The licences, as facts

| product | licence history |
|---|---|
| MongoDB | moved from the AGPLv3 to its own **Server Side Public License (SSPL)** in October 2018. The SSPL requires anyone offering the software as a service to publish the source of the whole service around it; the Open Source Initiative does not approve it as an open-source licence |
| Redis | BSD-licensed until 2024. With **Redis 7.4**, in 2024, it moved to a dual licence: the Redis Source Available License v2 (RSALv2) or the SSPLv1. With **Redis 8**, in 2025, the AGPLv3 was added as a third option |
| Valkey | a **fork of Redis 7.2.4**, the last BSD-licensed release, started in 2024 under the Linux Foundation and still under the BSD licence. Several cloud providers' Redis services now offer Valkey |
| Cassandra | the **Apache License 2.0**, as a project of the Apache Software Foundation, unchanged |

The images this course runs carry some of that themselves. MongoDB's package says it in its
copyright file, and Cassandra ships the licence text beside its binaries:

```
ana@vm:~$ docker run --rm mongo:8.0 mongod --version | head -1
db version v8.0.32
ana@vm:~$ docker run --rm mongo:8.0 grep -A2 "^License" /usr/share/doc/mongodb-org-server/copyright
License:

    SSPL
ana@vm:~$ docker run --rm cassandra:5.0 head -3 /opt/cassandra/LICENSE.txt

                                 Apache License
                           Version 2.0, January 2004
```

Redis is the one the lab cannot confirm:

```
ana@vm:~$ docker run --rm redis:7.4 redis-server --version
Redis server v=7.4.11 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=f20da322597b16d7
ana@vm:~$ docker run --rm redis:7.4 find / -xdev \( -iname "*licen*" -o -iname "copying*" \) -not -path "/usr/share/*"
```

The search found **no licence file at all** in the `redis:7.4` image outside the operating
system's own. The version is 7.4.11, which by Redis's own announcement falls under the RSALv2/SSPLv1
dual licence; that statement rests on the announcement, not on anything the image carries.

## What it means for you

**Running any of these for your own application is allowed under every licence above.** The SSPL
and the RSALv2 restrict offering the database itself as a service to others; a shop that stores its
orders in MongoDB or its sessions in Redis is not doing that. Where it matters is in the choice of
provider and of the future: a cloud provider that cannot sell the newest Redis sells Valkey, or an
older Redis, or a compatible engine, and the feature you want next year may exist on one side of
that line only. Which version, under which licence, from whom, is a line in the decision record of
lesson 22, and it is legal advice only when a lawyer writes it.
