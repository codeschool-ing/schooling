---
title: Ler menos
version: 1
---

Escrever é uma metade do custo de um pipeline. A outra é ler — pelos modelos que constroem os marts, e
por todo relatório que os consulta —, e num warehouse alugado por consulta ler costuma ser a metade
que aparece na fatura. O `BUFFERS` conta o que foi lido, em páginas de oito kilobytes:

```
-- Revenue for one month, and the pages of the table each query had to read.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT sum(line_cents) FROM big.fact_sales WHERE order_date BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT sum(line_cents) FROM big.fact_sales;
```

```
ana@vm:~/etl$ psql -q -d wh -f read.sql
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1 loops=1)
   Buffers: shared hit=220
   ->  Index Scan using fact_sales_order_date_idx on fact_sales (actual rows=9030 loops=1)
         Index Cond: ((order_date >= '2026-03-01'::date) AND (order_date <= '2026-03-31'::date))
         Buffers: shared hit=220
 Planning:
   Buffers: shared hit=91
(7 rows)

                                   QUERY PLAN                                    
---------------------------------------------------------------------------------
 Finalize Aggregate (actual rows=1 loops=1)
   Buffers: shared hit=2539 read=23417
   ->  Gather (actual rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=2539 read=23417
         ->  Partial Aggregate (actual rows=1 loops=3)
               Buffers: shared hit=2539 read=23417
               ->  Parallel Seq Scan on fact_sales (actual rows=1170700 loops=3)
                     Buffers: shared hit=2539 read=23417
(10 rows)

done
```

A receita de março: **220 páginas**, cerca de 1,7 MB, pelo índice. A receita dos seis anos: **25.956
páginas** — 2.539 já na memória e 23.417 lidas do disco —, cerca de 200 MB, que é a tabela inteira,
lida por três processos em paralelo. A segunda consulta não está mal escrita; ela pede tudo, e tudo é
o que ela custa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l19-pages\" aria-label=\"Páginas lidas para responder por um mês contra seis anos da tabela grande. Um mês pelo índice: 220 páginas, cerca de 1,7 MB. Os seis anos: 25.956 páginas, cerca de 200 MB, a tabela inteira.\"><text x=\"208.0\" y=\"43.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">março, pelo índice</text><rect x=\"220.0\" y=\"30.0\" width=\"3.6\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"231.6\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">220 páginas</text><text x=\"208.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seis anos, a tabela inteira</text><rect x=\"220.0\" y=\"80.0\" width=\"420.0\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">25.956 páginas</text></svg>", "caption": "A página mais barata é a que a consulta nunca lê."}
```

Os hábitos que mantêm a leitura barata vêm daí. **Filtrar pela coluna pela qual a tabela é
organizada** — aqui a data, que tem o índice — para que o banco possa pular o que não precisa. Pedir
as colunas que um relatório usa, e não todas, o que no PostgreSQL economiza pouco, mas num warehouse
colunar, em que cada coluna é guardada à parte, economiza a maior parte da fatura. Construir marts
para que os relatórios leiam o resumo pequeno e não a tabela fato grande: o `daily_sales` tem alguns
milhares de linhas onde o `fact_sales` tem dezenas de milhares, e essa proporção é a razão de ser de
um mart.

Warehouses na nuvem cobram isso de jeitos diferentes — pelos bytes que uma consulta varre, pelos
segundos de processamento que usa, ou por um tamanho de máquina reservado — e nenhum está ao alcance
do laboratório. Cada um deles cobra por uma das duas coisas medidas aqui: quanto foi lido, ou quanto
tempo levou.
