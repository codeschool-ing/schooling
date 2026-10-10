---
title: Reload or restart
version: 1
---

Saving a file changes nothing. The server reads its configuration when it starts and when it is
told to read it again, and those are the two ways to apply a change: **a reload, which every
connection survives, and a restart, which none of them do**. The `context` column of the
previous section says which one a parameter needs, and getting it wrong in either direction is a
common way to spend an hour.

## A file in conf.d

Create this file with `sudo nano /etc/postgresql/16/main/conf.d/50-course.conf`. It asks for two changes, one of each kind. The first logs every statement slower than a quarter
of a second, a `sighup` parameter that lesson 19 is about. The second doubles `shared_buffers`, a
`postmaster` one that lesson 6 is about:

```ini
# /etc/postgresql/16/main/conf.d/50-course.conf
log_min_duration_statement = 250ms
shared_buffers = 256MB
```

Then reload, and read what the server said about it:

```
ana@db:~$ cat /etc/postgresql/16/main/conf.d/50-course.conf
# /etc/postgresql/16/main/conf.d/50-course.conf
log_min_duration_statement = 250ms
shared_buffers = 256MB
ana@db:~$ sudo systemctl reload postgresql
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:41:48.064 -03 [101] LOG:  received SIGHUP, reloading configuration files
2026-10-10 04:41:48.065 -03 [101] LOG:  parameter "log_min_duration_statement" changed to "250ms"
2026-10-10 04:41:48.065 -03 [101] LOG:  parameter "shared_buffers" cannot be changed without restarting the server
2026-10-10 04:41:48.065 -03 [101] LOG:  configuration file "/etc/postgresql/16/main/conf.d/50-course.conf" contains errors; unaffected changes were applied
```

A reload is a signal, `SIGHUP`, sent to the postmaster, which rereads every file and passes the
new values on to every running process. `systemctl reload postgresql` sends it; so does
`SELECT pg_reload_conf();` from a superuser's `psql`, and so does `sudo pg_ctlcluster 16 main
reload`. All three do the same thing.

The log reports each parameter. **`log_min_duration_statement` changed at once**, for every
connection, including ones already open. `shared_buffers` did not, and the last line calls that
an error, which it is not: the file is fine and one value in it is waiting. Read the lines above
the word `errors` before you believe it.

The server keeps the same fact in `pg_settings`. Look there on a machine whose log you have not
been reading:

```
ana@db:~$ psql
ana=# SELECT name, setting, unit, pending_restart
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'log_min_duration_statement');
            name            | setting | unit | pending_restart 
----------------------------+---------+------+-----------------
 log_min_duration_statement | 250     | ms   | f
 shared_buffers             | 16384   | 8kB  | t
(2 rows)

ana=# \q
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql
ana=# SELECT name, setting, unit, pending_restart
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'log_min_duration_statement');
            name            | setting | unit | pending_restart 
----------------------------+---------+------+-----------------
 log_min_duration_statement | 250     | ms   | f
 shared_buffers             | 32768   | 8kB  | f
(2 rows)

ana=# \q
```

**`pending_restart` is true for a value the files ask for and the server is not yet using.** After
the restart `shared_buffers` is 32768 pages of 8 kB, the 256 MB the file asked for, and nothing
is pending. `SELECT name FROM pg_settings WHERE pending_restart;` is worth running on any server
you inherit: a row there is a change somebody made and never finished, which the next restart,
perhaps at a bad moment, will apply.

## What a restart costs

A restart stops the server and starts it again. **Every connection is cut**, and every
transaction in progress is rolled back; the applications see an error and have to reconnect.
The shared memory is released and allocated again, so everything the server had cached in it is
gone, and the first queries afterwards read from disk. On a busy server that is a scheduled
event with a warning to the people who use it, which is why the `postmaster` parameters are the
ones to get right before the server carries traffic.

## When the file is wrong

Make a typo on purpose, the kind everybody makes once: a unit in lower case.

```
ana@db:~$ echo 'work_mem = 64mb' | sudo tee -a /etc/postgresql/16/main/conf.d/50-course.conf
work_mem = 64mb
ana@db:~$ sudo systemctl reload postgresql
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:41:55.113 -03 [247] LOG:  received SIGHUP, reloading configuration files
2026-10-10 04:41:55.114 -03 [247] LOG:  invalid value for parameter "work_mem": "64mb"
2026-10-10 04:41:55.114 -03 [247] HINT:  Valid units for this parameter are "B", "kB", "MB", "GB", and "TB".
2026-10-10 04:41:55.114 -03 [247] LOG:  configuration file "/etc/postgresql/16/main/conf.d/50-course.conf" contains errors; unaffected changes were applied
ana@db:~$ psql
ana=# SHOW work_mem;
 work_mem 
----------
 4MB
(1 row)

ana=# SELECT sourcefile, sourceline, name, setting, error
ana-#   FROM pg_file_settings
ana-#  WHERE error IS NOT NULL;
                  sourcefile                   | sourceline |   name   | setting |            error             
-----------------------------------------------+------------+----------+---------+------------------------------
 /etc/postgresql/16/main/conf.d/50-course.conf |          4 | work_mem | 64mb    | setting could not be applied
(1 row)

ana=# \q
```

A reload with a bad value is harmless: **the running server keeps the value it had** and says so
in the log. `systemctl reload` itself printed nothing and succeeded, so the only places the
mistake shows are the log and `pg_file_settings`, a view that reads the files as they are on disk
right now, line by line, with an `error` column.

A restart with the same file is not harmless. The server reads the file at start, finds the bad
line and refuses to start at all, and a quick change has become an outage. On the recording machine `sudo systemctl restart postgresql` with this file in place did not come
back. The unit Ubuntu ships waits without a time limit for a server that is not coming, and the
reason was in the log: the same lines as above, with `FATAL` in place of the last `LOG`.

So **check the files before a restart**. The server binary can read the configuration and print one
parameter without starting anything, and it reads every file to do it:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/postgres -C work_mem -c config_file=/etc/postgresql/16/main/postgresql.conf
2026-10-10 04:41:57.969 -03 [302] LOG:  invalid value for parameter "work_mem": "64mb"
2026-10-10 04:41:57.969 -03 [302] HINT:  Valid units for this parameter are "B", "kB", "MB", "GB", and "TB".
2026-10-10 04:41:57.969 -03 [302] FATAL:  configuration file "/etc/postgresql/16/main/conf.d/50-course.conf" contains errors
ana@db:~$ sudo sed -i '/^work_mem/d' /etc/postgresql/16/main/conf.d/50-course.conf
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/postgres -C work_mem -c config_file=/etc/postgresql/16/main/postgresql.conf
4096
```

The `FATAL` is the line a restart would have died on, printed while the real server carried on
running. `sed -i '/^work_mem/d'` deleted the bad line, and the second run printed the value the
files now give, `4096` in kilobytes, the default. Use it, or the `pg_file_settings` query, every
time a restart follows an edit.
