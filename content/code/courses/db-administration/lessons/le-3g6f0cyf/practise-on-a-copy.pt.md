---
title: Ensaie numa cópia
version: 1
---

Um upgrade maior falha de jeitos que um menor não consegue. Uma extensão não tem versão compilada
para a versão nova. Um parâmetro do `postgresql.conf` mudou de nome. O disco tem espaço para uma
cópia dos dados e o método escolhido precisa de duas. A aplicação usa uma função cujo comportamento
mudou. **Cada uma dessas coisas é barata de achar numa cópia e cara de achar no servidor que todo
mundo usa**, por isso um upgrade maior sempre roda pelo menos uma vez em algo que não é produção.

A melhor cópia é uma máquina separada, restaurada do backup da noite anterior, porque isso também
prova que o backup funciona; restaurar um é o assunto das lições 1 a 10 de db-reliability. No seu
servidor há uma cópia mais barata que ensina os mesmos passos: **um segundo cluster ao lado do
`16/main`**, feito só para esta lição. A lição 3 disse que o postgresql-common roda vários clusters
lado a lado, e é para isso que serve. O `16/main` nunca é parado, nunca passa por upgrade e nunca
recebe uma escrita no que vem a seguir. Anote quando ele subiu pela última vez, para que o fim da
lição possa provar isso:

```sh
psql -c "SELECT pg_postmaster_start_time();"
```

## Um segundo cluster

```
ana@db:~$ sudo pg_createcluster 16 rehearsal --start
Creating new PostgreSQL cluster 16/rehearsal ...
/usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/rehearsal --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/16/rehearsal ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Ver Cluster   Port Status Owner    Data directory                   Log file
16  rehearsal 5433 online postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
```

O `pg_createcluster` rodou o `initdb` para um diretório de dados novo, escreveu uma configuração em
`/etc/postgresql/16/rehearsal` e **escolheu a próxima porta livre, 5433**, porque o `main` ocupa a
5432. Todo comando dirigido ao ensaio daqui em diante leva `-p 5433`; um comando sem isso vai para o
`main`.

```
ana@db:~$ pg_lsclusters 16
Ver Cluster   Port Status Owner    Data directory                   Log file
16  main      5432 online postgres /var/lib/postgresql/16/main      /var/log/postgresql/postgresql-16-main.log
16  rehearsal 5433 online postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
```

O cluster novo está vazio: tem o papel `postgres` e mais nada, nem um papel para você. Copie tudo
num pipe só. O `pg_dumpall` escreve o `main` inteiro como SQL — primeiro os papéis, depois cada
banco — e o `psql` no ensaio executa isso:

```
ana@db:~$ sudo -u postgres pg_dumpall | sudo -u postgres psql -q -p 5433 >/dev/null
ERROR:  role "postgres" already exists
ana@db:~$ psql -p 5433 -c "SELECT count(*) FROM orders;" shop
  count  
---------
 1000000
(1 row)
```

O único erro é esperado. O dump começa criando o papel `postgres`, e o cluster novo já tem um, então
esse comando falha e o resto segue. O `>/dev/null` jogou fora a saída comum dos comandos; um erro vai
para a outra saída e teria aparecido do mesmo jeito. O milhão de pedidos chegou.

## Deixe parecido com produção

Um ensaio vale o quanto se parece com a coisa real, e o que mais provavelmente quebra um upgrade
maior é uma **extensão**. Pergunte a cada banco do servidor real com `\dx` e dê à cópia a mesma
lista. Se as extensões que as lições 15 e 18 criaram ainda estão no seu `shop`, a cópia as trouxe
junto, e a recusa da próxima seção vai nomear mais delas do que a gravação. **O `shop` da máquina da
gravação não tem nenhuma**, então ela deu ao ensaio duas que representam os dois tipos que existem.
A `pg_stat_statements` vem com o próprio PostgreSQL, em toda versão. A `pg_repack`, que a lição 15
usou, é um projeto separado, empacotado uma vez para cada versão maior, como `postgresql-16-repack`:

```sh
sudo apt install -y postgresql-16-repack
```

```
ana@db:~$ psql -p 5433 shop
shop=# CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION

shop=# CREATE EXTENSION pg_repack;
CREATE EXTENSION

shop=# \dx
                                            List of installed extensions
        Name        | Version |   Schema   |                              Description                               
--------------------+---------+------------+------------------------------------------------------------------------
 pg_repack          | 1.5.0   | public     | Reorganize tables in PostgreSQL databases with minimal locks
 pg_stat_statements | 1.10    | public     | track planning and execution statistics of all SQL statements executed
 plpgsql            | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)

shop=# \q
```

Guarde esses dois números de versão, `1.5.0` e `1.10`. A próxima seção faz o upgrade deste cluster
para o 17, e cada extensão causa um problema diferente lá.
