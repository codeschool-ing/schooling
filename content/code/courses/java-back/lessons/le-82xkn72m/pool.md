---
title: The connection pool, and what running out looks like
version: 1
---

Every transaction in this lesson ran on a database connection, and none of them opened one. The
picture many people start with is a connection opened per request and closed after it. Opening a
PostgreSQL connection means a TCP handshake, authentication, and a new server process on the
database's side, which is slow next to a query that reads one row by its key. So the application
keeps a **pool**: a set of connections opened once and lent out. A transaction borrows one when it
begins and gives it back when it commits or rolls back.

Spring Boot's pool is **HikariCP**, which came with the JPA starter. Its startup lines have been in
every log since lesson 9; with the name section 02 gave it, they read:

```
MISSING CAPTURE hikari
```

## The three lines

Section 02 added three properties to `application.properties`:

```properties
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000
```

`pool-name` is only a label, so a log line says which pool it is about. **`maximum-pool-size` is the
most connections the pool will ever hold**: 10 is also HikariCP's default, and the line is there so
the number is written where somebody sees it. **`connection-timeout` is how long, in milliseconds,
a request waits for a free connection before it gives up**. HikariCP's default is 30 seconds, and
30 seconds is longer than anybody waits for a web page, so the bookshop gives up after 5.

## Running out

A transaction holds its connection from the first statement to the commit, including the time it
spends waiting for a lock. That makes exhaustion easy to produce. Restart the application in the
second terminal with a pool of two connections, overriding the property from the command line:

```
MISSING CAPTURE poolstart
```

In a third terminal, `psql` locks The Time Machine's row for eight seconds, the way a transaction
that called something slow would: `BEGIN`, a locking read, `pg_sleep(8)` and only then `COMMIT`. In
the first terminal, while that runs, three customers order The Time Machine at once:

```
MISSING CAPTURE exhaust
```

```
MISSING CAPTURE exhaustpsql
```

```
MISSING CAPTURE exhaustlog
```

Read the three answers against the pool. The first two requests each borrowed a connection and sat in
`findByIdForUpdate`, waiting for `psql` to let go of the row: they finished once the eight seconds
were up and placed their orders. The third found both connections lent out, waited for one for
5000 ms, and failed. HikariCP's message counts the pool at that instant: two connections in total,
both active, none idle. That failure has no handler of its own, so it comes back as a `500`, with the
detail kept in the server's log.

Restart the application without the override before going on.

## How big a pool

The tempting answer is bigger. It rarely helps, because the pool is not where the work happens.
PostgreSQL runs each connection as a process, and a database with more active queries than CPU
cores spends its time switching between them. The database also has its own ceiling,
`max_connections`, which section 05's output showed at 100, shared by every instance of the
application and every other client. Three copies of the bookshop at 10 each hold 30 of them.

HikariCP's documentation suggests starting from the database server's cores times two, plus the
number of disks, and measuring from there. What the bookshop's numbers say is the useful part: a
pool that runs out is usually a symptom of transactions that last too long, as the one above did,
and the fix is shorter transactions rather than more connections. Lesson 22 shows how to watch the
pool's numbers on a running application.
