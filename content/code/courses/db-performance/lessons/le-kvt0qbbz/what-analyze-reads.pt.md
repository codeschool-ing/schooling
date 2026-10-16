---
title: O que o ANALYZE lê, e quando roda sozinho
version: 1
---

O `ANALYZE orders` levou 132 milissegundos numa tabela de 2,3 milhões de linhas. É rápido demais para
ter lido todas as linhas, e ele não leu. A crença a abandonar é a de que o `ANALYZE` mede a tabela.
Ele a **amostra**, e o tamanho da amostra não tem nada a ver com o tamanho da tabela.

## A amostra

O `VERBOSE` faz o `ANALYZE` dizer o que leu:

```
market=# SHOW default_statistics_target;
 default_statistics_target 
---------------------------
 100
(1 row)

Time: 1.149 ms

market=# ANALYZE VERBOSE orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 19167 of 19167 pages, containing 2300000 live rows and 0 dead rows; 30000 rows in sample, 2300000 estimated total rows
ANALYZE
Time: 177.160 ms

market=# ANALYZE VERBOSE events;
INFO:  analyzing "public.events"
INFO:  "events": scanned 30000 of 65432 pages, containing 2292530 live rows and 0 dead rows; 30000 rows in sample, 5000161 estimated total rows
ANALYZE
Time: 237.927 ms
```

Leia as duas linhas `INFO`.

- **`orders`: scanned 19167 of 19167 pages, 30000 rows in sample.** A amostra é de **30.000 linhas**,
  300 vezes o `default_statistics_target`. `orders` tem menos páginas que isso, então o `ANALYZE`
  visitou todas as páginas e ficou com 30.000 linhas sorteadas entre os 2,3 milhões que achou nelas.
- **`events`: scanned 30000 of 65432 pages, 30000 rows in sample.** Uma tabela maior, e as mesmas
  30.000 linhas, agora uma de cada uma de 30.000 páginas sorteadas. Ele viu 2.292.530 linhas nessas
  páginas e **estimou** 5.000.161 para a tabela, pela fração de páginas que leu. Essa estimativa vira
  o `reltuples`, a contagem de linhas da qual o planejador parte em todo plano.

Então uma tabela de cinco milhões de linhas e uma de quinhentos milhões recebem a mesma amostra de
30.000 linhas, e por isso o `ANALYZE` é barato o bastante para rodar com frequência, e os resultados
dele mudam um pouco a cada vez: é uma amostra sorteada de novo a cada execução. A aula 7 lê o que se
faz com essas 30.000 linhas, os valores comuns, o histograma e as contagens de distintos, e como dar
uma amostra maior a uma coluna.

## Quando o autovacuum o roda

Sem a chave que a seção 03 desligou, ninguém precisaria ter digitado `ANALYZE`. O lançador do
autovacuum confere cada tabela mais ou menos uma vez por minuto, e analisa uma quando bastante dela
mudou:

```
market=# SELECT relname, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname IN ('orders', 'events') ORDER BY relname;
 relname | n_mod_since_analyze |         last_analyze          | last_autoanalyze 
---------+---------------------+-------------------------------+------------------
 events  |                   0 | 2026-10-15 22:10:02.506573-03 | 
 orders  |                   0 | 2026-10-15 22:10:01.967236-03 | 
(2 rows)

Time: 3.483 ms

market=# SHOW autovacuum_analyze_threshold;
 autovacuum_analyze_threshold 
------------------------------
 50
(1 row)

Time: 0.312 ms

market=# SHOW autovacuum_analyze_scale_factor;
 autovacuum_analyze_scale_factor 
---------------------------------
 0.1
(1 row)

Time: 0.329 ms

market=# ALTER TABLE orders RESET (autovacuum_enabled);
ALTER TABLE
Time: 118.083 ms
```

A regra é **limite + fator de escala × linhas**: 50 + 0,1 × `reltuples`. Para `orders` como a aula 3
começa, isso dá 50 + 0,1 × 2.000.000 = **200.050** linhas mudadas, e os 300.000 da importação teriam
passado disso. O autoanalyze teria rodado cerca de um minuto depois da importação, e o
`last_autoanalyze` mostraria quando.

A regra tem duas consequências que vale conhecer.

- **Uma tabela grande espera mais.** Com 0,1, uma tabela de 100 milhões de linhas é analisada de novo
  depois de 10 milhões de mudanças. Um lote que transforma um status raro num comum pode ficar muito
  abaixo disso e ainda assim mudar todo plano que filtra por ele. `ALTER TABLE … SET
  (autovacuum_analyze_scale_factor = 0.01)` baixa esse fator só para aquela tabela; a aula 14 de
  `db-administration` é o lugar do resto das configurações do autovacuum.
- **A janela depois de uma carga grande é real.** Entre o `COMMIT` de uma importação e o próximo
  autoanalyze, toda consulta planeja com a fotografia velha. Uma tarefa que carrega um lote grande e
  depois o consulta deveria rodar ela mesma o `ANALYZE` na tabela, logo depois da carga, em vez de
  torcer para o autovacuum chegar antes.

A última instrução do bloco desfaz a chave: `RESET (autovacuum_enabled)` devolve `orders` ao
autovacuum. Deixar o autovacuum desligado numa tabela é como as estatísticas dela, e as linhas mortas,
envelhecem para sempre.

## De volta ao início da aula 3

Esta aula inseriu 300.000 pedidos e mudou uma configuração de tabela. Feche o `psql` e devolva o
`market` ao estado de antes:

```sh
~/reset-market.sh
```
