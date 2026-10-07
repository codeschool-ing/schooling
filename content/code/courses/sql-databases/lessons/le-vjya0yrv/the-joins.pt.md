---
title: Como uma junção é feita de fato
version: 1
---

A aula 5 disse o que uma junção significa. Não disse nada sobre como uma é calculada, porque não
havia como ver isso então. Há três algoritmos, o planejador escolhe um por junção, e cada um tem
uma forma no plano que diz se foi a escolha certa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 242\" role=\"img\" aria-label=\"Três painéis lado a lado. Nested Loop: três linhas à esquerda, cada uma com uma seta para um bloco de busca no índice à direita, rotulado como uma busca por linha. Hash Join: um lado de construção alimentando uma tabela hash, e um lado de sondagem com uma seta de volta para ela, rotulado como na memória ou ela transborda. Merge Join: duas colunas ordenadas de quatro valores cada, com setas pareando-as, rotulado como percorridas uma vez, juntas. Sob cada painel, quando é a escolha certa e o sinal no plano de que foi a errada.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Três jeitos de fazer a mesma junção. O planejador escolhe pelo formato das duas entradas, não por qual é mais rápido em geral.</text><rect x=\"14\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"126\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Nested Loop</text><text x=\"26\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">boa: um lado pequeno, o outro indexado</text><text x=\"26\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errada: Seq Scan interno, ou voltas demais</text><rect x=\"28\" y=\"72\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 1</text><path d=\"M94 82 L144 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 82 L137 78 L137 86 Z\" fill=\"var(--phosphor)\"></path><rect x=\"28\" y=\"98\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 2</text><path d=\"M94 108 L144 108\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 108 L137 104 L137 112 Z\" fill=\"var(--phosphor)\"></path><rect x=\"28\" y=\"124\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 3</text><path d=\"M94 134 L144 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 134 L137 130 L137 138 Z\" fill=\"var(--phosphor)\"></path><rect x=\"148\" y=\"72\" width=\"76\" height=\"72\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"186\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">índice</text><text x=\"186\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">busca</text><text x=\"28\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma busca por linha</text><rect x=\"248\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Hash Join</text><text x=\"260\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">boa: os dois grandes, um cabe na memória</text><text x=\"260\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errada: Batches bem acima de 1</text><rect x=\"262\" y=\"72\" width=\"84\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">build</text><path d=\"M304 118 L304 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><rect x=\"262\" y=\"136\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">hash table</text><rect x=\"374\" y=\"72\" width=\"84\" height=\"90\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"416\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">probe</text><path d=\"M374 149 L348 149\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M348 149 L355 145 L355 153 Z\" fill=\"var(--phosphor)\"></path><text x=\"262\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na memória, ou vai para o disco</text><rect x=\"482\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"594\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Merge Join</text><text x=\"494\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">boa: os dois lados já ordenados</text><text x=\"494\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errada: um Sort sob cada filho, em escala</text><text x=\"536\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">ordenado</text><rect x=\"496\" y=\"76\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">10</text><rect x=\"496\" y=\"98\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">17</text><rect x=\"496\" y=\"120\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">24</text><rect x=\"496\" y=\"142\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">31</text><text x=\"652\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">ordenado</text><rect x=\"612\" y=\"76\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">10</text><rect x=\"612\" y=\"98\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">17</text><rect x=\"612\" y=\"120\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">24</text><rect x=\"612\" y=\"142\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">31</text><path d=\"M578 85 L608 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 85 L601 81 L601 89 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 107 L608 107\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 107 L601 103 L601 111 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 129 L608 129\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 129 L601 125 L601 133 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 151 L608 151\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 151 L601 147 L601 155 Z\" fill=\"var(--phosphor)\"></path><text x=\"496\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">percorridos juntos, uma vez</text><text x=\"14\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A ORDEM das junções é a outra decisão, e numa consulta de cinco tabelas vale ser lida antes dos métodos.</text></svg>", "caption": "O nome do nó é uma descrição do formato das entradas. Lido assim, \"por que um laço aninhado aqui\" vira uma pergunta sobre as contagens de linha embaixo dele.", "same": ["build", "probe"]}
```

## Nested Loop: para cada linha de um lado, buscar o outro

```
shop=# EXPLAIN ANALYZE SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';
                                                               QUERY PLAN                                                               
----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.93..55.93 rows=10 width=23) (actual time=0.057..0.066 rows=7 loops=1)
   ->  Index Scan using customers_email_key on customers c  (cost=0.42..8.44 rows=1 width=17) (actual time=0.037..0.037 rows=1 loops=1)
         Index Cond: (email = 'user42@example.com'::text)
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.38 rows=11 width=14) (actual time=0.017..0.024 rows=7 loops=1)
         Recheck Cond: (c.id = customer_id)
         Heap Blocks: exact=7
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.012..0.012 rows=7 loops=1)
               Index Cond: (customer_id = c.id)
 Planning Time: 0.858 ms
 Execution Time: 0.134 ms
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
 Aggregate  (cost=16715.95..16715.96 rows=1 width=8) (actual time=31.346..31.349 rows=1 loops=1)
   ->  Nested Loop  (cost=35.33..16697.82 rows=7250 width=0) (actual time=0.771..30.773 rows=7261 loops=1)
         ->  Bitmap Heap Scan on orders o  (cost=34.90..5631.57 rows=2900 width=4) (actual time=0.758..7.297 rows=2923 loops=1)
               Recheck Cond: (status = 'pending'::text)
               Heap Blocks: exact=2425
               ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..34.17 rows=2900 width=0) (actual time=0.440..0.441 rows=2923 loops=1)
                     Index Cond: (status = 'pending'::text)
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..3.79 rows=3 width=4) (actual time=0.007..0.007 rows=2 loops=2923)
               Index Cond: (order_id = o.id)
               Heap Fetches: 0
 Planning Time: 0.905 ms
 Execution Time: 31.494 ms
