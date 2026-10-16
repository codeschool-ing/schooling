---
title: Wraparound, o contador que não pode acabar
version: 1
---

Toda transação que altera alguma coisa recebe um número, e `xmin` e `xmax` são esses números.
**Eles têm 32 bits**, cerca de quatro bilhões de valores, e um servidor movimentado gasta um bilhão
em um ou dois anos. Por isso os números são comparados num círculo: a partir de qualquer transação,
dois bilhões estão no passado e dois bilhões no futuro. Uma linha escrita pela transação 782 está
no passado para a transação 805. Dois bilhões de transações depois, a mesma 782 cairia no futuro, e
**a linha sumiria** de toda consulta sem que ninguém a tivesse apagado.

O congelamento é o que impede isso. Uma linha congelada é visível para todos, diga o número o que
disser, então o `xmin` dela não entra mais na comparação. Cada tabela registra em `relfrozenxid` a
transação não congelada mais antiga que ainda pode conter, cada banco registra em `datfrozenxid` a
mais antiga das suas tabelas, e `age()` transforma qualquer um dos dois numa contagem de transações:

```
shop=# SELECT datname, age(datfrozenxid) FROM pg_database;
  datname  | age 
-----------+-----
 postgres  |  84
 ana       |  84
 template1 |  84
 template0 |  84
 shop      |  84
(5 rows)

shop=# SELECT relname, age(relfrozenxid) FROM pg_class WHERE relkind = 'r' ORDER BY 2 DESC LIMIT 3;
     relname      | age 
------------------+-----
 pg_foreign_table |  84
 pg_type          |  84
 pg_authid        |  84
(3 rows)

shop=# SHOW autovacuum_freeze_max_age;
 autovacuum_freeze_max_age 
---------------------------
 200000000
(1 row)
```

O servidor de `shop` é jovem, então toda idade é de poucas dezenas. **`autovacuum_freeze_max_age`
é a linha**: uma tabela cuja idade passa de 200 milhões recebe um autovacuum agressivo, que lê toda
página ainda não congelada, seja qual for a situação das linhas mortas. Ele roda mesmo com o
`autovacuum` desligado, e não sai da frente quando alguém quer uma trava na tabela, como faz um
autovacuum comum. Numa tabela grande em que ninguém pensou, essa passada agressiva muitas vezes é a
primeira vez que alguém repara no autovacuum, porque ela lê a tabela inteira numa hora que ninguém
escolheu.

## Como é quando isso não funciona

Esperar dois bilhões de transações para ver o fim não é prático. O `pg_resetwal` consegue definir
diretamente o próximo id de transação de um cluster parado, e isso basta para ver o fim num
**cluster de rascunho criado para isso**, nunca num que importe. O `pg_resetwal` joga fora o
write-ahead log, o que num cluster de verdade perde dados. O `dd` cria o pedaço do commit log, em
`pg_xact`, de que o novo id de transação precisa; sem ele o servidor não conseguiria registrar se
essa transação fez commit:

```
ana@db:~$ sudo pg_createcluster 16 wrap >/dev/null
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_resetwal -x 2145000000 /var/lib/postgresql/16/wrap
Write-ahead log reset
ana@db:~$ sudo -u postgres dd if=/dev/zero of=/var/lib/postgresql/16/wrap/pg_xact/07FD bs=256k count=1 status=none
ana@db:~$ sudo pg_ctlcluster 16 wrap start
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT datname, age(datfrozenxid) FROM pg_database;"
  datname  |    age     
-----------+------------
 postgres  | 2144999278
 template1 | 2144999278
 template0 | 2144999278
(3 rows)

ana@db:~$ sudo -u postgres psql -p 5433 -c "CREATE TABLE t (i int);"
ERROR:  database is not accepting commands to avoid wraparound data loss in database "template1"
HINT:  Stop the postmaster and vacuum that database in single-user mode.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT count(*) FROM pg_class;"
 count 
-------
   413
(1 row)
```

