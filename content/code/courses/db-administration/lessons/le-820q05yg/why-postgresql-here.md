---
title: Why this course is PostgreSQL-shaped
version: 1
---

Every lesson from here on is written against PostgreSQL 16, and that is a choice with reasons
rather than a preference.

**You can own all of it.** PostgreSQL is free under a licence that lets anybody run, change and
distribute it, and Ubuntu installs it with one command. The course needs a server you can install,
configure, fill, break and upgrade on your own computer, and of the four only PostgreSQL and MySQL
allow that without a licence conversation. SQL Server has a free Developer edition and Oracle a
free edition with limits, and both are a heavier thing to put on a practice machine.

**It shows its working.** Every setting is a line in a file you can read, every statistic is a view
you can query, and the log says what the server is doing in plain sentences. A lot of what a
commercial engine hides behind a dashboard, PostgreSQL leaves in front of you, which is exactly what
somebody learning the job needs.

**It is where the work is going.** New applications, cloud providers' managed services and
migrations away from commercial engines have all moved towards PostgreSQL in the last decade, and
MySQL is the other common choice. A DBA who knows PostgreSQL well is employable, and lesson 21 is
about the most common reason a company calls one: moving a database onto it.

**And it is strict.** PostgreSQL will not compare a number with a piece of text by quietly
converting one of them, and it will not cast a value to another type unless it is asked to. MySQL,
by comparison, decides that `'1abc' = 1` is true and records a warning nobody reads. For an
administrator that strictness is a feature: what the server accepted is what it stored.

## What changes when the engine is not PostgreSQL

The ideas of this course hold for the others, and the first section's table is the map. When a
lesson's subject is one where another engine is famously different, it says so in a sentence: MySQL
for connections and replication, SQL Server for its log, Oracle for undo. Where the lesson is about a
PostgreSQL-only mechanism — vacuum, the `pg_hba.conf` file, postgresql-common's clusters — it says
that too, so you know what not to look for elsewhere.

Lessons 1 and 2 ask you to type nothing. **Lesson 3 builds your server**, and from then on every
transcript in the course is something you can run and compare.
