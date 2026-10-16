---
title: Um número errado, e tudo o que se constrói sobre ele
version: 1
---

Uma estimativa errada num scan que lê a tabela inteira de qualquer jeito não custa nada por si só. O
que ela custa é **tudo o que está acima dela**: o método de join escolhido para as linhas que o scan
devolve, o lado sobre o qual uma tabela hash é construída, se uma ordenação é planejada na memória,
como os grupos são contados. Cada uma dessas é uma decisão tomada para a estimativa, e a aula 5
mostrou como os três métodos de join se comportam de jeitos diferentes quando o número de linhas
muda.

A consulta desta seção é uma tela que a equipe de operações usa: que vendedor tem mais pedidos
pendentes, e em que estado, para planejar as entregas. Ela junta `orders` a `sellers` e a
`customers`.

## Antes da importação

Rodada no banco como a aula 3 começa, com os seus 7319 pedidos pendentes e estatísticas que os
descrevem certo:

```
market=# EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=50054.74..50054.75 rows=5 width=21) (actual time=212.504..212.510 rows=5 loops=1)
   ->  Sort  (cost=50054.74..50071.24 rows=6600 width=21) (actual time=212.502..212.507 rows=5 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  GroupAggregate  (cost=49813.12..49945.12 rows=6600 width=21) (actual time=210.647..212.077 rows=3435 loops=1)
               Group Key: s.name, c.state
               ->  Sort  (cost=49813.12..49829.62 rows=6600 width=13) (actual time=210.624..210.935 rows=7319 loops=1)
                     Sort Key: s.name, c.state
                     Sort Method: quicksort  Memory: 493kB
                     ->  Hash Join  (cost=41778.00..49394.40 rows=6600 width=13) (actual time=161.481..205.961 rows=7319 loops=1)
                           Hash Cond: (o.seller_id = s.id)
                           ->  Hash Join  (cost=41749.50..49348.50 rows=6600 width=7) (actual time=161.106..204.167 rows=7319 loops=1)
                                 Hash Cond: (c.id = o.customer_id)
                                 ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.002..22.685 rows=200000 loops=1)
                                 ->  Hash  (cost=41667.00..41667.00 rows=6600 width=8) (actual time=161.021..161.022 rows=7319 loops=1)
                                       Buckets: 8192  Batches: 1  Memory Usage: 350kB
                                       ->  Seq Scan on orders o  (cost=0.00..41667.00 rows=6600 width=8) (actual time=159.386..160.109 rows=7319 loops=1)
                                             Filter: (status = 'pending'::text)
                                             Rows Removed by Filter: 1992681
                           ->  Hash  (cost=16.00..16.00 rows=1000 width=14) (actual time=0.358..0.359 rows=1000 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 55kB
                                 ->  Seq Scan on sellers s  (cost=0.00..16.00 rows=1000 width=14) (actual time=0.015..0.147 rows=1000 loops=1)
 Planning Time: 1.278 ms
 Execution Time: 212.766 ms
(24 rows)

Time: 234.594 ms
```

Todo nó abaixo do agrupamento bate com a estimativa dentro de 10%: 6600 pedidos pendentes esperados,
7319 achados. O plano são dois hash joins. O lado pequeno de cada um, os 7319 pedidos e os 1000
vendedores, é o que vira tabela hash, que é o jeito certo. Depois uma ordenação na memória, 493 kB, e
os grupos contados em ordem: **213 milissegundos**, a maior parte lendo `orders`.

## Depois da importação, antes do `ANALYZE`

A mesma consulta, depois da importação da seção 03, com as estatísticas ainda dizendo 0,0033:

