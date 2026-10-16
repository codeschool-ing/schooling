---
title: GIN: olhando dentro de um valor
version: 1
---

A aula 2 rodou a carga de trabalho e ordenou o placar pelo tempo total, e a instrução no topo foi o
`tag-search.sql`: vinte produtos com uma tag, do mais barato para cima. Ela é o primeiro conserto
desta aula, e precisa de um índice que olhe **dentro** de um valor. `tags` é um `text[]`, e a
pergunta `tags @> ARRAY['kitchen']`, "o array contém este elemento?", é sobre um elemento de uma
lista, que uma B-tree sobre arrays inteiros não consegue achar.

## Um índice invertido

GIN quer dizer Generalized Inverted Index, e "invertido" é a palavra que importa. Uma B-tree liga o
valor de cada linha à linha. O GIN inverte isso: quebra cada valor nos seus **elementos** e guarda,
para cada elemento, a lista de linhas que o contêm. Para `tags`, ele tem onze entradas, uma por tag,
cada uma com a lista de produtos que a usam. "Que produtos têm `kitchen`?" vira uma consulta e uma
lista.

O mesmo formato serve para tudo o que é feito de partes: os elementos de um array, as chaves e os
valores de um documento `jsonb`, as palavras de um texto na busca textual. Cada tipo de valor tem a
sua classe de operadores GIN, que sabe desmontá-lo.

## Antes: a busca por tag como está

Meça a instrução do jeito que a aula 2 mediu a carga, com o `pgbench` rodando só este arquivo, oito
clientes por quinze segundos, e fique com as duas linhas de resumo:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 58.704 ms
tps = 136.276697 (without initial connection time)
market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1540.89..1540.94 rows=20 width=28) (actual time=24.522..24.526 rows=20 loops=1)
   ->  Sort  (cost=1540.89..1565.97 rows=10030 width=28) (actual time=24.521..24.522 rows=20 loops=1)
         Sort Key: price_cents
         Sort Method: top-N heapsort  Memory: 27kB
         ->  Seq Scan on products  (cost=0.00..1274.00 rows=10030 width=28) (actual time=0.043..19.675 rows=9917 loops=1)
               Filter: (tags @> '{kitchen}'::text[])
               Rows Removed by Filter: 40083
 Planning Time: 0.569 ms
 Execution Time: 24.566 ms
(9 rows)

Time: 26.837 ms
```

**58,7 milissegundos** por busca sob carga e 24,6 numa execução sozinha, sem mais ninguém no
servidor: oito clientes dividem quatro processadores, e cada um espera a sua vez. O plano lê os
50.000 produtos, joga fora os 40.083 que não têm a tag e ordena os 9917 que sobram para ficar com os
vinte mais baratos.

## O índice GIN

```
market=# CREATE INDEX products_tags_idx ON products USING gin (tags);
CREATE INDEX
Time: 67.516 ms

market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1114.82..1114.87 rows=20 width=28) (actual time=16.976..16.982 rows=20 loops=1)
   ->  Sort  (cost=1114.82..1139.90 rows=10030 width=28) (actual time=16.973..16.977 rows=20 loops=1)
         Sort Key: price_cents
         Sort Method: top-N heapsort  Memory: 27kB
         ->  Bitmap Heap Scan on products  (cost=73.55..847.93 rows=10030 width=28) (actual time=1.474..14.795 rows=9917 loops=1)
               Recheck Cond: (tags @> '{kitchen}'::text[])
               Heap Blocks: exact=649
               ->  Bitmap Index Scan on products_tags_idx  (cost=0.00..71.05 rows=10030 width=0) (actual time=1.374..1.375 rows=9917 loops=1)
                     Index Cond: (tags @> '{kitchen}'::text[])
 Planning Time: 0.630 ms
 Execution Time: 17.052 ms
(11 rows)

