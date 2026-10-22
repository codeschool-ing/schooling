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
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'hikari'
2026-10-22T19:38:24.890-03:00  INFO 491 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Starting...
2026-10-22T19:38:25.354-03:00  INFO 491 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : bookshop-pool - Added connection org.postgresql.jdbc.PgConnection@53d6e959
2026-10-22T19:38:25.355-03:00  INFO 491 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Start completed.
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
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.hikari.maximum-pool-size=2 | grep -E 'hikari'
2026-10-22T19:39:27.054-03:00  INFO 2764 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Starting...
2026-10-22T19:39:27.753-03:00  INFO 2764 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : bookshop-pool - Added connection org.postgresql.jdbc.PgConnection@11e9ac24
2026-10-22T19:39:27.754-03:00  INFO 2764 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Start completed.
```

In a third terminal, `psql` locks The Time Machine's row for eight seconds, the way a transaction
that called something slow would: `BEGIN`, a locking read, `pg_sleep(8)` and only then `COMMIT`. In
the first terminal, while that runs, three customers order The Time Machine at once:

```
ana@vm:~/bookshop$ for c in ana bia cris; do curl -s -o /dev/null -w "$c %{http_code} %{time_total}s\n" -H "Content-Type: application/json" -d "{\"customer\":\"$c\",\"lines\":[{\"bookId\":2,\"quantity\":1}]}" localhost:8080/orders & done; wait
bia 500 5.260944s
ana 201 7.127874s
cris 201 7.131366s
```

```
ana@vm:~$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'BEGIN' -c 'SELECT title, stock FROM book WHERE id = 2 FOR UPDATE' -c 'SELECT pg_sleep(8)' -c 'COMMIT'
BEGIN
      title       | stock 
------------------+-------
 The Time Machine |     3
(1 row)

 pg_sleep 
----------
 
(1 row)

COMMIT
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.hikari.maximum-pool-size=2 | grep -E 'Connection is not available'
2026-10-22T19:39:39.420-03:00  WARN 2764 --- [bookshop] [nio-8080-exec-2] org.hibernate.orm.jdbc.error             : bookshop-pool - Connection is not available, request timed out after 5005ms (total=2, active=2, idle=0, waiting=0)
java.sql.SQLTransientConnectionException: bookshop-pool - Connection is not available, request timed out after 5005ms (total=2, active=2, idle=0, waiting=0)
```

Read the three answers against the pool. Two of the requests, ana's and cris's here, each borrowed a
connection and sat in `findByIdForUpdate`, waiting for `psql` to let go of the row: they finished once
the eight seconds were up, about 7 seconds after they were sent, and placed their orders. The third,
bia's, found both connections lent out, waited for one for 5 seconds, and failed. HikariCP's message counts the pool at that instant: two connections in total,
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
