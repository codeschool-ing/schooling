---
title: When the setup fails
version: 1
---

**Most setups fail on a step that was skipped or done twice**, and each says so in its own words.
Here are the ones a first run meets, each taken by skipping or repeating that step on the recording
machine, with what the message means and what to type.

## The server is not running

```
ana@lab:~/wh$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@lab:~/wh$ psql -c 'SELECT 1'
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
```

`down` in `pg_lsclusters` and *No such file or directory* from `psql`: the server is installed and
stopped. Where Ubuntu starts services at boot, it starts this one too. WSL without systemd does not,
and nor do some containers. Start it, and check:

```
ana@lab:~/wh$ sudo pg_ctlcluster 16 main start
ana@lab:~/wh$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

## The role does not exist

```
ana@lab:~/wh$ psql -c 'SELECT 1'
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The server is up and does not know your login name. The `createuser` command of section 04 makes the
role.

## The database does not exist

```
ana@lab:~/wh$ psql -c 'SELECT 1'
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "shop" does not exist
```

The role exists and `shop` does not. `PGDATABASE` in `~/.bashrc` makes `psql` connect to `shop`
whether or not it has been created yet; `createdb` makes it.

## A setting that did not change

```
ana@lab:~/wh$ psql -c 'SHOW shared_buffers'
 shared_buffers 
----------------
 128MB
(1 row)
```

`ALTER SYSTEM` wrote the new value into the server's configuration, and the server read its
configuration when it started. `sudo pg_ctlcluster 16 main restart`, and the same query answers
`512MB`.

## Loading twice

```
ana@lab:~/wh$ sh load.sh
ERROR:  duplicate key value violates unique constraint "shops_pkey"
DETAIL:  Key (shop_id)=(1) already exists.
CONTEXT:  COPY shops, line 2
```

`load.sh` stops at the first error, so nothing after the first table was loaded the second time,
and nothing loaded the first time was lost. Every table already has its rows, and their keys refuse
a second copy. If a load failed halfway instead, the database holds part of the data, and the
simplest repair for both is to start the database over:

```
ana@lab:~/wh$ dropdb shop && createdb --locale=C.UTF-8 --template=template0 shop && psql -q -f oltp.sql && sh load.sh
```

## Anything else

- `duckdb: command not found`, or `python3` cannot import `duckdb`: the virtual environment is not
  active in this terminal. The line in `~/.bashrc` activates it in every new one; `. ~/.bashrc`
  activates it in this one.
- `pip` cannot reach the package index: a proxy or a firewall between your machine and the
  internet. The virtual environment stays empty until `pip install` works.
- `No space left on device`: PostgreSQL needs the 1.1 GB of section 05 at once, and later lessons
  write copies of the warehouse beside it. `df -h ~` says how much is left. A virtual machine can be
  given a larger disk; a Multipass one is easiest to recreate with a larger `--disk`.

For anything that is not on this list, read the last lines a command printed. `load.sh` and the
build script of lesson 2 stop at the first error, so the last message is the one that matters.
