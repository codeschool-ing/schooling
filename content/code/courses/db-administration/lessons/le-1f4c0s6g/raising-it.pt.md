---
title: O que custa aumentá-lo
version: 1
---

Quando uma aplicação começa a falhar com `too many clients`, o movimento óbvio é aumentar o
`max_connections`, e funciona no sentido de que o erro para. O problema é o que isso custa, e que
raramente resolve o que estava errado. Aumente para mil e olhe:

```
ana@db:~$ psql shop -c "ALTER SYSTEM SET max_connections = 1000"
ALTER SYSTEM
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ psql shop -c "SHOW max_connections" -c "SHOW shared_memory_size"
 max_connections 
-----------------
 1000
(1 row)

 shared_memory_size 
--------------------
 184MB
(1 row)
```

## Memória antes de alguém conectar

**Cada vaga é paga na partida, seja usada ou não.** O servidor reserva memória compartilhada por
vaga para a contabilidade de um backend que talvez nunca exista: a entrada dele nas tabelas de
locks, o lugar dele na lista de transações em andamento. A seção anterior viu 139 MB com cinco vagas
e 143 MB com cem; mil vagas pedem 184 MB, cerca de 46 kB para cada uma das 900 acrescentadas. Nesta
máquina isso é pouco, e é a parte mais barata.

## Memória por conexão

Uma conexão que existe usa memória própria, e ela cresce conforme o backend trabalha. Um backend
consegue informar a sua:

```
ana@db:~$ psql shop
shop=# SELECT pg_size_pretty(sum(total_bytes)) FROM pg_backend_memory_contexts;
 pg_size_pretty 
----------------
 1504 kB
(1 row)

shop=# \d+ orders
                                                               Table "public.orders"
   Column    |           Type           | Collation | Nullable |           Default            | Storage  | Compression | Stats target | Description 
-------------+--------------------------+-----------+----------+------------------------------+----------+-------------+--------------+-------------
 id          | bigint                   |           | not null | generated always as identity | plain    |             |              | 
 customer_id | bigint                   |           | not null |                              | plain    |             |              | 
 status      | text                     |           | not null |                              | extended |             |              | 
 total_cents | integer                  |           | not null |                              | plain    |             |              | 
 created_at  | timestamp with time zone |           | not null |                              | plain    |             |              | 
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
    "orders_created_at" btree (created_at)
    "orders_customer_id" btree (customer_id)
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id)
Access method: heap

shop=# SELECT pg_size_pretty(sum(total_bytes)) FROM pg_backend_memory_contexts;
 pg_size_pretty 
----------------
 2154 kB
(1 row)
```

Um backend novo tinha 1504 kB, e descrever uma tabela o levou a 2154 kB, porque as consultas por
trás do `\d+` encheram os caches privados do catálogo desse backend. A conexão de uma aplicação que
tocou todas as tabelas por horas guarda muito mais, e nada disso é compartilhado. Depois, cada
ordenação ou hash que uma consulta roda pode pegar até `work_mem` por cima, o que a lição 6 calculou
para um servidor cheio. **Mil conexões são mil vezes tudo isso**, e o pior caso é o que decide se a
máquina fica sem memória.

## A vazão não acompanha

A surpresa maior são os processadores. O `pgbench`, que vem com o PostgreSQL, roda uma carga pequena
e padronizada contra um banco próprio; o `--select-only` faz de cada transação uma busca pela chave
primária, então o disco sai da conta e só os processadores contam. Dê a ele um banco e rode com
quatro clientes e depois com oitenta:

```
ana@db:~$ createdb bench
ana@db:~$ pgbench --initialize --quiet --scale=10 bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
1000000 of 1000000 tuples (100%) done (elapsed 0.91 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.35 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.94 s, vacuum 0.14 s, primary keys 0.27 s).
ana@db:~$ pgbench --select-only --client=4 --jobs=4 --time=15 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 10
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 1358800
number of failed transactions: 0 (0.000%)
latency average = 0.044 ms
initial connection time = 10.639 ms
tps = 90620.117573 (without initial connection time)
ana@db:~$ pgbench --select-only --client=80 --jobs=4 --time=15 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 10
query mode: simple
number of clients: 80
number of threads: 4
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 813516
number of failed transactions: 0 (0.000%)
latency average = 1.470 ms
initial connection time = 92.567 ms
tps = 54424.941721 (without initial connection time)
```

O `--scale=10` criou um milhão de linhas em `pgbench_accounts`. **Vinte vezes mais clientes fizeram
menos trabalho**: 90.620 transações por segundo com quatro, 54.425 com oitenta. E cada transação
esperou muito mais, 0,044 ms em média com quatro clientes e 1,470 ms com oitenta. A máquina de
gravação tem quatro processadores, então oitenta backends se revezaram neles, com o kernel alternando
entre eles e os backends disputando as mesmas estruturas compartilhadas. A lição 22 do
`db-performance` trata de rodar benchmarks direito; estes números são da máquina de gravação, com o
próprio `pgbench` disputando os mesmos quatro processadores, e os seus serão diferentes.

**Mais conexões do que processadores não somam vazão; somam espera.** A solução de verdade para uma
aplicação que fica sem conexões costuma ser que ela as segura por tempo demais ou abre conexões
demais, e as duas próximas seções são esses dois casos. Ponha a configuração de volta antes de
seguir:

```
ana@db:~$ psql shop -c "ALTER SYSTEM RESET max_connections"
ALTER SYSTEM
ana@db:~$ sudo systemctl restart postgresql@16-main
```

O `ALTER SYSTEM RESET` removeu a linha do `postgresql.auto.conf`, que a lição 5 mostrou, então o
padrão de 100 volta a valer.
