---
title: Achando os que ninguém lê
version: 1
---

O servidor conta, para cada índice, quantas vezes uma consulta começou uma varredura nele. A
contagem fica em `pg_stat_user_indexes.idx_scan`, e um índice cuja contagem fica em zero enquanto a
aplicação roda é um índice que ninguém lê. **Essa frase é o método inteiro, e quase todo jeito de
errar com ela é um engano sobre o período que o contador cobre.** Esta seção lê o contador depois
de um minuto realista e então passa pelos quatro motivos pelos quais um zero pode mentir.

## Um minuto da carga real

Os contadores cobrem tudo desde que foram zerados pela última vez, o que no `market` inclui as duas
execuções do pgbench da seção anterior. Zere-os e rode a mistura inteira da aula 2 por um minuto,
com o mesmo comando que a aula 2 usou:

```
market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.992 ms
```

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 20.0 s, 2464.3 tps, lat 3.242 ms stddev 6.756, 0 failed
progress: 40.0 s, 2410.9 tps, lat 3.318 ms stddev 6.985, 0 failed
progress: 60.0 s, 2384.7 tps, lat 3.353 ms stddev 7.093, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 145211
number of failed transactions: 0 (0.000%)
latency average = 3.305 ms
latency stddev = 6.945 ms
initial connection time = 8.505 ms
tps = 2419.598234 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 72683 transactions (50.1% of total, tps = 1211.090471)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.545 ms
 - latency stddev = 1.118 ms
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 36337 transactions (25.0% of total, tps = 605.470254)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.605 ms
 - latency stddev = 1.126 ms
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 14456 transactions (10.0% of total, tps = 240.875086)
 - number of failed transactions: 0 (0.000%)
 - latency average = 21.895 ms
 - latency stddev = 6.219 ms
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 14503 transactions (10.0% of total, tps = 241.658230)
 - number of failed transactions: 0 (0.000%)
 - latency average = 5.144 ms
 - latency stddev = 3.333 ms
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 5750 transactions (4.0% of total, tps = 95.810165)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.907 ms
 - latency stddev = 1.206 ms
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 1475 transactions (1.0% of total, tps = 24.577390)
 - number of failed transactions: 0 (0.000%)
 - latency average = 14.932 ms
 - latency stddev = 5.515 ms
```

(Em seguida o pgbench imprimiu um detalhamento por script, deixado de fora aqui.) Agora leia a
contagem de cada índice, da menor para a maior:

```
market=# SELECT relname AS table, indexrelname AS index, idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_stat_user_indexes ORDER BY idx_scan, relname, indexrelname;
    table    |            index            | idx_scan |  size   
-------------+-----------------------------+----------+---------
 customers   | customers_email_key         |        0 | 14 MB
 events      | events_pkey                 |        0 | 107 MB
 order_lines | order_lines_pkey            |        0 | 152 MB
 order_lines | order_lines_product_id_idx  |        0 | 33 MB
 orders      | orders_customer_id_idx      |        0 | 18 MB
 orders      | orders_placed_at_idx        |        0 | 44 MB
 orders      | orders_placed_at_status_idx |        0 | 79 MB
 orders      | orders_seller_id_idx        |        0 | 14 MB
 orders      | orders_total_cents_idx      |        0 | 14 MB
 orders      | orders_status_idx           |     1475 | 14 MB
 orders      | orders_seller_placed_idx    |     5750 | 69 MB
 customers   | customers_pkey              |    29010 | 4408 kB
 orders      | orders_pkey                 |    29010 | 45 MB
 sellers     | sellers_pkey                |    29010 | 40 kB
 order_lines | order_lines_order_id_idx    |    50844 | 78 MB
 order_lines | order_lines_product_id_idx1 |    72678 | 33 MB
 orders      | orders_customer_idx         |    72686 | 18 MB
 products    | products_pkey               |   192376 | 1112 kB
(18 rows)

