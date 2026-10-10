---
title: Apagando um sem se arrepender
version: 1
---

Seis das sobras têm um caso contra elas agora: duas duplicatas, duas sobrepostas por um índice
maior, uma sobreposta e sem leitura, e o `orders_total_cents_idx`, que ninguém lê e que custa o HOT
de todo update. Apagar um índice leva milissegundos. **O risco não está no apagamento, está em estar
errado sobre ele**, e no PostgreSQL não há como desligar um índice e ver o que acontece: a versão
16 não tem índice invisível nem desativado. Então o apagamento seguro são três hábitos: guardar o
caminho de volta, apagar sem parar a tabela e medir depois.

## Guarde o caminho de volta

O `pg_get_indexdef` devolve o comando exato que criaria um índice de novo, como o servidor o
guardou. Grave os seis num arquivo antes de mexer em qualquer coisa:

```sh
psql -XAt market > ~/dropped-indexes.sql <<'SQL'
SELECT pg_get_indexdef(indexrelid) || ';'
FROM pg_index
WHERE indexrelid IN ('orders_customer_idx'::regclass,
                     'order_lines_product_id_idx1'::regclass,
                     'orders_total_cents_idx'::regclass,
                     'orders_seller_id_idx'::regclass,
                     'orders_placed_at_status_idx'::regclass,
                     'order_lines_order_id_idx'::regclass);
SQL
```

`-A` e `-t` imprimem os valores puros, sem tabela em volta, e `-X` pula o `~/.psqlrc`, para que
nenhuma linha `Time:` vá parar no arquivo:

```
ana@vm:~$ cat ~/dropped-indexes.sql
CREATE INDEX orders_seller_id_idx ON public.orders USING btree (seller_id);
CREATE INDEX orders_customer_idx ON public.orders USING btree (customer_id);
CREATE INDEX orders_placed_at_status_idx ON public.orders USING btree (placed_at, status);
CREATE INDEX orders_total_cents_idx ON public.orders USING btree (total_cents);
CREATE INDEX order_lines_order_id_idx ON public.order_lines USING btree (order_id);
CREATE INDEX order_lines_product_id_idx1 ON public.order_lines USING btree (product_id);
```

Esse arquivo é o desfazer. Num sistema de verdade ele vai na migração que apaga os índices, como o
passo reverso dela, para que recolocar um seja uma mudança revisada e não alguém lembrando uma
lista de colunas de madrugada.

## Apague sem parar a tabela

Um `DROP INDEX` comum pega a trava (lock) mais forte que o PostgreSQL tem sobre a tabela, pelo
instante que leva para remover o índice. O instante é curto, mas a trava precisa esperar toda
consulta que já está rodando na tabela, e enquanto espera, toda consulta nova na tabela espera atrás
dela. A aula 12 desmonta essa fila; numa tabela `orders` movimentada, é assim que um apagamento de
dois milissegundos vira uma queda de um minuto.

O `DROP INDEX CONCURRENTLY` evita isso: ele marca o índice como não mais utilizável, espera as
consultas que ainda possam estar usando-o terminarem e só então o remove, sem nunca bloquear
leituras nem escritas na tabela. Ele tem duas restrições, e as duas aparecem como erro:

```
market=# BEGIN;
BEGIN
Time: 0.412 ms

market=*# DROP INDEX CONCURRENTLY orders_total_cents_idx;
ERROR:  DROP INDEX CONCURRENTLY cannot run inside a transaction block
Time: 0.475 ms

market=!# ROLLBACK;
ROLLBACK
Time: 0.352 ms

market=# DROP INDEX CONCURRENTLY orders_pkey;
ERROR:  cannot drop index orders_pkey because constraint orders_pkey on table orders requires it
HINT:  You can drop constraint orders_pkey on table orders instead.
Time: 1.467 ms
```

**Ele não roda dentro de um bloco de transação**, porque faz mais de um commit por conta própria
enquanto trabalha; uma ferramenta de migração que embrulha todo arquivo em `BEGIN … COMMIT` precisa
ser avisada para deixar este comando de fora. **E nenhuma forma de `DROP INDEX` remove um índice que
pertence a uma constraint**: o índice da chave primária só sai com a chave primária, que é o
servidor mantendo a regra sobre a qual a seção 03 desta aula avisou.

