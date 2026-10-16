---
title: A consulta que ignora o particionamento
version: 1
---

A poda compara uma condição com os limites das partições, e os limites são valores de `at`. Uma
condição que o planejador não consegue transformar numa faixa de `at` não lhe dá nada para comparar,
então ele mantém todas as partições. Nada avisa: a consulta devolve a resposta certa, e o único sinal
é um plano com todas as partições dentro e um tempo parecido com o da tabela sem particionamento.

## Uma função sobre a chave

O mesmo dia da seção 02, perguntado do jeito que muita gente escreve, com `date()`:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE date(at) = '2025-11-10';
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=179.334..185.604 rows=1 loops=1)
   ->  Gather (actual time=179.183..185.592 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=176.604..176.608 rows=1 loops=3)
               ->  Parallel Append (actual time=136.237..175.780 rows=18565 loops=3)
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_3 (actual time=58.586..58.587 rows=0 loops=3)
                           Filter: (date(at) = '2025-11-10'::date)
                           Rows Removed by Filter: 573903
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_2 (actual time=30.984..88.444 rows=27847 loops=2)
                           Filter: (date(at) = '2025-11-10'::date)
                           Rows Removed by Filter: 805694
                     ->  Parallel Seq Scan on events_2025_10 events_by_month_1 (actual time=171.103..171.103 rows=0 loops=1)
                           Filter: (date(at) = '2025-11-10'::date)
                           Rows Removed by Filter: 1611210
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4 (actual time=0.001..0.002 rows=0 loops=1)
                           Filter: (date(at) = '2025-11-10'::date)
 Planning Time: 0.932 ms
 Execution Time: 185.731 ms
(19 rows)

Time: 187.951 ms
```

A resposta é a mesma, 18565 linhas por worker, e o plano lê **todas as partições**: outubro, que não
pode guardar uma única linha de 10 de novembro, foi lido inteiro e jogou fora todas as suas 1611210
linhas. **185,7 milissegundos**, contra 48,3 da faixa na seção 02, e perto dos 216,7 da tabela sem
particionamento.

**`date(at)` não é `at`.** Para podar, o planejador teria de saber que `date(at) = '2025-11-10'`
significa uma faixa de `at`, e ele não raciocina sobre o que uma função faz. É o mesmo motivo pelo
qual o `date(placed_at)` da aula 1 não podia usar o índice em `placed_at`, e tem a mesma correção:
**escreva a condição sobre a própria coluna**, como uma faixa, `at >= '2025-11-10' AND at <
'2025-11-11'`. Há um segundo motivo, mais sutil, neste caso: o `date()` de um `timestamptz` depende do
fuso horário da sessão, então nem um planejador que tentasse poderia compará-lo com limites fixos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A condição da consulta, at de 2025-11-10 a 2025-11-11, desenhada contra as quatro partições de events_by_month: outubro, novembro, dezembro e janeiro de 2026. O intervalo cai só dentro de novembro, então novembro é lido e as outras três ficam fora do plano. Embaixo, uma condição escrita como date(at) não dá ao planejador nenhuma faixa para comparar, e as quatro são lidas.\"><text x=\"14\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">faixa em at</text><text x=\"14\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">at &gt;= '2025-11-10'</text><rect x=\"150\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">events_2025_10</text><rect x=\"290\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"355\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_11</text><rect x=\"430\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"495\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">events_2025_12</text><rect x=\"570\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"635\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">events_2026_01</text><text x=\"355\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">uma partição lida, 48,3 ms</text><text x=\"14\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">função em at</text><text x=\"14\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">date(at) = ...</text><rect x=\"150\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"215\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_10</text><rect x=\"290\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"355\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_11</text><rect x=\"430\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"495\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_12</text><rect x=\"570\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"635\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2026_01</text><text x=\"425\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">as quatro lidas, 185,7 ms</text></svg>", "caption": "A poda compara a condição com os limites de cada partição. Uma faixa na chave deixa um mês; o mesmo dia escrito através de uma função deixa os quatro."}
```

`extract(month FROM at) = 11` falha do mesmo jeito, e lê as quatro:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE extract(month FROM at) = 11;
                                  QUERY PLAN                                   
-------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Append
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_3
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_2
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
                     ->  Parallel Seq Scan on events_2025_10 events_by_month_1
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
(13 rows)

Time: 1.533 ms
```

## Uma condição em outra coluna

**Uma consulta que filtra numa coluna que não é a chave também não poda**, seja qual for a forma:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE customer_id = 42;
                                              QUERY PLAN                                              
------------------------------------------------------------------------------------------------------
 Aggregate
   ->  Append
         ->  Index Only Scan using events_2025_10_customer_id_idx on events_2025_10 events_by_month_1
               Index Cond: (customer_id = 42)
         ->  Index Only Scan using events_2025_11_customer_id_idx on events_2025_11 events_by_month_2
               Index Cond: (customer_id = 42)
         ->  Index Only Scan using events_2025_12_customer_id_idx on events_2025_12 events_by_month_3
               Index Cond: (customer_id = 42)
         ->  Seq Scan on events_2026_01 events_by_month_4
               Filter: (customer_id = 42)
(10 rows)

Time: 2.102 ms
```

Os eventos do cliente 42: um `Append` sobre as quatro partições, uma leitura de índice em cada mês que
tem linhas. Nada em `customer_id = 42` diz em que mês as linhas estão, então o planejador pergunta a
todos os meses. Com quatro partições e um índice em cada, são quatro sondagens pequenas, e custa
pouco. É a busca por id da aula 17 de novo, e o motivo de ela importar é a próxima seção: o número de
sondagens é o número de partições.

## Achando essas consultas

Uma consulta que ignora o particionamento parece normal em todo lugar, menos no plano. Três hábitos a
encontram:

- **Leia o plano das consultas importantes de uma tabela particionada**, e conte as partições embaixo
  do `Append`. Uma consulta sobre um dia com todos os meses embaixo é o sintoma.
- **Procure a chave dentro de uma função** nas consultas que importam — `date(at)`, `at::date`,
  `extract(… FROM at)`, `to_char(at, …)` — e reescreva como faixas sobre a coluna.
- **Confira pelo que as consultas importantes filtram**, contra a chave de partição. Se as consultas
  que importam filtram por outra coisa, o particionamento não as está ajudando, e a pergunta da aula
  17 sobre a chave foi respondida para as consultas erradas.

O `pg_stat_statements` da aula 2 é de onde vêm as consultas importantes: ordenado pelo tempo total, o
topo da lista numa tabela particionada é a lista de planos a ler.
