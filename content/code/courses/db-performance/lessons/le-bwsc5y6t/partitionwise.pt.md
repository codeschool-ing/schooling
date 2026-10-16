---
title: Agregações e joins partição por partição
version: 1
---

A poda decide quais partições uma consulta lê. Duas outras configurações decidem se o planejador pode
tratar as partições como pedaços separados de trabalho depois de tê-las: a **agregação por
partição** (partitionwise aggregate) e o **join por partição** (partitionwise join). As duas vêm
desligadas, e o motivo é o da seção anterior: elas deixam o planejador considerar mais planos por
partição, e o tempo de planejamento cresce com isso.

## Agregando partição por partição

Conte os eventos de cada tipo na tabela inteira, primeiro com o padrão e depois com a configuração
ligada:

```
market=# SHOW enable_partitionwise_aggregate;
 enable_partitionwise_aggregate 
--------------------------------
 off
(1 row)

Time: 0.455 ms

market=# SELECT kind, count(*) FROM events_by_month GROUP BY kind;
   kind   |  count  
----------+---------
 cart     |  500558
 checkout |  500211
 search   |  999127
 view     | 3000104
(4 rows)

Time: 364.303 ms

market=# SET enable_partitionwise_aggregate = on;
SET
Time: 0.362 ms

market=# EXPLAIN (COSTS OFF) SELECT kind, count(*) FROM events_by_month GROUP BY kind;
                                     QUERY PLAN                                      
-------------------------------------------------------------------------------------
 Finalize GroupAggregate
   Group Key: events_by_month_2.kind
   ->  Sort
         Sort Key: events_by_month_2.kind
         ->  Gather
               Workers Planned: 2
               ->  Parallel Append
                     ->  Partial HashAggregate
                           Group Key: events_by_month_2.kind
                           ->  Parallel Seq Scan on events_2025_12 events_by_month_2
                     ->  Partial HashAggregate
                           Group Key: events_by_month_1.kind
                           ->  Parallel Seq Scan on events_2025_11 events_by_month_1
                     ->  Partial HashAggregate
                           Group Key: events_by_month.kind
                           ->  Parallel Seq Scan on events_2025_10 events_by_month
                     ->  Partial HashAggregate
                           Group Key: events_by_month_3.kind
                           ->  Parallel Seq Scan on events_2026_01 events_by_month_3
(19 rows)

Time: 0.726 ms

market=# SELECT kind, count(*) FROM events_by_month GROUP BY kind;
   kind   |  count  
----------+---------
 cart     |  500558
 checkout |  500211
 search   |  999127
 view     | 3000104
(4 rows)

Time: 292.783 ms
```

Com ela ligada, o plano agrega **cada partição sozinha**: um `Partial HashAggregate` sob o `Append`
para cada mês, e um `Finalize GroupAggregate` acima, que junta quatro resultados pequenos num só. Sem
ela, as linhas das quatro partições são emendadas primeiro e agregadas juntas.

As duas execuções levaram **364 e 293 milissegundos**. A diferença é real nesta transcrição e pequena
o bastante para o ruído da aula 1 engolir boa parte dela, então leia como "não ficou mais lento", e
não como um ganho com que contar. Os casos em que ela paga claramente são dois: quando o `GROUP BY`
inclui a chave de partição, de modo que os grupos de cada partição já são finais e nada precisa ser
combinado; e quando a agregação de cada partição cabe na memória e a da tabela inteira não caberia.

## Fazendo o join partição por partição

Um join entre duas tabelas **particionadas do mesmo jeito** — a mesma chave, os mesmos limites — pode
ser feito como um join por par de partições, outubro com outubro e novembro com novembro, em vez de um
join de tudo com tudo. Juntando `events_by_month` com ela mesma pela chave, com a configuração ligada:

```
market=# SET enable_partitionwise_join = on;
SET
Time: 0.399 ms

market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month AS a JOIN events_by_month AS b USING (id, at);
                                 QUERY PLAN                                 
----------------------------------------------------------------------------
 Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Parallel Append
               ->  Parallel Hash Join
                     Hash Cond: ((a_3.id = b_3.id) AND (a_3.at = b_3.at))
                     ->  Parallel Seq Scan on events_2025_12 a_3
                     ->  Parallel Hash
                           ->  Parallel Seq Scan on events_2025_12 b_3
               ->  Parallel Hash Join
                     Hash Cond: ((a_2.id = b_2.id) AND (a_2.at = b_2.at))
                     ->  Parallel Seq Scan on events_2025_11 a_2
                     ->  Parallel Hash
                           ->  Parallel Seq Scan on events_2025_11 b_2
               ->  Parallel Hash Join
                     Hash Cond: ((a_1.id = b_1.id) AND (a_1.at = b_1.at))
                     ->  Parallel Seq Scan on events_2025_10 a_1
                     ->  Parallel Hash
                           ->  Parallel Seq Scan on events_2025_10 b_1
               ->  Nested Loop
                     Join Filter: ((a_4.id = b_4.id) AND (a_4.at = b_4.at))
                     ->  Parallel Seq Scan on events_2026_01 a_4
                     ->  Seq Scan on events_2026_01 b_4
(23 rows)

Time: 21.070 ms
```

Quatro joins sob um `Append`, cada um pareando um mês com o mesmo mês, e cada um construindo uma
tabela hash de um mês em vez de três. O par vazio de janeiro ganha um nested loop, que não custa nada
para duas tabelas vazias.

A condição é tudo, e a tabela diária mostra isso. Junte `events_by_month` com `events_by_day` pelas
mesmas colunas, com a configuração ligada, e fique só com as linhas que dizem que tipo de join foi
escolhido:

```
ana@vm:~$ psql market -c 'SET enable_partitionwise_join = on' -c 'EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month AS a JOIN events_by_day AS b USING (id, at)' | grep -E 'Join|Append'
         ->  Parallel Hash Join
               ->  Parallel Append
                     ->  Parallel Append
```

**Um** `Parallel Hash Join`, com um `Append` das partições de cada tabela embaixo: os limites não
batem, um mês contra um dia, então não há pares para juntar um a um, e o planejador junta tudo com
tudo como faria sem a configuração.

## Quando ligá-las

As duas configurações valem por sessão. Dá para ligá-las nas consultas que ganham com elas, como um
relatório que agrega pela chave de partição ou um join entre duas tabelas cortadas do mesmo jeito, e
deixá-las desligadas no resto, onde só acrescentariam planejamento. É o padrão que esta aula e as
duas anteriores sugerem para o particionamento em geral: ele paga pelas consultas escritas para ele,
e custa um pouco para todas as outras.

A aula mudou `market` acrescentando `events_by_day`, e a `events_by_month` da aula 17 não faz parte de
onde a aula 19 começa. Feche todo `psql` em `market` e ponha-o de volta:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 9.691 ms
CREATE INDEX
Time: 710.727 ms
```
