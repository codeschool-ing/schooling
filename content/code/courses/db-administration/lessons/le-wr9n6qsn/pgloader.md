---
title: pgloader, and the three times it stops
version: 1
---

**pgloader** reads a MySQL database's catalogue, creates the same tables in PostgreSQL with types it
chooses, copies the rows with PostgreSQL's `COPY`, then builds the indexes, the keys and the
sequences. One command does all of it. On Ubuntu 24.04 against MySQL 8.0, that command fails three
times before it works, and each failure is worth seeing once: two are the tool, and one is the data.

```sh
sudo apt install -y pgloader
```

pgloader reads from MySQL over the network, as an ordinary client with a password, so it needs a
MySQL user of its own. It only reads, and it gets only `SELECT`. The PostgreSQL side needs an empty
database, and your own role is enough to write into it:

```
ana@db:~$ sudo mysql -e "CREATE USER 'migrator'@'localhost' IDENTIFIED BY 'change-me'; GRANT SELECT, SHOW VIEW ON legacy.* TO 'migrator'@'localhost';"
ana@db:~$ createdb legacy
ana@db:~$ pgloader --version
pgloader version "3.6.7~devel"
compiled with SBCL 2.2.9.debian
ana@db:~$ pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy
2026-10-10T07:33:41.020000Z LOG pgloader version "3.6.7~devel"
2026-10-10T07:33:41.104000Z LOG Migrating from #<MYSQL-CONNECTION mysql://migrator@localhost:3306/legacy {1005DC3983}>
2026-10-10T07:33:41.104000Z LOG Migrating into #<PGSQL-CONNECTION pgsql://ana@UNIX:5432/legacy {1005F8FAB3}>
2026-10-10T07:33:41.132000Z ERROR mysql: Failed to connect to mysql at "localhost" (port 3306) as user "migrator": Condition QMYND:MYSQL-UNSUPPORTED-AUTHENTICATION was signalled.
2026-10-10T07:33:41.132000Z LOG report summary reset
       table name     errors       rows      bytes      total time
-----------------  ---------  ---------  ---------  --------------
  fetch meta data          0          0                     0.000s
-----------------  ---------  ---------  ---------  --------------
-----------------  ---------  ---------  ---------  --------------
```

The two arguments are the source and the target. `postgresql:///legacy`, with nothing between the
slashes, means the local socket and your own role, the same door `psql` uses.

## First: the password exchange

**`MYSQL-UNSUPPORTED-AUTHENTICATION` is the client inside pgloader failing to log in.** MySQL 8
stores new passwords with `caching_sha2_password`, and the MySQL client built into this pgloader
only speaks the older `mysql_native_password`. Changing the user alone is not enough, which is
worth knowing before you spend an hour on it:

```
ana@db:~$ sudo mysql -e "ALTER USER 'migrator'@'localhost' IDENTIFIED WITH mysql_native_password BY 'change-me';"
ana@db:~$ pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy 2>&1 | grep ERROR
2026-10-10T07:33:42.164000Z ERROR mysql: Failed to connect to mysql at "localhost" (port 3306) as user "migrator": Condition QMYND:MYSQL-UNSUPPORTED-AUTHENTICATION was signalled.
```

The server opens every conversation by proposing its default method, and this client cannot
answer a proposal it does not know, even for a user whose password is stored the old way. **The
server's default has to change too**, in a file of its own under MySQL's configuration directory:

