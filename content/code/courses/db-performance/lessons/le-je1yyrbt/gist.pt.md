---
title: GiST: perto, parecido e sobreposto
version: 1
---

Uma B-tree precisa de uma ordem, e o GIN precisa de um valor feito de partes. O GiST, a Generalized
Search Tree, não precisa de nenhum dos dois. É uma árvore em que cada entrada mais acima **resume**
tudo o que está abaixo dela: uma caixa em volta de alguns pontos, um intervalo cobrindo alguns
intervalos, um conjunto de trigramas cobrindo algumas strings. Uma busca pode pular todo ramo cujo
resumo a descarte. Isso basta para responder perguntas que nenhuma lista ordenada responde: **está
perto**, **é parecido**, **se sobrepõe**.

Duas delas cabem no `market`: achar títulos de produto por um fragmento ou um erro de digitação, e
recusar dois intervalos de tempo que se sobrepõem.

## Títulos por fragmento: `pg_trgm`

A seção 02 terminou com uma consulta que nenhuma B-tree ajuda, um padrão com curinga no começo. A
caixa de busca de uma loja vive cheia delas: alguém digita `chair 4242` e espera achar "Wooden chair
4242". O `pg_trgm` é uma extensão que vem com o PostgreSQL. Ela corta uma string em **trigramas**,
cada sequência de três caracteres, e oferece suporte de índice para comparar strings pelos trigramas
que elas têm em comum.

```
market=# CREATE EXTENSION pg_trgm;
CREATE EXTENSION
Time: 12.155 ms

market=# EXPLAIN ANALYZE SELECT id, title FROM products WHERE title ILIKE '%chair 4242%';
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on products  (cost=0.00..1274.00 rows=5 width=24) (actual time=41.850..50.085 rows=1 loops=1)
   Filter: (title ~~* '%chair 4242%'::text)
   Rows Removed by Filter: 49999
 Planning Time: 0.956 ms
 Execution Time: 50.131 ms
(5 rows)

Time: 51.969 ms

market=# CREATE INDEX products_title_trgm_idx ON products USING gist (title gist_trgm_ops);
CREATE INDEX
Time: 683.224 ms

market=# EXPLAIN ANALYZE SELECT id, title FROM products WHERE title ILIKE '%chair 4242%';
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=4.32..23.06 rows=5 width=24) (actual time=1.642..1.643 rows=1 loops=1)
   Recheck Cond: (title ~~* '%chair 4242%'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on products_title_trgm_idx  (cost=0.00..4.31 rows=5 width=0) (actual time=1.619..1.619 rows=1 loops=1)
         Index Cond: (title ~~* '%chair 4242%'::text)
 Planning Time: 0.307 ms
 Execution Time: 1.745 ms
(7 rows)

Time: 2.654 ms
```

**50 milissegundos para 1,7.** Sem índice, o `ILIKE '%chair 4242%'` confere cada um dos 50.000
títulos. Com o índice de trigramas, o planejador procura os trigramas de `chair 4242`, acha os poucos
títulos que contêm todos eles e confere só esses: uma linha, de uma página.

O `CREATE EXTENSION pg_trgm` não precisa de nada instalado, já que faz parte do pacote `postgresql`
da aula 1; ele acrescenta as funções e as classes de operadores ao banco em que você o roda.

## Parecido, e o mais perto primeiro

A segunda coisa que os trigramas dão é uma **distância** entre duas strings, o operador `<->`: 0 para
idênticas, 1 para nada em comum. Com ela, uma consulta pode pedir os títulos mais próximos do que foi
digitado, com erros e tudo:

```
market=# SELECT id, title, round((title <-> 'wodden chiar 4242')::numeric, 3) AS distance FROM products ORDER BY title <-> 'wodden chiar 4242' LIMIT 5;
  id   |       title        | distance 
-------+--------------------+----------
 42493 | Wooden chair 42493 |    0.679
 42437 | Wooden chair 42437 |    0.679
 42432 | Wooden chair 42432 |    0.679
 42404 | Wooden chair 42404 |    0.679
  4265 | Wooden chair 4265  |    0.714
(5 rows)

Time: 23.000 ms

market=# EXPLAIN SELECT id, title FROM products ORDER BY title <-> 'wodden chiar 4242' LIMIT 5;
                                              QUERY PLAN                                              
------------------------------------------------------------------------------------------------------
 Limit  (cost=0.28..0.92 rows=5 width=28)
   ->  Index Scan using products_title_trgm_idx on products  (cost=0.28..6384.28 rows=50000 width=28)
         Order By: (title <-> 'wodden chiar 4242'::text)
(3 rows)

Time: 0.641 ms
```

