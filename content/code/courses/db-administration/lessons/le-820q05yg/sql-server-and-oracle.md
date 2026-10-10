---
title: SQL Server and Oracle, from a PostgreSQL administrator's chair
version: 1
---

**Nothing in this section was run for the course.** Both are commercial products with licences
that make them awkward to put on a practice machine, and both exist mostly inside companies that
already run them. What follows is what an administrator who knows PostgreSQL needs to recognise on
the first day in front of one.

## SQL Server

Microsoft's engine, on Windows for most of its life and on Linux since 2017. Its administration
happens mostly in **SQL Server Management Studio**, a graphical tool, and in T-SQL, its dialect of
SQL — and much of what PostgreSQL puts in a text file is a server setting changed with
`sp_configure` or a click.

What maps directly onto this course: the **transaction log** is the write-ahead log, and a log that
grows until the disk is full is SQL Server's version of lesson 7's problem. Its **recovery model**
(`SIMPLE` or `FULL`) decides whether that log is kept for point-in-time restore, the decision
PostgreSQL makes with WAL archiving. **Statistics** go stale exactly as lesson 16 describes, and
**index fragmentation** is the bloat of lesson 15 under another name. The login-and-user split is the
one thing with no PostgreSQL counterpart: a login gets into the instance, and a user in each
database decides what it may touch there.

## Oracle

The oldest of the four as a commercial product, and the one with the largest vocabulary. An Oracle
**instance** is the memory and the processes; the **database** is the files; the two are named
separately because one can exist without the other while the server starts. The memory is the
**SGA**, shared by everything, and the **PGA**, private to each session — the same split lesson 6
draws between shared buffers and work memory.

Oracle keeps **undo** in its own tablespace and reads old row versions from it, where PostgreSQL
keeps old versions in the table itself until vacuum removes them. That single design difference is
why Oracle has no autovacuum and PostgreSQL has lessons 14 and 15, and why Oracle has the
"snapshot too old" error that PostgreSQL does not. Administration is done in **SQL\*Plus** or
**SQL Developer**, and a great deal of it through **RMAN**, Oracle's backup tool.

## What carries over, and what does not

Carries over: the six parts of the first section, the habit of reading the log before anything
else, the logic of privileges and least privilege, the reasons statistics matter and the danger of a
schema change on a big table. **Does not**: file paths, the names of parameters, the tools, and the
exact meaning of `database`, `schema` and `user`. `sql-databases` lesson 13 says more about where
Oracle is used and why companies stay on it; this course's lesson 21 is about the day somebody
decides to move a database from one engine to another.
