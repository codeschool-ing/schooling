---
title: Keeping extensions through updates and upgrades
version: 1
---

An extension has **two versions that move separately**: the files on disk, which `apt` replaces,
and the objects in each database, which stay as `CREATE EXTENSION` made them until somebody
updates them. Most of the trouble extensions cause on upgrade day comes from forgetting the second.

## Installed and default

`pg_available_extensions` shows both. An old version installed on purpose makes the gap visible:

```
ana=# CREATE EXTENSION pg_trgm VERSION '1.5';
CREATE EXTENSION

ana=# SELECT name, default_version, installed_version
ana-#   FROM pg_available_extensions
ana-#  WHERE installed_version IS NOT NULL
ana-#  ORDER BY name;
   name   | default_version | installed_version 
----------+-----------------+-------------------
 pg_trgm  | 1.6             | 1.5
 pgcrypto | 1.3             | 1.3
 plpgsql  | 1.0             | 1.0
 postgis  | 3.4.2           | 3.4.2
(4 rows)

ana=# ALTER EXTENSION pg_trgm UPDATE;
ALTER EXTENSION

ana=# \dx pg_trgm
                                  List of installed extensions
  Name   | Version | Schema |                            Description                            
---------+---------+--------+-------------------------------------------------------------------
 pg_trgm | 1.6     | public | text similarity measurement and index searching based on trigrams
(1 row)
```

`default_version` is what the files on disk would install today; `installed_version` is what this
database has. **`ALTER EXTENSION … UPDATE` runs the upgrade scripts** between the two, here
`pg_trgm--1.5--1.6.sql`, one of the files listed in the first section. The same thing happens
without anybody asking for an old version: a package update brings new files and a new default,
and every database keeps the old objects until it is told. A query that lists the rows where the
two columns differ, run in each database after an update, is a good line in a maintenance
checklist.

**The library is the exception.** A `.so` file is replaced by the package and loaded fresh by the
next backend that needs it, or at the next restart for anything in `shared_preload_libraries`.
PostGIS's release notes say when a minor update needs `ALTER EXTENSION postgis UPDATE` as well;
read them before the update rather than after.

## What a dump carries

`pg_dump` writes **one `CREATE EXTENSION` line per extension**, not the objects it made:

```
ana@db:~$ pg_dump --schema-only ana | grep -i extension
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';
ana@db:~$ pg_dump --schema-only ana | wc -l
112
```

The whole schema of `ana`, PostGIS included, is 112 lines, against the 893 objects PostGIS alone
created. That is what makes a dump portable, and it is also its condition: **the server that
restores the dump has to have the extension's files installed**, or the restore stops at that line
with an error. db-reliability's lessons on backups restore exactly such dumps.

## Before a major upgrade

A major upgrade, 16 to 17, puts a second server beside the first, and the second has its own
directory of extension files. `postgresql-16-postgis-3` serves 16 and nothing else; **17 needs
`postgresql-17-postgis-3` installed before the upgrade starts**, and so does every other extension
that came from a package of its own. The contrib modules arrive with the new server.

So the inventory comes first: `\dx` in every database, and for each extension, whether the new
version has a package and whether the installed version can be updated to it. Lesson 20 performs
the upgrade and comes back to this list afterwards.

## Putting the server back

The rest of the course does not use any of this, so the lesson leaves the server as it found it:
the tables and extensions dropped, the role gone, and `shared_preload_libraries` back to empty
with one more restart.

```
ana=# DROP TABLE app_users, warehouses;
DROP TABLE

ana=# DROP EXTENSION pgcrypto, postgis, pg_trgm;
DROP EXTENSION

ana=# REVOKE CREATE ON DATABASE ana FROM clerk;
REVOKE

ana=# DROP ROLE clerk;
DROP ROLE

ana=# \c shop
You are now connected to database "shop" as user "ana".

shop=# DROP EXTENSION pg_stat_statements;
DROP EXTENSION

shop=# ALTER SYSTEM RESET shared_preload_libraries;
ALTER SYSTEM
```

```
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ psql shop -c "SHOW shared_preload_libraries"
 shared_preload_libraries 
--------------------------
 
(1 row)
```

The `postgresql-16-postgis-3` package can stay installed: files on disk do nothing until a
database asks for them.
