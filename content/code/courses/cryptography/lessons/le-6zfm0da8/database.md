---
title: The database's files, and transparent data encryption
version: 1
---

**A database keeps its tables in ordinary files, and whatever is in a table is in those files, in
readable form, unless something encrypts them.** Whoever copies the data directory, a backup or a
disk snapshot gets the data without logging in to the database at all.

## Reading a table without asking the database

Vereda's lab database holds a `patients` table, built in the next section. After a checkpoint flushes
the table to disk, the table's file can be read with `strings`, which prints any run of readable
characters in a binary file. The file belongs to PostgreSQL's own account, so reading it takes
`sudo`, which whoever administers the server has:

```
ana@lab:~/lab$ psql -c CHECKPOINT
CHECKPOINT
ana@lab:~/lab$ sudo strings /var/lib/postgresql/16/main/$(psql -Atc "SELECT pg_relation_filepath('patients')") | grep -oE 'Marina Duarte|Joao Pires|111\.444\.777-35' | sort | uniq -c
      2 Joao Pires
      2 Marina Duarte
```

Both patients' names are there, twice each: PostgreSQL keeps old versions of updated rows until
`VACUUM` reclaims them, so a file also holds what a table no longer shows. The CPF is **not** there,
because the next section encrypts that one column. Everything else in the table, and in every other
table, is readable by whoever holds the file, on the server, in its backups and in any copy of either.

## Transparent data encryption

**TDE** encrypts the database's files as the database writes them and decrypts them as it reads, so
neither the application nor the queries change: hence *transparent*. SQL Server, Oracle and MySQL
offer it, and managed cloud databases (Amazon RDS, Azure SQL, Cloud SQL) encrypt their storage by
default. Community PostgreSQL has no built-in TDE; deployments rely on the disk encryption of the
previous section, or on a distribution that adds it.

TDE stops exactly one kind of theft: the **files**. Copied data files, a stolen backup, a decommissioned
disk. It does nothing against anybody who can run a query, because the database decrypts for every
authorised session, and that includes:

- a database administrator, or anybody who obtains an administrator's credentials;
- an application account used through SQL injection;
- a `pg_dump` or `mysqldump`, which produces an **unencrypted** dump, unless the dump is then
  encrypted as a file of its own.

That last point is where many backup arrangements fail quietly: the database is "encrypted at rest",
the nightly dump is written in clear text to a bucket, and the bucket is what leaks.

## Where the key lives decides it

A TDE key stored in the same server's configuration file is copied along with the data files by
anybody who copies the server, which reduces TDE to the obfuscation of lesson 11. Serious deployments
keep the TDE master key in a key management service or an HSM, which the database asks to unwrap its
keys at start-up. The last section of this lesson builds that arrangement.
