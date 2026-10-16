---
title: Podando quando a consulta roda
version: 1
---

A poda em tempo de planejamento precisa dos valores no texto da consulta. Duas situações comuns não
os têm. Um **prepared statement** é planejado uma vez com marcadores, `$1`, e executado muitas vezes
com valores diferentes, que é o que a maioria dos drivers de aplicação faz. E uma condição pode
comparar a chave com algo que só se conhece durante a execução: uma subconsulta, ou um valor do outro
lado de um join. O planejador não pode deixar uma partição fora de um plano cujos valores ele não
viu, então o PostgreSQL poda uma segunda vez, **quando a consulta começa e enquanto ela roda**, e o
plano mostra isso de outro jeito.

## Um prepared statement

O `PREPARE` dá um nome e marcadores a um comando; o `EXECUTE` o roda com valores. Depois de algumas
execuções o servidor pode passar para um **plano genérico**, um plano para todos os valores, e é esse
o caso em que a poda não pode acontecer no planejamento. `plan_cache_mode = force_generic_plan` faz
ele passar na hora, para o efeito aparecer na primeira execução:

```
market=# PREPARE day_count(timestamptz) AS SELECT count(*) FROM events_by_month WHERE at >= $1 AND at < $1 + interval '1 day';
PREPARE
Time: 1.510 ms

market=# SET plan_cache_mode = force_generic_plan;
SET
Time: 0.287 ms

market=# EXPLAIN (ANALYZE, COSTS OFF) EXECUTE day_count('2025-11-10');
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=89.506..95.186 rows=1 loops=1)
   ->  Gather (actual time=89.147..95.137 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=73.862..73.864 rows=1 loops=3)
               ->  Parallel Append (actual time=16.060..72.904 rows=18565 loops=3)
                     Subplans Removed: 3
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_1 (actual time=16.059..71.556 rows=18565 loops=3)
                           Filter: ((at >= $1) AND (at < ($1 + '1 day'::interval)))
                           Rows Removed by Filter: 537129
 Planning Time: 1.763 ms
 Execution Time: 120.182 ms
(12 rows)

Time: 122.699 ms
```

O `Parallel Append` continua só com novembro embaixo, e acima dele uma linha que a poda em tempo de
planejamento nunca imprime: **`Subplans Removed: 3`**. O plano foi montado para as quatro partições,
porque no planejamento `$1` podia ser qualquer instante; quando o comando começou com `$1 =
'2025-11-10'`, o executor comparou o valor com os limites e descartou três subplanos antes de ler
qualquer coisa. O filtro ainda diz `$1`, e é por aí que se percebe que este plano não foi feito para
este valor.

O resultado é o mesmo trabalho da poda em tempo de planejamento da seção 02, um mês lido. O custo é
um plano maior para guardar e para iniciar, o que com quatro partições não é nada, e a seção 05 mede
o que isso vira com centenas.

## Um valor vindo de uma subconsulta

Os eventos do último dia em que a loja recebeu um pedido. O corte não está na consulta; é o que o
`max(placed_at)` em `orders` devolver:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= (SELECT max(placed_at) FROM orders) - interval '1 day';
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=103.250..110.046 rows=1 loops=1)
   InitPlan 2 (returns $1)
     ->  Result (actual time=8.367..8.369 rows=1 loops=1)
           InitPlan 1 (returns $0)
             ->  Limit (actual time=0.128..0.129 rows=1 loops=1)
                   ->  Index Only Scan Backward using orders_placed_at_idx on orders (actual time=0.114..0.115 rows=1 loops=1)
                         Index Cond: (placed_at IS NOT NULL)
                         Heap Fetches: 0
   ->  Gather (actual time=103.029..110.029 rows=3 loops=1)
         Workers Planned: 2
         Params Evaluated: $1
         Workers Launched: 2
         ->  Partial Aggregate (actual time=79.986..79.989 rows=1 loops=3)
               ->  Parallel Append (actual time=69.901..78.399 rows=36984 loops=3)
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_3 (actual time=64.543..70.670 rows=36984 loops=3)
                           Filter: (at >= ($1 - '1 day'::interval))
                           Rows Removed by Filter: 536919
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_2 (never executed)
                           Filter: (at >= ($1 - '1 day'::interval))
                     ->  Parallel Seq Scan on events_2025_10 events_by_month_1 (never executed)
                           Filter: (at >= ($1 - '1 day'::interval))
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4 (actual time=0.002..0.002 rows=0 loops=1)
                           Filter: (at >= ($1 - '1 day'::interval))
 Planning Time: 1.228 ms
 Execution Time: 127.075 ms
(25 rows)

Time: 129.854 ms
```

Leia o plano de cima para baixo. A subconsulta, `InitPlan`, rodou primeiro e devolveu o valor como
`$1`. Depois cada partição ganhou uma anotação diferente. Dezembro foi lido e achou as linhas.
**Outubro e novembro dizem `(never executed)`**: estavam no plano, o executor conferiu `$1` contra os
limites deles quando chegou neles, e os pulou sem abri-los. Janeiro foi aberto e não achou nada, em
microssegundos, porque está vazio.

Esta forma não imprime `Subplans Removed`, porque o valor chegou depois de o executor começar; as
partições puladas ficam no plano e são marcadas. As duas formas são a mesma ideia: os limites
comparados com um valor no último momento em que ele é conhecido.

## Quando a poda em execução é a que você recebe

Numa aplicação, o caso preparado é o comum. Um driver que prepara os comandos, ou um pool fazendo isso
por ele, como o PgBouncer da aula 16 faz com `max_prepared_statements`, manda exatamente a consulta
acima, muitas vezes, com datas diferentes. Depois de cinco execuções o servidor compara o custo do
plano genérico com os planos específicos que vinha fazendo, e fica com o genérico se ele não for pior;
dali em diante toda execução poda em tempo de execução. O plano que você vê digitando a consulta com
uma data literal no `psql` é um plano específico, podado no planejamento, e ele parece diferente do
que a aplicação roda. Os dois leem um mês. O `EXPLAIN (ANALYZE)` sobre o `EXECUTE`, como acima, é o
jeito de ver o que a aplicação recebe.
