---
title: What this course is, and what it assumes
version: 1
---

**This course is about where data lands on AWS, where it lives, and where it is asked questions**,
and about the bill each of those choices writes. It follows the data of one company, Quitanda, a
grocery delivery service in São Paulo: the files its shop exports every night, the database its
orders live in, the clicks its app sends every second, and the warehouse its analysts query.

It runs in six parts:

| lessons | what | the question each part answers |
|---|---|---|
| 1 to 5 | S3 | where a file lives, how long, who can read it, and what reading it costs |
| 6 to 8 | RDS and Aurora | what "managed" takes off your hands in a relational database, and what it does not |
| 9 to 13 | DynamoDB and ElastiCache | a store designed around its queries, and the cache in front of everything |
| 14 to 19 | Redshift, Athena, Glue, Lake Formation | the warehouse and the lake, and the two decisions that set what a query costs |
| 20 to 23 | Kinesis, Firehose, MSK | data that never stops arriving, and what "delivered" means |
| 24 to 27 | EMR, MWAA, DMS, and the choice | the jobs that run at night, the database you migrate from, and how to choose the store |

**It assumes two courses.** From `aws-foundations`, the account, regions and zones, IAM's principals
and policies, and the command line itself. From `sql-databases`, the relational vocabulary: a table,
a primary key, an index, a transaction. A lesson that leans on either says which lesson of which
course, and none of them explains a policy document or a `JOIN` from the beginning.

## The bill, without a bill

**Every lesson that makes a choice prices it**, because on AWS a design and its invoice are the same
decision. A table designed around the wrong key is a table that costs ten times what it should, and
a lake partitioned by the wrong column is a lake every query reads whole. Cost is the one thing in
this subject that is learnt by feeling it, and this course cannot make you feel it, because nothing in it ever touches a real account. It does the next best thing: every
price is read from AWS's published list by a program you run, and every lesson that quotes one shows
the arithmetic, so that the number is checkable rather than asserted.

The money in this course is therefore always a calculation and never an invoice. That is safer and
honest about what it is, and it is not the same as watching a real total climb overnight. If you
later practise on a real account, the section of `aws-foundations` lesson 1 on a real account sets
a budget with an alert before creating anything, and lesson 13 of that course is about budgets.
That order of steps is the most valuable thing a real account can teach.