`wodden chiar 4242`, dois erros de digitação, e os títulos mais próximos são cadeiras de madeira
cujos números têm mais caracteres em comum com 4242. A segunda consulta mostra como: um `Index Scan`
com uma linha **`Order By`**, o que quer dizer que o próprio índice entrega as linhas da mais próxima
para a mais distante e o `Limit` para depois de cinco. Isso se chama busca do vizinho mais próximo, e
é o que o GiST faz e o GIN não consegue. Um índice GIN de trigramas, criado com `gin_trgm_ops`, também
serve ao `ILIKE` e costuma ser mais rápido nisso, mas não ordena por distância.

## Intervalos que não podem se sobrepor

O outro uso clássico do GiST é uma restrição. Suponha que os vendedores possam se marcar como
ausentes, e que um vendedor nunca possa ter duas ausências sobrepostas. Uma restrição `UNIQUE` não
consegue dizer isso: dois intervalos diferentes não são iguais, eles se sobrepõem. Uma **restrição de
exclusão** consegue. Ela diz "nenhum par de linhas pode ter *este* operador verdadeiro entre si", e
precisa de um índice que responda ao operador, que para `&&`, sobrepõe, é o GiST:

```
market=# CREATE EXTENSION btree_gist;
CREATE EXTENSION
Time: 197.678 ms

market=# CREATE TABLE seller_away (seller_id integer NOT NULL, during tstzrange NOT NULL, EXCLUDE USING gist (seller_id WITH =, during WITH &&));
CREATE TABLE
Time: 7.054 ms

market=# INSERT INTO seller_away VALUES (42, '[2025-12-20, 2026-01-05)');
INSERT 0 1
Time: 2.725 ms

market=# INSERT INTO seller_away VALUES (42, '[2026-01-02, 2026-01-10)');
ERROR:  conflicting key value violates exclusion constraint "seller_away_seller_id_during_excl"
DETAIL:  Key (seller_id, during)=(42, ["2026-01-02 00:00:00-03","2026-01-10 00:00:00-03")) conflicts with existing key (seller_id, during)=(42, ["2025-12-20 00:00:00-03","2026-01-05 00:00:00-03")).
Time: 1.486 ms

market=# INSERT INTO seller_away VALUES (43, '[2026-01-02, 2026-01-10)');
INSERT 0 1
Time: 1.272 ms
```

A restrição diz: nenhum par de linhas em que `seller_id` é igual **e** `during` se sobrepõe. A segunda
ausência do vendedor 42 começa em 2 de janeiro, dentro da primeira, e o banco a recusa com as duas
linhas citadas no erro. O intervalo idêntico do vendedor 43 entra, porque o vendedor é outro.

O `btree_gist` é a outra metade do truque. O `=` em `seller_id` é uma pergunta de B-tree, e uma
restrição de exclusão precisa de um índice só para todas as suas colunas; esta extensão, também parte
do pacote, ensina o GiST a lidar com os tipos comuns usando `=`. Sem ela o `CREATE TABLE` falha.

Esse é o tipo de regra que uma aplicação tenta garantir com um `SELECT` antes do `INSERT`, e erra no
dia em que duas requisições chegam juntas. A aula 14 trata de corridas como essa entre duas sessões;
uma restrição de exclusão fecha esta, porque o índice confere cada insert contra toda linha
confirmada ou em andamento.

Nada na carga da aula 2 busca títulos ou intervalos, então o GiST não conserta nada naquela lista. A
caixa de busca e o calendário de ausências são as perguntas para as quais ele existe, e o
`~/reset-market.sh` no fim da aula remove as duas extensões, o índice e a `seller_away`.
