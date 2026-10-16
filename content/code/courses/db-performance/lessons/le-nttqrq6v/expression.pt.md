---
title: Um índice sobre uma expressão
version: 1
---

A aula 1, seção 05, mostrou uma consulta lenta por um motivo que nada tinha a ver com falta de
índice: `WHERE date(placed_at) = '2025-06-01'` não conseguia usar o índice em `placed_at`, porque o
índice guarda valores de `placed_at` e a consulta pergunta sobre valores de `date(placed_at)`. O
conserto ali foi reescrever a consulta como uma faixa. Esta seção é a outra saída: construir o índice
sobre **a expressão que a consulta usa**, para que índice e consulta falem nos mesmos termos.

## E-mail sem diferenciar maiúsculas

O caso do dia a dia é um formulário de login. As pessoas digitam o endereço com maiúsculas,
`User42@Example.com`, e a aplicação compara em minúsculas:

```
market=# EXPLAIN ANALYZE SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..5147.71 rows=1000 width=26) (actual time=0.418..60.808 rows=1 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   ->  Parallel Seq Scan on customers  (cost=0.00..4047.71 rows=588 width=26) (actual time=25.602..53.560 rows=0 loops=2)
         Filter: (lower(email) = 'user42@example.com'::text)
         Rows Removed by Filter: 100000
 Planning Time: 1.432 ms
 Execution Time: 60.955 ms
(8 rows)

Time: 63.893 ms
```

**61 milissegundos** para achar um cliente, um scan paralelo calculando `lower(email)` para os
200.000. O índice único em `email` não ajuda: ele guarda `user42@example.com` ordenado entre os
valores originais, e nada nele diz quais são as suas formas em minúsculas.

Indexe a expressão:

```
market=# CREATE INDEX customers_lower_email_idx ON customers (lower(email));
CREATE INDEX
Time: 210.386 ms

market=# EXPLAIN ANALYZE SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on customers  (cost=28.17..1850.16 rows=1000 width=26) (actual time=0.056..0.057 rows=1 loops=1)
   Recheck Cond: (lower(email) = 'user42@example.com'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on customers_lower_email_idx  (cost=0.00..27.92 rows=1000 width=0) (actual time=0.045..0.046 rows=1 loops=1)
         Index Cond: (lower(email) = 'user42@example.com'::text)
 Planning Time: 0.335 ms
 Execution Time: 0.102 ms
(7 rows)

Time: 1.069 ms
```

**0,10 milissegundo.** O índice guarda `lower(email)` de cada linha, calculado uma vez quando a linha
foi gravada, e o `WHERE` da consulta bate com ele exatamente. Os parênteses duplos de que a maioria
dos índices de expressão precisa não fazem falta aqui porque uma única chamada de função pode ir sem
eles; qualquer coisa a mais, `(a + b)` ou um cast, precisa de um par só seu.

A correspondência precisa ser **exata, aos olhos do planejador**. `lower(email)` no índice atende a
`lower(email) = …` numa consulta, e não a `upper(email) = …`, nem a `email ILIKE …`, nem a
`lower(trim(email))`. A expressão da consulta precisa ser a mesma expressão, escrita do mesmo jeito,
ou o índice fica invisível. Esse é o preço desta saída comparada à da aula 1: o índice funciona para
um jeito de escrever a pergunta, e toda consulta que o quiser precisa escrever desse jeito.

## As estatísticas que vêm junto

Veja o `rows=1000` nos dois planos acima. O planejador não fazia ideia de quantos clientes têm um
dado `lower(email)`: `lower(email)` não é uma coluna, então o `ANALYZE` nunca o tinha medido, e o
planejador recorreu a um palpite fixo de meio por cento da tabela. Com uma linha batendo de verdade,
o palpite estava mil vezes alto demais, e o plano é um bitmap scan feito para mil linhas.

Um índice de expressão muda isso, porque **o `ANALYZE` coleta estatísticas das expressões
indexadas** como se fossem colunas:

```
market=# ANALYZE customers;
ANALYZE
Time: 434.498 ms

market=# EXPLAIN SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Scan using customers_lower_email_idx on customers  (cost=0.42..8.44 rows=1 width=26)
   Index Cond: (lower(email) = 'user42@example.com'::text)
(2 rows)

Time: 0.989 ms

market=# SELECT tablename, attname, n_distinct FROM pg_stats WHERE tablename = 'customers_lower_email_idx';
         tablename         | attname | n_distinct 
---------------------------+---------+------------
 customers_lower_email_idx | lower   |         -1
(1 row)

Time: 3.180 ms
```

Depois do `ANALYZE customers`, a estimativa é **1 linha** e o plano um index scan simples. A última
consulta mostra onde moram os números novos: o `pg_stats` tem uma linha cujo `tablename` é o
**índice**, com a expressão como coluna, `lower`, e um `n_distinct` de -1, todo valor diferente. Tudo
o que a aula 7 leu para colunas de verdade está ali para a expressão.

Às vezes isso já vale um índice. Uma consulta que filtra por uma expressão que o planejador vive
avaliando mal pode ter as estimativas consertadas por um índice de expressão, mesmo que o plano depois
leia a tabela de outro jeito. O `CREATE STATISTICS`, da aula 7, também coleta estatísticas de uma
expressão sem construir índice nenhum, e essa é a escolha mais barata quando só a estimativa está
errada.

## A data, de novo

A consulta que a aula 1 reescreveu era sobre o dia em que um pedido foi feito. Um índice sobre essa
expressão é o próximo passo óbvio, e ele falha, com um erro que merece uma seção só sua: a próxima.
