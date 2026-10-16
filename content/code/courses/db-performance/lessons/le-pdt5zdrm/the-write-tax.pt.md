---
title: O imposto sobre a escrita, medido
version: 1
---

A imagem comum de um índice que ninguém usa é um arquivo no disco que custa algum espaço e de
resto fica parado. **Essa imagem está errada justamente no sentido que importa.** Um índice é uma
segunda cópia de algumas colunas, mantida em ordem, e o PostgreSQL mantém toda cópia atualizada a
cada escrita: um `INSERT` numa tabela com nove índices são dez inserções, quer alguma consulta leia
os outros nove, quer não. O lado da leitura é livre para ignorar um índice. O lado da escrita nunca
é.

Esta seção mede esse custo no `market`, com o `place-order.sql` da aula 2 como a escrita: um
pedido, uma linha, o total preenchido, numa transação. Ela parte do banco como o
`~/reset-market.sh` o deixa e com os arquivos de carga da aula 2 em `~/workload`.

## A linha de base

Abra o `psql market` e digite as seis linhas abaixo. A primeira faz um **checkpoint**, para que as
duas execuções partam do mesmo estado do write-ahead log; o porquê disso vem mais abaixo. As duas
seguintes zeram os contadores de atividade e guardam a posição atual do log numa variável do psql.
Então o pgbench roda 20.000 pedidos de dentro do psql, com `\!`, e as duas últimas leem quanto o
log andou e como os 20.000 updates foram feitos:

```
market=# CHECKPOINT;
CHECKPOINT
Time: 477.396 ms

market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.802 ms

market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.536 ms

market=# \! pgbench -n -c 4 -j 4 -t 5000 -f ~/workload/place-order.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/place-order.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
number of transactions per client: 5000
number of transactions actually processed: 20000/20000
number of failed transactions: 0 (0.000%)
latency average = 1.424 ms
initial connection time = 5.922 ms
tps = 2808.862523 (without initial connection time)

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
  wal  | bytes_per_order 
-------+-----------------
 93 MB |            4895
(1 row)

Time: 1.094 ms

market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     20000 |         19996
(1 row)

Time: 3.863 ms
```

Três números para guardar. **2809 pedidos por segundo, a 1,424 ms cada.** **93 MB de write-ahead
log, 4895 bytes para cada pedido.** E `n_tup_hot_upd`: 19.996 dos 20.000 updates foram **HOT**,
heap-only tuple updates, que a próxima parte desta página explica.

`pg_current_wal_lsn()` é a posição até onde o servidor escreveu o log, um endereço em bytes que só
cresce; `pg_wal_lsn_diff` subtrai dois deles. Tudo o que o servidor muda vai para esse log antes de
ir para qualquer outro lugar (aula 7 de `db-administration`), então a diferença é o total de
escrita que a execução causou, num número só, seja qual for a tabela ou o índice onde caiu.

## Três anos de migrações

Nenhuma equipe cria nove índices numa tabela de uma vez. Eles chegam uma migração por vez, cada um
para uma tela ou um relatório que alguém estava olhando naquela semana. Este arquivo é essa
história para `orders` e `order_lines`, com a data e o motivo em cada linha. Grave-o no seu
diretório pessoal e rode:

```sh
cat > ~/leftovers.sql <<'SQL'
-- leftovers.sql: the indexes three years of migrations left on orders
-- and order_lines. Each one made sense to somebody on the day.
CREATE INDEX orders_customer_idx ON orders (customer_id);          -- 2023-03 support search
CREATE INDEX orders_seller_placed_idx ON orders (seller_id, placed_at); -- 2023-08 seller dashboard
CREATE INDEX orders_placed_at_status_idx ON orders (placed_at, status); -- 2024-01 monthly report
CREATE INDEX orders_status_idx ON orders (status);                 -- 2024-06 operations screen
CREATE INDEX orders_total_cents_idx ON orders (total_cents);       -- 2024-09 largest orders
CREATE INDEX order_lines_order_id_idx ON order_lines (order_id);   -- 2025-02 order page
CREATE INDEX ON order_lines (product_id);                          -- 2025-07 product sales
SQL
```

```
ana@vm:~$ psql market -f ~/leftovers.sql
CREATE INDEX
Time: 857.829 ms
CREATE INDEX
Time: 1253.471 ms (00:01.253)
CREATE INDEX
Time: 896.094 ms
CREATE INDEX
Time: 892.228 ms
CREATE INDEX
Time: 835.149 ms
CREATE INDEX
Time: 1481.093 ms (00:01.481)
CREATE INDEX
Time: 2061.541 ms (00:02.062)
```

Sete índices em cerca de oito segundos. A última linha não dá nome, então o PostgreSQL inventa um,
e você vai ver daqui a pouco o que ele escolheu. Cada um deles tem o tamanho de um índice de
verdade:

```
market=# SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_index WHERE indrelid IN ('orders'::regclass, 'order_lines'::regclass) ORDER BY indrelid, indexrelid;
            index            |  size  
-----------------------------+--------
 orders_pkey                 | 43 MB
 orders_customer_id_idx      | 18 MB
 orders_placed_at_idx        | 43 MB
 orders_seller_id_idx        | 14 MB
 orders_customer_idx         | 18 MB
 orders_seller_placed_idx    | 61 MB
 orders_placed_at_status_idx | 77 MB
 orders_status_idx           | 14 MB
 orders_total_cents_idx      | 14 MB
 order_lines_pkey            | 151 MB
 order_lines_product_id_idx  | 33 MB
 order_lines_order_id_idx    | 77 MB
 order_lines_product_id_idx1 | 33 MB
(13 rows)

Time: 2.487 ms
```

