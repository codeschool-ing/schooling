---
title: A varredura de índice, e a ordem em que as linhas estão
version: 1
---

Uma varredura de índice desce a árvore B até a primeira entrada que bate, percorre as entradas na
ordem do índice e, para cada uma, **busca na tabela a linha para a qual ela aponta**. Duas coisas a
tornam rápida ou lenta, e só a primeira é a que as pessoas lembram: quantas entradas batem, e em
quantas páginas diferentes da tabela essas entradas apontam.

## Uma linha

O caso menor é uma chave primária:

```
market=# EXPLAIN ANALYZE SELECT * FROM orders WHERE id = 42;
                                                     QUERY PLAN                                                      
---------------------------------------------------------------------------------------------------------------------
 Index Scan using orders_pkey on orders  (cost=0.43..8.45 rows=1 width=37) (actual time=0.097..0.098 rows=1 loops=1)
   Index Cond: (id = 42)
 Planning Time: 0.600 ms
 Execution Time: 0.178 ms
(4 rows)

Time: 1.987 ms
```

`Index Cond: (id = 42)` e mais nada. Algumas páginas do índice, da raiz da árvore até a folha, uma
página da tabela para a linha, e um custo total de `8.45` contra os `36667.00` de uma varredura
sequencial da mesma tabela. **Para um punhado de linhas, nada é mais barato**, porque o trabalho é
proporcional às linhas encontradas e não ao tamanho da tabela.

O custo inicial, `0.43`, é a descida da árvore antes de chegar à primeira entrada. É por isso que
uma varredura de índice também é o plano de que um `LIMIT` gosta, como a aula 3 mostrou com os dez
pedidos mais antigos: as linhas saem na ordem do índice, uma por vez, desde a primeira página
tocada.

## Um dia de pedidos, em 35 páginas

Desligue os planos paralelos na sessão, como na aula 3, para que cada plano seja uma árvore só, e
some os pedidos de um dia:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.341 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=135.56..135.57 rows=1 width=8) (actual time=1.390..1.391 rows=1 loops=1)
   Buffers: shared read=35
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..127.77 rows=3117 width=4) (actual time=0.093..1.007 rows=2801 loops=1)
         Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-06-02 00:00:00-03'::timestamp with time zone))
         Buffers: shared read=35
 Planning:
   Buffers: shared hit=116
 Planning Time: 0.721 ms
 Execution Time: 1.493 ms
(9 rows)

Time: 3.271 ms
```

**2801 linhas de 35 páginas.** As entradas do índice para primeiro de junho levam a linhas que estão
uma ao lado da outra na tabela, umas 120 por página, então a varredura buscou umas poucas dezenas de
páginas e achou boa parte dos pedidos do dia em cada uma. Não é sorte. O `market.sql` gravou os
pedidos na ordem em que foram feitos, que é como cresce a maioria das tabelas que registram
eventos: as linhas de hoje vão para o fim.

## Correlação

O PostgreSQL mede essa propriedade por coluna, como parte das estatísticas que o `ANALYZE` coleta:

```
market=# SELECT attname, correlation FROM pg_stats WHERE tablename = 'orders' AND attname IN ('placed_at', 'customer_id', 'seller_id');
   attname   | correlation  
-------------+--------------
 customer_id | 0.0064027454
 seller_id   |   0.07900135
 placed_at   |            1
(3 rows)

Time: 5.070 ms
```

**`correlation` diz o quanto a ordem dos valores de uma coluna acompanha a ordem das linhas no
disco**, de 1 (exatamente a mesma ordem), passando por 0 (nenhuma relação), até −1 (exatamente
invertida). `placed_at` é 1: percorrer o índice dela é percorrer a tabela de frente para trás.
`customer_id` é 0,006: os pedidos do cliente 1000 e os do cliente 1001 estão em qualquer lugar da
tabela, com três anos de distância. O planejador usa esse número quando precifica uma varredura de
índice. Com correlação perto de 1 ele cobra as páginas buscadas como se fossem lidas em sequência;
perto de 0, como leituras aleatórias a `random_page_cost`, que é 4 contra 1.

Para ver quanto custa uma correlação zero, pegue cerca de um terço das linhas daquele dia — os
pedidos de cem clientes — e faça o planejador buscá-las pelo índice. O segundo `SET` desliga as
varreduras bitmap na sessão, por um motivo que a próxima seção explica; aqui ele serve só para
mostrar a varredura de índice simples:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.366 ms

market=# SET enable_bitmapscan = off;
SET
Time: 0.278 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=4240.69..4240.70 rows=1 width=8) (actual time=5.743..5.744 rows=1 loops=1)
   Buffers: shared hit=160 read=834
   ->  Index Scan using orders_customer_id_idx on orders  (cost=0.43..4237.98 rows=1086 width=4) (actual time=0.027..5.620 rows=991 loops=1)
         Index Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
         Buffers: shared hit=160 read=834
 Planning:
   Buffers: shared hit=123 read=3
 Planning Time: 0.713 ms
 Execution Time: 5.813 ms
(9 rows)

Time: 7.579 ms
```

**991 linhas, e 994 páginas tocadas.** Cada linha veio de uma página diferente: os pedidos de cem
clientes espalhados por três anos de tabela, então cada busca caiu num lugar novo e quase nenhuma
dividiu página com a anterior. Um terço das linhas do dia de cima custou quase trinta vezes as
páginas. O planejador pôs o preço em `4237.98`, contra `127.77` para as 2801 linhas do dia, e a
diferença entre esses dois custos é quase toda a correlação.

Essa é a fraqueza da varredura de índice. **Ela busca na ordem do índice, não na da tabela**, então
numa coluna sem correlação visita páginas em ordem aleatória, e quando duas linhas que batem dividem
uma página mas estão longe uma da outra no índice, ela lê essa página duas vezes. Com poucas linhas
isso não importa. Com milhares, é o plano mais lento disponível, e a próxima seção trata daquele que
o planejador escolhe no lugar.

## Do que uma varredura de índice precisa

- **poucas linhas que batem**, ou linhas que ficam juntas porque a coluna tem correlação com a ordem
  da tabela;
- **um índice cuja coluna inicial está na condição**, na forma em que o índice está escrito — o
  `date(placed_at)` da aula 1 foi o contraexemplo;
- uma consulta que tira proveito da ordem do índice, que é o caso do `ORDER BY … LIMIT`.

A aula 10 acrescenta a variante que dispensa a tabela, a varredura só de índice (index-only scan),
quando o índice tem todas as colunas que a consulta pede.
