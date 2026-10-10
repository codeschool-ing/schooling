---
title: Ordene pelo total, não pela média
version: 1
---

A carga rodou por um minuto. Pergunte ao placar quais comandos mais custaram ao servidor, ordenados
pelo tempo **total**, com a fatia de cada um no todo:

```
market=# SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms, round(100 * total_exec_time / sum(total_exec_time) OVER ()) AS pct, left(regexp_replace(query, '\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY total_exec_time DESC LIMIT 8;
 calls | total_ms | mean_ms | pct |                       query                        
-------+----------+---------+-----+----------------------------------------------------
  5497 |   166407 |   30.27 |  45 | SELECT id, title, price_cents FROM products WHERE 
   540 |   119417 |  221.14 |  32 | SELECT count(*) FROM orders WHERE status = $1
  2164 |    76810 |   35.49 |  21 | SELECT date_trunc($1, placed_at) AS day, count(*),
 27489 |     3043 |    0.11 |   1 | SELECT id, placed_at, status, total_cents FROM ord
 13787 |     1320 |    0.10 |   0 | SELECT p.title, l.quantity, l.price_cents FROM ord
  5356 |     1084 |    0.20 |   0 | INSERT INTO orders (customer_id, seller_id, placed
  5356 |      572 |    0.11 |   0 | INSERT INTO order_lines (order_id, line, product_i
  5356 |      402 |    0.08 |   0 | UPDATE orders SET total_cents = (SELECT sum(quanti
(8 rows)

Time: 3.643 ms
```

Três comandos são **98% de tudo o que o servidor fez** naquele minuto — 45, 32 e 21 por cento —, e
todos os outros comandos que a aplicação mandou, inclusive a lista de pedidos do cliente, que rodou
27489 vezes, dividem o que sobra. Esse é o formato comum, e é o fato mais útil desta aula: o trabalho
de deixar um banco mais rápido quase nunca está espalhado pela aplicação. Ele está em dois ou três
comandos, e o placar diz quais.

A coluna da consulta está cortada em cinquenta caracteres para caber na tela. Os três do alto são a
busca por etiqueta em `products`, a contagem de pedidos pendentes da tela de operações e a soma dia a
dia do painel do vendedor.

## As mesmas linhas, ordenadas pela média

```
market=# SELECT calls, round(mean_exec_time::numeric, 2) AS mean_ms, round(total_exec_time) AS total_ms, left(regexp_replace(query, '\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY mean_exec_time DESC LIMIT 5;
 calls | mean_ms | total_ms |                       query                        
-------+---------+----------+----------------------------------------------------
   540 |  221.14 |   119417 | SELECT count(*) FROM orders WHERE status = $1
  2164 |   35.49 |    76810 | SELECT date_trunc($1, placed_at) AS day, count(*),
  5497 |   30.27 |   166407 | SELECT id, title, price_cents FROM products WHERE 
     1 |   16.87 |       17 | CREATE EXTENSION pg_stat_statements
     1 |    0.36 |        0 | SELECT calls, round(total_exec_time) AS total_ms, 
(5 rows)

Time: 3.758 ms
```

Os mesmos três, em outra ordem, e outra história. Pela média, a contagem de pedidos pendentes é a
vilã óbvia: **221 milissegundos por execução**, seis ou sete vezes as outras duas. Pelo total, ela é
a segunda, porque roda 540 vezes enquanto a busca por etiqueta roda 5497.

Nenhuma das duas ordens está errada; elas respondem a perguntas diferentes. A **média** diz quanto
tempo uma pessoa espera. O **total** diz quanto do servidor um comando tira de todos os outros, e é
isso que decide se o pedido do próximo cliente encontra um processador livre. Um comando de 0,11
milissegundo que roda 27489 vezes por minuto custa mais ao servidor que um de 200 que roda uma vez
por hora, e uma lista ordenada pela média nunca o mostraria.

Então a regra que este curso segue é: **ache os candidatos pelo total, depois leia a média deles**
para saber o que consertar um daria a cada usuário. A busca por etiqueta ganha nos dois critérios, o
que a torna o primeiro alvo por qualquer medida. A aula 8 é onde ela ganha o índice de que precisa.

## Uma linha, lida inteira

Duas linhas do placar dizem muito mais que uma coluna. Esta é a linha do painel do vendedor
completa, com o `\x` transformando cada coluna numa linha própria:

```
market=# \x on
Expanded display is on.

market=# SELECT queryid, calls, total_exec_time, min_exec_time, max_exec_time, mean_exec_time, stddev_exec_time, rows, shared_blks_hit, shared_blks_read, query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') AND query LIKE '%date_trunc%';
-[ RECORD 1 ]----+--------------------------------------------------------------------
queryid          | 4646798757709325093
calls            | 2164
total_exec_time  | 76810.45463800027
min_exec_time    | 12.083803000000001
max_exec_time    | 116.41520399999999
mean_exec_time   | 35.4946648049907
stddev_exec_time | 14.829679595729468
rows             | 62120
shared_blks_hit  | 7276882
shared_blks_read | 1181
query            | SELECT date_trunc($1, placed_at) AS day, count(*), sum(total_cents)+
                 | FROM orders                                                        +
                 | WHERE seller_id = $2 AND placed_at >= $3                           +
                 | GROUP BY 1 ORDER BY 1

Time: 2.286 ms
```

`calls` vezes `mean_exec_time` é `total_exec_time`: 2164 execuções de 35,5 milissegundos cada, 76,8
segundos do servidor num minuto. O espalhamento é a primeira coisa que vale ler. A execução mais
rápida levou **12 milissegundos e a mais lenta, 116**, quase dez vezes mais, e o desvio-padrão de
14,8 contra uma média de 35,5 diz que não foi uma execução azarada, e sim um comando cujo custo
depende de qual vendedor foi perguntado. Alguns vendedores têm mais pedidos em dezembro que outros.

Os dois contadores de páginas dizem de onde os dados vieram: **7276882 páginas encontradas na
memória** e 1181 lidas de fora dela. Páginas têm 8 kB cada, então isso é perto de 60 GB de leituras
de página num minuto, para um painel que devolveu 62120 linhas no total — vinte e nove linhas por
chamada. Um comando que lê tanto para devolver tão pouco está fazendo trabalho de que não precisa, e
a aula 3 trata de ler exatamente onde.