Time: 19.301 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 19.761 ms
tps = 404.835676 (without initial connection time)
```

O plano mudou de forma. Um `Bitmap Index Scan` no novo índice acha os 9917 produtos com a tag em
cerca de um milissegundo, depois a tabela é lida para essas linhas e ordenada como antes. **58,7
milissegundos viraram 19,8**, três vezes mais rápido, e o servidor deu conta de 405 buscas por
segundo em vez de 136.

É o conserto dos livros, e é real. Mas veja para onde foi o tempo: a parte do índice levou 1,4
milissegundo, e os outros 15 foram para ler 649 páginas da tabela, todas elas, e ordenar dez mil
linhas para ficar com vinte. Um quinto de todos os produtos usa `kitchen`, então um quinto da tabela
precisou ser lido. O GIN respondeu bem ao `WHERE`, e o `WHERE` não era a metade cara da pergunta.

## A outra metade: `ORDER BY price_cents LIMIT 20`

A seção 02 mostrou uma B-tree servindo a um `ORDER BY` com `LIMIT`: ela entrega as linhas já em
ordem e para quando tem o bastante. Aqui isso quer dizer percorrer os produtos do mais barato para
cima, guardando os que usam a tag, até juntar vinte. Com um produto em cada cinco usando a tag, isso
deveria levar umas cem linhas.

```
market=# CREATE INDEX products_price_cents_idx ON products (price_cents);
CREATE INDEX
Time: 51.995 ms

market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.29..7.58 rows=20 width=28) (actual time=0.067..0.157 rows=20 loops=1)
   ->  Index Scan using products_price_cents_idx on products  (cost=0.29..3655.24 rows=10030 width=28) (actual time=0.066..0.155 rows=20 loops=1)
         Filter: (tags @> '{kitchen}'::text[])
         Rows Removed by Filter: 54
 Planning Time: 0.685 ms
 Execution Time: 0.185 ms
(6 rows)

Time: 2.271 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.706 ms
tps = 11334.248681 (without initial connection time)
```

O planejador escolheu a nova B-tree em vez do GIN: leu **74 linhas**, 20 mantidas e 54 removidas, e
terminou em 0,19 milissegundo. Sob carga a busca foi de 19,8 milissegundos para **0,7**, e o servidor
foi de 405 buscas por segundo para 11.334. Desde o começo, de 58,7 para 0,7 são umas oitenta vezes.

Então o índice que consertou a consulta mais cara da aula 2 foi uma B-tree comum, numa coluna que a
cláusula `WHERE` nem menciona. **A pergunta que uma consulta faz é o texto inteiro dela, não o seu
`WHERE`**, e aqui o `LIMIT` fez da ordem a parte seletiva.

## Onde o plano da B-tree quebra

Ele funciona porque a tag é comum. Peça uma tag que ninguém usa, digamos um erro de digitação:

```
market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchn'] ORDER BY price_cents LIMIT 20;
                                                                   QUERY PLAN                                                                    
-------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.29..292.69 rows=20 width=28) (actual time=41.095..41.096 rows=0 loops=1)
   ->  Index Scan using products_price_cents_idx on products  (cost=0.29..3655.24 rows=250 width=28) (actual time=41.093..41.094 rows=0 loops=1)
         Filter: (tags @> '{kitchn}'::text[])
         Rows Removed by Filter: 50000
 Planning Time: 0.722 ms
 Execution Time: 41.130 ms
(6 rows)

Time: 43.273 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('products', 'products_tags_idx', 'products_price_cents_idx');
         relname          |  size   
--------------------------+---------
 products                 | 5192 kB
 products_tags_idx        | 264 kB
 products_price_cents_idx | 368 kB
(3 rows)

