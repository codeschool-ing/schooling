---
title: Quanto da tabela a amostra lê
version: 1
---

Um `ANALYZE` numa tabela de um bilhão de linhas termina em segundos, e esse é o primeiro sinal de
que **ele não lê a tabela**. Ele lê uma amostra, e uma configuração decide o tamanho da amostra e
quanto do que ela encontrou é guardado.

```
shop=# SHOW default_statistics_target;
 default_statistics_target 
---------------------------
 100
(1 row)

shop=# \timing on
Timing is on.

shop=# ANALYZE VERBOSE orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 8334 of 8334 pages, containing 1000000 live rows and 0 dead rows; 30000 rows in sample, 1000000 estimated total rows
ANALYZE
Time: 119.425 ms
```

O `VERBOSE` faz o `ANALYZE` dizer o que fez. A linha a ler é **`30000 rows in sample`**: a amostra
tem 300 linhas para cada unidade do alvo de estatísticas, e o alvo é 100. Em `orders` a amostra sai
das 8.334 páginas, porque a tabela é pequena; numa tabela de um milhão de páginas ainda seriam 30.000
linhas, tiradas de 30.000 delas. É por isso que o tempo quase não cresce com a tabela, e é por isso
que as frequências da primeira seção eram próximas e não exatas.

O mesmo número limita o que é guardado para cada coluna: **até 100 entradas na lista de valores
comuns, e um histograma de 100 faixas**, que a `pg_stats` guarda como 101 limites.

## Aumentando para uma coluna

O alvo pode ser definido por coluna, e a coluna com o maior alvo decide o tamanho da amostra da
tabela inteira:

```
shop=# ALTER TABLE orders ALTER COLUMN total_cents SET STATISTICS 1000;
ALTER TABLE
Time: 1.335 ms

shop=# ANALYZE VERBOSE orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 8334 of 8334 pages, containing 1000000 live rows and 0 dead rows; 300000 rows in sample, 1000000 estimated total rows
ANALYZE
Time: 752.260 ms

shop=# \timing off
Timing is off.

shop=# SELECT attname, attstattarget FROM pg_attribute WHERE attrelid = 'orders'::regclass AND attnum > 0;
   attname   | attstattarget 
-------------+---------------
 id          |            -1
 customer_id |            -1
 status      |            -1
 total_cents |          1000
 created_at  |            -1
(5 rows)

shop=# SELECT attname, array_length(histogram_bounds, 1) AS bounds FROM pg_stats WHERE tablename = 'orders' AND attname IN ('customer_id', 'total_cents');
   attname   | bounds 
-------------+--------
 customer_id |    101
 total_cents |   1001
(2 rows)
```

Dez vezes o alvo, dez vezes a amostra: 300.000 linhas, e o `ANALYZE` levou 752.260 ms onde tinha
levado 119.425 ms. `attstattarget` mostra qual coluna tem uma configuração própria, e `-1` quer dizer
que ela segue `default_statistics_target`. O histograma de `total_cents` agora tem 1.001 limites e
`customer_id` fica com os seus 101, embora os dois tenham sido calculados da mesma amostra maior.

**Um alvo maior custa em todo `ANALYZE` daquela tabela, e em todo plano que usa a coluna**, porque o
planejador percorre listas mais longas. É por isso que ele é aumentado coluna por coluna, onde se viu
uma estimativa errada, e quase nunca por `default_statistics_target`, que aumentaria o alvo de toda
coluna de toda tabela de uma vez.

A coluna que merece isso tem mais valores importantes do que uma lista de 100 comporta: um `country`
ou um `product_id` em que algumas centenas de valores levam a maior parte das linhas e o resto vai
rareando, de modo que um valor logo fora da lista é estimado como se fosse médio. O jeito de achar
uma é a comparação que a seção anterior fez — estimativa contra o real no `EXPLAIN ANALYZE`, na
condição sobre aquela coluna — e a lição 7 de `db-performance` percorre o histograma e os valores
comuns em detalhe.

Devolva `orders` ao que era, e analise de novo para o resumo ser construído no padrão:

```
shop=# ALTER TABLE orders ALTER COLUMN total_cents SET STATISTICS -1;
ALTER TABLE

shop=# ANALYZE orders;
ANALYZE
```

Existe mais uma forma de sobrepor o valor, para o caso em que a amostra erra sempre o mesmo número.
`n_distinct` é a estimativa em que uma amostra é pior, e uma coluna cuja contagem de distintos você
conhece pode recebê-la, como contagem ou como fração negativa:

```sql
ALTER TABLE orders ALTER COLUMN customer_id SET (n_distinct = 50000);
```

Ela vale a partir do próximo `ANALYZE`. Aparece aqui sem ser rodada, porque a amostra acerta esta
coluna com uma margem de um ou dois por cento, e um valor fixado que está certo hoje está errado
quando os clientes dobrarem.
