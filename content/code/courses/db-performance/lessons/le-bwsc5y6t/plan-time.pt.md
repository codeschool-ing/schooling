---
title: Podando quando a consulta é planejada
version: 1
---

A aula 17 construiu `events_by_month` e mostrou que uma tabela particionada faz **mais** trabalho numa
consulta que não menciona a chave de partição. Esta aula é o outro lado: o que ela faz por uma
consulta que menciona. O mecanismo é a **poda de partições** (partition pruning), o planejador
deixando fora do plano toda partição cujos limites não podem conter uma linha que satisfaça a
condição, e ela acontece em dois momentos. Esta seção é o primeiro e o mais simples, quando a
consulta é planejada.

Esta aula começa onde a aula 17 deixou `market`: o ponto de partida da aula 3, mais `events_by_month`
construída pelo arquivo da aula 17. Se você rodou o `~/reset-market.sh` desde então, rode `psql market
-f events_by_month.sql` de novo antes. Confira que ela está lá:

```
market=# \d events_by_month
               Partitioned table "public.events_by_month"
   Column    |           Type           | Collation | Nullable | Default 
-------------+--------------------------+-----------+----------+---------
 id          | bigint                   |           | not null | 
 at          | timestamp with time zone |           | not null | 
 customer_id | integer                  |           |          | 
 kind        | text                     |           | not null | 
 payload     | jsonb                    |           | not null | 
Partition key: RANGE (at)
Indexes:
    "events_by_month_pkey" PRIMARY KEY, btree (id, at)
    "events_by_month_customer_id_idx" btree (customer_id)
Number of partitions: 4 (Use \d+ to list them.)
```

## Um dia, uma partição

Conte os eventos de um dia, 10 de novembro, e peça o plano:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-11-10' AND at < '2025-11-11';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Seq Scan on events_2025_11 events_by_month
                     Filter: ((at >= '2025-11-10 00:00:00-03'::timestamp with time zone) AND (at < '2025-11-11 00:00:00-03'::timestamp with time zone))
(6 rows)

Time: 2.107 ms
```

**Uma leitura, em `events_2025_11`.** O planejador comparou a condição, `at` do dia 10 ao dia 11 de
novembro, com os limites de cada partição, viu que só o intervalo de novembro se sobrepõe a ela, e
montou um plano só com essa partição. As outras três nem estão no plano, e nunca são abertas. Sem
condição em `at`, a mesma contagem lê as quatro:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month;
                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Append
                     ->  Parallel Index Only Scan using events_2025_12_customer_id_idx on events_2025_12 events_by_month_3
                     ->  Parallel Index Only Scan using events_2025_11_customer_id_idx on events_2025_11 events_by_month_2
                     ->  Parallel Index Only Scan using events_2025_10_customer_id_idx on events_2025_10 events_by_month_1
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4
(9 rows)

Time: 1.844 ms
```

Um `Append`, o nó que lê vários filhos um depois do outro, sobre **quatro** partições. E uma condição
que atravessa uma fronteira fica exatamente com as partições a que se sobrepõe:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-12-20';
                                          QUERY PLAN                                          
----------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Append
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_1
                           Filter: (at >= '2025-12-20 00:00:00-03'::timestamp with time zone)
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_2
                           Filter: (at >= '2025-12-20 00:00:00-03'::timestamp with time zone)
(9 rows)

Time: 0.972 ms
```

Do dia 20 de dezembro em diante são dezembro e janeiro, então o plano tem essas duas. Os limites são
comparados com os **valores escritos na consulta**, e é isso que faz desta a poda em tempo de
planejamento: tudo de que o planejador precisa está no texto do comando.

## Quanto ela vale

A mesma contagem de um dia, na tabela `events` comum e em `events_by_month`, com os planos executados:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events WHERE at >= '2025-11-10' AND at < '2025-11-11';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=212.754..216.575 rows=1 loops=1)
   ->  Gather (actual time=211.446..216.556 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=208.630..208.632 rows=1 loops=3)
               ->  Parallel Seq Scan on events (actual time=86.286..207.487 rows=18565 loops=3)
                     Filter: ((at >= '2025-11-10 00:00:00-03'::timestamp with time zone) AND (at < '2025-11-11 00:00:00-03'::timestamp with time zone))
                     Rows Removed by Filter: 1648102
 Planning Time: 0.407 ms
 Execution Time: 216.684 ms
(10 rows)

Time: 218.378 ms

market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-11-10' AND at < '2025-11-11';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=45.322..48.230 rows=1 loops=1)
   ->  Gather (actual time=45.152..48.216 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=42.091..42.093 rows=1 loops=3)
               ->  Parallel Seq Scan on events_2025_11 events_by_month (actual time=11.509..41.294 rows=18565 loops=3)
                     Filter: ((at >= '2025-11-10 00:00:00-03'::timestamp with time zone) AND (at < '2025-11-11 00:00:00-03'::timestamp with time zone))
                     Rows Removed by Filter: 537129
 Planning Time: 0.582 ms
 Execution Time: 48.271 ms
(10 rows)

Time: 49.498 ms
```

Em `events`, uma leitura sequencial da tabela inteira: cada um dos três workers ficou em média com
18565 linhas e jogou fora **1648102**. Em `events_by_month`, o mesmo tipo de leitura sobre **um mês**:
537129 jogadas fora por worker. **216,7 contra 48,3 milissegundos**, umas quatro vezes e meia mais
rápido, pelo motivo que a aula 17 prometeu: a consulta menciona a chave, então o servidor lê um mês em
três.

É esse o ganho que as pessoas esperam do particionamento, e agora as condições dele podem ser ditas.
Ele precisa de **uma condição na chave de partição** que o planejador consiga comparar com os limites,
e paga na proporção da parte da tabela que pula. Uma consulta sobre um dia de três meses pula dois
terços da tabela. Uma consulta sobre o período inteiro não pula nada e paga o custo extra da busca por
id da aula 17.

Também vale ver o que ela não é. As 18565 linhas do dia por worker ainda são achadas lendo **o mês
inteiro**: a poda escolheu a partição, e dentro dela o servidor fez uma leitura sequencial, porque
nada indexa `at`. Um índice em `at` acharia as linhas do dia direto, com ou sem partições, e o BRIN da
aula 8 é um que combina com uma tabela gravada em ordem de tempo. Poda e índice respondem a perguntas
diferentes: em que pedaço da tabela procurar, e onde dentro dele.