```
ana@db:~$ printf '[mysqld]\ndefault_authentication_plugin = mysql_native_password\n' | sudo tee /etc/mysql/mysql.conf.d/pgloader.cnf
[mysqld]
default_authentication_plugin = mysql_native_password
ana@db:~$ sudo systemctl restart mysql
ana@db:~$ pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy
2026-10-10T07:33:45.016000Z LOG pgloader version "3.6.7~devel"
2026-10-10T07:33:45.100000Z LOG Migrating from #<MYSQL-CONNECTION mysql://migrator@localhost:3306/legacy {1005DD1A33}>
2026-10-10T07:33:45.100000Z LOG Migrating into #<PGSQL-CONNECTION pgsql://ana@UNIX:5432/legacy {1005F9ECA3}>
2026-10-10T07:33:45.144000Z ERROR mysql: 76 fell through ECASE expression.
       Wanted one of (2 3 4 5 6 8 9 10 11 14 15 17 20 21 23 27 28 30 31 32 33
                      35 41 42 45 46 47 48 49 50 51 52 54 55 56 60 61 62 63 64
                      65 69 72 77 78 79 82 83 87 90 92 93 94 95 96 97 98 101
                      102 103 104 105 106 107 108 109 110 111 112 113 114 115
                      116 117 118 119 120 121 122 123 124 128 129 130 131 132
                      133 134 135 136 137 138 139 140 141 142 143 144 145 146
                      147 148 149 150 151 159 160 161 162 163 164 165 166 167
                      168 169 170 171 172 173 174 175 176 177 178 179 180 181
                      182 183 192 193 194 195 196 197 198 199 200 201 202 203
                      204 205 206 207 208 209 210 211 212 213 214 215 223 224
                      225 226 227 228 229 230 231 232 233 234 235 236 237 238
                      239 240 241 242 243 244 245 246 247 254).
2026-10-10T07:33:45.144000Z LOG report summary reset
       table name     errors       rows      bytes      total time
-----------------  ---------  ---------  ---------  --------------
  fetch meta data          0          0                     0.000s
-----------------  ---------  ---------  ---------  --------------
-----------------  ---------  ---------  ---------  --------------
```

`mysql_native_password` is the weaker method and MySQL 8.0 calls it deprecated; 8.4 turns it off by
default. Use it for the migration, and **remove `pgloader.cnf` and drop the `migrator` user when the
migration is over**.

## Second: a collation it has never heard of

The login works now, and the next failure is stranger: `76 fell through ECASE expression`, followed
by a list of numbers. Every collation in MySQL has a number, and the client inside pgloader decodes
text by looking that number up in a table it was built with. **The table ends before MySQL 8.**
Collation 76 is `utf8mb3_tolower_ci`, which MySQL 8.0.30 and later use for column names in the
catalogue, so the very first question pgloader asks comes back in a collation it cannot decode.
The default of every table here, `utf8mb4_0900_ai_ci`, is number 255, and it is missing from the
list too.

pgloader can load code of its own at start-up with `--load-lisp-file`, and that is enough to teach
the client the missing numbers. Save this as `mysql8.lisp`:

```
;; mysql8.lisp: teach the pgloader in Ubuntu 24.04 the collations of MySQL 8.
;; Load it with: pgloader --load-lisp-file mysql8.lisp ...
;;
;; The MySQL client inside pgloader decodes text by the collation's number,
;; and its table ends before MySQL 8: 76 (utf8mb3_tolower_ci) is in every
;; catalogue query MySQL 8.0.30 and later answers, and 255 and above are the
;; utf8mb4 collations MySQL 8 made the default. All of them are UTF-8.
(in-package :qmynd-impl)

(let ((known (fdefinition 'mysql-cs-coll-to-character-encoding)))
  (setf (fdefinition 'mysql-cs-coll-to-character-encoding)
        (lambda (id)
          (if (or (= id 76) (>= id 255))
              :utf-8
              (funcall known id)))))
```

It wraps the client's lookup: the numbers MySQL 8 added are answered as UTF-8, and every other
number goes to the original table as before. **This is a workaround for one build of the tool**,
and it is printed here because it is what made this migration run. A pgloader built against a newer
version of its MySQL client may not need it; test whichever build you have against your server the
same way, with a database you do not care about.

## Third: the data

