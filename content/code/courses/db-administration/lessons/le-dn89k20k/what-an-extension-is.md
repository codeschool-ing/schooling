---
title: What an extension is
version: 1
---

An **extension** is a bundle of SQL objects, and sometimes a compiled library, that somebody else
wrote and PostgreSQL knows how to install, upgrade and remove as one thing. The wrong picture is a
plugin you download from a website. Most of the ones a DBA uses arrived with the server, in the
same package, and are waiting for a command.

The server knows what it could install:

```
shop=# SELECT count(*) FROM pg_available_extensions;
 count 
-------
    47
(1 row)

shop=# SELECT name, default_version, installed_version, comment
shop-#   FROM pg_available_extensions
shop-#  WHERE name IN ('pg_stat_statements', 'pgcrypto', 'pg_trgm', 'plpgsql', 'postgis')
shop-#  ORDER BY name;
        name        | default_version | installed_version |                                comment                                 
--------------------+-----------------+-------------------+------------------------------------------------------------------------
 pg_stat_statements | 1.10            |                   | track planning and execution statistics of all SQL statements executed
 pg_trgm            | 1.6             |                   | text similarity measurement and index searching based on trigrams
 pgcrypto           | 1.3             |                   | cryptographic functions
 plpgsql            | 1.0             | 1.0               | PL/pgSQL procedural language
(4 rows)
```

Forty-seven, and only `plpgsql` has an `installed_version` in `shop`. The rest are the **contrib**
modules: extensions maintained inside the PostgreSQL project itself, released with every version
and packaged with the server on Ubuntu. `postgis` is not in the list because it is not part of the
project and not installed yet; it has a package of its own, and the section after next installs it.

## Files on disk

Each available extension is a handful of files. A **control file** says what it is called, which
version is the default and whether it needs a library; a **script** for each version creates its
objects; and an **upgrade script** for each step between versions moves an old installation forward:

```
ana@db:~$ ls /usr/share/postgresql/16/extension/pgcrypto*
/usr/share/postgresql/16/extension/pgcrypto--1.0--1.1.sql
/usr/share/postgresql/16/extension/pgcrypto--1.1--1.2.sql
/usr/share/postgresql/16/extension/pgcrypto--1.2--1.3.sql
/usr/share/postgresql/16/extension/pgcrypto--1.3.sql
/usr/share/postgresql/16/extension/pgcrypto.control
ana@db:~$ cat /usr/share/postgresql/16/extension/pgcrypto.control
# pgcrypto extension
comment = 'cryptographic functions'
default_version = '1.3'
module_pathname = '$libdir/pgcrypto'
relocatable = true
trusted = true
ana@db:~$ ls -l /usr/lib/postgresql/16/lib/pgcrypto.so
-rw-r--r-- 1 root root 125920 Aug 13 16:12 /usr/lib/postgresql/16/lib/pgcrypto.so
```

`module_pathname` points at the compiled half, `pgcrypto.so`, which holds the code the functions
call. `trusted = true` is the line this section comes back to below.

**None of these files does anything by being there.** They belong to the server and to the package
that put them there; `apt` replaces them on an update and nothing in any database changes.

## CREATE EXTENSION, one database at a time

`CREATE EXTENSION` reads the control file, runs the script for the default version **inside the
database you are connected to**, and records that the objects it made belong to the extension:

```
ana=# CREATE EXTENSION pgcrypto;
CREATE EXTENSION

ana=# \dx
                  List of installed extensions
   Name   | Version |   Schema   |         Description          
----------+---------+------------+------------------------------
 pgcrypto | 1.3     | public     | cryptographic functions
 plpgsql  | 1.0     | pg_catalog | PL/pgSQL procedural language
(2 rows)

ana=# \c shop
You are now connected to database "shop" as user "ana".

shop=# \dx
                 List of installed extensions
  Name   | Version |   Schema   |         Description          
---------+---------+------------+------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(1 row)
```

