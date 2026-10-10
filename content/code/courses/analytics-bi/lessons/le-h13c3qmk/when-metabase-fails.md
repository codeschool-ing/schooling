---
title: When Metabase does not work
version: 1
---

Metabase fails in fewer ways than PostgreSQL, and most of them show up as one red sentence on the
**Add your data** form, or as a page that will not load. Each has a check from the shell that says
which.

## The page does not load at all

Metabase may still be starting: give it a minute, and ask it directly from the machine with `curl
-s -w '\n' http://localhost:3000/api/health`. `{"status":"ok"}` means it is up and the problem is
the path from your browser — the port forwarding of lesson 1, or the address on UTM. No answer
means Metabase itself is not running, and `sudo docker ps -a` says whether the container exists and
how it ended.

A container that stopped seconds after starting usually says why in its log. One way to cause it
is to start a second Metabase while the first holds port 3000:

```
ana@vm:~$ sudo docker run -d --name metabase2 --network host metabase/metabase:v0.64.1.5
b691785eeb17c3a3dcc59e1be3fcc1c8d71b01767ad8fc7bc443dcbac708b29e
ana@vm:~$ sudo docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
metabase2   Exited (1) 23 seconds ago
metabase    Up About a minute
ana@vm:~$ sudo docker logs metabase2 2>&1 | grep FAILED
2026-10-10 05:17:26,268 ERROR core.core :: Metabase Initialization FAILED: Failed to bind to /0.0.0.0:3000 
```

`Exited (1)` and `Failed to bind to /0.0.0.0:3000`: something else had the port. `sudo docker logs
metabase` shows the whole log of yours, and the line with `FAILED` in it is the one to read.

A container that keeps restarting, or a machine that freezes while Metabase starts, is short of
memory: the virtual machine has less than lesson 1 asked for, or the `-Xmx1g` was left out.

## `password authentication failed`

```
ana@vm:~$ PGPASSWORD=wrong-password psql -h localhost -U metabase lantern -c 'SELECT 1'
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "metabase"
connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "metabase"
```

The password in the form is not the role's. That is the only meaning of this message, and the check
above reproduces it from the shell, so you can test a password without the form.
`ALTER ROLE metabase PASSWORD '…'` in `psql lantern` sets a new one.

## The connection is refused

If you started Metabase without `--network host`, `localhost` inside the container is the container
itself, where no PostgreSQL runs, and the form reports that the connection was refused. Remove the
container with `sudo docker rm -f metabase` and start it again with the full command from this
lesson. (This failure was not reproduced for the course; the explanation follows from what the
option does.)

## Metabase shows no tables, or old ones

After re-running `semantic.sql`, the views are new and the role has no grants on them:

```
ana@vm:~$ psql -q lantern -f semantic.sql 2>/dev/null
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM semantic.orders'
ERROR:  permission denied for schema semantic
LINE 1: SELECT count(*) FROM semantic.orders
                             ^
```

Run the `GRANT` block of this lesson again. Metabase also remembers what it saw at the last sync,
so a view that was renamed or added appears only after the next one; in the admin settings, under
*Databases*, the Lantern database has a button to sync its schema now.