```
ana@db:~$ pgloader --load-lisp-file mysql8.lisp mysql://migrator:change-me@localhost/legacy postgresql:///legacy; echo "exit status $?"
Loading code from #P"mysql8.lisp"
2026-10-10T07:33:45.020000Z LOG pgloader version "3.6.7~devel"
2026-10-10T07:33:45.116000Z LOG Migrating from #<MYSQL-CONNECTION mysql://migrator@localhost:3306/legacy {1005EF41F3}>
2026-10-10T07:33:45.116000Z LOG Migrating into #<PGSQL-CONNECTION pgsql://ana@UNIX:5432/legacy {10060BF153}>
2026-10-10T07:33:45.488001Z ERROR Database error 23502: null value in column "birthdate" of relation "customers" violates not-null constraint
DETAIL: Failing row contains (7, customer7@example.com, Mário Customer 7, t, null, 2024-01-02 06:00:00-03).
CONTEXT: COPY customers, line 7: "7	customer7@example.com	Mário Customer 7	t	\N	2024-01-02 06:00:00"
2026-10-10T07:33:45.700001Z ERROR PostgreSQL Database error 23503: insert or update on table "orders" violates foreign key constraint "orders_customer_fk"
DETAIL: Key (customerid)=(1920) is not present in table "customers".
QUERY: ALTER TABLE legacy.orders ADD CONSTRAINT orders_customer_fk FOREIGN KEY(customerid) REFERENCES legacy.customers(customerid) ON UPDATE NO ACTION ON DELETE NO ACTION
2026-10-10T07:33:45.704001Z LOG report summary reset
             table name     errors       rows      bytes      total time
-----------------------  ---------  ---------  ---------  --------------
        fetch meta data          0          7                     0.084s
         Create Schemas          0          0                     0.004s
       Create SQL Types          0          1                     0.012s
          Create tables          0          4                     0.012s
         Set Table OIDs          0          2                     0.004s
-----------------------  ---------  ---------  ---------  --------------
       legacy.customers          1          0                     0.136s
          legacy.orders          0      10000   297.5 kB          0.132s
-----------------------  ---------  ---------  ---------  --------------
COPY Threads Completion          0          4                     0.136s
 Index Build Completion          0          4                     0.120s
         Create Indexes          0          4                     0.036s
        Reset Sequences          0          2                     0.032s
           Primary Keys          0          2                     0.004s
    Create Foreign Keys          1          0                     0.004s
        Create Triggers          0          0                     0.000s
        Set Search Path          0          1                     0.000s
       Install Comments          0          0                     0.000s
-----------------------  ---------  ---------  ---------  --------------
      Total import time          1      10000   297.5 kB          0.332s
exit status 0
```

This time it ran, and **the summary has to be read line by line**. `legacy.orders` copied every
row. `legacy.customers` has one error and **0 rows**: the whole table was refused, because pgloader
copies in batches, one bad row fails its whole batch, and this table fits in one. The first `ERROR` line says why. A zero
`BirthDate` became NULL, which is pgloader's default for a zero date, and the column kept its `NOT
NULL`. The second error follows from the first: with no customers, the foreign key from `orders`
cannot be built.

**And the exit status is 0.** A whole table missing, a foreign key never built, and pgloader told
the shell that everything went well. A script that ran it with `&& echo done` would have printed
`done`. Read the `errors` column and the row counts, every time, and then check the target yourself,
which is the next section.

## The migration as a file

Running pgloader from the command line uses its defaults for every decision. A **load file** writes
the decisions down, which is what you want for a migration you will rehearse more than once. Save
this as `legacy.load`:

```sql
-- legacy.load: the migration, with its decisions written down.
-- Run it with: pgloader --load-lisp-file mysql8.lisp legacy.load
LOAD DATABASE
     FROM mysql://migrator:change-me@localhost/legacy
     INTO postgresql:///legacy

WITH include drop, create tables, create indexes, reset sequences,
     foreign keys, downcase identifiers

CAST type date when default '0000-00-00'
          to date drop not null drop default using zero-dates-to-null;
```

`WITH` names the options this migration relies on, most of them pgloader's defaults, so that nobody
has to look them up: drop what an earlier attempt left, create the tables and indexes, move each sequence past the highest id, build the foreign keys,
and fold every name to lower case. **`CAST` is the decision the third failure asked for**: a `date`
column whose default is the zero date becomes a nullable `date`, and each zero becomes NULL. A
`DATETIME` with a zero default is already treated that way by pgloader's own rules, which is why
`orders` loaded.

```
ana@db:~$ pgloader --load-lisp-file mysql8.lisp legacy.load > load.log 2>&1; echo "exit status $?"
exit status 0
ana@db:~$ grep -E 'errors|legacy\.' load.log
             table name     errors       rows      bytes      total time
       legacy.customers          0       2001   155.7 kB          0.060s
          legacy.orders          0      10000   297.5 kB          0.056s
```

Both tables, no errors, 2,001 customers and 10,000 orders. That is what pgloader says it did. The
next section checks it.