As idades são 2.144.999.278, logo abaixo de 2.147.483.648, onde o círculo viraria. **O servidor
recusa tudo o que precisa de um novo id de transação** e continua atendendo leituras: o
`CREATE TABLE` falha, o `count(*)` funciona. Ele faz isso 3 milhões de transações antes do ponto
sem volta, e a partir de 40 milhões antes cada novo id de transação vem com um aviso no log. Esses
avisos são o alarme que um servidor monitorado teria dado semanas antes; este cluster pulou por
cima deles.

A saída é um VACUUM que congele todos os bancos:

```
ana@db:~$ sudo -u postgres vacuumdb -p 5433 --all --freeze 2> vacuum.log
vacuumdb: vacuuming database "postgres"
vacuumdb: vacuuming database "template1"
ana@db:~$ grep -c "as a failsafe" vacuum.log
216
ana@db:~$ grep -m1 -A3 "as a failsafe" vacuum.log
WARNING:  bypassing nonessential maintenance of table "postgres.pg_catalog.pg_proc" as a failsafe after 0 index scans
DETAIL:  The table's relfrozenxid or relminmxid is too far in the past.
HINT:  Consider increasing configuration parameter "maintenance_work_mem" or "autovacuum_work_mem".
You might also need to consider other ways for VACUUM to keep up with the allocation of transaction IDs.
ana@db:~$ grep -A2 "must be vacuumed" vacuum.log
WARNING:  database "template1" must be vacuumed within 2484369 transactions
HINT:  To avoid a database shutdown, execute a database-wide VACUUM in that database.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
--
WARNING:  database "template0" must be vacuumed within 2484369 transactions
HINT:  To avoid a database shutdown, execute a database-wide VACUUM in that database.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

**`as a failsafe`** apareceu 216 vezes. Passado o `vacuum_failsafe_age`, 1,6 bilhão por padrão, o
VACUUM larga tudo o que não seja congelar: nada de limpeza de índice, nada de freio, só trazer a
idade de volta para baixo. Os avisos no fim nomeiam os bancos ainda em risco.

```
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT datname, datallowconn, age(datfrozenxid) FROM pg_database;"
  datname  | datallowconn |    age     
-----------+--------------+------------
 postgres  | t            |          0
 template1 | t            |          0
 template0 | f            | 2144999278
(3 rows)
```

`postgres` e `template1` estão em 0. **`template0` não**, porque não aceita conexões e o
`vacuumdb --all` o pula, então o servidor continua recusando. Esse fica com o autovacuum, que
consegue alcançá-lo, e em cerca de um minuto tinha feito:

```
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT datname, datallowconn, age(datfrozenxid) FROM pg_database;"
  datname  | datallowconn | age 
-----------+--------------+-----
 postgres  | t            |   0
 template1 | t            |   0
 template0 | f            |   0
(3 rows)

ana@db:~$ sudo -u postgres psql -p 5433 -c "CREATE TABLE t (i int);"
CREATE TABLE
ana@db:~$ sudo pg_dropcluster --stop 16 wrap
```

A dica na recusa manda parar o servidor e rodar o vacuum em modo de usuário único. Aqui um
`vacuumdb` comum, com o servidor no ar e ainda atendendo leituras, fez o trabalho, e o autovacuum
fez o resto. Parar o servidor o tira de todo mundo, então tente primeiro o caminho comum.

Neste cluster a emergência inteira levou um minuto, porque ele quase não guarda nada. Num servidor
com uma tabela de dois terabytes, o mesmo congelamento lê dois terabytes enquanto a aplicação não
consegue escrever, e pode levar boa parte de um dia. **A cura é nunca chegar lá**: acompanhe
`age(datfrozenxid)` como a primeira consulta acima faz, e trate como incidente uma idade que
continua subindo além de `autovacuum_freeze_max_age`. Isso quer dizer que o autovacuum não
consegue terminar, em geral por um motivo que a seção anterior já nomeou.
