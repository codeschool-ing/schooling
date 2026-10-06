---
title: The lab, and three ways to run it
version: 1
---

**A star schema is not understood by reading one.** You understand it when a query you expected to
be slow comes back in twenty milliseconds, or when a total you trusted turns out to count every
book twice. So every lesson here is run, and you should run it too.

The lab is two databases on one Linux machine:

- **PostgreSQL 16** holds the shop's operational database, `shop`: fifteen tables in third normal
  form, the shape `sql-databases` taught you to build.
- **DuckDB** holds the warehouse, `wh.duckdb`, one file in Ana's working directory. It is an
  analytical database that runs inside the program that opens it, with no server, and it stores
  data by column — lesson 8 is about why that matters.

```
ana@lab:~/wh$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/wh$ duckdb --version
v1.5.6 (Variegata) 069cc9f9b5
```

The course's own lab script, `lab.sh`, sits beside the course's material. It creates a user called
`ana`, generates the data, loads it into PostgreSQL and installs DuckDB into a Python virtual
environment. On the machine the course was recorded on it took about a minute and left this much
on disk:

```
ana@lab:~/wh$ du -sh /var/lib/wh-data /var/lib/wh-pg ~/wh
97M	/var/lib/wh-data
802M	/var/lib/wh-pg
140M	/home/ana/wh
```

The data files are 97 MB. PostgreSQL turns them into 802 MB, because of the indexes, the space a
row carries for its own bookkeeping and the room it leaves for updates. The 140 MB in `~/wh` is the
extract and the warehouse built from it. **Keep those three numbers**: lesson 8 explains the
second.

## Three ways to run it

**In a virtual machine — recommended.** An Ubuntu 24.04 virtual machine with 2 GB of memory and
5 GB of free disk is enough. `lab.sh` adds a user and a database server, which is exactly the kind
of change you do not want on the computer you work on. `virtualization` lesson 4 builds one in
VirtualBox if you have not.

**Installed on your own computer.** Install PostgreSQL 16 and DuckDB yourself, create a database
called `shop`, run the course's `lab/oltp.sql`, and load the CSV files `lab/generate.py` writes.
That is what `lab.sh` does, one step at a time, and reading it is the instruction.

**Online, for half of it.** DuckDB also runs inside a web browser, at `shell.duckdb.org`, and can
query a CSV or Parquet file you open in it. That covers the warehouse queries and not the
PostgreSQL half. The course was not recorded that way; it is named here so that a student with no
machine of their own still has the larger part of the course.

## When the setup fails

Three failures account for most of it, and each one says so:

- `PostgreSQL 16 is required` — the script found no `initdb`. Install the `postgresql-16` package
  and run it again; it picks up where it stopped.
- `pip` cannot reach the package index — the virtual environment is empty and the first
  `duckdb` command answers `command not found`. A proxy or a firewall is the usual cause. Once
  `pip install duckdb-cli` works by hand, the script works too.
- `No space left on device` — the database needs the 802 MB above at once. Free the space, or give
  the virtual machine a larger disk, and run `lab.sh reset`.

If something fails that is not on the list, read the last ten lines the script printed. It stops at
the first error rather than carrying on, so the last line is the one that broke.
