---
title: PostgreSQL and MySQL on one machine
version: 1
---

The quickest way to see the shared machine is to put two engines on one server and ask each the
same questions. **The transcripts below are for reading now**: the server they ran on is the one
lesson 3 builds, with MySQL 8.0 installed beside PostgreSQL from Ubuntu's own archive. Once you have
yours, you can repeat them with one more command, and nothing later in the course depends on it:

```sh
sudo apt install -y mysql-server-8.0
```

Two servers, two versions, and from the operating system's side, two programs:

```
ana@db:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@db:~$ mysql --version
mysql  Ver 8.0.46-0ubuntu0.24.04.4 for Linux on x86_64 ((Ubuntu))
```

```
ana@db:~$ ps -eo user,pid,cmd | grep -E "^(postgres|mysql) " | grep -v grep
postgres      98 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
postgres     102 postgres: 16/main: checkpointer 
postgres     103 postgres: 16/main: background writer 
postgres     105 postgres: 16/main: walwriter 
postgres     106 postgres: 16/main: autovacuum launcher 
postgres     107 postgres: 16/main: logical replication launcher 
mysql        816 /usr/sbin/mysqld
```

**PostgreSQL is six processes and MySQL is one.** The postmaster and its workers each have a line,
while `mysqld` does the same jobs in threads inside a single process, which `ps` does not list
unless asked. Every connection to PostgreSQL will add a line here; a connection to MySQL adds a
thread.

## Where each keeps its data

```
ana@db:~$ psql -XAtc "SHOW data_directory"
/var/lib/postgresql/16/main
ana@db:~$ sudo mysql -N -e "SELECT @@datadir"
/var/lib/mysql/
ana@db:~$ sudo ls /var/lib/mysql
#ib_16384_0.dblwr
#ib_16384_1.dblwr
#innodb_redo
#innodb_temp
auto.cnf
binlog.000001
binlog.000002
binlog.000003
binlog.index
ca-key.pem
ca.pem
client-cert.pem
client-key.pem
db.pid
debian-5.7.flag
ib_buffer_pool
ibdata1
ibtmp1
mysql
mysql.ibd
performance_schema
private_key.pem
public_key.pem
server-cert.pem
server-key.pem
sys
undo_001
undo_002
```

The same idea, a directory owned by the server's own user, with different furniture. `ibdata1` and
the `undo_` files are InnoDB's shared space and its undo log; `#innodb_redo` is the redo log, the
counterpart of `pg_wal`; the `binlog.` files are the binary log the last section described; and each
database is a subdirectory, as under PostgreSQL's `base/`, except that MySQL names it after the
database rather than by a number.

`sudo mysql` connected without a password for the same reason `sudo -u postgres psql` does on
PostgreSQL: Ubuntu's MySQL lets the operating system's `root` in as the database's `root`, by asking
the kernel who is on the other end of the socket. Different name, same mechanism.

## Databases, or schemas

```
ana=# \l
                                                   List of databases
   Name    |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 ana       | ana      | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
(4 rows)
ana@db:~$ sudo mysql -t -e "SHOW DATABASES"
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

Both start with a few databases of their own. Now ask each for a database and a schema:

```
ana@db:~$ sudo mysql -t -e "CREATE DATABASE shop; CREATE SCHEMA billing; SHOW DATABASES"
+--------------------+
| Database           |
+--------------------+
| billing            |
| information_schema |
| mysql              |
| performance_schema |
| shop               |
| sys                |
+--------------------+
ana=# CREATE SCHEMA billing;
CREATE SCHEMA

ana=# \dn
       List of schemas
  Name   |       Owner       
---------+-------------------
 billing | ana
 public  | pg_database_owner
(2 rows)
```

In MySQL, `CREATE SCHEMA billing` made something listed by `SHOW DATABASES`, beside `shop`: **the two
words are one thing**. In PostgreSQL the schema went inside the database `ana`, next to `public`, the
schema every database starts with, and `\l` would not list it at all.

## Who may connect

```
ana@db:~$ sudo mysql -t -e "SELECT user, host, plugin FROM mysql.user"
+------------------+-----------+-----------------------+
| user             | host      | plugin                |
+------------------+-----------+-----------------------+
| debian-sys-maint | localhost | caching_sha2_password |
| mysql.infoschema | localhost | caching_sha2_password |
| mysql.session    | localhost | caching_sha2_password |
| mysql.sys        | localhost | caching_sha2_password |
| root             | localhost | auth_socket           |
+------------------+-----------+-----------------------+
ana=# SELECT rolname, rolsuper, rolcanlogin FROM pg_roles WHERE rolname NOT LIKE 'pg\_%';
 rolname  | rolsuper | rolcanlogin 
----------+----------+-------------
 postgres | t        | t
 ana      | t        | t
(2 rows)
```

MySQL identifies an account by a **user and a host together**: `root@localhost` is one account, and
`root` connecting from another machine would be a different one, with its own password and its own
privileges. The `plugin` column is how each proves who it is — `auth_socket` is the peer check, and
`caching_sha2_password` is a password. PostgreSQL keeps who-may-connect-from-where in a separate
file, `pg_hba.conf`, which lesson 5 reads, and its roles carry no host at all.

## Where each writes about itself

```
ana@db:~$ sudo ls /var/log/mysql /var/log/postgresql
/var/log/mysql:
error.log

/var/log/postgresql:
postgresql-16-main.log
```

One file each, both under `/var/log`, both readable by administrators. When either server will not
start, that is the first file to open.
