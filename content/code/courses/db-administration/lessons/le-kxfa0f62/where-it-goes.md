---
title: Where the log goes
version: 1
---

**Every PostgreSQL process writes its log lines to standard error**, and what happens to them next
depends on one parameter and on whoever started the server. On Ubuntu that is
`pg_ctlcluster`, and the answer is a single file under `/var/log/postgresql`. Most of what is
written about PostgreSQL's logging describes the other arrangement, with files inside the data
directory, so it is worth seeing which one your server is using before reading any advice.

The parameters that decide it, and the ones the rest of this lesson changes, as the package left
them:

```
shop=# SELECT name, setting FROM pg_settings
shop-#  WHERE name IN ('logging_collector', 'log_destination', 'log_line_prefix',
shop(#                 'log_min_messages', 'log_min_duration_statement', 'log_statement',
shop(#                 'log_lock_waits', 'log_temp_files', 'log_connections',
shop(#                 'log_checkpoints', 'log_autovacuum_min_duration')
shop-#  ORDER BY name;
            name             |     setting      
-----------------------------+------------------
 log_autovacuum_min_duration | 600000
 log_checkpoints             | on
 log_connections             | off
 log_destination             | stderr
 log_line_prefix             | %m [%p] %q%u@%d 
 log_lock_waits              | off
 log_min_duration_statement  | -1
 log_min_messages            | warning
 log_statement               | none
 log_temp_files              | -1
 logging_collector           | off
(11 rows)

shop=# SELECT pg_current_logfile();
 pg_current_logfile 
--------------------
 
(1 row)
```

**`logging_collector` is off and `log_destination` is `stderr`**: the server does nothing with
its log except write it to standard error. `pg_current_logfile()` answers only for files the server
opened itself, so it returns nothing. Of the rest, only `log_checkpoints` is on, which PostgreSQL 16
made the default; every other line in that table is a kind of event this server does not record yet.

## The file, and who opened it

```
ana@db:~$ ls -l /var/log/postgresql
total 4
-rw-r----- 1 postgres adm 556 Oct 10 16:43 postgresql-16-main.log
ana@db:~$ sudo ls -l /proc/$(sudo head -1 /var/lib/postgresql/16/main/postmaster.pid)/fd/2
l-wx------ 1 postgres postgres 64 Oct 10 16:44 /proc/99/fd/2 -> /var/log/postgresql/postgresql-16-main.log
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:43:49.701 -03 [99] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2026-10-10 16:43:49.735 -03 [99] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 16:43:49.781 -03 [105] LOG:  database system was shut down at 2026-10-10 03:18:41 -03
2026-10-10 16:43:49.792 -03 [99] LOG:  database system is ready to accept connections
```

The first line of `postmaster.pid` is the postmaster's process id, and `/proc/<pid>/fd/2` is
where its standard error points: **it is that file**. The server did not
choose it. `pg_ctlcluster` started the server with `pg_ctl -l`, which opens the file and hands it
over as standard error, and every backend the postmaster starts inherits it. The file belongs to
`postgres` and to the group `adm`, which is why `sudo` is in front of every command that reads it.

systemd's journal has the unit starting and nothing from inside the server:

```
ana@db:~$ sudo journalctl -u postgresql@16-main --no-pager -n 4
Oct 10 16:43:48 db systemd[1]: Starting postgresql@16-main.service - PostgreSQL Cluster 16-main...
Oct 10 16:43:51 db systemd[1]: Started postgresql@16-main.service - PostgreSQL Cluster 16-main.
```

That surprises people who expect every service's output in the journal. It is there only when a
server writes to standard error and nobody has redirected it, which is not how Ubuntu's package
starts it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Diagram. The postmaster and every process it starts write their log lines to standard error. With logging_collector off, which is Ubuntu's default, pg_ctlcluster has started the server with pg_ctl -l, so standard error is the file /var/log/postgresql/postgresql-16-main.log, cut weekly by logrotate with copytruncate. With logging_collector on, a logger process collects every line and writes files under log/ in the data directory, in stderr, csvlog or jsonlog format, and the server itself rotates them by age and size.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"220\" y=\"16\" width=\"280\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the postmaster and every process it starts</text><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">write to stderr</text><path d=\"M 300 72 L 190 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><path d=\"M 420 72 L 530 120\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><text x=\"190\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">logging_collector = off (Ubuntu's default)</text><text x=\"530\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">logging_collector = on</text><rect x=\"20\" y=\"152\" width=\"340\" height=\"132\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pg_ctlcluster starts the server with pg_ctl -l</text><text x=\"36\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/var/log/postgresql/</text><text x=\"48\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">postgresql-16-main.log</text><text x=\"36\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cut weekly by logrotate, copytruncate</text><rect x=\"380\" y=\"152\" width=\"320\" height=\"132\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"396\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a logger process collects every line</text><text x=\"396\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/var/lib/postgresql/16/main/log/</text><text x=\"408\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">postgresql-…json  (.csv, .log)</text><text x=\"396\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cut by the server: log_rotation_age, log_rotation_size</text></svg>", "caption": "Two ways for the same lines to reach a disk. Ubuntu chooses the first; the second is what jsonlog and csvlog need."}
```

## The other arrangement

With **`logging_collector = on`** the server starts an extra process, the logger, that reads
every other process's standard error and writes its own files under `log_directory`, `log` inside
the data directory by default. It names them by date with `log_filename`, starts a new file by age
or size, and is the only arrangement that can write `csvlog` or `jsonlog`. Turning it on needs a
restart. The last section of this lesson does it for JSON and puts it back.

Nothing is wrong with Ubuntu's choice. One file, rotated by the same tool as every other log on
the machine, is simple to find at three in the morning. **What matters is knowing which one you
have**, because on a server set up the other way `/var/log/postgresql` holds a couple of start-up
lines and the real log is somewhere you have not looked.
