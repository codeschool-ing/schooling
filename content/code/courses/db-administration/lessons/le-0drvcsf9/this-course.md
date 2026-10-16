---
title: What the twenty-four lessons cover, and what they leave to others
version: 1
---

The course follows the order somebody learns the job in, and the lessons are narrow on purpose: each
one is a single task on a real server. Read in sequence they are close to a runbook.

| lessons | what you do |
|---|---|
| 1 and 2 | understand the job and the four engines you will meet; nothing to type |
| 3 and 4 | build your own server, load the course's database and find its files |
| 5 to 10 | configure it: the configuration file, memory, the write-ahead log, checkpoints, the disk, connections |
| 11 to 13 | decide who can do what: roles, grants and default privileges |
| 14 to 19 | keep it healthy: autovacuum, bloat, statistics, reindexing, extensions and logging |
| 20 to 23 | change it safely: upgrades, moving between engines, changing a live table, configuration as code |
| 24 | write down what you did |

**From lesson 3 on, everything is done on a server you own**: a virtual machine running Ubuntu and
PostgreSQL 16, built in that lesson. The platform does not provide one, and the course never needs
anything you did not install yourself. You will need a computer that can run a virtual machine with
4 GB of memory, and lesson 3 says what to do if yours cannot.

## What this course assumes

`sql-databases`, for SQL itself — tables, joins, transactions and what an index is — and
`linux-terminal`, for the shell: files and permissions, `sudo`, services and `systemd`, packages
with `apt`. Both are needed, and this course does not teach either again.

## What it leaves to the courses after it

Three courses build on this one, and each owns a subject this course only names:

- **`db-performance`** owns making queries fast: reading execution plans in detail, the kinds of
  index, locks and who is blocking whom, isolation under real load, connection pooling and
  partitioning. When a lesson here meets one of those, it points at the lesson there.
- **`db-reliability`** owns surviving failure: backups and restores, archiving the write-ahead log,
  point-in-time recovery, replication, failover and incidents.
- **`nosql-operations`** takes the same operational questions to MongoDB, Redis and Cassandra.

Everything the three of them stand on — where the files are, what a setting does, what vacuum and
the statistics are for, who may connect — is here.
