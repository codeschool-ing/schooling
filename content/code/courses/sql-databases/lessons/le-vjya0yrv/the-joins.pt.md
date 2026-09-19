---
title: Como uma junção é feita de fato
version: 1
---

A aula 5 disse o que uma junção significa. Não disse nada sobre como uma é calculada, porque não
havia como ver isso então. Há três algoritmos, o planejador escolhe um por junção, e cada um tem
uma forma no plano que diz se foi a escolha certa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 242\" role=\"img\" aria-label=\"Três painéis lado a lado. Nested Loop: três linhas à esquerda, cada uma com uma seta para um bloco de busca no índice à direita, rotulado como uma busca por linha. Hash Join: um lado de construção alimentando uma tabela hash, e um lado de sondagem com uma seta de volta para ela, rotulado como na memória ou ela transborda. Merge Join: duas colunas ordenadas de quatro valores cada, com setas pareando-as, rotulado como percorridas uma vez, juntas. Sob cada painel, quando é a escolha certa e o sinal no plano de que foi a errada.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Três jeitos de fazer a mesma junção. O planejador escolhe pelo formato das duas entradas, não por qual é mais rápido em geral.</text><rect x=\"14\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"126\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Nested Loop</text><text x=\"26\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">boa quando um lado é pequeno e o outro indexado</text><text x=\"26\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errada quando um Seq Scan interno, ou milhões de voltas</text><rect x=\"28\" y=\"72\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 1</text><path d=\"M94 82 L144 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 82 L137 78 L137 86 Z\" fill=\"var(--phosphor)\"></path><rect x=\"28\" y=\"98\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 2</text><path d=\"M94 108 L144 108\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 108 L137 104 L137 112 Z\" fill=\"var(--phosphor)\"></path><rect x=\"28\" y=\"124\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 3</text><path d=\"M94 134 L144 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 134 L137 130 L137 138 Z\" fill=\"var(--phosphor)\"></path><rect x=\"148\" y=\"72\" width=\"76\" height=\"72\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"186\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">index</text><text x=\"186\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">lookup</text><text x=\"28\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one lookup per row</text><rect x=\"248\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Hash Join</text><text x=\"260\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">boa quando os dois grandes, um cabe na memória</text><text x=\"260\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errada quando Batches bem acima de 1</text><rect x=\"262\" y=\"72\" width=\"84\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">build</text><path d=\"M304 118 L304 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><rect x=\"262\" y=\"136\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">hash table</text><rect x=\"374\" y=\"72\" width=\"84\" height=\"90\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"416\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">probe</text><path d=\"M374 149 L348 149\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M348 149 L355 145 L355 153 Z\" fill=\"var(--phosphor)\"></path><text x=\"262\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in memory, or it spills</text><rect x=\"482\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"594\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Merge Join</text><text x=\"494\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">boa quando os dois lados já ordenados</text><text x=\"494\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errada quando um Sort sob cada filho, em entradas grandes</text><text x=\"536\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">sorted</text><rect x=\"496\" y=\"76\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">10</text><rect x=\"496\" y=\"98\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">17</text><rect x=\"496\" y=\"120\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">24</text><rect x=\"496\" y=\"142\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">31</text><text x=\"652\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">sorted</text><rect x=\"612\" y=\"76\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">10</text><rect x=\"612\" y=\"98\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">17</text><rect x=\"612\" y=\"120\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">24</text><rect x=\"612\" y=\"142\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">31</text><path d=\"M578 85 L608 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 85 L601 81 L601 89 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 107 L608 107\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 107 L601 103 L601 111 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 129 L608 129\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 129 L601 125 L601 133 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 151 L608 151\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 151 L601 147 L601 155 Z\" fill=\"var(--phosphor)\"></path><text x=\"496\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">walked once, together</text><text x=\"14\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A ORDEM das junções é a outra decisão, e numa consulta de cinco tabelas vale ser lida antes dos métodos.</text></svg>", "caption": "O nome do nó é uma descrição do formato das entradas. Lido assim, \"por que um laço aninhado aqui\" vira uma pergunta sobre as contagens de linha embaixo dele."}
```

## Nested Loop: para cada linha de um lado, buscar o outro

```
shop=# EXPLAIN ANALYZE SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';
                                                               QUERY PLAN                                                               
----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.93..55.93 rows=10 width=23) (actual time=0.037..0.102 rows=13 loops=1)
   ->  Index Scan using customers_email_key on customers c  (cost=0.42..8.44 rows=1 width=17) (actual time=0.010..0.011 rows=1 loops=1)
         Index Cond: (email = 'user42@example.com'::text)
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.38 rows=11 width=14) (actual time=0.024..0.086 rows=13 loops=1)
         Recheck Cond: (c.id = customer_id)
         Heap Blocks: exact=13
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.010..0.010 rows=13 loops=1)
               Index Cond: (customer_id = c.id)
 Planning Time: 0.704 ms
 Execution Time: 0.166 ms
