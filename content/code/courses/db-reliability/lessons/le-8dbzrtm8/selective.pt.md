---
title: Algumas linhas, algumas tabelas
version: 1
---

Uma publicação não precisa oferecer um banco inteiro. Ela nomeia tabelas, e desde o PostgreSQL 15 pode
filtrar as linhas delas com um `WHERE` ou listar só algumas das colunas. Ofereça apenas os clientes de
Recife, para um segundo banco no 17:

```
shop=# CREATE PUBLICATION recife_pub FOR TABLE customers WHERE (city = 'Recife');
CREATE PUBLICATION
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -c "CREATE DATABASE recife"
CREATE DATABASE
ana@vm:~$ pg_dump --schema-only --no-owner --no-privileges -t customers shop | psql -q -o /dev/null -h 127.0.0.1 -p 5440 -U postgres recife
recife=# CREATE SUBSCRIPTION recife_sub CONNECTION 'host=127.0.0.1 port=5432 dbname=shop user=replicator password=replica-pass-1' PUBLICATION recife_pub;
NOTICE:  created replication slot "recife_sub" on publisher
CREATE SUBSCRIPTION
recife=# SELECT city, count(*) FROM customers GROUP BY city;
  city  | count 
--------+-------
 Recife |   250
(1 row)
```

250 clientes, todos em Recife: um quarto da tabela, o quarto que o filtro seleciona. Um escritório
regional que deve ver os próprios clientes e os de mais ninguém, um servidor de relatórios que precisa
de três tabelas entre quarenta, um sistema de busca que quer a tabela de produtos e nenhum dado pessoal:
cada um é uma publicação, e nenhum deles precisa de uma cópia de tudo.

Cada subscription também é mais um slot no publisher (`recife_sub` fica ao lado de `shop_sub`), e cada
uma é um acúmulo de log esperando para acontecer se o subscriber dela parar. O `lagcheck.sh` da lição 13
lê o `pg_stat_replication`, onde elas também aparecem, com o nome da subscription.