(12 rows)
```

`loops=2923` no `Index Only Scan` interno, com `rows=2`: duas linhas **por volta** — uma média,
arredondada para uma linha inteira — e 2923 voltas, que são as 7261 que a junção devolveu. O
`actual time` desse nó também é por volta — sete milésimos de milissegundo cada, que somados dão
vinte dos 31 ms. Um número por volta
parece inofensivo sozinho, e é a multiplicação que decide se o plano é bom.

## Hash Join: montar uma tabela de um lado, sondar com o outro

```
shop=# EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=28331.11..28331.21 rows=10 width=18) (actual time=489.337..489.343 rows=10 loops=1)
   Group Key: c.city
   Batches: 1  Memory Usage: 24kB
   ->  Hash Join  (cost=3237.00..23331.11 rows=1000000 width=10) (actual time=38.425..344.566 rows=1000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         ->  Seq Scan on orders o  (cost=0.00..17469.00 rows=1000000 width=4) (actual time=0.014..68.051 rows=1000000 loops=1)
         ->  Hash  (cost=1987.00..1987.00 rows=100000 width=14) (actual time=37.790..37.792 rows=100000 loops=1)
               Buckets: 131072  Batches: 1  Memory Usage: 5712kB
               ->  Seq Scan on customers c  (cost=0.00..1987.00 rows=100000 width=14) (actual time=0.012..16.491 rows=100000 loops=1)
 Planning Time: 0.715 ms
 Execution Time: 489.557 ms
(11 rows)
```

Dois filhos de novo, e o que está sob `Hash` é lido primeiro, inteiro, para uma tabela hash
chaveada pela coluna da junção — todo cliente, em memória, `Memory Usage: 5712kB`. Depois o outro
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

```
shop=# SET enable_hashjoin = off;
SET

shop=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id;
                                                                            QUERY PLAN                                                                             
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=130979.92..130979.93 rows=1 width=8) (actual time=857.013..857.014 rows=1 loops=1)
   ->  Merge Join  (cost=2.85..124729.92 rows=2500000 width=0) (actual time=3.308..734.858 rows=2500000 loops=1)
         Merge Cond: (o.id = l.order_id)
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.42..25980.42 rows=1000000 width=4) (actual time=0.026..110.744 rows=1000000 loops=1)
               Heap Fetches: 0
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..65004.43 rows=2500000 width=4) (actual time=0.030..266.332 rows=2500000 loops=1)
               Heap Fetches: 0
 Planning Time: 0.833 ms
 JIT:
   Functions: 5
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.157 ms, Inlining 0.000 ms, Optimization 0.188 ms, Emission 3.086 ms, Total 3.431 ms
 Execution Time: 874.100 ms
(13 rows)
```

Os dois filhos são `Index Only Scan`s em chaves primárias, então os dois chegam ordenados de
graça, e o merge os percorre. É o plano quando as entradas já estão ordenadas — duas chaves
indexadas, ou um `ORDER BY` que teria que acontecer de qualquer jeito — e é o que escala além da
memória, porque nada é hasheado. Ele ter vencido o hash join aqui, 874 ms contra 1212, é o
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
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=19050.09..19052.62 rows=10 width=18) (actual time=216.497..221.603 rows=10 loops=1)
   Group Key: c.city
   ->  Gather Merge  (cost=19050.09..19052.42 rows=20 width=18) (actual time=216.488..221.590 rows=30 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=18050.06..18050.09 rows=10 width=18) (actual time=213.455..213.458 rows=10 loops=3)
               Sort Key: c.city
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=18049.80..18049.90 rows=10 width=18) (actual time=213.416..213.420 rows=10 loops=3)
                     Group Key: c.city
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Hash Join  (cost=3237.00..15966.46 rows=416667 width=10) (actual time=33.789..162.720 rows=333333 loops=3)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Parallel Seq Scan on orders o  (cost=0.00..11635.67 rows=416667 width=4) (actual time=0.014..27.223 rows=333333 loops=3)
                           ->  Hash  (cost=1987.00..1987.00 rows=100000 width=14) (actual time=33.170..33.171 rows=100000 loops=3)
                                 Buckets: 131072  Batches: 1  Memory Usage: 5712kB
                                 ->  Seq Scan on customers c  (cost=0.00..1987.00 rows=100000 width=14) (actual time=0.019..11.714 rows=100000 loops=3)
 Planning Time: 0.749 ms
 Execution Time: 222.012 ms
(23 rows)
```

Toda captura até aqui foi tirada numa sessão que começou com
`SET max_parallel_workers_per_gather = 0`, a linha do começo da primeira etapa, para que os planos
se lessem como uma árvore só. Este é o mesmo relatório por cidade numa sessão nova, em que a
consulta paralela está ligada, que é o padrão: `Gather Merge` no topo, `Workers Launched: 2`, e
`Parallel` na frente da varredura de `orders`. Três processos leem um terço de `orders` cada —
`rows=333333 loops=3` — e cada um monta o seu próprio hash de todos os clientes, que é o `Hash` com
`loops=3` e `rows=100000`. Cada um agrega o seu terço, e o líder intercala os resultados parciais.
Levou 222 ms contra os 490 do plano de um processo só.

Leia como a mesma árvore com uma regra a mais: **um nó sob um `Gather` relata por worker**, e
`loops=3` é o líder mais dois workers. Nada sobre as varreduras ou a junção mudou; simplesmente
há três de cada.
