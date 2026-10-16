---
title: A B-tree, e o que "em ordem" compra
version: 1
---

Quando alguém diz "cria um índice", está falando de uma B-tree, e `CREATE INDEX` sem cláusula
`USING` cria uma. Todo índice com que o `market` nasceu é uma B-tree, e o que a aula 2 acrescentou
também. Ela é a resposta certa tantas vezes que é fácil acreditar que é a única, e o resto desta aula
são as perguntas que ela não aceita. Esta seção são as que ela aceita, e o único lugar em que ela
recusa em silêncio.

## Uma ideia: os valores, mantidos em ordem

Uma B-tree são os valores da coluna em ordem, cada um com um ponteiro para a sua linha, arrumados
numa árvore rasa para que achar qualquer valor custe a leitura de poucas páginas a partir do topo.
Tudo em que ela é boa decorre de **em ordem**:

| pergunta | por que uma lista ordenada a responde |
|---|---|
| `=` | achar o valor, ler as entradas que batem |
| `<`, `>`, `BETWEEN` | achar onde a faixa começa, ler para a frente até ela acabar |
| `ORDER BY` | as entradas já estão nessa ordem, então não há nada a ordenar |
| `ORDER BY … DESC` | ler a mesma lista de trás para a frente |
| `LIKE 'abc%'` | um prefixo é uma faixa: tudo de `abc` até logo antes de `abd` |

A terceira e a quarta linhas são as que as pessoas esquecem, e muitas vezes valem mais que as duas
primeiras. Uma consulta com `ORDER BY placed_at LIMIT 5` não precisa achar cinco linhas. Ela precisa
das cinco **primeiras** linhas numa ordem, e uma B-tree nessa coluna as entrega sem ler nem ordenar
mais nada:

```
market=# EXPLAIN SELECT id, placed_at FROM orders WHERE placed_at >= '2025-12-24' ORDER BY placed_at LIMIT 5;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..0.61 rows=5 width=16)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..923.49 rows=24918 width=16)
         Index Cond: (placed_at >= '2025-12-24 00:00:00-03'::timestamp with time zone)
(3 rows)

Time: 2.600 ms

market=# EXPLAIN SELECT id, placed_at FROM orders ORDER BY placed_at DESC LIMIT 5;
                                                 QUERY PLAN                                                  
-------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..0.60 rows=5 width=16)
   ->  Index Scan Backward using orders_placed_at_idx on orders  (cost=0.43..68618.43 rows=2000000 width=16)
(2 rows)

Time: 0.657 ms
```

Os dois planos têm um `Limit` direto em cima de um `Index Scan`, e nenhum nó `Sort` em lugar
nenhum. O segundo são os cinco pedidos mais recentes entre dois milhões, a custo 0,60, percorrendo o
índice **de trás para a frente** a partir do fim. O `rows=2000000` do scan não é o que ele lê. É o
que ele leria se ninguém o parasse, e o `Limit` o para depois de cinco.

Guarde esse formato: um índice pode servir ao `ORDER BY` de uma consulta tanto quanto ao `WHERE`, e
a seção 04 desta aula acaba consertando a busca por tag exatamente com isso.

## A pegadinha do `LIKE 'prefixo%'`

A tabela acima diz que uma B-tree responde a uma busca por prefixo. Experimente em
`customers.email`, que já tem uma B-tree, a que sustenta a restrição `UNIQUE`:

```
market=# EXPLAIN SELECT * FROM customers WHERE email LIKE 'user42@%';
                          QUERY PLAN                          
--------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..4783.00 rows=20 width=59)
   Filter: (email ~~ 'user42@%'::text)
(2 rows)

Time: 3.345 ms

market=# SELECT datcollate FROM pg_database WHERE datname = current_database();
 datcollate 
------------
 C.UTF-8
(1 row)

Time: 0.954 ms
```

Um scan sequencial dos 200.000 clientes, com uma B-tree na própria coluna parada ali. O motivo é a
**collation**: as regras que decidem como o texto é ordenado. O `market` ordena por `C.UTF-8`, e um
banco criado na sua máquina pode dizer `en_US.UTF-8` ou `pt_BR.UTF-8`. Na collation de um idioma, a
ordem das strings não é a ordem simples dos bytes, então "tudo o que começa com `user42@`" não tem
garantia de ser um trecho contínuo do índice. O PostgreSQL 16 só transforma um prefixo de `LIKE` numa
faixa de B-tree cuja collation é a `C` simples, e `C.UTF-8` não conta. O índice comum é construído
com a collation da coluna, então o planejador não o usa para `LIKE`.

O conserto é um índice construído com uma **classe de operadores** que compara strings byte a byte,
`text_pattern_ops`:

```
market=# CREATE INDEX customers_email_pattern_idx ON customers (email text_pattern_ops);
CREATE INDEX
Time: 192.789 ms

market=# EXPLAIN SELECT * FROM customers WHERE email LIKE 'user42@%';
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Index Scan using customers_email_pattern_idx on customers  (cost=0.42..8.44 rows=20 width=59)
   Index Cond: ((email ~>=~ 'user42@'::text) AND (email ~<~ 'user42A'::text))
   Filter: (email ~~ 'user42@%'::text)
(3 rows)

Time: 0.916 ms

market=# EXPLAIN SELECT * FROM customers WHERE email LIKE '%42@example.com';
                          QUERY PLAN                          
--------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..4783.00 rows=20 width=59)
   Filter: (email ~~ '%42@example.com'::text)
(2 rows)

Time: 2.475 ms
```

Agora o plano o usa, e o `Index Cond` mostra o truque: `LIKE 'user42@%'` virou a faixa de `user42@`
até `user42A`, a próxima string depois de toda continuação possível. A última consulta mostra o
limite do truque. Um **curinga no começo**, `LIKE '%42@example.com'`, não é uma faixa de coisa
nenhuma em ordem, e nenhuma B-tree ajuda. A seção 05 tem o índice que ajuda.

O índice de padrão é um segundo índice na mesma coluna, e não substitui o primeiro: a ordem dele
não é a da collation, então `ORDER BY email` e comparações `<` pela collation continuam precisando
do original. Crie um só para uma coluna que é de fato buscada por prefixo.

## Para o que a B-tree não serve

Toda pergunta da tabela é sobre o **valor inteiro** comparado com outro valor: igual, menor, antes,
começa com. As perguntas do resto desta aula têm outro formato:

- **este array contém `kitchen`?** O valor é uma lista, e a pergunta é sobre um elemento dentro dela.
  Ordenar arrays inteiros põe `{home,new}` e `{kitchen,new}` longe um do outro e `{home,new}` e
  `{home,sale}` juntos, o que não ajuda em nada a achar todo array com `kitchen`.
- **que títulos se parecem com este erro de digitação?** Não existe ordem em que strings parecidas
  fiquem juntas.
- **que intervalos de tempo se sobrepõem a este?** Dois intervalos não são "menores" nem "maiores"
  um que o outro.

Essas são as seções 04 e 05. Antes delas, a única estrutura que responde menos que uma B-tree, de
propósito.
