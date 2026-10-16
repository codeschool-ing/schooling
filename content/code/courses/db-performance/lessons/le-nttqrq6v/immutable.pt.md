---
title: A data que não se deixou indexar
version: 1
---

Um índice sobre uma expressão guarda o resultado da expressão para cada linha, calculado quando a
linha é gravada, e o lê de volta meses depois. Isso só faz sentido se a mesma linha der o mesmo
resultado em qualquer momento futuro, para qualquer pessoa, com qualquer configuração. O PostgreSQL
exige isso: toda função numa expressão de índice precisa estar marcada como **`IMMUTABLE`**, uma
promessa de que o resultado depende dos argumentos e de mais nada.

## O erro

```
market=# CREATE INDEX orders_placed_date_idx ON orders (date(placed_at));
ERROR:  functions in index expression must be marked IMMUTABLE
Time: 1.401 ms

market=# SELECT provolatile FROM pg_proc WHERE oid = 'date(timestamp with time zone)'::regprocedure;
 provolatile 
-------------
 s
(1 row)

Time: 1.854 ms
```

`functions in index expression must be marked IMMUTABLE`, e o `pg_proc` diz por quê: `date()` de um
`timestamptz` está marcada como **`s`, stable**. Stable quer dizer "o mesmo dentro de uma instrução",
uma promessa mais fraca, e a consulta seguinte mostra do que a função depende além do argumento.

## Do que ela depende

```
market=# SET TimeZone = 'UTC';
SET
Time: 0.773 ms

market=# SELECT date(timestamptz '2025-06-01 22:30-03');
    date    
------------
 2025-06-02
(1 row)

Time: 0.569 ms

market=# SET TimeZone = 'America/Sao_Paulo';
SET
Time: 0.383 ms

market=# SELECT date(timestamptz '2025-06-01 22:30-03');
    date    
------------
 2025-06-01
(1 row)

Time: 0.424 ms
```

O mesmo instante, 22h30 de 1º de junho em São Paulo, é **2 de junho** para uma sessão cujo `TimeZone`
é UTC, e **1º de junho** para uma em São Paulo. Um `timestamptz` é um momento, não uma data de
calendário, e o dia em que um momento cai depende de onde você está. `date()` consulta a configuração
`TimeZone` da sessão, então o resultado dela para uma linha pode mudar entre duas sessões, ou entre
duas instalações da mesma aplicação.

Agora imagine que o índice tivesse sido aceito. Ele guardaria a data de cada pedido calculada pela
sessão que o construiu, fosse ela qual fosse. Uma sessão com outro `TimeZone` pediria ao índice
`2025-06-01`, receberia as linhas que eram 1º de junho para outra pessoa, e ganharia uma resposta
errada sem erro nenhum. Um índice que discorda da tabela é o pior tipo de erro, e a regra do
`IMMUTABLE` existe para torná-lo impossível.

## Tornando a expressão imutável

O conserto é tirar a dependência, dizendo em que fuso horário o dia é contado. `AT TIME ZONE
'America/Sao_Paulo'` transforma o momento numa hora local de um fuso com nome, diga a sessão o que
disser, e o cast disso para `date` é imutável:

```
market=# CREATE INDEX orders_placed_date_idx ON orders (((placed_at AT TIME ZONE 'America/Sao_Paulo')::date));
CREATE INDEX
Time: 1076.044 ms (00:01.076)

market=# EXPLAIN SELECT count(*) FROM orders WHERE (placed_at AT TIME ZONE 'America/Sao_Paulo')::date = '2025-06-01';
                                                 QUERY PLAN                                                  
-------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=15406.29..15406.30 rows=1 width=8)
   ->  Bitmap Heap Scan on orders  (cost=113.93..15381.29 rows=10000 width=0)
         Recheck Cond: (((placed_at AT TIME ZONE 'America/Sao_Paulo'::text))::date = '2025-06-01'::date)
         ->  Bitmap Index Scan on orders_placed_date_idx  (cost=0.00..111.43 rows=10000 width=0)
               Index Cond: (((placed_at AT TIME ZONE 'America/Sao_Paulo'::text))::date = '2025-06-01'::date)
(5 rows)

Time: 1.997 ms

market=# ANALYZE orders;
ANALYZE
Time: 268.478 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE (placed_at AT TIME ZONE 'America/Sao_Paulo')::date = '2025-06-01';
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=58.79..58.80 rows=1 width=8) (actual time=0.713..0.714 rows=1 loops=1)
   ->  Index Scan using orders_placed_date_idx on orders  (cost=0.43..54.62 rows=1668 width=0) (actual time=0.062..0.567 rows=2801 loops=1)
         Index Cond: (((placed_at AT TIME ZONE 'America/Sao_Paulo'::text))::date = '2025-06-01'::date)
 Planning Time: 0.247 ms
 Execution Time: 0.760 ms
(5 rows)

Time: 1.570 ms

market=# EXPLAIN SELECT count(*) FROM orders WHERE date(placed_at) = '2025-06-01';
                                       QUERY PLAN                                       
----------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=30177.63..30177.64 rows=1 width=8)
   ->  Gather  (cost=30177.42..30177.63 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=29177.42..29177.43 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=4167 width=0)
                     Filter: (date(placed_at) = '2025-06-01'::date)
(6 rows)

Time: 0.804 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders_placed_at_idx', 'orders_placed_date_idx');
        relname         | size  
------------------------+-------
 orders_placed_at_idx   | 43 MB
 orders_placed_date_idx | 14 MB
(2 rows)

Time: 1.080 ms
```

Quatro coisas nesse bloco.

- **O índice foi aceito**, porque a expressão não pergunta mais nada à sessão. Os parênteses extras
  são obrigatórios: qualquer coisa além de uma única chamada de função precisa ir entre parênteses.
- **A primeira estimativa foi de 10.000 linhas**, meio por cento da tabela, o mesmo palpite fixo da
  seção anterior: o índice existia e o `ANALYZE` ainda não tinha medido a sua expressão. Depois do
  `ANALYZE orders` a estimativa é **1668** contra **2801** reais, agora a partir das estatísticas dos
  dias.
- **A consulta levou 0,76 milissegundo**, contra os 119 da original da aula 1 e o 1,3 da sua
  reescrita como faixa.
- **`date(placed_at)` continua recebendo scan sequencial.** O índice atende à expressão sobre a qual
  foi construído, escrita do mesmo jeito, e a mais nada, como a seção anterior disse.

## Indexar a expressão, ou reescrever a consulta?

A aula 1 reescreveu esta consulta como uma faixa em `placed_at`, e essa resposta não precisou de
índice novo: o existente a atendeu em 1,3 milissegundo. O índice de expressão responde em 0,8, e
custa **14 MB** de disco e uma entrada a mais para manter a cada pedido gravado, ao lado do índice de
43 MB em `placed_at`, que continua necessário para todo o resto.

Então a reescrita costuma ser a melhor escolha quando você pode mudar a consulta. O índice de
expressão é o certo quando você não pode: um ORM que gera `date(...)`, uma ferramenta de relatório,
uma consulta que agrupa pelo dia além de filtrar por ele. De qualquer jeito, o dia a que um pedido
pertence depende de um fuso horário, e escrever esse fuso é uma decisão sobre o negócio, não sobre o
índice.

Esta aula criou índices e uma tabela no `market`. Feche o `psql` e devolva o banco ao estado em que a
aula 3 começa:

```sh
~/reset-market.sh
```