(10 rows)
```

O filho externo roda uma vez e acha um cliente. Para cada linha que ele produz — uma — o filho
interno roda e acha os pedidos daquele cliente pelo índice. `loops=1` no nó interno aqui, porque
houve uma linha externa.

Este é o plano certo quando o lado externo é pequeno e o lado interno tem índice. A forma que
está errada é o mesmo nó com uma varredura sequencial como filho interno: aí a tabela inteira é
lida uma vez por linha externa, e o custo do plano é o produto dos dois lados. Essa forma quer
dizer que falta um índice, e é o achado mais comum numa junção lenta.

Aqui está a contagem de voltas fazendo o que a seção anterior avisou:

```
shop=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id WHERE o.status = 'pending';
                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=16456.24..16456.25 rows=1 width=8) (actual time=14.460..14.461 rows=1 loops=1)
   ->  Nested Loop  (cost=34.04..16439.19 rows=6823 width=0) (actual time=0.666..14.113 rows=7500 loops=1)
         ->  Bitmap Heap Scan on orders o  (cost=33.61..5454.52 rows=2733 width=4) (actual time=0.656..5.080 rows=2984 loops=1)
               Recheck Cond: (status = 'pending'::text)
               Heap Blocks: exact=2469
               ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..32.92 rows=2733 width=0) (actual time=0.349..0.349 rows=2984 loops=1)
                     Index Cond: (status = 'pending'::text)
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..3.99 rows=3 width=4) (actual time=0.002..0.003 rows=3 loops=2984)
               Index Cond: (order_id = o.id)
               Heap Fetches: 0
 Planning Time: 0.681 ms
 Execution Time: 14.577 ms
(12 rows)
```

`loops=2984` no `Index Only Scan` interno, com `rows=3`: três linhas **por volta**, e 2984 voltas,
que são as 7500 que a junção devolveu. O `actual time` desse nó também é por volta — três
milésimos de milissegundo cada, que somados dão a maior parte dos 14 ms. Um número por volta
parece inofensivo sozinho, e é a multiplicação que decide se o plano é bom.

## Hash Join: montar uma tabela de um lado, sondar com o outro

```
shop=# EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=28443.11..28443.21 rows=10 width=18) (actual time=477.568..477.573 rows=10 loops=1)
   Group Key: c.city
   Batches: 1  Memory Usage: 24kB
   ->  Hash Join  (cost=3352.00..23443.11 rows=1000000 width=10) (actual time=31.104..342.406 rows=1000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         ->  Seq Scan on orders o  (cost=0.00..17466.00 rows=1000000 width=4) (actual time=0.003..51.395 rows=1000000 loops=1)
         ->  Hash  (cost=2102.00..2102.00 rows=100000 width=14) (actual time=30.633..30.635 rows=100000 loops=1)
               Buckets: 131072  Batches: 1  Memory Usage: 5777kB
               ->  Seq Scan on customers c  (cost=0.00..2102.00 rows=100000 width=14) (actual time=0.005..14.189 rows=100000 loops=1)
 Planning Time: 0.569 ms
 Execution Time: 477.798 ms
(11 rows)
```

Dois filhos de novo, e o que está sob `Hash` é lido primeiro, inteiro, para uma tabela hash
chaveada pela coluna da junção — todo cliente, em memória, `Memory Usage: 5777kB`. Depois o outro
filho é varrido uma vez, e o `customer_id` de cada linha é procurado no hash. Um milhão de buscas,
cada uma em tempo constante, e nenhum índice envolvido.

Este é o plano para juntar dois conjuntos grandes, e ele não se importa se existe índice. O custo
dele é memória: o lado hasheado tem que caber em `work_mem`, e quando não cabe, `Batches` passa
de um e o hash vaza para o disco em pedaços. `Batches: 1` aqui é o caso bom. A junção de `orders`
com `order_lines`, um milhão de linhas contra dois milhões e meio, sai como `Batches: 8` nos 4 MB
de `work_mem` desta máquina — ainda um hash join, ainda o plano mais barato, e oito passadas em
vez de uma.

Qual lado é hasheado é escolha do planejador, e ele hasheia o menor. Quando um plano hasheia o
lado errado — um milhão de linhas em memória para sondar com cem — a estimativa de um dos filhos
está errada, e a seção sobre estimativas é para onde ir.

## Merge Join: os dois lados ordenados, percorridos juntos

O terceiro algoritmo precisa das duas entradas em ordem pela coluna da junção, e então percorre
cada uma uma vez, como quem intercala duas listas ordenadas. O planejador não o escolheu por
conta própria para nenhuma consulta desta aula; com hash joins desligados para uma instrução, ele
mostra a forma:

```sql
SET enable_hashjoin = off;
```

```
shop=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id;
                                                                            QUERY PLAN                                                                             
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=142187.74..142187.75 rows=1 width=8) (actual time=711.199..711.201 rows=1 loops=1)
   ->  Merge Join  (cost=2.90..135946.80 rows=2496376 width=0) (actual time=2.662..614.129 rows=2496376 loops=1)
         Merge Cond: (o.id = l.order_id)
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.42..25980.42 rows=1000000 width=4) (actual time=0.025..84.630 rows=1000000 loops=1)
               Heap Fetches: 0
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..76262.07 rows=2496376 width=4) (actual time=0.022..243.053 rows=2496376 loops=1)
               Heap Fetches: 0
 Planning Time: 0.631 ms
 JIT:
   Functions: 5
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.135 ms, Inlining 0.000 ms, Optimization 0.140 ms, Emission 2.491 ms, Total 2.766 ms
 Execution Time: 724.810 ms