Os seis, um de cada vez:

```
market=# DROP INDEX CONCURRENTLY orders_customer_idx;
DROP INDEX
Time: 16.957 ms

market=# DROP INDEX CONCURRENTLY order_lines_product_id_idx1;
DROP INDEX
Time: 24.680 ms

market=# DROP INDEX CONCURRENTLY orders_total_cents_idx;
DROP INDEX
Time: 14.936 ms

market=# DROP INDEX CONCURRENTLY orders_seller_id_idx;
DROP INDEX
Time: 18.813 ms

market=# DROP INDEX CONCURRENTLY orders_placed_at_status_idx;
DROP INDEX
Time: 53.193 ms

market=# DROP INDEX CONCURRENTLY order_lines_order_id_idx;
DROP INDEX
Time: 48.628 ms
```

Cada um abaixo de 60 ms numa máquina ociosa. Numa movimentada, o tempo é quase todo a espera pelas
consultas que já estão rodando, e ninguém mais espera por ele.

Se um apagamento concorrente for interrompido, ele pode deixar o índice para trás marcado como
inválido: ainda mantido a cada escrita, nunca usado numa leitura, o pior dos dois mundos. O
`\d orders` o mostra com `INVALID` depois do nome; rode o apagamento de novo. A aula 17 de
`db-administration` cobre a mesma falha para criações concorrentes.

## Recolocando um

Suponha que o relatório dos maiores pedidos exista, afinal. A definição está em
`~/dropped-indexes.sql`; crie-o com `CONCURRENTLY` acrescentado, para que a tabela continue
aceitando escritas enquanto ele é construído:

```
market=# CREATE INDEX CONCURRENTLY orders_total_cents_idx ON orders (total_cents);
CREATE INDEX
Time: 1337.880 ms (00:01.338)

market=# DROP INDEX CONCURRENTLY orders_total_cents_idx;
DROP INDEX
Time: 12.287 ms
```

**1,3 segundo** para 2 milhões de pedidos, e ele foi apagado de novo logo em seguida. Esse número é
o preço real de estar errado, e ele cresce com a tabela; durante todo esse tempo, o relatório roda
sem o seu índice. É por isso que o arquivo de desfazer e a janela longa de contagem da seção 03 vêm
antes do apagamento, não depois.

## E meça

As mesmas seis linhas da seção 02 desta aula, na tabela como está agora:

```
market=# CHECKPOINT;
CHECKPOINT
Time: 95.387 ms

market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.926 ms

market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.468 ms

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
latency average = 1.471 ms
initial connection time = 4.938 ms
tps = 2719.811049 (without initial connection time)

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
  wal  | bytes_per_order 
-------+-----------------
 95 MB |            4993
(1 row)

Time: 0.927 ms

market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     20000 |         19996
(1 row)

Time: 3.318 ms
```

| | antes das sobras | com elas | depois dos apagamentos |
|---|---|---|---|
| pedidos por segundo | 2809 | 2447 | 2720 |
| log por pedido | 4895 bytes | 9396 bytes | 4993 bytes |
| updates HOT | 19.996 | 0 | 19.996 |

O log voltou a 2% de onde começou, e o HOT voltou inteiro, porque `total_cents` não está mais em
índice nenhum. Os dois índices das sobras que ficaram, o do painel do vendedor e o da tela de
operações, são lidos pela carga, e juntos custam uns 100 bytes de log por pedido. **Isso é o que
custa um índice que merece o lugar, e o que os outros seis custavam a mais.**

## De volta ao começo

Esta aula criou e apagou índices e escreveu 74.503 pedidos. Ponha o `market` de volta como a aula
12 espera, com todo `psql` no `market` fechado antes:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 12.252 ms
CREATE INDEX
Time: 919.533 ms
```

O `~/leftovers.sql` e os três arquivos de consulta ficam no seu diretório pessoal. Guarde as três
consultas: `unused-indexes.sql`, `duplicate-indexes.sql` e `overlapping-indexes.sql` rodam sem
mudança em qualquer banco PostgreSQL que lhe entregarem.
