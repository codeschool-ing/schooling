---
title: What a managed service takes away, and what it leaves
version: 1
---

A managed service is the third way, and it is where many of the servers you will be paid to look
after already live. **Nothing in this section was run for the course**: it describes what the
large providers document, and the details move with their products. The shape does not.

## What you get

You create an **instance** in a web console or with an API call: the major version, the size of
the machine, the size of the disk, a region and a password. A few minutes later you have a
hostname and a port. You connect to it with the same `psql` you have just installed, over the
network and with a password, and from there SQL is SQL.

## What is not yours

**The machine.** There is no shell. You cannot list the data directory, read
`postgresql.conf` or look at the server's processes. Lesson 4 and most of lessons 5, 9 and 19
have no equivalent there.

**The superuser.** The provider keeps it. Your first role has most administrative powers — on
Amazon RDS it is a member of a role called `rds_superuser`, on Azure of `azure_pg_admin` — but
not all of them. Anything that would let you reach the operating system through the database is
refused: reading server files, loading arbitrary libraries, some extensions.

**The configuration file.** It becomes a **parameter group** or a list of server flags in the
console. Some parameters can be changed, some are fixed, and memory settings are often written as
formulas over the size of the machine you chose. A change that needs a restart is applied when
the provider restarts the instance, often in a maintenance window you agreed to in advance.

**The log.** It exists, and you read it through the provider's console or download it. What it
records is still set by the parameters in lesson 19.

## What is still yours

Everything **inside** the database: the roles and their grants, the default privileges, the
schema and how it changes while the application runs, whether autovacuum is keeping up with one
particular table, whether the statistics the planner uses are current. A managed service runs
autovacuum; it does not know that your `events` table receives forty million rows a day and needs
different thresholds. Lessons 11 to 17 and 22 are your job wherever the server lives.

So are the decisions the console only executes: which major version, when to upgrade to the next,
how big the machine has to be. A provider will upgrade your minor version for you. It will not
read the release notes of the next major version and tell you which of your queries will change
plan.

## Why the course does not use one

Because a managed service hides precisely the parts of the server that this course explains. The
best way to understand what a provider's "storage autoscaling" or "point-in-time restore" button
does is to have built the thing it automates, once, on a machine where you could watch it. After
this course a managed service is a set of decisions somebody made for you, and you can read them.