```
market=# EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=57599.04..57599.06 rows=5 width=21) (actual time=661.501..661.511 rows=5 loops=1)
   ->  Sort  (cost=57599.04..57618.02 rows=7590 width=21) (actual time=661.500..661.508 rows=5 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  GroupAggregate  (cost=57321.18..57472.98 rows=7590 width=21) (actual time=605.205..660.587 rows=9000 loops=1)
               Group Key: s.name, c.state
               ->  Sort  (cost=57321.18..57340.15 rows=7590 width=13) (actual time=605.177..640.593 rows=307319 loops=1)
                     Sort Key: s.name, c.state
                     Sort Method: external merge  Disk: 7216kB
                     ->  Nested Loop  (cost=7565.28..56832.01 rows=7590 width=13) (actual time=163.166..415.153 rows=307319 loops=1)
                           ->  Hash Join  (cost=7565.00..56343.85 rows=7590 width=7) (actual time=161.908..335.908 rows=307319 loops=1)
                                 Hash Cond: (o.customer_id = c.id)
                                 ->  Seq Scan on orders o  (cost=0.00..47916.93 rows=7590 width=8) (actual time=107.107..148.260 rows=307319 loops=1)
                                       Filter: (status = 'pending'::text)
                                       Rows Removed by Filter: 1992681
                                 ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=53.694..53.696 rows=200000 loops=1)
                                       Buckets: 262144  Batches: 2  Memory Usage: 5966kB
                                       ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.018..20.372 rows=200000 loops=1)
                           ->  Memoize  (cost=0.29..0.31 rows=1 width=14) (actual time=0.000..0.000 rows=1 loops=307319)
                                 Cache Key: o.seller_id
                                 Cache Mode: logical
                                 Hits: 306319  Misses: 1000  Evictions: 0  Overflows: 0  Memory Usage: 114kB
                                 ->  Index Scan using sellers_pkey on sellers s  (cost=0.28..0.30 rows=1 width=14) (actual time=0.001..0.001 rows=1 loops=1000)
                                       Index Cond: (id = o.seller_id)
 Planning Time: 1.035 ms
 Execution Time: 662.895 ms
(26 rows)

Time: 665.444 ms
```

**663 milissegundos.** Leia de baixo para cima, como a seção 02 disse.

- **`Seq Scan on orders`**: 7590 estimadas, **307.319** reais. Este é o nó mais baixo em que os dois
  se separam, e a causa.
- **`Hash Join`**: os mesmos 7590 contra 307.319, herdados. Aqui o planejador fez uma escolha que se
  sustentou, construindo o hash sobre `customers` e não sobre os pedidos.
- **`Nested Loop` com `Memoize` em `sellers`**: escolhido porque um laço de sete mil buscas, com um
  cache na frente do índice dos vendedores, sai mais barato que construir outra tabela hash. Ele rodou
  **307.319 vezes**. O cache o salvou, 306.319 acertos e 1000 faltas, mas cada uma dessas 307.319
  linhas ainda passou pelo laço. É o nested loop de que a aula 5 avisou: certo para alguns milhares
  de linhas do lado de fora, errado para trezentas mil.
- **`Sort`**: planejado para 7590 linhas na memória, recebeu 307.319 e **transbordou 7216 kB para o
  disco**, `external merge`. A memória planejada para uma estimativa é gasta com o real.
- **`GroupAggregate`** esperava 7590 grupos e achou 9000, a única estimativa aqui que acertou mais ou
  menos, por acaso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O plano velho como árvore, lido de baixo para cima. Embaixo, Seq Scan em orders estimou 7.590 linhas e devolveu 307.319: o nó mais baixo em que estimativa e real se separam. Todo nó acima herda o erro: o Hash Join, estimado em 7.590 contra 307.319; o Nested Loop com Memoize em sellers, escolhido para alguns milhares de buscas e executado 307.319 vezes; o Sort planejado na memória, que transbordou 7.216 kB para o disco; e o GroupAggregate. customers, do outro lado do hash join, foi estimada certo em 200.000.\"><rect x=\"230\" y=\"20\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"240\" y=\"35\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GroupAggregate</text><text x=\"240\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"305\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"365\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reais</text><text x=\"405\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">9,000</text><rect x=\"230\" y=\"78\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sort</text><text x=\"240\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"305\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"365\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reais</text><text x=\"405\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"230\" y=\"136\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Nested Loop + Memoize</text><text x=\"240\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"305\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"365\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reais</text><text x=\"405\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"100\" y=\"194\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"209\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Hash Join</text><text x=\"110\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"175\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"235\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reais</text><text x=\"275\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"14\" y=\"252\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"267\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Seq Scan on orders</text><text x=\"24\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"89\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"149\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reais</text><text x=\"189\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"330\" y=\"252\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"340\" y=\"267\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Seq Scan on customers</text><text x=\"340\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"405\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">200,000</text><text x=\"465\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reais</text><text x=\"505\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">200,000</text><path d=\"M355 64 L355 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M355 122 L355 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M355 180 L225 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M225 238 L139 252\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M225 238 L455 252\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"500\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Sort: 7.216 kB</text><text x=\"500\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">transbordou para o disco</text><text x=\"500\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">307.319 loops</text><text x=\"14\" y=\"316\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o nó mais baixo onde os dois se separam: comece a ler por aqui</text></svg>", "caption": "Onde o plano velho errou, e o que arrastou junto. Um número errado embaixo; toda escolha acima dele foi feita para esse número."}
