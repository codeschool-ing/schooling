---
title: Quanto custa um índice mais largo
version: 1
---

Um índice de cobertura é mais rápido para a consulta que cobre e mais caro para todo o resto. O custo
passa despercebido com facilidade, porque não aparece na consulta que você estava olhando. Aparece no
disco, e em toda escrita na tabela.

## No disco

```
market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders', 'orders_customer_id_idx', 'orders_customer_placed_idx');
          relname           |  size  
----------------------------+--------
 orders_customer_id_idx     | 18 MB
 orders                     | 133 MB
 orders_customer_placed_idx | 112 MB
(3 rows)

Time: 2.544 ms
```

**112 MB para o índice de cobertura, 18 MB para o que só tem `customer_id`**: seis vezes o tamanho, e
quase tão grande quanto a tabela de 133 MB que ele indexa. Ele guarda cinco colunas para cada um de
dois milhões de pedidos, e um índice de cobertura é, por definição, uma cópia parcial da sua tabela.
Cada coluna a mais no `INCLUDE` é mais uma fatia da tabela copiada para o índice.

Esse tamanho custa além do disco. O índice disputa com a tabela os 128 MB de shared buffers que a aula
1 mediu, e a consulta que mais roda é aquela cujas páginas de índice ficam na memória; um índice seis
vezes maior precisa de seis vezes mais páginas quentes, ou não consegue tê-las.

## Em toda escrita

Cada índice de uma tabela é atualizado em todo insert, e em todo update que não pode ser feito no
lugar. A segunda parte importa aqui, e precisa de mais uma peça de como o PostgreSQL atualiza linhas.

Quando um `UPDATE` não muda nenhuma coluna guardada em algum índice, e a versão nova cabe na mesma
página, o PostgreSQL pode fazer um **HOT update**, heap-only tuple: a versão nova vai na mesma página,
encadeada à antiga, e **nenhum índice é tocado**. Quando o update muda uma coluna indexada, todo índice
da tabela ganha uma entrada nova.

O `place-order.sql` da aula 2 insere um pedido com `total_cents = 0` e depois atualiza `total_cents`
com a soma real. Rode-o por quinze segundos sem o índice de cobertura, depois com ele, e conte os
updates que foram HOT:

```
market=# DROP INDEX orders_customer_placed_idx;
DROP INDEX
Time: 133.094 ms

market=# SELECT pg_stat_reset_single_table_counters('orders'::regclass);
 pg_stat_reset_single_table_counters 
-------------------------------------
 
(1 row)

Time: 0.968 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f place-order.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 2.443 ms
tps = 3274.924436 (without initial connection time)
market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     49119 |         49051
(1 row)

Time: 8.344 ms
```

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (id, status, total_cents);
CREATE INDEX
Time: 1997.432 ms (00:01.997)

market=# SELECT pg_stat_reset_single_table_counters('orders'::regclass);
 pg_stat_reset_single_table_counters 
-------------------------------------
 
(1 row)

Time: 0.809 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f place-order.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 2.311 ms
tps = 3460.963785 (without initial connection time)
market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     51946 |             0
(1 row)

Time: 4.678 ms
```

**Sem o índice de cobertura, 49.051 de 49.119 updates foram HOT.** `total_cents` não estava em
índice nenhum, então quase todo update ficou na sua página e não tocou índice nenhum. **Com ele, 0 de
51.946.** O índice tem `total_cents` no `INCLUDE`, então mudá-la é mudar um valor indexado, e todo
update agora grava uma versão nova da linha em outro lugar e uma entrada nova em **todo** índice de
`orders`: a chave primária, `customer_id`, `placed_at`, `seller_id` e o de cobertura.

E mesmo assim a vazão não caiu: **3275 transações por segundo sem, 3461 com**. Esse é o resultado
honesto desta medição, e vale não tentar explicá-lo para longe. Quinze segundos de uma transação
pequena numa máquina com memória sobrando não mostram o custo; a diferença entre as duas execuções
está dentro do ruído de que a aula 1 avisou. O que a execução mostra é o mecanismo, num contador que
não depende de tempo: todo update agora deixa para trás uma versão morta da linha e cinco entradas de
índice para o `VACUUM` limpar, onde antes não deixava quase nada. Numa tabela movimentada isso é mais
trabalho de `VACUUM`, mais inchaço entre um vacuum e outro, e os bits de visibilidade da seção 03
desligados em mais páginas. A aula 11 trata desse imposto sobre a escrita, medido por si só.

## Decidindo

Um índice de cobertura vale a pena quando a consulta que ele cobre é **frequente**, e quando as
colunas que ele carrega são **raramente atualizadas**. O `customer-orders.sql` é a consulta mais
frequente da carga da aula 2, o que pesa a favor. `total_cents` é atualizada logo depois de todo
insert, o que pesa contra incluí-la.

Então aqui a melhor escolha pode ser o índice sem `total_cents`: chave `(customer_id, placed_at)`,
`INCLUDE (id, status)`. Ele ainda acha os dez pedidos e os entrega em ordem, sem ordenação, e lê dez
páginas da tabela para `total_cents`, e um update de `total_cents` pode voltar a ser HOT. A outra saída
é mudar a aplicação para gravar o total no `INSERT` em vez de atualizá-lo depois. Cada escolha troca
alguma coisa. O ponto desta seção é que a troca tem dois lados, e o tempo da consulta que você
consertou é só um deles.

Esta aula mudou linhas e criou um índice no `market`. Feche o `psql` e devolva o banco ao estado em
que a aula 3 começa:

```sh
~/reset-market.sh
```