`orders` foi de quatro índices para nove, e `order_lines` de dois para quatro. Os sete novos somam
**294 MB**, um quinto do banco inteiro, e nada nas tabelas em si mudou.

## A mesma execução, com as sobras

Digite as mesmas seis linhas de novo:

```
market=# CHECKPOINT;
CHECKPOINT
Time: 149.390 ms

market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.726 ms

market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.542 ms

market=# \! pgbench -n -c 4 -j 4 -t 5000 -f ~/workload/place-order.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/place-order.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
number of transactions per client: 5000
number of transactions actually processed: 20000/20000
number of failed transactions: 0 (0.000%)
latency average = 1.635 ms
initial connection time = 4.397 ms
tps = 2447.139942 (without initial connection time)

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
  wal   | bytes_per_order 
--------+-----------------
 179 MB |            9396
(1 row)

Time: 0.996 ms

market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     20000 |             0
(1 row)

Time: 4.016 ms
```

| | antes | depois |
|---|---|---|
| pedidos por segundo | 2809 | 2447 |
| latência | 1,424 ms | 1,635 ms |
| write-ahead log | 93 MB | 179 MB |
| log por pedido | 4895 bytes | 9396 bytes |
| updates HOT | 19.996 | 0 |

**A taxa caiu 13% e o log quase dobrou.** Os dois números não merecem a mesma confiança. A taxa
varia vários por cento entre duas execuções da mesma coisa nesta máquina, porque o que domina uma
transação curta aqui é esperar o disco confirmar um commit, não manter índices. O volume de log não
varia assim: são bytes que o servidor escreveu, e esses bytes precisam ser guardados, arquivados,
enviados a cada réplica e reaplicados depois de uma queda. **Num sistema com muita escrita, o log é
onde o custo de um índice aparece primeiro**, e aparece lá esteja alguém olhando a taxa de
transações ou não.

## Por que o log dobrou

Duas coisas, e vale reconhecer as duas quando você as encontrar de novo.

**Uma imagem de página depois de cada checkpoint.** A primeira vez que uma página é alterada depois
de um checkpoint, o servidor escreve a página inteira de 8 kB no log em vez de só a mudança, para
que uma queda no meio da escrita dessa página possa ser reparada (aula 8 de `db-administration`).
Um índice cujas chaves novas caem em qualquer lugar dele toca uma folha diferente a quase cada
pedido: um cliente aleatório, um produto aleatório, um total aleatório. Cada uma dessas páginas
custa uma imagem inteira uma vez por checkpoint. Um índice sobre algo que só cresce, como
`placed_at` ou `order_id`, acrescenta cada chave nova na ponta direita e toca as mesmas poucas
páginas de novo e de novo. Quatro das sobras são do primeiro tipo: cliente, vendedor, total e
produto chegam sem ordem nenhuma.

**O update deixou de ser barato.** O `place-order.sql` insere o pedido com total zero e depois o
atualiza. Antes das sobras, 19.996 desses updates eram HOT: a nova versão da linha foi para a mesma
página da antiga, e **nenhum índice precisou ser tocado**, porque nenhuma coluna indexada tinha
mudado. HOT só é possível quando nenhum índice contém uma coluna que o update muda. O
`orders_total_cents_idx` contém `total_cents`, então com ele presente cada update teve de inserir
uma entrada nova em todos os nove índices de `orders`, e a contagem caiu para **0**. Um índice numa
coluna pela qual ninguém busca transformou 20.000 updates baratos em 20.000 caros.

Contado em entradas de índice, um pedido foi de seis para vinte e duas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Entradas de índice escritas para um pedido pelo place-order.sql. Antes das sobras: o insert do pedido escreve 4 entradas, o da linha 2, e o update nenhuma, porque é um update HOT; 6 ao todo. Com as sobras: o insert do pedido escreve 9, o da linha 4, e o update 9, porque total_cents agora está indexado; 22 ao todo.\"><text x=\"222\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">antes das sobras</text><text x=\"472\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">com as sobras</text><text x=\"14\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO orders</text><rect x=\"222\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"294\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"520\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"592\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"616\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"664\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO order_lines</text><rect x=\"222\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"520\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE orders SET total_cents</text><text x=\"222\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">HOT: nenhum índice tocado</text><rect x=\"472\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"520\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"592\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"616\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"664\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><path d=\"M14 188 L706 188\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"14\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">entradas de índice por pedido</text><text x=\"222\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">6</text><text x=\"472\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">22</text></svg>", "caption": "O que uma execução do place-order.sql escreve nos índices. O update é o passo que mais mudou: HOT antes, nove entradas depois."}
```

Então o imposto não é o mesmo para todo índice. Um índice numa coluna que só cresce é barato de
manter. Um índice cujas chaves chegam em ordem aleatória custa imagens de página. **Um índice numa
coluna que é atualizada custa mais que todos, porque tira o HOT de todo update dessa coluna.** O
resto desta aula descobre quais das sete se pagam, e a próxima seção começa pela pergunta óbvia:
alguém lê esses índices?