Time: 6.663 ms
```

Dezoito índices, e **nove deles não foram lidos nenhuma vez em 145.211 transações.** Antes de
apagar qualquer coisa, olhe o que a lista diz de fato, porque ela é mais interessante que nove
zeros.

**As duplicatas dividem as leituras.** O `orders_customer_idx`, criado em 2023 para a busca do
suporte, recebeu 72.686 varreduras, e o `orders_customer_id_idx`, aquele com que o banco nasceu,
nenhuma. O planejador viu dois índices idênticos e escolheu um, e o contador registra fielmente
que ele nunca precisou do outro. O mesmo aconteceu com o `order_lines_product_id_idx1`. Lida de
forma ingênua, a lista manda apagar os originais; lida direito, ela diz que um de cada par sobra,
e a seção 04 desta aula decide qual.

**Uma chave primária sem leituras.** O `order_lines_pkey` mostra zero, porque a página do pedido
pede `WHERE order_id = …` e o planejador preferiu para isso o `order_lines_order_id_idx`, menor e
de uma coluna só, 50.844 vezes. A chave primária continua fazendo o outro trabalho dela: recusar
uma segunda linha com o mesmo `(order_id, line)`. Esse trabalho não deixa rastro em `idx_scan`.

**Algumas leituras vêm do próprio servidor.** O `sellers_pkey` e o `customers_pkey` foram
varridos 29.010 vezes cada, por ninguém da carga: nenhum script busca um vendedor pelo id. Todo
pedido inserido tem de provar que seu `seller_id` e seu `customer_id` existem, e essas checagens
de chave estrangeira são varreduras de índice. O mesmo número no `orders_pkey` é o
`UPDATE … WHERE id = :order_id` do `place-order.sql`.

## Desde quando

Um zero não significa nada sem o momento em que a contagem começou. O PostgreSQL guarda isso por
banco:

```
market=# SELECT stats_reset FROM pg_stat_database WHERE datname = 'market';
          stats_reset          
-------------------------------
 2026-10-10 04:50:09.488338-03
(1 row)

Time: 3.293 ms

market=# SELECT indexrelname AS index, idx_scan, last_idx_scan FROM pg_stat_user_indexes WHERE relname = 'orders' ORDER BY indexrelname;
            index            | idx_scan |         last_idx_scan         
-----------------------------+----------+-------------------------------
 orders_customer_id_idx      |        0 | 
 orders_customer_idx         |    72686 | 2026-10-10 04:51:09.932455-03
 orders_pkey                 |    29010 | 2026-10-10 04:51:09.932455-03
 orders_placed_at_idx        |        0 | 
 orders_placed_at_status_idx |        0 | 
 orders_seller_id_idx        |        0 | 
 orders_seller_placed_idx    |     5750 | 2026-10-10 04:51:09.932455-03
 orders_status_idx           |     1475 | 2026-10-10 04:51:09.932455-03
 orders_total_cents_idx      |        0 | 
(9 rows)

Time: 4.702 ms
```

Os contadores começaram às 04:50:09 e a última varredura de qualquer coisa em `orders` foi às
04:51:09, o fim da execução de um minuto. O `last_idx_scan` é novo no PostgreSQL 16, e é a coluna
para ler num servidor de verdade, porque **uma varredura na semana passada e nenhuma em um ano
parecem iguais em `idx_scan`, mas não em `last_idx_scan`**.

## A consulta para guardar

Este arquivo lista os índices sem leituras desde o zeramento, do maior para o menor, e deixa de
fora os únicos pelo motivo que o `order_lines_pkey` mostrou: um índice único impõe uma regra mesmo
quando nenhuma consulta o lê, e apagá-lo apaga a regra. Grave-o e rode:

```sh
cat > ~/unused-indexes.sql <<'SQL'
-- unused-indexes.sql: indexes no query has read since the counters
-- were last reset, biggest first. Unique ones are left out: they
-- enforce a rule even when nobody reads them.
SELECT s.relname AS table,
       s.indexrelname AS index,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS size
