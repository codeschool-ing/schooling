---
title: When the connection fails
version: 1
---

Every way a connection fails prints a sentence that says which way, and the sentence is always in
the same place. The difficulty is finding it. With the password changed on the command line, the way
lesson 4 overrides a property, the bookshop refuses to start and writes this much:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | wc -l
140
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | grep -E "ERROR|Caused by" | cut -c1-110
2026-10-22T19:16:10.152-03:00 ERROR 15645 --- [bookshop] [           main] o.s.boot.SpringApplication         
Caused by: org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'bo
Caused by: org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'jd
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'jdbcClient'
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'dataSourceS
Caused by: org.springframework.jdbc.datasource.init.UncategorizedScriptException: Failed to execute database s
Caused by: org.springframework.jdbc.CannotGetJdbcConnectionException: Failed to obtain JDBC Connection
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "bookshop"
```

A hundred and forty lines, and `cut` has kept only the first 110 characters of the ones `grep`
picked. Each `Caused by` is one layer explaining the layer above it: a bean could not be created
because its dependency could not, because the script could not run, because no connection could be
had. **The last `Caused by` is the reason; everything above it is the route the failure took.** It
is always the driver's own exception, `org.postgresql.util.PSQLException`, and the rest of this
section greps for it directly. Each case breaks one line of `application.properties` from the
command line.

## Nothing is listening

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.url=jdbc:postgresql://localhost:5433/bookshop 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: Connection to localhost:5433 refused. Check that the hostname and port are correct and that the postmaster is accepting TCP/IP connections.
```

`refused` means the machine at that address answered, and nothing was listening on that port. Here
it is the wrong port, 5433. The same message comes when the port is right and the server is not
running, so ask the server:

```sh
pg_lsclusters
```

If the status column says `down` rather than `online`, start it with
`sudo pg_ctlcluster 16 main start`, and if it will not start, the reason is in the log file named
in the last column. A virtual machine switched off rather than shut down, and a full disk, both end
here.

## The password, and the role that is not there

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "bookshop"
```

The password is wrong, and the message says so. The next one looks the same and is a different
problem:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.username=bookshp 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "bookshp"
```

The role is misspelt, `bookshp`, and the server **still says the password failed**. That is
deliberate. If a wrong user name produced a different answer from a wrong password, anybody who can
reach the port could find out which role names exist, one guess at a time. So the client is told
only that it did not get in, and the true reason goes to the server's log, which only an
administrator reads:

```
ana@vm:~/bookshop$ sudo grep bookshp /var/log/postgresql/postgresql-16-main.log | tail -n 3
2026-10-22 22:16:00.354 UTC [15519] bookshp@bookshop FATAL:  password authentication failed for user "bookshp"
2026-10-22 22:16:00.354 UTC [15519] bookshp@bookshop DETAIL:  Role "bookshp" does not exist.
2026-10-22 22:16:03.277 UTC [15570] bookshop@bookshp FATAL:  database "bookshp" does not exist
```

`DETAIL:  Role "bookshp" does not exist.` is the line the client never saw. When the password is
certainly right and the server still refuses it, read this log before resetting anything.

## Logged in, to nothing

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.url=jdbc:postgresql://localhost:5432/bookshp 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: FATAL: database "bookshp" does not exist
```

This one got further. The login succeeded, so user and password are right, and the database named
at the end of the URL does not exist. Check the spelling in `spring.datasource.url`, and if it is
right, the `createdb` step was skipped or run on another machine.

## All of them at once

| what it says | what it means | where to look |
|---|---|---|
| `No suitable driver found` | no driver on the class path accepts the URL | the class path, or the `jdbc:postgresql:` prefix |
| `Connection to … refused` | nothing listens on that host and port | the port in the URL, then `pg_lsclusters` |
| `password authentication failed` | the password is wrong, or the role does not exist | the server's log, which says which |
| `database "…" does not exist` | the login worked; the database is missing | the URL's last part, then `createdb` |
| `Peer authentication failed` | `psql` came in by the socket as somebody else | connect to `localhost` instead |
| `role "…" does not exist` | a socket login for a role the server lacks | create the role, or name the right one |

The last two come from `psql` on the socket, and the application never meets them, because JDBC
always connects over TCP. Lesson 14 adds the failure this table does not have: a server that is
there and a pool with every connection already lent out.
