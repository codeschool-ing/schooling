---
title: O hash join, e a memória de que ele precisa
version: 1
---

Um hash join trabalha em duas fases. Primeiro lê uma entrada inteira — o lado de **construção**, o
filho embaixo do nó `Hash` — e põe cada linha numa tabela hash na memória, pela coluna da junção.
Depois lê a outra entrada — o lado de **consulta** — uma vez, e procura a chave de cada linha na
tabela hash. Cada busca leva mais ou menos o mesmo tempo, seja qual for o tamanho da tabela, e não
há índice envolvido.

Isso o torna a junção para **duas entradas grandes**, ou uma grande contra uma média: o custo é uma
passada por cada lado, não uma busca por linha. O preço é memória, e o plano diz exatamente quanto.

## Pedidos por estado

Cada pedido junto ao seu cliente, contado por estado. Cada comando desta seção rodou uma vez antes
do impresso, então os tempos são quentes:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.498 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=75890.11..75890.20 rows=9 width=11) (actual time=1331.942..1331.949 rows=9 loops=1)
   Group Key: c.state
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=4531 read=14419, temp read=3262 written=3262
   ->  Hash Join  (cost=7565.00..65890.11 rows=2000000 width=3) (actual time=55.542..1082.460 rows=2000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         Buffers: shared hit=4531 read=14419, temp read=3262 written=3262
         ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=4) (actual time=0.068..187.424 rows=2000000 loops=1)
               Buffers: shared hit=2248 read=14419
         ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=54.364..54.367 rows=200000 loops=1)
               Buckets: 262144  Batches: 2  Memory Usage: 5966kB
               Buffers: shared hit=2283, temp written=340
               ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.014..20.245 rows=200000 loops=1)
                     Buffers: shared hit=2283
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.274 ms
 Execution Time: 1332.031 ms
(18 rows)

Time: 1337.217 ms (00:01.337)
```

O nó `Hash` montou uma tabela a partir de `customers`, todos os 200000; o `Seq Scan on orders`
acima dele passou dois milhões de pedidos por ela, e cada um achou o seu cliente por `Hash Cond:
(o.customer_id = c.id)`. **O planejador fez o hash do lado menor**: 200000 clientes, e não dois
milhões de pedidos. É a primeira coisa a conferir em qualquer hash join, e quem decide são as
estimativas de linhas dos dois filhos. Um hash join que constrói sobre o lado que o planejador achou
pequeno, e não era, é assunto da aula 6.

Agora a linha embaixo do `Hash`:

```
Buckets: 262144  Batches: 2  Memory Usage: 5966kB
```

`Buckets` é o tamanho da tabela hash. **`Batches: 2` quer dizer que a tabela não coube na memória
permitida à junção.** Então o lado de construção foi dividido em duas partes, uma mantida na memória
e outra gravada num arquivo temporário, e o lado de consulta foi dividido do mesmo jeito. Cada linha
de consulta cujo par está na segunda parte é gravada em disco e lida de volta depois. O `temp
read=3262 written=3262` na linha do `Hash Join` é esse tráfego: 3262 páginas de 8 kB, uns 25 MB,
gravados e lidos de novo.

A memória permitida é o `work_mem` vezes o `hash_mem_multiplier`: 4 MB vezes 2 por padrão. A tabela
dos clientes precisou de um pouco mais que isso, então foi para dois lotes.

## Mudando a memória

A mesma junção com o `work_mem` em 1 MB e depois em 32 MB, os dois só na sessão:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.484 ms

market=# SET work_mem = '1MB';
SET
Time: 0.392 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=75890.11..75890.20 rows=9 width=11) (actual time=942.778..942.786 rows=9 loops=1)
   Group Key: c.state
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=4595 read=14355, temp read=5729 written=5729
   ->  Hash Join  (cost=7565.00..65890.11 rows=2000000 width=3) (actual time=44.818..712.901 rows=2000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         Buffers: shared hit=4595 read=14355, temp read=5729 written=5729
         ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=4) (actual time=0.075..171.397 rows=2000000 loops=1)
               Buffers: shared hit=2312 read=14355
         ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=43.786..43.789 rows=200000 loops=1)
               Buckets: 65536  Batches: 8  Memory Usage: 1491kB
               Buffers: shared hit=2283, temp written=594
               ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.008..18.495 rows=200000 loops=1)
                     Buffers: shared hit=2283
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.282 ms
 Execution Time: 942.935 ms
(18 rows)

Time: 943.912 ms

market=# SET work_mem = '32MB';
SET
Time: 0.350 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=58700.11..58700.20 rows=9 width=11) (actual time=1401.331..1401.340 rows=9 loops=1)
   Group Key: c.state
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=4659 read=14291
   ->  Hash Join  (cost=6783.00..48700.11 rows=2000000 width=3) (actual time=65.163..1157.497 rows=2000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         Buffers: shared hit=4659 read=14291
         ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=4) (actual time=0.079..157.691 rows=2000000 loops=1)
               Buffers: shared hit=2376 read=14291
         ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=63.939..63.943 rows=200000 loops=1)
               Buckets: 262144  Batches: 1  Memory Usage: 9861kB
               Buffers: shared hit=2283
               ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.017..23.579 rows=200000 loops=1)
                     Buffers: shared hit=2283
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.262 ms
 Execution Time: 1401.457 ms
(18 rows)

Time: 1403.509 ms (00:01.404)

market=# RESET work_mem;
RESET
Time: 0.405 ms

market=# SHOW hash_mem_multiplier;
 hash_mem_multiplier 
---------------------
 2
(1 row)

Time: 0.441 ms
```

