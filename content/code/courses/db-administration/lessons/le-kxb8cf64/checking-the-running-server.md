---
title: Checking the running server
version: 1
---

The script saying `wrote` and `reloaded` proves that a file was copied and a signal was sent. It
does not prove the server took the values. **Two views answer that, and they answer different
questions.** `pg_settings` is what the server is running now, and for each value, the file and line
it came from. `pg_file_settings` is what the configuration files say now, read again from disk
every time you query it, with an error beside any line the server could not use.

## What is running, and from where

On the server the script built, ask for every value whose source is the repository's file. There
is no role for you on this machine, so `psql` runs as `postgres`:

```
postgres=# SELECT name, setting, unit, sourceline, pending_restart FROM pg_settings WHERE sourcefile = '/etc/postgresql/16/main/conf.d/50-shop.conf' ORDER BY sourceline;
            name            | setting | unit | sourceline | pending_restart 
----------------------------+---------+------+------------+-----------------
 listen_addresses           | *       |      |          3 | f
 shared_buffers             | 131072  | 8kB  |          4 | f
 work_mem                   | 32768   | kB   |          5 | f
 maintenance_work_mem       | 262144  | kB   |          6 | f
 log_min_duration_statement | 500     | ms   |          7 | f
 log_lock_waits             | on      |      |          8 | f
(6 rows)
```

Six rows for the six settings in the file, each at its line. `setting` is in the unit beside it,
so `shared_buffers` is 131072 pages of 8 kB, which is the 1 GB the file asked for, and `work_mem`
is the 32 MB committed in the last section. **`pending_restart` is `f` on every row**, because the
restart after the first run applied the two values that needed one. A row with `t` is a value the
file has and the server is not running yet; any monitoring that knows this view should be asking
for those rows.

## A hand edit, with a typo

Now the drift the previous sections warned about. Somebody on call during a slow night appends
two lines to the deployed file on the server, reloads, and goes back to bed. The `printf` stands
for their editor:

```
ana@db:~$ printf 'work_mem = 64MB\nlog_min_duraton_statement = 250ms\n' | sudo tee -a /etc/postgresql/16/main/conf.d/50-shop.conf
work_mem = 64MB
log_min_duraton_statement = 250ms
ana@db:~$ sudo systemctl reload postgresql@16-main
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:31:27.769 -03 [2578] LOG:  parameter "work_mem" changed to "32MB"
2026-10-10 04:31:29.959 -03 [2578] LOG:  received SIGHUP, reloading configuration files
2026-10-10 04:31:29.960 -03 [2578] LOG:  unrecognized configuration parameter "log_min_duraton_statement" in file "/etc/postgresql/16/main/conf.d/50-shop.conf" line 10
2026-10-10 04:31:29.960 -03 [2578] LOG:  configuration file "/etc/postgresql/16/main/conf.d/50-shop.conf" contains errors; no changes were applied
```

**`systemctl reload` printed nothing and succeeded.** It sends a signal, and delivering a signal is
all it reports on; whether the server liked the files is not its business. The answer is in the
log. The first line is the previous section's reload. The last three are this one: the misspelt
parameter on line 10, and then the sentence that matters — **no changes were applied**. A file
with an error in it is refused whole, so the correct `work_mem = 64MB` on line 9 was refused with
the typo, and the server went on running exactly as before.

That is the safe way to fail, and it is still a trap. The person on call believes `work_mem` is
64 MB. The file on the server says it is. Only the log and the running server disagree.

## What the files say now

`pg_file_settings` reads the files at the moment you ask, so it shows the lines whether or not
the server applied them:

```
postgres=# SELECT sourceline, name, setting, applied, error FROM pg_file_settings WHERE sourcefile LIKE '%50-shop.conf' ORDER BY sourceline;
 sourceline |            name            | setting | applied |                error                 
------------+----------------------------+---------+---------+--------------------------------------
          3 | listen_addresses           | *       | f       | 
          4 | shared_buffers             | 1GB     | f       | 
          5 | work_mem                   | 32MB    | f       | 
          6 | maintenance_work_mem       | 256MB   | f       | 
          7 | log_min_duration_statement | 500ms   | f       | 
          8 | log_lock_waits             | on      | f       | 
          9 | work_mem                   | 64MB    | f       | 
         10 | log_min_duraton_statement  | 250ms   | f       | unrecognized configuration parameter
(8 rows)

postgres=# SHOW work_mem;
 work_mem 
----------
 32MB
(1 row)
```

`applied` is `f` on all eight lines, because the file containing them would not be applied. Line
10 carries the reason. `work_mem` now appears twice, and even with the typo fixed, line 9 would win
over line 5 and line 5 would show `applied = f`; a parameter set twice in one file is a smaller
version of the same drift. `SHOW work_mem` confirms what the log said: still 32 MB.

**One query is worth running after every reload**, by hand or from whatever watches the server:

```sql
SELECT sourcefile, sourceline, name, error FROM pg_file_settings WHERE error IS NOT NULL;
```

It returns no rows when the files are sound, and a file and a line when they are not.

## The repository wins

The deployed file now differs from the repository's, and `diff` shows by how much. Running the
script is how it is put back:

```
ana@db:~$ diff shop-db/conf.d/50-shop.conf /etc/postgresql/16/main/conf.d/50-shop.conf
8a9,10
> work_mem = 64MB
> log_min_duraton_statement = 250ms
ana@db:~$ sudo bash shop-db/provision.sh
wrote /etc/postgresql/16/main/conf.d/50-shop.conf
reloaded the configuration
```

And in `psql` on the server:

```
postgres=# SELECT count(*) FROM pg_file_settings WHERE error IS NOT NULL;
 count 
-------
     0
(1 row)

postgres=# SHOW work_mem;
 work_mem 
----------
 32MB
(1 row)
```

The script found the files different, copied the repository's over the edited one and reloaded,
and the error is gone. **So is the 64 MB the person on call wanted.** If it was the right value, it
goes through the repository as a commit with a reason, and the next run applies it. Running the
script on a schedule — every night, or after every merge — turns drift from a thing found once a
year into a thing undone within a day. It also undoes every emergency fix that never became a
commit, which is exactly the pressure that makes people commit them.
