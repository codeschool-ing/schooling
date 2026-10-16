---
title: Quando um índice é o começo de outro
version: 1
---

Um B-tree em `(seller_id, placed_at)` é ordenado primeiro por `seller_id`, e por `placed_at` só
entre linhas do mesmo vendedor. Então ele também é, entrada por entrada, um B-tree ordenado por
`seller_id`: toda pergunta que um índice só em `(seller_id)` responde, o índice de duas colunas
responde lendo a primeira coluna e ignorando a segunda. **Um índice cujas colunas são as primeiras
colunas de outro está sobreposto por ele**, e manter os dois paga o imposto sobre a escrita duas
vezes por um único conjunto de leituras.

A crença comum vai no sentido contrário: que o planejador precisa de um índice "exatamente nas
colunas do `WHERE`", então uma consulta em `seller_id` precisa do seu próprio. Não precisa, e o
`market` mostra isso.

## Achando os pares

A consulta compara cada dois índices da mesma tabela e fica com os pares em que as colunas-chave do
menor, com suas operator classes, são as primeiras colunas-chave do maior. Ela usa `indnkeyatts`,
o número de colunas-chave, em vez de todas as colunas, para que as colunas `INCLUDE` da aula 10 não
contem como chave. Índices de expressão e parciais ficam de fora, porque saber se um deles cobre
outro é uma pergunta sobre as expressões e as condições, e uma pessoa a responde mais rápido que
uma consulta:

```sh
cat > ~/overlapping-indexes.sql <<'SQL'
-- overlapping-indexes.sql: pairs where the shorter index's key columns
-- are the first key columns of the longer one, on the same table, with
-- the same operator classes. Expressions and partial indexes are left
-- out: they need reading by eye.
SELECT a.indrelid::regclass AS table,
       a.indexrelid::regclass AS shorter,
       b.indexrelid::regclass AS longer,
       a.indisunique AS shorter_is_unique
FROM pg_index AS a
JOIN pg_index AS b ON b.indrelid = a.indrelid AND b.indexrelid <> a.indexrelid
WHERE a.indnkeyatts < b.indnkeyatts
  AND (b.indkey::int2[])[0:a.indnkeyatts - 1] = (a.indkey::int2[])[0:a.indnkeyatts - 1]
  AND (b.indclass::oid[])[0:a.indnkeyatts - 1] = (a.indclass::oid[])[0:a.indnkeyatts - 1]
  AND a.indexprs IS NULL AND b.indexprs IS NULL
  AND a.indpred IS NULL AND b.indpred IS NULL
ORDER BY 1, 2;
SQL
```

`indkey` e `indclass` são guardados como vetores numerados a partir de 0, e é por isso que os
recortes começam em 0. Rode:

```
ana@vm:~$ psql market -f overlapping-indexes.sql
    table    |         shorter          |           longer            | shorter_is_unique 
-------------+--------------------------+-----------------------------+-------------------
 orders      | orders_placed_at_idx     | orders_placed_at_status_idx | f
 orders      | orders_seller_id_idx     | orders_seller_placed_idx    | f
 order_lines | order_lines_order_id_idx | order_lines_pkey            | f
(3 rows)

Time: 2.717 ms
```

Três pares, e cada um é uma decisão diferente.

## Provando que o maior basta

Antes de apagar o `orders_seller_id_idx`, confira que o plano para os pedidos de um vendedor
sobrevive sem ele. DDL no PostgreSQL é transacional, então dá para apagar o índice dentro de uma
transação, perguntar e desfazer o apagamento:

```
market=# BEGIN;
BEGIN
Time: 0.283 ms

market=*# DROP INDEX orders_seller_id_idx;
DROP INDEX
Time: 1.763 ms

market=*# EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE seller_id = 42;
                           QUERY PLAN                           
----------------------------------------------------------------
 Aggregate
   ->  Index Only Scan using orders_seller_placed_idx on orders
         Index Cond: (seller_id = 42)
(3 rows)

Time: 1.786 ms

market=*# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1588
(1 row)

Time: 1.245 ms

market=*# ROLLBACK;
ROLLBACK
Time: 0.602 ms
```

Sem o índice de uma coluna, o planejador foi direto ao `orders_seller_placed_idx`, leu só a
primeira coluna e contou os 1588 pedidos do vendedor 42 em **1,245 ms**, contra 0,8 ms da aula 1 no
índice de uma coluna, numa tabela menor. A aula 3 ensina a ler esse plano; o que importa aqui é o
nome que aparece nele.

**Faça isso na sua máquina, não num servidor movimentado.** Um `DROP INDEX` dentro de uma transação
aberta segura a trava (lock) mais forte que existe sobre `orders` até o `ROLLBACK`, e toda consulta
na tabela espera atrás dela. A aula 12 explica por quê.

## As três decisões

**`orders_seller_id_idx` sob `orders_seller_placed_idx`: apague o menor.** É o caso comum. O maior
serve o painel, que a seção 03 desta aula viu lê-lo 5.750 vezes, e serve também uma busca simples
por vendedor, como o plano acima mostra. O menor é 14 MB de imposto puro.

**`order_lines_order_id_idx` sob `order_lines_pkey`: apague o menor, por outro motivo.** O maior é
a chave primária: não pode ser apagado, então vai ser mantido seja qual for a sua decisão, e as
50.844 leituras que o menor recebeu irão para ele. A migração de 2025 que criou o
`order_lines_order_id_idx` pagou 78 MB e uma segunda inserção de índice por linha por uma página de
pedido que já tinha índice.

**`orders_placed_at_idx` sob `orders_placed_at_status_idx`: apague o MAIOR.** A regra prática diz
que o menor sai, e os contadores discordam. O composto foi criado em 2024 para o relatório mensal,
e quando o relatório rodou na seção 03, ele leu o índice de uma coluna e deixou o composto em zero.
O composto é o maior dos dois, 79 MB contra 44, e ninguém o lê. A sobreposição diz que um do par
sobra; **os contadores dizem qual deles está se pagando.**

## Quando o menor fica

Dois casos fazem o índice menor valer a pena, e a última coluna da consulta é o primeiro deles.

**Ele é único.** Um índice único em `(email)` com um índice comum em `(email, name)` não é
redundante: o maior permite duas linhas com o mesmo email, e o menor é o que proíbe isso. Quando
`shorter_is_unique` vier `t`, apague o maior, se for o caso, nunca o menor.

**Ele é muito menor e muito usado.** O índice maior é maior, então uma busca pela primeira coluna
dele lê mais páginas para achar as mesmas linhas. Com `(customer_id)` e `(customer_id, notes)`, em
que `notes` é uma coluna de texto longa, o índice de duas colunas poderia ser muitas vezes o
tamanho do de uma, e uma busca que roda milhares de vezes por segundo sentiria isso. Meça esse caso
antes de decidir; para duas colunas estreitas como `seller_id` e `placed_at`, o plano acima é a
medição.
