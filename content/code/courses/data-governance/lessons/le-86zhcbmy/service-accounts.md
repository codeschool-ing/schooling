---
title: People leave, programs multiply
version: 1
---

A login is created on somebody's first day. The question this section is about is what happens
to it on their last, and to the logins that belong to no person at all.

## An account with an end date

Lia was an intern. Her contract ended on 30 June, and her role was created knowing that:
`VALID UNTIL '2026-06-30'`. After that date her password stops working, whether or not anybody
remembers to do anything:

```
ana@lab:~/gov$ psql -h db.ipe.example -U lia -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "lia"
password retrieved from file "/home/ana/.pgpass"
connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "lia"
password retrieved from file "/home/ana/.pgpass"
```

The client is told only that authentication failed — the same answer as a wrong password, for
the reason the last section gave. The line `password retrieved from file` is libpq telling Ana
where the password it tried came from, which is the first thing to check when a login that
worked yesterday does not today.

**An expiry date is the cheapest control in this lesson and the one most often missing.** Access
reviews happen quarterly if they happen at all; a contract's end date is known on the first day.
Writing it on the role means the default outcome of forgetting is that access ends.

It is not the whole answer, though. `VALID UNTIL` expires the *password*: a role that logs in by
`peer` or by certificate is not affected, and the role, its grants and anything it owns are all
still there. The complete offboarding is three statements. Lesson 2 runs them, once Lia has
grants to lose:

```sql
ALTER ROLE lia NOLOGIN;            -- no new sessions, by any method
REASSIGN OWNED BY lia TO ipe_owner; -- anything she created now has an owner who stays
DROP OWNED BY lia;                 -- and every privilege granted to her goes
```

## Logins that are programs

Two of the six roles are not people. `site_app` is the website and `etl_loader` is the nightly
pipeline. They are called **service accounts**, and the rules for them are different because the
risks are:

- **Nobody types their password, so it can be long and random**, and should be. It lives in a
  secret store or an environment the program reads, never in the code — lesson 4 puts one in a
  key-management server.
- **They should be able to do exactly what the program does and nothing else.** The website
  inserts orders and reads products; it has no reason to read `health.prescriptions` in bulk.
  Lesson 2 builds that.
- **They should be limited in how much they can do at once.** A program with a bug can open
  connections in a loop, and every connection costs the server memory.

That last one is an attribute, and Ana set it when she created the role:

```
ana@lab:~/gov$ for i in 1 2 3; do psql -h db.ipe.example -U site_app -c "SELECT pg_sleep(2)" >/dev/null & done; sleep 1; psql -h db.ipe.example -U site_app -c "SELECT 1"; wait
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  too many connections for role "site_app"
```

Three connections were already open, each sleeping for two seconds; the fourth was refused. A
leak in the website now takes down the website's own logins rather than the database everybody
else is using. The limit belongs on a service account, not on a person: a person who opens a
fourth window is not a fault.

**One service account per program, never one shared by several.** When the nightly pipeline and a
reporting tool share `etl_loader`, a connection storm, a slow query or a strange read in the log
has two possible owners, and the investigation starts by finding out which.
