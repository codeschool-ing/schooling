---
title: PostgreSQL e MySQL numa máquina
version: 1
---

O jeito mais rápido de ver a máquina em comum é pôr dois motores num servidor e fazer a cada um as
mesmas perguntas. **As transcrições abaixo são para ler agora**: o servidor em que rodaram é o que a
lição 3 monta, com o MySQL 8.0 instalado ao lado do PostgreSQL pelo arquivo do próprio Ubuntu. Quando
tiver o seu, você pode repeti-las com mais um comando, e nada adiante no curso depende disso:

```sh
sudo apt install -y mysql-server-8.0
```

Dois servidores, duas versões, e do lado do sistema operacional, dois programas:

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

**O PostgreSQL são seis processos e o MySQL é um.** O postmaster e seus processos de fundo têm uma
linha cada, enquanto o `mysqld` faz os mesmos trabalhos em threads dentro de um único processo, que
o `ps` não lista a não ser que se peça. Cada conexão ao PostgreSQL vai acrescentar uma linha aqui;
uma conexão ao MySQL acrescenta uma thread.

## Onde cada um guarda os dados

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

A mesma ideia, um diretório que pertence ao usuário do próprio servidor, com outros móveis. O
`ibdata1` e os arquivos `undo_` são o espaço compartilhado do InnoDB e o seu undo log. O
`#innodb_redo` é o redo log, o equivalente do `pg_wal`, e os arquivos `binlog.` são o binary log que a
seção anterior descreveu. Cada database é um subdiretório, como em `base/` no PostgreSQL, só que o
MySQL usa o nome do database em vez de um número.

O `sudo mysql` conectou sem senha pelo mesmo motivo que o `sudo -u postgres psql` conecta no
PostgreSQL: o MySQL do Ubuntu deixa o `root` do sistema operacional entrar como o `root` do banco,
perguntando ao kernel quem está do outro lado do socket. Outro nome, o mesmo mecanismo.

## Bancos, ou esquemas

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

Os dois começam com alguns bancos próprios. Agora peça a cada um um banco e um esquema:

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

No MySQL, o `CREATE SCHEMA billing` criou algo listado pelo `SHOW DATABASES`, ao lado do `shop`: **as
duas palavras são uma coisa só**. No PostgreSQL o esquema foi para dentro do banco `ana`, ao lado do
`public`, o esquema com que todo banco começa, e o `\l` nem o listaria.

## Quem pode conectar

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

O MySQL identifica uma conta por **um usuário e um host juntos**: `root@localhost` é uma conta, e o
`root` conectando de outra máquina seria outra, com senha e privilégios próprios. A coluna `plugin` é
como cada um prova quem é — `auth_socket` é a verificação peer, e `caching_sha2_password` é uma
senha. O PostgreSQL guarda quem-pode-conectar-de-onde num arquivo separado, o `pg_hba.conf`, que a
lição 5 lê, e os papéis dele não carregam host nenhum.

## Onde cada um escreve sobre si mesmo

```
ana@db:~$ sudo ls /var/log/mysql /var/log/postgresql
/var/log/mysql:
error.log

/var/log/postgresql:
postgresql-16-main.log
```

Um arquivo cada, os dois em `/var/log`, os dois legíveis por administradores. Quando qualquer um dos
servidores não sobe, esse é o primeiro arquivo a abrir.