Time: 2.350 ms
```

**41 milissegundos e nenhuma linha**: o percurso passou pelos 50.000 produtos em ordem de preço
procurando vinte que nunca vieram, mais devagar que o scan sequencial que ele substituiu. O índice
GIN teria respondido "ninguém" numa fração de milissegundo, e o planejador não o escolheu porque
esperava 250 linhas, um palpite para um elemento que as estatísticas não listam, e com 250 o
percurso parecia barato. É de novo o assunto da aula 7: uma estimativa errada, escolhendo entre dois
índices bons.

Os tamanhos estão na última linha: os dois índices juntos somam 632 kB contra uma tabela de 5 MB.
Manter os dois é barato, e deixa ao planejador a ferramenta certa para uma tag comum e para uma rara.
Se ele escolhe bem depende da estimativa, e por isso a tela de busca nunca deveria mandar uma tag que
não existe.

## GIN em `jsonb`

`events.payload` guarda `{"product": …, "ms": …}`, e achar os eventos de um produto também é uma
pergunta de conteúdo:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE payload @> '{"product": 4242}';
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=92473.50..92473.51 rows=1 width=8) (actual time=990.909..995.263 rows=1 loops=1)
   ->  Gather  (cost=92473.29..92473.50 rows=2 width=8) (actual time=990.512..995.251 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=91473.29..91473.30 rows=1 width=8) (actual time=985.942..985.943 rows=1 loops=3)
               ->  Parallel Seq Scan on events  (cost=0.00..91472.77 rows=208 width=0) (actual time=14.957..985.814 rows=32 loops=3)
                     Filter: (payload @> '{"product": 4242}'::jsonb)
                     Rows Removed by Filter: 1666635
 Planning Time: 0.664 ms
 Execution Time: 995.468 ms
(10 rows)

Time: 997.462 ms

market=# CREATE INDEX events_payload_idx ON events USING gin (payload);
CREATE INDEX
Time: 20791.065 ms (00:20.791)

market=# CREATE INDEX events_payload_path_idx ON events USING gin (payload jsonb_path_ops);
CREATE INDEX
Time: 9646.656 ms (00:09.647)

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('events', 'events_payload_idx', 'events_payload_path_idx');
         relname         |  size  
-------------------------+--------
 events                  | 511 MB
 events_payload_idx      | 55 MB
 events_payload_path_idx | 42 MB
(3 rows)

Time: 1.255 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE payload @> '{"product": 4242}';
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1892.48..1892.49 rows=1 width=8) (actual time=1.026..1.028 rows=1 loops=1)
   ->  Bitmap Heap Scan on events  (cost=19.71..1891.23 rows=500 width=0) (actual time=0.059..1.012 rows=96 loops=1)
         Recheck Cond: (payload @> '{"product": 4242}'::jsonb)
         Heap Blocks: exact=96
         ->  Bitmap Index Scan on events_payload_path_idx  (cost=0.00..19.58 rows=500 width=0) (actual time=0.029..0.029 rows=96 loops=1)
               Index Cond: (payload @> '{"product": 4242}'::jsonb)
 Planning Time: 0.385 ms
 Execution Time: 1.071 ms
(8 rows)

Time: 1.916 ms

market=# DROP INDEX events_payload_idx;
DROP INDEX
Time: 12.118 ms

market=# DROP INDEX events_payload_path_idx;
DROP INDEX
Time: 13.695 ms
```

**995 milissegundos para 1,07.** O scan sequencial leu cinco milhões de payloads em paralelo para
achar 96 eventos; o índice foi direto a eles. O bloco também construiu o índice duas vezes, com duas
classes de operadores, e a diferença vale conhecer:

- a padrão, `jsonb_ops`, indexa cada chave e cada valor separadamente: **55 MB**, 20,8 segundos para
  construir. Responde a `@>` e também a `?`, "esta chave existe?", e às suas variações.
- `jsonb_path_ops` indexa cada par caminho-e-valor como um hash só: **42 MB**, 9,6 segundos. Responde
  só a `@>`, e o planejador a preferiu aqui.

Se a aplicação só pergunta "o documento contém isto", `jsonb_path_ops` é a menor e a mais rápida.
Nenhuma consulta da carga da aula 2 lê `events`, então este é um conserto para um relatório que
ninguém escreveu ainda; os dois índices são apagados no fim do bloco.

## O que o GIN custa

O GIN é caro de manter atualizado, porque uma linha acrescenta uma entrada por elemento: um evento
inserido numa tabela com `jsonb_ops` acrescenta duas chaves e dois valores ao índice. O PostgreSQL
ameniza isso com uma **lista pendente**, um buffer onde as entradas novas esperam para serem
incorporadas em lote, o que deixa os inserts mais baratos e as buscas um pouco mais lentas até a
incorporação. Em `products`, que muda pouco, nada disso importa. Em `events`, que recebe milhares de
linhas por minuto, é a primeira coisa a medir, e a aula 11 trata desse imposto.
