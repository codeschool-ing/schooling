---
title: A varredura bitmap, e as páginas que ela visita uma vez
version: 1
---

A varredura bitmap é a resposta do planejador à fraqueza da seção anterior: linhas demais para
buscar uma por vez na ordem do índice, poucas demais para ler a tabela inteira. Ela divide o
trabalho em dois nós, e a divisão é a ideia toda:

1. **`Bitmap Index Scan`** lê o índice e, em vez de buscar qualquer coisa, monta um bitmap na
   memória: uma marca para cada página da tabela que tem uma linha que bate, e quais linhas são.
2. **`Bitmap Heap Scan`** então percorre a tabela **na ordem das páginas**, visitando só as páginas
   marcadas, cada uma uma vez.

As linhas saem na ordem da tabela, não na do índice, então uma varredura bitmap não atende a um
`ORDER BY` como uma varredura de índice atende. O que ela compra é que nenhuma página é lida duas
vezes e as páginas são lidas da frente para trás, que é a direção barata.

## Os mesmos cem clientes

Aqui estão de novo os 991 pedidos dos clientes 1000 a 1100, com as varreduras bitmap permitidas —
`RESET enable_bitmapscan;` se a sua sessão ainda tem o ajuste da seção anterior —, que é o plano
que o planejador escolhe sozinho para eles:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.365 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3453.67..3453.68 rows=1 width=8) (actual time=2.576..2.578 rows=1 loops=1)
   Buffers: shared hit=971
   ->  Bitmap Heap Scan on orders  (cost=19.56..3450.95 rows=1086 width=4) (actual time=0.308..2.494 rows=991 loops=1)
         Recheck Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
         Heap Blocks: exact=967
         Buffers: shared hit=971
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..19.29 rows=1086 width=0) (actual time=0.169..0.169 rows=991 loops=1)
               Index Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
               Buffers: shared hit=4
 Planning:
   Buffers: shared hit=126
 Planning Time: 0.550 ms
 Execution Time: 2.672 ms
(13 rows)

Time: 4.056 ms
```

`Heap Blocks: exact=967`: o bitmap marcou 967 páginas, e a varredura da tabela visitou cada uma uma
vez, em ordem. Com as 4 páginas do índice, isso dá os 971 de `Buffers`, contra 994 da varredura de
índice simples das mesmas linhas. A contagem de páginas mal se mexeu, porque essas linhas estão
mesmo em 967 páginas diferentes; o que mudou foi a ordem, e o preço que o planejador dá a ela:
**`3450.95` contra `4237.98`**, porque páginas lidas em ordem crescente são cobradas mais perto de
leituras sequenciais.

A linha `Recheck Cond` é impressa em toda varredura bitmap da tabela. Se ela de fato confere alguma
coisa de novo depende do tipo de marca que cada página recebeu, que é a próxima parte.

## Dez por cento dos clientes

Agora peça os pedidos dos clientes 1 a 20000, um décimo deles:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.404 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=23250.24..23250.25 rows=1 width=8) (actual time=185.872..185.875 rows=1 loops=1)
   Buffers: shared hit=1266 read=15630
   ->  Bitmap Heap Scan on orders  (cost=3017.14..22740.80 rows=203777 width=4) (actual time=16.651..160.631 rows=200378 loops=1)
         Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
         Heap Blocks: exact=16667
         Buffers: shared hit=1266 read=15630
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0) (actual time=13.463..13.464 rows=200378 loops=1)
               Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
               Buffers: shared hit=5 read=224
 Planning:
   Buffers: shared hit=122
 Planning Time: 0.781 ms
 Execution Time: 186.112 ms
(13 rows)

Time: 188.068 ms
```

**`Heap Blocks: exact=16667` é toda página de `orders`.** Duzentos mil pedidos, um décimo da
tabela, e como `customer_id` não tem correlação com a ordem da tabela, há uma linha que bate em
cada página. A varredura bitmap ainda ganhou — lê cada página uma vez, em ordem —, mas ganhou lendo
a tabela inteira, e a linha que diz isso é `Heap Blocks`, não o nome do plano.

## Quando o bitmap não cabe: páginas com perdas

O bitmap mora na memória, e a memória que ele pode usar é o `work_mem`, o mesmo orçamento por
operação de que ordenações e hashes tiram: 4 MB por padrão. Com uma marca por linha para duzentas
mil linhas, ele coube. Reduza o `work_mem` para 64 kB na sessão e peça o plano de novo:

```
market=# SET work_mem = '64kB';
SET
Time: 1.078 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                             QUERY PLAN                              
---------------------------------------------------------------------
 Aggregate  (cost=47176.44..47176.45 rows=1 width=8)
   ->  Seq Scan on orders  (cost=0.00..46667.00 rows=203777 width=4)
         Filter: ((customer_id >= 1) AND (customer_id <= 20000))
(3 rows)

Time: 1.117 ms
```

O planejador abandonou o bitmap e escolheu uma varredura sequencial, e tinha um motivo. Desligue a
varredura sequencial para ver o bitmap que ele recusou:

```
market=# SET enable_seqscan = off;
SET
Time: 0.257 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=49365.90..49365.91 rows=1 width=8) (actual time=234.640..234.642 rows=1 loops=1)
   Buffers: shared hit=973 read=15923 written=1
   ->  Bitmap Heap Scan on orders  (cost=3017.14..48856.46 rows=203777 width=4) (actual time=7.339..220.238 rows=200378 loops=1)
         Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
         Rows Removed by Index Recheck: 1729287
         Heap Blocks: exact=635 lossy=16032
         Buffers: shared hit=973 read=15923 written=1
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0) (actual time=7.180..7.181 rows=200378 loops=1)
               Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
               Buffers: shared hit=5 read=224
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.839 ms
 Execution Time: 234.689 ms
(14 rows)

Time: 236.167 ms
```

**`Heap Blocks: exact=635 lossy=16032`.** Sem espaço para lembrar quais linhas de cada página
batiam, o bitmap abriu mão do detalhe na maioria das páginas e ficou com um bit por página: "alguma
coisa nesta página bate". Uma página com perdas (lossy) precisa ser lida inteira e **cada linha dela
conferida de novo** contra a condição — é para isso que serve o `Recheck Cond`, e é isso que `Rows
Removed by Index Recheck: 1729287` conta. A varredura leu toda página e testou quase toda linha, o
que é uma varredura sequencial com uma busca no índice na frente. O planejador pôs o preço disso em
`48856.46` para a varredura contra `46667.00` para ler a tabela direto, e a varredura sequencial
ganhou.

O `work_mem` não é um ajuste para mudar com base num plano só; a aula 6 de `db-administration` é a
aritmética, porque cada ordenação, hash e bitmap de cada conexão pode ocupar esse tanto ao mesmo
tempo. O que levar daqui é como ler: **`lossy` acima de zero quer dizer que o bitmap não coube no
`work_mem`**, e `Rows Removed by Index Recheck` é quanto isso custou. Devolva os dois ajustes com
`RESET work_mem;` e `RESET enable_seqscan;`, ou feche o `psql`, que esquece todo `SET`.

## Dois índices de uma vez

O painel do vendedor da aula 3 mostrou a outra coisa que só um bitmap faz: combinar índices. Dois
`Bitmap Index Scan` em dois índices diferentes, unidos por um `BitmapAnd`, marcam só as páginas que
as duas condições atingem. Um `OR` entre duas condições indexadas dá um `BitmapOr` do mesmo jeito.
Uma varredura de índice simples segue um índice; um bitmap pode seguir vários e cruzá-los antes de
tocar na tabela.