(13 rows)
```

Os dois filhos são `Index Only Scan`s em chaves primárias, então os dois chegam ordenados de
graça, e o merge os percorre. É o plano quando as entradas já estão ordenadas — duas chaves
indexadas, ou um `ORDER BY` que teria que acontecer de qualquer jeito — e é o que escala além da
memória, porque nada é hasheado. Ele ter vencido o hash join aqui, 725 ms contra 1105, é o
`Batches: 8` de cima: com um `work_mem` maior o hash teria vencido, e a estimativa do planejador
sobre isso é uma configuração, que é o assunto da última seção.

Desligar um método de junção é um jeito de **ver** um plano e nunca um jeito de entregar um. A
configuração é por sessão, e a seção sobre correções diz o que fazer no lugar.

## Qual junção é qual

| nó | bom quando | o sinal de que estava errado |
|---|---|---|
| `Nested Loop` | um lado é pequeno e o outro é indexado | um `Seq Scan` interno, ou `loops` na casa dos milhões |
| `Hash Join` | os dois lados são grandes e um cabe em memória | `Batches` bem acima de 1 |
| `Merge Join` | os dois lados já estão ordenados | um nó `Sort` sob cada filho, em entradas grandes |

**A ordem das junções é a outra decisão**, e é por isso que `EXPLAIN` numa consulta de cinco
tabelas vale ser lido antes dos métodos de junção. O planejador escolhe qual par juntar primeiro,
e um plano que junta duas tabelas grandes e depois filtra o resultado — em vez de filtrar primeiro
e juntar o resto pequeno — é um plano cuja estimativa disse que o filtro não era seletivo. O que,
mais uma vez, é a próxima seção.

## Planos com workers

```
shop=# EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=18235.62..18238.16 rows=10 width=18) (actual time=185.141..188.726 rows=10 loops=1)
   Group Key: c.city
   ->  Gather Merge  (cost=18235.62..18237.96 rows=20 width=18) (actual time=185.133..188.714 rows=30 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=17235.60..17235.62 rows=10 width=18) (actual time=182.572..182.576 rows=10 loops=3)
               Sort Key: c.city
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=17235.33..17235.43 rows=10 width=18) (actual time=182.545..182.549 rows=10 loops=3)
                     Group Key: c.city
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=2425.54..15152.00 rows=416667 width=10) (actual time=14.458..127.090 rows=333333 loops=3)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Parallel Seq Scan on orders o  (cost=0.00..11632.67 rows=416667 width=4) (actual time=0.008..22.685 rows=333333 loops=3)
                           ->  Parallel Hash  (cost=1690.24..1690.24 rows=58824 width=14) (actual time=14.112..14.114 rows=33333 loops=3)
                                 Buckets: 131072  Batches: 1  Memory Usage: 6048kB
                                 ->  Parallel Seq Scan on customers c  (cost=0.00..1690.24 rows=58824 width=14) (actual time=0.006..4.908 rows=33333 loops=3)
 Planning Time: 0.628 ms
 Execution Time: 188.855 ms
(23 rows)
```

Toda captura até aqui foi tirada com a consulta paralela desligada, para que os planos se lessem
como uma árvore só. Este é o mesmo relatório por cidade com ela ligada, que é o padrão:
`Gather Merge` no topo, `Workers Launched: 2`, e `Parallel` na frente das varreduras e do hash.
Três processos leem um terço de `orders` cada — `rows=333333 loops=3` — agregam o seu terço, e o
líder intercala os resultados parciais. Levou 189 ms contra os 478 do plano de um processo só.

Leia como a mesma árvore com uma regra a mais: **um nó sob um `Gather` relata por worker**, e
`loops=3` é o líder mais dois workers. Nada sobre as varreduras ou a junção mudou; simplesmente
há três de cada.
