---
title: O que mudar, e em que ordem
version: 1
---

Um plano foi lido e o nó lento foi achado. O que fazer a respeito é uma lista curta, e a ordem
importa, porque as correções baratas são as que tornam as caras desnecessárias.

## 1. Reescreva a consulta para o índice poder se aplicar

Antes de acrescentar qualquer coisa, confira se a consulta está recusando um índice que existe. A
lista de sete razões da aula 9 é o roteiro, e o plano mostra qual delas é: a coluna está numa
linha `Filter` com uma função ou uma expressão em volta.

```
shop=# EXPLAIN ANALYZE SELECT * FROM customers WHERE lower(email) = 'user42@example.com';
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..2487.00 rows=500 width=48) (actual time=0.069..32.713 rows=1 loops=1)
   Filter: (lower(email) = 'user42@example.com'::text)
   Rows Removed by Filter: 99999
 Planning Time: 0.492 ms
 Execution Time: 32.818 ms
(5 rows)
```

Há um índice único em `email`, e o plano é uma varredura sequencial de cem mil linhas para achar
uma. A linha `Filter` diz por quê — `lower(email)` — e a correção é ou a consulta, se os endereços
já estão guardados em minúsculas, ou um índice na expressão. Nada aqui precisava de um índice novo
do tipo que o próximo passo acrescenta; precisava que a consulta e o índice nomeassem a mesma
coisa.

`date(placed_at)`, `price * 1.1`, `phone = 5551234` — cada um destes é uma reescrita, não um
índice, e cada um também conserta a estimativa.

## 2. Acrescente o índice que o plano está pedindo

O plano está pedindo um quando uma varredura lê uma tabela grande para ficar com poucas linhas, ou
quando um nested loop tem uma varredura sequencial no lado interno. Ele diz qual coluna na linha
`Filter`. Estas são as duas rodadas da etapa sobre `EXPLAIN ANALYZE`, antes do índice em
`customer_id` e depois dele:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=8.803..54.976 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
 Planning Time: 0.594 ms
 Execution Time: 55.058 ms
(5 rows)
```

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.51..47.38 rows=11 width=28) (actual time=0.023..0.030 rows=7 loops=1)
   Recheck Cond: (customer_id = 42)
   Heap Blocks: exact=7
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.016..0.016 rows=7 loops=1)
         Index Cond: (customer_id = 42)
 Planning Time: 0.470 ms
 Execution Time: 0.104 ms
(7 rows)
```

A mesma consulta, um índice, de 55 ms para 0,1. A aula 9 diz como escolher as colunas e a ordem
delas, e a seção `maintaining-them` dela diz para construir com `CONCURRENTLY`. Faça isso, e então
rode o `EXPLAIN` de novo — um índice que o planejador recusa é um custo sem benefício, e o plano é
o único jeito de saber que ele foi aceito.

## 3. Peça menos

Menos colunas, e menos linhas. A seção sobre varreduras teve a versão disso que surpreende as
pessoas:

```
shop=# EXPLAIN ANALYZE SELECT customer_id FROM orders WHERE customer_id = 42;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using orders_customer_id_idx on orders  (cost=0.42..4.62 rows=11 width=4) (actual time=0.055..0.057 rows=7 loops=1)
   Index Cond: (customer_id = 42)
   Heap Fetches: 0
 Planning Time: 0.381 ms
 Execution Time: 0.101 ms
(5 rows)
```

`SELECT customer_id` em vez de `SELECT *`, e a varredura vira index-only. A mesma consulta com `*`
busca toda linha. Quando a aplicação precisa de três colunas e pede vinte, ela está pagando pelas
dezessete em páginas lidas, e o plano é onde isso aparece.

Menos linhas é o argumento da aula 4 com um plano anexado. Paginar com `OFFSET`:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 500000;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=16726.42..16727.09 rows=20 width=28) (actual time=76.137..76.142 rows=20 loops=1)
   ->  Index Scan using orders_pkey on orders  (cost=0.42..33452.43 rows=1000000 width=28) (actual time=0.029..58.786 rows=500020 loops=1)
 Planning Time: 0.246 ms
 Execution Time: 76.176 ms
(4 rows)
```

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE id > 500000 ORDER BY id LIMIT 20;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..1.14 rows=20 width=28) (actual time=0.023..0.027 rows=20 loops=1)
   ->  Index Scan using orders_pkey on orders  (cost=0.42..18083.49 rows=502861 width=28) (actual time=0.022..0.025 rows=20 loops=1)
         Index Cond: (id > 500000)
 Planning Time: 0.115 ms
 Execution Time: 0.041 ms
(5 rows)
```

As duas devolvem vinte linhas. A primeira lê 500 020 pelo índice para jogar fora 500 000 — o
`rows=500020` na varredura diz isso — e a segunda lê vinte. A paginação por chave, `WHERE id >
last`, custa o mesmo na página um e na página vinte e cinco mil, e `OFFSET` custa mais a cada
página do que na anterior.

## 4. Conserte a estimativa

Quando a forma do plano está errada — um nested loop que deveria ter sido hash, um hash montado
do lado errado — e as varreduras já usam seus índices, a seção anterior se aplica. `ANALYZE`; um
índice de expressão, ou uma reescrita para a coluna ficar nua; estatísticas estendidas para colunas
que andam juntas. O índice não é a correção aqui; o planejador o teria usado se soubesse.

## 5. Mude a forma do trabalho

Algumas consultas são lentas porque fazem muito, corretamente. Um relatório que junta todo pedido
a todo cliente e agrupa por cidade lê duas tabelas inteiras e não há índice que mude isso. As
opções são as que aulas anteriores construíram: uma view materializada atualizada em horário
(aula 7), uma tabela de resumo mantida conforme as linhas chegam, ou rodar o relatório numa
réplica onde ele não compete com ninguém. A aula 11 acrescenta a que vem do lado da aplicação —
uma consulta que é rápida e roda mil vezes por página, que nenhum plano vai mostrar como lenta.

## O que não fazer

**Não desligue configurações do planejador em produção.** `enable_seqscan = off` e os irmãos
servem para ver um plano alternativo numa sessão, como a seção sobre junções fez. Deixados
ligados, fazem o planejador mentir para si mesmo sobre toda consulta do servidor, inclusive as que
iam bem.

**Não acrescente um índice para cada consulta lenta.** Cada um é o imposto permanente sobre
escritas da aula 9. A pergunta é sempre se a consulta vale isso — o `pg_stat_statements` diz com
que frequência ela roda, e um relatório rodado uma vez por mês não ganha um índice que um milhão
de inserções por dia vai manter.

**Não ajuste para uma execução só.** A primeira rodada aquece o cache; um valor na beirada da
distribuição não é o valor que a consulta costuma receber. Meça duas vezes, com um valor típico,
e com `BUFFERS`.

## E depois meça de novo

O número da primeira seção — o que o `pg_stat_statements` ou o log lhe deu — é contra o que a
correção se compara. Uma mudança que lê menos páginas, com o mesmo valor, com o cache quente, é
uma correção. Qualquer outra coisa é uma hipótese, e a aula passada disse o que fazer com essas.
