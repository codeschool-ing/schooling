---
title: Estatísticas sobre a tabela de ontem
version: 1
---

As estatísticas são uma fotografia. O `ANALYZE` a tira, e o planejador continua usando-a até o
próximo `ANALYZE` tirar outra. Entre as duas a tabela pode mudar por completo, e o planejador não vai
saber. Normalmente o autovacuum tira uma fotografia nova quando linhas suficientes mudaram, e a seção
05 mede quando. O intervalo antes disso é onde os planos dão errado, e o jeito de observar esse
intervalo é mantê-lo aberto de propósito.

## Mantendo o intervalo aberto

Um novo canal de vendas manda o seu atraso num lote só: trezentos mil pedidos pendentes, todos feitos
em 2 de janeiro de 2026. Antes de carregá-lo, desligue o autovacuum de `orders`, o que desliga também
o `ANALYZE` automático dela. Um servidor de verdade não faria isso; aqui é para as estatísticas
ficarem exatamente tão velhas quanto a aula precisa, pelo tempo que ela precisar:

```
market=# ALTER TABLE orders SET (autovacuum_enabled = off);
ALTER TABLE
Time: 16.426 ms

market=# SELECT setseed(0.6);
 setseed 
---------
 
(1 row)

Time: 0.819 ms

market=# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) SELECT 1 + floor(random() * 200000)::int, 2 + floor(random() * 999)::int, timestamptz '2026-01-02 00:00-03' + random() * interval '1 day', 'pending', 500 + floor(random() * 50000)::int FROM generate_series(1, 300000);
INSERT 0 300000
Time: 6409.504 ms (00:06.410)
```

O `setseed` faz o `random()` sortear na sua máquina os mesmos pedidos que na máquina destas
transcrições. A importação levou seis segundos e multiplicou os pedidos pendentes por quarenta, de
7319 para 307.319.

## Os contadores dizem

O `pg_stat_user_tables` conta mudanças por tabela, e o `pg_class` guarda o que o último `ANALYZE`
anotou. Abra um `psql` novo, para que os contadores da sessão que inseriu já tenham sido enviados, e
pergunte aos dois:

```
market=# SELECT n_live_tup, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname = 'orders';
 n_live_tup | n_mod_since_analyze | last_analyze | last_autoanalyze 
------------+---------------------+--------------+------------------
     300000 |              300000 |              | 
(1 row)

Time: 4.125 ms

market=# SELECT reltuples::bigint, relpages, pg_relation_size('orders') / 8192 AS pages_now FROM pg_class WHERE relname = 'orders';
 reltuples | relpages | pages_now 
-----------+----------+-----------
   2000000 |    16667 |     19167
(1 row)

Time: 1.033 ms
```

- **`n_mod_since_analyze: 300000`** é cada linha inserida, atualizada ou apagada desde que as
  estatísticas foram tiradas. É o número a acompanhar: ele diz a idade da fotografia, em linhas.
- **`last_analyze` e `last_autoanalyze` estão vazios.** A cópia do `market` feita pelo script de
  reinício da aula 2 nunca foi analisada neste banco; as estatísticas dela vieram junto do
  `market_base`, que a carga da aula 1 analisou.
- **`reltuples` ainda diz 2.000.000 e `relpages` 16.667**, enquanto a tabela tem de fato **19.167**
  páginas agora.

## A estimativa que sai

Conte os pedidos pendentes, com o plano e os números reais:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47935.90..47935.91 rows=1 width=8) (actual time=192.117..192.119 rows=1 loops=1)
   ->  Seq Scan on orders  (cost=0.00..47916.93 rows=7590 width=0) (actual time=144.194..178.753 rows=307319 loops=1)
         Filter: (status = 'pending'::text)
         Rows Removed by Filter: 1992681
 Planning Time: 0.425 ms
 Execution Time: 192.221 ms
(6 rows)

Time: 193.695 ms
```

**7590 estimadas, 307.319 reais**, uma razão de 40. A conta mostra exatamente que parte da fotografia
está velha e que parte o planejador corrigiu sozinho:

- a **fração** vem do `pg_stats`: `pending` era 0,0033 das linhas quando a amostra foi tirada, e a
  aula 7, seção 03, leu esse número. Ele não mudou, porque nada voltou a amostrar a coluna.
- a **contagem de linhas** não vem de `reltuples` como está. O planejador lê o tamanho real da tabela
  em páginas na hora de planejar, 19.167, e escala `reltuples` por ele: 2.000.000 × 19.167 ÷ 16.667
  dá 2,3 milhões, o total certo. 0,0033 × 2,3 milhões dá **7590**.

Então o planejador sabia que a tabela tinha crescido, e acreditou que ela tinha crescido com a mesma
mistura de linhas de antes. Esse é o formato comum de uma estimativa velha: a contagem está mais ou
menos certa e a distribuição está errada. Uma importação de um tipo diferente de linha, um status que
era raro e de repente não é, um cliente novo cujos pedidos chegam aos milhares, um intervalo de datas
que ninguém tinha consultado antes: cada um muda o jeito das linhas sem mudar o que a fotografia diz.

Esta consulta não se importa. Não há índice em `status`, então ela lê a tabela seja qual for a
estimativa, e 192 milissegundos é o que ler a tabela custa. A próxima seção é uma consulta que se
importa.
