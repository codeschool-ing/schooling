---
title: Hash: igualdade e mais nada
version: 1
---

Um índice hash é a B-tree sem a ordem. Ele passa cada valor por uma função de hash e arquiva a linha
sob o número resultante, então consegue responder exatamente uma pergunta, **esta coluna é igual a
este valor?**, e nada sobre menor, maior, faixas, prefixos ou ordem. Em troca, guarda um código de
hash de tamanho fixo em vez do próprio valor, o que o deixa menor quando os valores são longos.

Ele também carrega uma reputação antiga que já não vale. Antes do PostgreSQL 10, índices hash não
eram gravados no write-ahead log, então não sobreviviam a uma queda nem eram copiados para réplicas,
e a documentação mandava não usá-los. Desde a versão 10 eles são **tão seguros quanto qualquer outro
índice**. O que sobra é uma ferramenta estreita, e esta seção mede o quanto.

## A mesma coluna, de três jeitos

`customers.email` já tem uma B-tree, a que sustenta o `UNIQUE`. A seção 02 acrescentou uma segunda,
com `text_pattern_ops`, para buscas por prefixo. Crie um índice hash ao lado delas e compare os
tamanhos:

```
market=# CREATE INDEX customers_email_hash_idx ON customers USING hash (email);
CREATE INDEX
Time: 476.519 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('customers_email_key', 'customers_email_pattern_idx', 'customers_email_hash_idx');
           relname           |  size   
-----------------------------+---------
 customers_email_key         | 14 MB
 customers_email_pattern_idx | 7960 kB
 customers_email_hash_idx    | 6568 kB
(3 rows)

Time: 1.493 ms
```

**14 MB para a B-tree da restrição, 6568 kB para o hash**, um pouco menos da metade. Os endereços
aqui têm uns vinte caracteres, `user123456@example.com`, e o hash guarda um código de quatro bytes
para cada um onde a B-tree guarda os vinte. O índice de padrão sai com 7960 kB, menor que a primeira
B-tree embora guarde os mesmos valores. Os dois foram construídos de jeitos diferentes: o índice da
restrição foi criado com a tabela vazia e cresceu um insert de cada vez, dividindo páginas pelo
caminho, e o índice de padrão foi construído de uma vez sobre a tabela pronta, com as páginas cheias.

## O que o planejador faz com ele

```
market=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                        QUERY PLAN                                         
-------------------------------------------------------------------------------------------
 Index Scan using customers_email_hash_idx on customers  (cost=0.00..8.02 rows=1 width=59)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)

Time: 1.202 ms

market=# EXPLAIN SELECT * FROM customers WHERE email > 'user99990';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Bitmap Heap Scan on customers  (cost=77.95..2334.22 rows=1746 width=59)
   Recheck Cond: (email > 'user99990'::text)
   ->  Bitmap Index Scan on customers_email_key  (cost=0.00..77.52 rows=1746 width=0)
         Index Cond: (email > 'user99990'::text)
(4 rows)

Time: 4.390 ms

market=# DROP INDEX customers_email_hash_idx;
DROP INDEX
Time: 4.030 ms

market=# DROP INDEX customers_email_pattern_idx;
DROP INDEX
Time: 16.947 ms
```

Para igualdade o planejador escolhe o índice hash, o mais barato dos três de ler. Para `>`, uma
faixa, ele vai para a B-tree da restrição, porque um hash nem pode ser consultado para isso. **O
índice hash é invisível para toda consulta que não seja `=`.**

## Quando vale a pena

**Quase nunca como substituto**, e esse é o resumo honesto. Os casos em que um índice hash merece o
lugar são estreitos:

- **valores longos comparados só por igualdade**: uma URL, um token, um resumo de conteúdo, uma
  chave natural longa que é procurada e nunca ordenada nem buscada por prefixo. Quanto mais longo o
  valor, maior a economia, já que o hash continua com quatro bytes.
- **uma coluna em que você nunca faria um scan por faixa**, onde a ordem da B-tree não compra nada.

E os motivos para deixá-lo de lado:

- **ele não garante `UNIQUE`.** A restrição em `customers.email` precisa da sua B-tree de qualquer
  jeito, então um índice hash nessa coluna é um índice a mais, não um mais barato.
- **ele não serve a `ORDER BY`, a uma faixa nem a um prefixo**, e o próximo requisito de uma coluna
  costuma ser um desses.
- **é mais um índice para manter atualizado** a cada insert e update, e a aula 11 põe preço nisso.

`customers.email` é uma coluna onde ele não compensa: a B-tree tem de ficar, e o hash seria um
terceiro índice numa coluna só. Os dois índices extras saem de novo no fim do bloco acima, e a busca
por tag, a que a aula 2 pôs no topo do placar, vem a seguir.