`ana` has pgcrypto and `shop` does not. A database is a separate set of catalogues, so an
extension installed in one is invisible from the other, and a server with ten databases that all
need pgcrypto needs ten `CREATE EXTENSION` commands. A new database is copied from `template1`, so
an extension created in `template1` appears in every database made after it, and in none made
before.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Diagram. On the left, the files an extension is made of, one copy per server: pgcrypto.control and the SQL scripts under /usr/share/postgresql/16/extension, and pgcrypto.so under /usr/lib/postgresql/16/lib. On the right, two databases. In ana, CREATE EXTENSION has run the script and the extension pgcrypto 1.3 holds its functions; the library is loaded into a backend when a function first needs it. Shop has nothing until CREATE EXTENSION is run there too.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Files: one copy per server, from the package</text><text x=\"36\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/share/postgresql/16/extension/</text><text x=\"48\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pgcrypto.control</text><text x=\"48\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">pgcrypto--1.3.sql</text><text x=\"48\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pgcrypto--1.2--1.3.sql</text><text x=\"48\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">…</text><text x=\"36\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/lib/postgresql/16/lib/</text><text x=\"48\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">pgcrypto.so</text><rect x=\"430\" y=\"20\" width=\"270\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">database ana</text><rect x=\"446\" y=\"58\" width=\"238\" height=\"74\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"458\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">extension pgcrypto 1.3</text><text x=\"458\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">digest(), crypt(), gen_salt(), …</text><rect x=\"430\" y=\"190\" width=\"270\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">database shop</text><text x=\"446\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nothing until CREATE EXTENSION</text><path d=\"M 324 116 C 370 116, 390 80, 444 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><path d=\"M 324 218 C 390 218, 400 120, 444 118\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\" stroke-dasharray=\"5 4\"></path><text x=\"330\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">CREATE EXTENSION runs the script here</text><text x=\"330\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a backend loads the library when it first needs it</text></svg>", "caption": "The files are the server's; the extension is the database's. CREATE EXTENSION copies one into the other, one database at a time."}
```

## Loaded when needed, or loaded at start

The library is a separate matter from the SQL. Most extensions' libraries are loaded **into one
backend, the first time one of its functions is called**, and stay loaded until that connection
ends. That needs no configuration at all.

A few extensions have to watch everything the server does from the moment it starts. They hook
into the executor, or need shared memory sized before the first connection arrives. Those are named
in **`shared_preload_libraries`**, read only at start, so changing it needs a restart; lesson 5 put
it among the parameters with context `postmaster`. `pg_stat_statements` is the one every DBA meets,
and it is next.

## Trusted extensions

Creating an extension used to require a superuser, because a script can create functions written
in C and C runs with the server's own rights. Since PostgreSQL 13 a control file may say
**`trusted = true`**: the extension is judged safe enough that **any role with the `CREATE`
privilege on the database** may install it, and the objects are still created with superuser
rights behind the scenes. pgcrypto is trusted; pageinspect, which reads raw pages off the disk, is
not:

```
ana=# CREATE ROLE clerk;
CREATE ROLE

ana=# GRANT CREATE ON DATABASE ana TO clerk;
GRANT

ana=# DROP EXTENSION pgcrypto;
DROP EXTENSION

ana=# SET ROLE clerk;
SET

ana=> CREATE EXTENSION pgcrypto;
CREATE EXTENSION

ana=> CREATE EXTENSION pageinspect;
ERROR:  permission denied to create extension "pageinspect"
HINT:  Must be superuser to create this extension.

ana=> RESET ROLE;
RESET

ana=# \dx pgcrypto
             List of installed extensions
   Name   | Version | Schema |       Description       
----------+---------+--------+-------------------------
 pgcrypto | 1.3     | public | cryptographic functions
(1 row)
```

`SET ROLE clerk` made the session act as an ordinary role, and the prompt's `>` says so. The
difference matters most where you are never a superuser at all, as on the managed services of
lesson 3. Lesson 13's predefined roles, `pg_monitor` among them, cover much of the rest of what an
application owner asks a superuser for.