FROM pg_stat_user_indexes AS s
JOIN pg_index AS i USING (indexrelid)
WHERE s.idx_scan = 0 AND NOT i.indisunique
ORDER BY pg_relation_size(s.indexrelid) DESC;
SQL
```

```
ana@vm:~$ psql market -f unused-indexes.sql
    table    |            index            | size  
-------------+-----------------------------+-------
 orders      | orders_placed_at_status_idx | 79 MB
 orders      | orders_placed_at_idx        | 44 MB
 order_lines | order_lines_product_id_idx  | 33 MB
 orders      | orders_customer_id_idx      | 18 MB
 orders      | orders_total_cents_idx      | 14 MB
 orders      | orders_seller_id_idx        | 14 MB
(6 rows)

Time: 3.996 ms
```

Seis candidatos e 202 MB. **Um candidato, não um veredito**, e aqui estão os quatro motivos.

## Quatro jeitos de um zero mentir

**A janela foi curta demais.** O arquivo das sobras diz que o `orders_placed_at_status_idx` foi
criado em 2024 para o relatório mensal, e um minuto de tráfego diurno nunca roda um relatório
mensal. Rode-o uma vez:

```
market=# SELECT status, count(*) FROM orders WHERE placed_at >= '2025-11-01' AND placed_at < '2025-12-01' GROUP BY status;
  status   | count  
-----------+--------
 cancelled |   3108
 delivered | 102395
(2 rows)

Time: 34.511 ms
```

```
market=# SELECT indexrelname AS index, idx_scan FROM pg_stat_user_indexes WHERE indexrelname LIKE 'orders_placed_at%';
            index            | idx_scan 
-----------------------------+----------
 orders_placed_at_idx        |        1
 orders_placed_at_status_idx |        0
(2 rows)

Time: 3.398 ms
```

Uma varredura, e do `orders_placed_at_idx`, o índice com que o banco nasceu, não do que foi criado
para o relatório. Isso já é uma descoberta, e a seção 05 desta aula a usa. Mas a regra geral é a
que vale guardar: **o contador tem de ter coberto todo ciclo que a aplicação tem** — o job noturno,
o fechamento do mês, a auditoria anual. Num servidor de verdade, isso quer dizer ler o
`stats_reset` e esperar até que ele seja mais antigo que o mais longo desses ciclos, ou perguntar a
quem roda os relatórios.

**Os contadores foram zerados.** `pg_stat_reset()` é uma chamada, e qualquer pessoa com permissão
para rodá-la pode ter feito isso, para a própria medição. Os contadores também recomeçam do zero
depois de uma queda ou de um desligamento imediato, embora um reinício limpo os preserve. O
`stats_reset` é a data a ler antes de acreditar em qualquer zero.

**As leituras acontecem em outro servidor.** Os contadores são por servidor. Uma aplicação que
manda os relatórios para uma réplica de leitura (aula 20) lê índices lá, e o primário, que é onde
dá vontade de apagá-los, não conta nada. Leia o `pg_stat_user_indexes` em toda réplica também: o
índice é o mesmo arquivo em todo lugar, então apagá-lo no primário o apaga de todas elas.

**O índice existe por uma regra, não por leituras.** A consulta acima deixa de fora os índices
únicos, mas um índice não único também pode importar sem leituras: uma exclusion constraint se
apoia num, e apagar linhas de uma tabela pai precisa de um índice na chave estrangeira da filha
para não ler a tabela filha inteira, o que acontece raramente e só aparece como varredura no dia em
que é necessário. Antes de apagar um índice numa coluna que referencia outra tabela, pergunte se as
linhas da tabela pai chegam a ser apagadas.

Nenhum desses motivos torna o contador inútil. Eles o tornam **a primeira pergunta, e não a
última**: zero numa janela longa o bastante, em todos os servidores, para um índice que não impõe
nada, é o mais perto de prova que um banco de dados oferece.
