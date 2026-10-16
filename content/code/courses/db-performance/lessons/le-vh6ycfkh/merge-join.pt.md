---
title: O merge join, e o planejador apanhado
version: 1
---

Um merge join precisa das duas entradas **ordenadas pela chave da junção**. Aí ele as percorre
juntas, como quem intercala à mão duas listas ordenadas: compara as duas linhas atuais, emite um
par quando as chaves batem, avança o lado que ficou para trás. Cada entrada é lida uma vez, em
ordem, e nenhuma tabela hash é montada.

O porém é a palavra *ordenadas*. Se uma entrada precisa ser ordenada antes, o custo inicial da
ordenação — a ordenação da aula 3, que não podia entregar nada antes de ter visto tudo — vem na
frente da junção. Um merge join se justifica quando a ordem vem de graça: de um índice na chave da
junção, ou de um nó abaixo que já produziu as linhas nessa ordem.

## Duas chaves primárias, ambas em ordem

`orders.id` e `order_lines.order_id` são, cada uma, a coluna inicial de uma chave primária, então
uma varredura de índice de cada uma entrega as linhas na ordem da junção sem custo extra. Junte os
duzentos mil primeiros pedidos às suas linhas e conte. Primeiro vem a escolha do planejador, depois
o plano que ele faria com os hash joins desligados na sessão — o jeito da aula 4 de perguntar pelo
plano rejeitado. Cada um rodou uma vez antes da execução impressa, então os dois estão quentes:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.465 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;
                                                                        QUERY PLAN                                                                         
-----------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=145144.82..145144.83 rows=1 width=8) (actual time=1391.081..1391.090 rows=1 loops=1)
   Buffers: shared hit=2767 read=29631, temp read=8879 written=8879
   ->  Hash Join  (cost=9057.96..143883.88 rows=504377 width=0) (actual time=54.065..1367.600 rows=500000 loops=1)
         Hash Cond: (l.order_id = o.id)
         Buffers: shared hit=2767 read=29631, temp read=8879 written=8879
         ->  Seq Scan on order_lines l  (cost=0.00..81847.92 rows=4999992 width=8) (actual time=3.505..399.658 rows=5000000 loops=1)
               Buffers: shared hit=2217 read=29631
         ->  Hash  (cost=5747.07..5747.07 rows=201751 width=8) (actual time=49.344..49.348 rows=200000 loops=1)
               Buckets: 262144  Batches: 2  Memory Usage: 5966kB
               Buffers: shared hit=550, temp written=340
               ->  Index Only Scan using orders_pkey on orders o  (cost=0.43..5747.07 rows=201751 width=8) (actual time=0.042..16.594 rows=200000 loops=1)
                     Index Cond: (id <= 200000)
                     Heap Fetches: 0
                     Buffers: shared hit=550
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.315 ms
 JIT:
   Functions: 10
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.370 ms, Inlining 0.000 ms, Optimization 0.226 ms, Emission 3.363 ms, Total 3.959 ms
 Execution Time: 1392.046 ms
(22 rows)

Time: 1393.115 ms (00:01.393)

market=# SET enable_hashjoin = off;
SET
Time: 0.374 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;
                                                                            QUERY PLAN                                                                            
------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=177245.60..177245.61 rows=1 width=8) (actual time=170.424..170.426 rows=1 loops=1)
   Buffers: shared hit=2477
   ->  Merge Join  (cost=4.75..175984.65 rows=504377 width=0) (actual time=2.473..143.094 rows=500000 loops=1)
         Merge Cond: (o.id = l.order_id)
         Buffers: shared hit=2477
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.43..5747.07 rows=201751 width=8) (actual time=0.013..20.031 rows=200000 loops=1)
               Index Cond: (id <= 200000)
               Heap Fetches: 0
               Buffers: shared hit=550
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..152204.31 rows=4999992 width=8) (actual time=0.035..48.203 rows=500001 loops=1)
               Heap Fetches: 0
               Buffers: shared hit=1927
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.278 ms
 JIT:
   Functions: 6
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.306 ms, Inlining 0.000 ms, Optimization 0.172 ms, Emission 2.296 ms, Total 2.775 ms
 Execution Time: 170.886 ms
(20 rows)

Time: 171.969 ms
```

O planejador escolheu um hash join, e ele levou **1392 milissegundos**: leu as cinco milhões de
linhas de pedido da tabela para ficar com o meio milhão dos duzentos mil primeiros pedidos, e
derramou para arquivos temporários no caminho. O merge join que ele rejeitou levou **171**, oito
vezes menos. Os dois `Index Only Scan` dele entregaram as linhas já na ordem de `id`, e olhe o
segundo: `rows=500001`. O merge parou de ler `order_lines` assim que passou do pedido 200000, uma
linha além da última que batia, então tocou 2477 páginas, enquanto o hash join tocou mais de trinta
mil.

Ou seja, o planejador errou, por um fator de oito, numa junção simples com boas estimativas — 504377
linhas esperadas, 500000 achadas. **A estimativa estava certa e a escolha, ainda assim, errada**, o
que quer dizer que outra das entradas dele estava fora.

## Qual entrada

A aula 3 mostrou que todo custo é aritmética sobre uma tabela de preços, e o preço que domina uma
varredura de índice é o `random_page_cost`: 4, contra 1 para uma página lida em sequência. O plano
do merge join são duas varreduras de índice; o do hash join é sobretudo uma varredura sequencial.
Pergunte o que o planejador escolheria se uma página fora de ordem custasse mais ou menos o que
custa uma página em ordem:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.455 ms

market=# SET random_page_cost = 1.1;
SET
Time: 0.469 ms

market=# EXPLAIN SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;
                                                   QUERY PLAN                                                    
-----------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=119671.14..119671.15 rows=1 width=8)
   ->  Merge Join  (cost=3.43..118410.20 rows=504377 width=0)
         Merge Cond: (o.id = l.order_id)
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.43..4140.47 rows=201751 width=8)
               Index Cond: (id <= 200000)
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..96231.41 rows=4999992 width=8)
 JIT:
   Functions: 6
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(9 rows)

Time: 19.341 ms
```

Com o `random_page_cost` em 1.1 o merge join custa `119671.15`, abaixo dos `145144.83` do hash join,
e o planejador o escolhe sozinho. Nesta máquina o banco inteiro cabe no cache do sistema
operacional, como a aula 1 mediu, então uma leitura "aleatória" é uma cópia da memória, e o padrão
de 4 cobra a mais por toda varredura de índice. Foi essa a entrada que o enganou aqui.

Isso ainda não é um conserto para digitar numa sessão e esquecer. O `random_page_cost` certo é um
fato sobre o armazenamento da máquina, medido com a carga toda e ajustado uma vez na configuração, e
`db-administration` é onde isso se decide. O que esta seção acrescenta é o método: o plano forçado
disse que o planejador errou, as estimativas disseram que as linhas não eram o motivo, e a tabela de
preços disse qual era. Feche o `psql`, ou dê `RESET` nos dois ajustes, antes de seguir.

## Quando um merge join é a resposta certa

- as duas entradas já estão na ordem da junção, por um índice ou por um nó abaixo;
- as entradas são grandes, então as buscas de um nested loop seriam muitas;
- uma tabela hash de qualquer um dos lados seria grande, ou a consulta também quer o resultado nessa
  ordem — a saída de um merge join sai ordenada pela chave, então um `ORDER BY` nela não custa nada a
  mais.

E é o único dos três que consegue **parar cedo numa faixa**, como fez aqui, porque os dois lados
chegam em ordem e a primeira chave depois do fim de um lado encerra a junção.
