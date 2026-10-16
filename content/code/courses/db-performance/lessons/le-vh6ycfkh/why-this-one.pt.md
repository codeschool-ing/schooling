---
title: Por que o planejador escolhe um
version: 1
---

O planejador não tem junção favorita. Para cada par de entradas ele precifica os três métodos que
pode usar — e dos dois lados, já que qualquer um pode ser o externo, ou virar hash — e fica com o
mais barato. O preço de cada método depende de alguns números, e o que mais se mexe é a **contagem
de linhas que ele espera de cada lado**. Mude esse número e o método muda junto.

## A mesma junção, três tamanhos

Clientes com os seus pedidos, para os primeiros 10, 1000 e 20000 clientes. Só a faixa muda:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.731 ms

market=# EXPLAIN SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <= 10;
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.93..487.72 rows=100 width=24)
   ->  Index Scan using customers_pkey on customers c  (cost=0.42..8.59 rows=10 width=16)
         Index Cond: (id <= 10)
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.80 rows=11 width=16)
         Recheck Cond: (c.id = customer_id)
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0)
               Index Cond: (customer_id = c.id)
(7 rows)

Time: 3.090 ms

market=# EXPLAIN SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <= 1000;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.85..37897.88 rows=10270 width=24)
   ->  Index Scan using customers_pkey on customers c  (cost=0.42..45.39 rows=1027 width=16)
         Index Cond: (id <= 1000)
   ->  Index Scan using orders_customer_id_idx on orders o  (cost=0.43..36.75 rows=11 width=16)
         Index Cond: (customer_id = c.id)
(5 rows)

Time: 0.820 ms

market=# EXPLAIN SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <= 20000;
                                             QUERY PLAN                                              
-----------------------------------------------------------------------------------------------------
 Hash Join  (cost=1056.09..42973.20 rows=199890 width=24)
   Hash Cond: (o.customer_id = c.id)
   ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=16)
   ->  Hash  (cost=806.23..806.23 rows=19989 width=16)
         ->  Index Scan using customers_pkey on customers c  (cost=0.42..806.23 rows=19989 width=16)
               Index Cond: (id <= 20000)
(6 rows)

Time: 0.918 ms
```

Dez clientes: um nested loop, com os dez clientes do lado de fora e uma varredura bitmap dos pedidos
deles do lado de dentro. Mil: ainda um nested loop, agora com uma varredura de índice simples dentro.
Vinte mil: um hash join, com os vinte mil clientes em hash e os dois milhões de pedidos lidos uma vez
diante deles.

A aritmética por trás da virada é a da aula 3, e dá para lê-la direto nestes planos:

| clientes externos | nested loop ≈ linhas externas × uma busca | hash join ≈ uma passada por `orders` + o hash |
|---|---|---|
| 10 | 10 × 47.80 ≈ 478 → impresso `487.72` | pelo menos `36667` só pela varredura |
| 1000 | 1027 × 36.75 ≈ 37742 → impresso `37897.88` | pelo menos `36667` |
| 20000 | 19989 × 36.75 ≈ 734596 | impresso `42973.20` |

**O custo de um nested loop cresce com as linhas externas; o de um hash join quase não cresce**,
porque ele lê o lado grande uma vez, aconteça o que acontecer, e só o hash aumenta. Com mil clientes,
os 37898 do loop são pouco mais que uma passada por `orders` sozinha, e um hash join somaria a essa
passada a consulta de dois milhões de linhas, então o loop ainda ganha; com vinte mil, o loop
custaria dezessete vezes o hash join. Em algum ponto entre os dois a linha é cruzada, e onde depende
das entradas: o preço de uma busca, o tamanho da tabela a varrer, a memória para o hash.

## Que lado vai onde

A virada também mostra a outra escolha que o planejador faz, a **ordem da junção**. Nos dois nested
loops os clientes são o lado externo, porque são menos e o lado interno, `orders`, tem um índice em
`customer_id` para consultar. No hash join os clientes são o lado em hash, porque 20000 linhas fazem
uma tabela menor que dois milhões. Na página do pedido da aula 3, as linhas eram o lado externo e os
produtos o interno, pelo mesmo motivo ao contrário: quatro linhas, e um índice em `products.id`.

Com duas tabelas há só um punhado de arranjos para precificar. Com mais, o número cresce rápido, e o
planejador busca as ordens que consegue bancar; a regra que ele segue não muda — entradas menores e
filtradas cedo e do lado de fora, grandes varridas uma vez ou consultadas por um índice.

## A estimativa é a entrada que importa

Cada linha daquela tabela foi calculada a partir de uma **estimativa**: 10, 1027, 19989 clientes, 11
pedidos por cliente. Aqui as estimativas estão perto da verdade, então as escolhas estão certas.
Agora imagine que o planejador espera 10 clientes e chegam 200000. Ele escolhe o nested loop, põe o
preço em algumas centenas, e depois roda a busca interna duzentas mil vezes. Nada na junção estava
errado; era a junção certa para um número que não era verdadeiro.

É por isso que a primeira pergunta sobre uma junção ruim nunca é "que método ela deveria ter usado?",
e sim **"quantas linhas ela esperava de cada lado, e quantas vieram?"**. Compare `rows` na estimativa
e `rows` no real nos filhos da junção, como a aula 3 ensinou, e a primeira diferença grande que você
achar a partir do pé da árvore costuma ser a causa de tudo acima dela. A aula 6 constrói essa
diferença de propósito, com estatísticas que envelheceram, e a segue árvore acima até uma junção que
escolhe o método errado.

E quando as estimativas estão certas e a escolha ainda está errada, como a seção do merge join
descobriu, a entrada a questionar é a tabela de preços, não a junção.

## Os três, lado a lado

| | nested loop | hash join | merge join |
|---|---|---|---|
| bom quando | poucas linhas externas, um índice no lado interno | duas entradas grandes, uma pequena o bastante para o hash | as duas entradas já na ordem da junção |
| o custo cresce com | linhas externas × busca | uma passada por cada lado | uma passada por cada lado |
| precisa de | um índice na coluna de junção interna, de preferência | memória: `work_mem` × `hash_mem_multiplier` | entradas ordenadas, ou uma ordenação na frente |
| o sinal de alerta | `loops` na casa dos milhares onde se esperavam poucos | `Batches` acima de 1, o lado grande em hash | um `Sort` na frente de cada entrada |
