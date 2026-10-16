---
title: amcheck, que pergunta a um índice se ele ainda está certo
version: 1
---

Um índice corrompido não dá sinal de si até uma consulta ler a página errada, e aí o sinal é uma
resposta errada, que ninguém relata como erro. **O `amcheck` lê um índice e o confere contra as
próprias regras dele**, para você fazer a pergunta antes de um usuário. É uma das extensões que vêm
com o próprio PostgreSQL, já instalada com o pacote do servidor, e a lição 18 trata de extensões em
geral.

```
shop=# CREATE EXTENSION amcheck;
CREATE EXTENSION

shop=# SELECT c.relname, bt_index_check(c.oid, heapallindexed => true) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am am ON am.oid = c.relam WHERE am.amname = 'btree' AND c.relnamespace = 'public'::regnamespace;
       relname       | bt_index_check 
---------------------+----------------
 customers_pkey      | 
 customers_email_key | 
 orders_pkey         | 
 orders_customer_id  | 
 orders_created_at   | 
(5 rows)
```

O `bt_index_check` confere um índice B-tree, o tipo comum, e a consulta o roda sobre todo índice
B-tree do esquema `public`. **Um resultado vazio numa linha é a resposta boa**: a função não devolve
nada quando não acha nada, e levanta um erro quando acha um problema.

Sem opções, ela confere que as entradas dentro de cada página estão em ordem e que cada página
concorda com as vizinhas. **`heapallindexed => true` acrescenta a conferência que mais importa**: lê
a tabela e confirma que toda linha tem a sua entrada no índice, que é a corrupção que faz uma
consulta perder linhas. Leva mais tempo, mais ou menos uma leitura da tabela, e as duas pegam só o
lock que um `SELECT` pega, então são seguras num servidor em uso. O `bt_index_parent_check` confere
mais, os elos entre os níveis da árvore, e pega um lock que bloqueia escritas enquanto roda.

Para um banco inteiro há uma ferramenta de linha de comando, o `pg_amcheck`. O Ubuntu não a põe no
`PATH`, então ela é chamada pelo caminho completo:

```
ana@db:~$ /usr/lib/postgresql/16/bin/pg_amcheck --heapallindexed shop && echo clean
clean
```

O `pg_amcheck` em si não imprimiu nada, e o `echo` rodou porque ele terminou com sucesso: tudo o
que conferiu passou, todo índice B-tree, e também toda tabela, que o amcheck também sabe ler em busca de dano. Na
versão 16 nada no amcheck confere um índice GIN ou GiST.

## Um índice que discorda da sua tabela

Um resultado limpo é o comum, então aqui vai um índice construído para estar errado, do mesmo jeito
que um índice de texto dá errado depois de uma mudança na glibc: **construído com um conjunto de
regras, lido com outro.** As regras aqui são um fuso horário, e o culpado é uma função que promete
mais do que consegue cumprir.

```
shop=# CREATE FUNCTION order_day(ts timestamptz) RETURNS date LANGUAGE sql IMMUTABLE AS $$ SELECT ts::date $$;
CREATE FUNCTION

shop=# CREATE TABLE day_check AS SELECT id, created_at FROM orders WHERE id <= 100000;
SELECT 100000

shop=# SET TimeZone = 'America/Sao_Paulo';
SET

shop=# CREATE INDEX day_check_day ON day_check (order_day(created_at));
CREATE INDEX

shop=# ANALYZE day_check;
ANALYZE

shop=# SELECT bt_index_check('day_check_day', heapallindexed => true);
 bt_index_check 
----------------
 
(1 row)

shop=# SET TimeZone = 'UTC';
SET

shop=# EXPLAIN (COSTS OFF) SELECT min(created_at), max(created_at) FROM day_check WHERE order_day(created_at) = '2026-01-02';
                               QUERY PLAN                               
------------------------------------------------------------------------
 Aggregate
   ->  Bitmap Heap Scan on day_check
         Recheck Cond: (order_day(created_at) = '2026-01-02'::date)
         ->  Bitmap Index Scan on day_check_day
               Index Cond: (order_day(created_at) = '2026-01-02'::date)
(5 rows)

shop=# SELECT min(created_at), max(created_at) FROM day_check WHERE order_day(created_at) = '2026-01-02';
          min           |          max           
------------------------+------------------------
 2026-01-02 03:00:01+00 | 2026-01-03 02:56:01+00
(1 row)

shop=# SELECT bt_index_check('day_check_day', heapallindexed => true);
ERROR:  heap tuple (408,120) from table "day_check" lacks matching index tuple within index "day_check_day"
HINT:  Retrying verification using the function bt_index_parent_check() might provide a more specific error.

shop=# RESET TimeZone;
RESET

shop=# DROP TABLE day_check;
DROP TABLE

shop=# DROP FUNCTION order_day;
DROP FUNCTION

shop=# DROP EXTENSION amcheck;
DROP EXTENSION
```

Um índice sobre uma expressão só é permitido quando a expressão é `IMMUTABLE`: a mesma entrada dá a
mesma saída para sempre. A `order_day` diz que é, e não é, **porque o dia em que um instante cai
depende do `TimeZone` da sessão**. O índice foi construído no horário de São Paulo, definido logo antes
para a demonstração funcionar em qualquer fuso que o seu servidor use, e a primeira conferência passou: pelas regras com que foi construído, o índice estava
certo.

Então a sessão passou para UTC. O plano usa o índice, como deve, e pedindo 2 de janeiro devolve
pedidos com horário entre 03:00 de 2 de janeiro e quase 03:00 de 3 de janeiro em UTC: o 2 de janeiro
de São Paulo, não o que foi pedido. **A consulta recebeu uma resposta errada e nenhum erro.** A
segunda conferência pegou: o `heapallindexed` calculou `order_day` para uma linha da tabela com as
regras atuais, procurou essa entrada no índice e não achou, e a mensagem nomeia a linha pela posição
física dela.

Essa é a família inteira. Uma collation que mudou debaixo de um índice de texto, uma função marcada
`IMMUTABLE` que não é, um disco que perdeu uma escrita: cada um deixa um índice cujas entradas não
batem com o que a tabela diz agora, e o `bt_index_check` com `heapallindexed` é como achar um.
**Reconstruir só resolve o primeiro e o último.** Para uma função mentirosa, o `REINDEX` construiria o
índice com o fuso que a sessão tiver e o quebraria para o outro; a correção é uma função que diga a
verdade, como uma que converte com `AT TIME ZONE 'America/Sao_Paulo'` antes de tirar a data, e depois
a reconstrução. Tudo o que foi criado aqui é apagado de novo, a extensão inclusive.