```

## Depois do `ANALYZE`

Tire uma fotografia nova de `orders`, e rode a consulta de novo:

```
market=# ANALYZE orders;
ANALYZE
Time: 131.735 ms

market=# EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
                                                                      QUERY PLAN                                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=62714.17..62714.19 rows=5 width=21) (actual time=463.852..463.873 rows=5 loops=1)
   ->  Sort  (cost=62714.17..62736.67 rows=9000 width=21) (actual time=463.850..463.869 rows=5 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  HashAggregate  (cost=62474.69..62564.69 rows=9000 width=21) (actual time=461.940..462.854 rows=9000 loops=1)
               Group Key: s.name, c.state
               Batches: 1  Memory Usage: 1169kB
               ->  Hash Join  (cost=7593.50..60221.26 rows=300457 width=13) (actual time=186.243..397.733 rows=307319 loops=1)
                     Hash Cond: (o.seller_id = s.id)
                     ->  Hash Join  (cost=7565.00..59400.72 rows=300457 width=7) (actual time=185.889..355.253 rows=307319 loops=1)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Seq Scan on orders o  (cost=0.00..47917.00 rows=300457 width=8) (actual time=127.722..165.349 rows=307319 loops=1)
                                 Filter: (status = 'pending'::text)
                                 Rows Removed by Filter: 1992681
                           ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=57.098..57.099 rows=200000 loops=1)
                                 Buckets: 262144  Batches: 2  Memory Usage: 5966kB
                                 ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.014..21.839 rows=200000 loops=1)
                     ->  Hash  (cost=16.00..16.00 rows=1000 width=14) (actual time=0.336..0.351 rows=1000 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 55kB
                           ->  Seq Scan on sellers s  (cost=0.00..16.00 rows=1000 width=14) (actual time=0.011..0.121 rows=1000 loops=1)
 Planning Time: 0.994 ms
 Execution Time: 464.233 ms
(22 rows)

Time: 466.854 ms
```

A estimativa do scan agora é **300.457** contra 307.319, e todo nó acima dela mudou junto. Os dois
joins são hash joins. A busca dos vendedores é uma tabela hash de 55 kB em vez de um laço rodando
307.319 vezes. Os grupos são contados num `HashAggregate` em 1169 kB de memória, sem ordenar trezentas
mil linhas e sem gravar nada no disco. **464 milissegundos**, contra 663 para a mesma consulta e as
mesmas linhas um minuto antes.

É uma diferença de 30%, e vale ser honesto sobre o tamanho dela. Nesta máquina, com todo o `market` no
cache do sistema operacional, o plano pior não foi um desastre; ler 2,3 milhões de pedidos é a maior
parte do tempo de qualquer jeito. A cascata fica cara quando o laço de aparência barata lá embaixo
busca numa tabela que não está na memória, ou quando as linhas mal estimadas alimentam um segundo e um
terceiro join que as multiplicam. O que não depende da máquina é o padrão: **uma razão de 40 lá
embaixo, e todo operador acima dela escolhido para o número errado**.

## O hábito

Quando um plano está lento, antes de olhar que método de join ele escolheu, ache o nó mais baixo cujas
linhas reais estão longe da estimativa. Depois pergunte por que essa estimativa está errada. Aqui ela
estava velha, e o `ANALYZE` a consertou em 132 milissegundos. A aula 7 é a outra metade da resposta:
estimativas erradas embora as estatísticas estejam frescas, e o que dar ao planejador nesse caso.