Com 1 MB o hash foi para **8 lotes** e o tráfego temporário cresceu para 5729 páginas. Com 32 MB
coube em **1 lote, 9861 kB**, e a linha `temp` sumiu. O custo do planejador acompanhou: a estimativa
da consulta inteira caiu de `75890.11` para `58700.11` quando os lotes acabaram.

Os tempos não acompanharam. 943 milissegundos com oito lotes, 1332 com dois, 1401 com um: o que não
gravou nada em disco foi o mais lento dos três. Os arquivos temporários eram pequenos o bastante
para o sistema operacional mantê-los na memória, então gravá-los custou pouco, e o tempo foi para o
que os três fizeram igual, dois milhões de consultas e dois milhões de linhas contadas. Um motivo
provável de os lotes menores terem ido melhor é que uma tabela hash de 1,5 MB cabe no cache do
processador e uma de 10 MB não, mas nada nesta tela prova isso. **O que a tela prova é que `Batches`
acima de 1 é um custo que o planejador cobra, não um veredito**: meça antes de aumentar o `work_mem`
para eliminá-lo. A aula 6 de `db-administration` é a aritmética de aumentá-lo, porque cada hash e
cada ordenação de cada conexão pode usar esse tanto ao mesmo tempo.

## O melhor caso: um lado de construção pequeno

Receita por vendedor, de toda linha de pedido junto ao seu produto:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.676 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT p.seller_id, sum(l.quantity * l.price_cents) AS revenue FROM order_lines AS l JOIN products AS p ON p.id = l.product_id GROUP BY p.seller_id ORDER BY revenue DESC LIMIT 5;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=134274.56..134274.57 rows=5 width=12) (actual time=2204.021..2204.029 rows=5 loops=1)
   Buffers: shared hit=2156 read=30344
   ->  Sort  (cost=134274.56..134277.06 rows=1000 width=12) (actual time=2189.217..2189.223 rows=5 loops=1)
         Sort Key: (sum((l.quantity * l.price_cents))) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=2156 read=30344
         ->  HashAggregate  (cost=134247.95..134257.95 rows=1000 width=12) (actual time=2188.950..2189.040 rows=1000 loops=1)
               Group Key: p.seller_id
               Batches: 1  Memory Usage: 129kB
               Buffers: shared hit=2153 read=30344
               ->  Hash Join  (cost=1774.00..96748.01 rows=4999992 width=12) (actual time=26.427..1656.072 rows=5000000 loops=1)
                     Hash Cond: (l.product_id = p.id)
                     Buffers: shared hit=2153 read=30344
                     ->  Seq Scan on order_lines l  (cost=0.00..81847.92 rows=4999992 width=12) (actual time=0.057..382.860 rows=5000000 loops=1)
                           Buffers: shared hit=2153 read=29695
                     ->  Hash  (cost=1149.00..1149.00 rows=50000 width=8) (actual time=25.931..25.933 rows=50000 loops=1)
                           Buckets: 65536  Batches: 1  Memory Usage: 2466kB
                           Buffers: shared read=649
                           ->  Seq Scan on products p  (cost=0.00..1149.00 rows=50000 width=8) (actual time=0.107..11.866 rows=50000 loops=1)
                                 Buffers: shared read=649
 Planning:
   Buffers: shared hit=147 read=10
 Planning Time: 1.527 ms
 JIT:
   Functions: 16
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.900 ms, Inlining 0.000 ms, Optimization 0.843 ms, Emission 14.113 ms, Total 15.857 ms
 Execution Time: 2230.844 ms
(28 rows)

Time: 2235.224 ms (00:02.235)
```

Cinco milhões de linhas de pedido contra cinquenta mil produtos. O hash dos produtos ocupou **2466
kB e um lote**, montado em 26 milissegundos, e depois cinco milhões de consultas passaram por ele. É
o formato para o qual um hash join existe: uma tabela pequena, guardada na memória uma vez, contra
uma grande, lida uma vez. Um nested loop teria feito cinco milhões de buscas em índice em
`products`.

Os cinco vendedores saem de um `Limit` acima de um `Sort` acima de um `HashAggregate` — a agregação
também usa hash, uma entrada por vendedor, `Memory Usage: 129kB`. Hash não é só para junções; o
`GroupAggregate` da aula 3 era a alternativa ordenada.

## O que procurar

- **qual lado vira hash** — deveria ser o menor, pelas linhas reais, não só pela estimativa;
- **`Batches`** — 1 quer dizer que coube; mais quer dizer arquivos temporários, com `temp` na linha
  de `Buffers`;
- **as `rows` do lado de consulta** — um hash join paga uma passada inteira por ele, então, se esse
  lado tem um filtro seletivo e um índice, um nested loop pode ter sido o plano melhor, e a seção 05
  mostra onde fica essa linha.
