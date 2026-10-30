---
title: What this course is, and what it assumes
version: 1
---

**This course is about where data lands on Azure, where it lives, and where it is asked questions**,
and about the bill each of those choices writes. It follows the data of one company, Quitanda, a
grocery delivery service in São Paulo: the files its shop exports every night, the database its
orders live in, the clicks its app sends every second, and the warehouse its analysts query.

It runs in seven parts:

| lessons | what | the question each part answers |
|---|---|---|
| 1 to 7 | storage accounts, Blob Storage, ADLS Gen2 | where a file lives, how long, who can read it, and what reading it costs |
| 8 to 10 | Azure SQL, Managed Instance, flexible servers | what "managed" takes off your hands in a relational database, and what it does not |
| 11 to 15 | Cosmos DB and Azure Cache for Redis | a store designed around its queries, and the cache in front of everything |
| 16 to 18 | Synapse, Fabric, Delta Lake | the warehouse and the lake, and the file layout that sets what a query costs |
| 19 to 21 | Data Factory, data flows, Databricks | the jobs that have to run at three in the morning |
| 22 to 24 | Event Hubs and Stream Analytics | data that never stops arriving, and what "delivered" means |
| 25 to 26 | Purview, and the choice | knowing what you hold, and how to choose the store |

**It assumes two courses.** From `azure-foundations`, the account model: a tenant, subscriptions,
resource groups, regions and zones, Entra ID and role-based access, and the command line itself.
From `sql-databases`, the relational vocabulary: a table, a primary key, an index, a transaction. A
lesson that leans on either says which lesson of which course, and none of them explains a role
assignment or a `JOIN` from the beginning.

## What is practised, and what is read

**Every lesson that can be practised on your computer is**, against the emulators the section after
next describes: Blob Storage, Cosmos DB, Event Hubs, and the database engines themselves. The
analytics services, Synapse, Fabric, Data Factory, Databricks, Stream Analytics and Purview, have no
emulator of any kind, and a course that pretended otherwise would teach you a fake. Those lessons are
taught from Microsoft's documentation and say so at the top. Where the idea underneath runs on a
laptop, a Parquet file, a Delta table, a window over a stream, the lesson runs that part with an open
tool and names the tool.

## The bill, without a bill

**Every lesson that makes a choice prices it**, because on Azure a design and its invoice are the
same decision. A Cosmos DB container partitioned on the wrong field costs many times what it should,
and a lake partitioned by the wrong column is a lake every query reads whole. Cost is the one thing in
this subject that is learnt by feeling it, and this course cannot make you feel it, because nothing in
it ever touches a real subscription.

It does the next best thing, which is to make every sum explicit. The meters, what Azure counts and
charges for, come from Microsoft's documentation. The prices are read by a program you run, shown in
the price-sheet section of this lesson, and the lessons do their arithmetic with round numbers that
say they are illustrative. If you later practise on a real subscription, `azure-foundations` lesson
13 sets a budget with an alert before anything is created, and that order of steps is the most
valuable thing a real account can teach.
