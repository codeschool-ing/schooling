---
title: O scan que nunca lê a tabela
version: 1
---

Um index scan comum faz duas coisas para cada linha que devolve. Acha a entrada no índice, e depois
segue o ponteiro da entrada até a tabela, o **heap**, para ler a linha. A aula 4 mostrou quanto custa
esse segundo passo quando as linhas estão espalhadas: uma leitura de página por linha, em ordem
nenhuma que ajude. Um **index-only scan** pula o segundo passo. Se o índice já guarda todas as colunas
de que a consulta precisa, a resposta pode vir só do índice.

A ideia errada a abandonar primeiro é que um index-only scan é um tipo especial de índice. Não é.
Qualquer B-tree consegue fazer um; quem decide é a **consulta**, e se todas as colunas que ela toca
estão no índice.

## Um índice, duas consultas

O `orders_placed_at_idx` guarda `placed_at` e mais nada. Faça a ele duas perguntas sobre dezembro de
2025:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3290.29..3290.30 rows=1 width=8) (actual time=19.599..19.600 rows=1 loops=1)
   Buffers: shared hit=1 read=298
   ->  Index Only Scan using orders_placed_at_idx on orders  (cost=0.43..3025.05 rows=106093 width=0) (actual time=0.078..14.296 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Heap Fetches: 0
         Buffers: shared hit=1 read=298
 Planning:
   Buffers: shared hit=110 read=6
 Planning Time: 0.816 ms
 Execution Time: 19.696 ms
(10 rows)

Time: 21.948 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-12-01';
                                                                   QUERY PLAN                                                                    
-------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=4178.29..4178.30 rows=1 width=8) (actual time=50.919..50.921 rows=1 loops=1)
   Buffers: shared hit=1197
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..3913.06 rows=106093 width=4) (actual time=0.046..34.855 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Buffers: shared hit=1197
 Planning:
   Buffers: shared hit=6
 Planning Time: 0.129 ms
 Execution Time: 50.960 ms
(9 rows)

Time: 51.932 ms
```

As duas consultas filtram por `placed_at` e as duas leem os mesmos 107.780 pedidos, e os planos são
diferentes.

- **`count(*)`** não precisa de coluna nenhuma, só do número de linhas que passam pela condição,
  então o índice tem tudo. O plano é um `Index Only Scan`, `Heap Fetches: 0`, e **299 páginas** lidas
  no total, as páginas do próprio índice para aquele trecho de datas.
- **`sum(total_cents)`** precisa de `total_cents`, que não está no índice. O plano é um `Index Scan`
  comum, e ele tocou **1197 páginas**: as mesmas páginas do índice, mais as da tabela. Levou 51
  milissegundos contra 20.

As linhas `Buffers` são as da aula 3: `hit` conta páginas achadas na memória e `read` páginas
trazidas de fora dela. A primeira consulta leu de fora porque rodou primeiro, com o cache frio; o que
importa aqui é o total, que conta as páginas de um jeito ou de outro.

## As duas linhas a ler

Duas linhas de um plano dizem se um index-only scan é mesmo um:

- **o nome do nó**, `Index Only Scan` e não `Index Scan`. O planejador só o escolhe quando toda coluna
  que a consulta usa, na lista do `SELECT`, no `WHERE`, no `ORDER BY` e em qualquer outro lugar, está
  guardada no índice.
- **`Heap Fetches`**, o número de linhas para as quais o scan precisou ir à tabela mesmo assim. O nome
  promete zero; o número diz o que aconteceu.

A segunda linha é a que as pessoas pulam, e é o assunto da próxima seção. Um index-only scan com um
`Heap Fetches` grande é um index scan comum usando o outro nome, e o `BUFFERS` da aula 3 vai mostrá-lo
lendo tantas páginas quanto um.

## Por que a tabela é necessária

Se todas as colunas estão no índice, por que o scan iria à tabela? Porque o índice não sabe **se uma
linha está visível** para a sua transação. O PostgreSQL guarda versões antigas e novas das linhas lado
a lado, e qual versão uma transação pode ver está escrito no cabeçalho da linha na tabela, não no
índice. Uma entrada de índice pode apontar para uma linha apagada há um segundo, ou inserida por uma
transação que ainda não confirmou. A aula 15 trata dessas versões e do que elas custam; aqui o ponto
é mais estreito. Antes de responder pelo índice, o scan precisa saber que a linha por trás da entrada
está visível, e o jeito barato de saber é um mapa que a tabela mantém das páginas em que toda linha é
visível para todo mundo. Esse mapa, e o que o apaga, é a seção 03.
