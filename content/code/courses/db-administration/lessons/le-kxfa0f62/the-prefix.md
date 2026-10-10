---
title: The prefix on every line
version: 1
---

A log line is a **prefix** and a **message**. The message is what happened; the prefix is when,
in which process, and for whom, and it is the part that makes a line findable a week later. It is
set by `log_line_prefix`, and Ubuntu's package sets it to something better than PostgreSQL's own
default:

```
shop=# SHOW log_line_prefix;
shop=# SELECT 1/0;
```

```
ana@db:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
```

Each `%` escape is replaced on every line:

| escape | becomes | in the line above |
|---|---|---|
| `%m` | the time, to the millisecond, with the time zone | the date and `-03` |
| `%p` | the process id, here inside `[ ]` | the backend that ran the statement |
| `%q` | nothing; it ends the prefix for processes with no session | — |
| `%u` | the role | `ana` |
| `%d` | the database | `shop` |

**`%q` is the clever one.** The checkpointer and the other background processes have no user and
no database, and without `%q` their lines would carry an empty `@`. With it, everything after `%q`
is left out for them, so a checkpoint line ends after the process id. The process id is what ties
lines together: the `ERROR` and the `STATEMENT` under it share one, and so does everything else that
one session wrote.

The second line exists because of `log_min_error_statement`, which is `error` by default: **any
statement that fails is written out after its error**, whether or not statements are logged at all.
That is often all a developer needs to reproduce a bug, and it is also how a password typed into a
failing statement ends up in the log.

## Adding the application

The prefix is worth extending in one direction: **which program sent the statement**. `%a` is the
`application_name` the client declared, which psql fills in on its own and most drivers let an
application set. Changing the prefix needs only a reload:

```
shop=# ALTER SYSTEM SET log_line_prefix = '%m [%p] %q%u@%d %a ';
shop=# SELECT pg_reload_conf();
shop=# SELECT 1/0;
```

```
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
```

The reload itself is logged, with the new value, and the line from the postmaster has no user
because of `%q`. On a server shared by a web application, a batch job and a reporting tool, `%a` is
the difference between *some session was slow* and *the nightly export was slow*. Other escapes
are in the documentation for `log_line_prefix`: `%h` adds the client's address, worth having once
connections arrive over the network, and `%x` the transaction id.

**Keep the time first and the format stable.** Every tool that reads these lines, from `grep` to a
log shipper, is written against the prefix, and changing it on a busy server breaks whatever
parses it.
