---
title: O Postgres também faz isso
version: 1
---

A loja de `sql-databases` rodava em PostgreSQL, e os motivos dados para sair de um banco relacional
são quase todos sobre recursos que ele supostamente não tem: documentos de forma flexível, acesso
chave-valor rápido, um cache, uma fila. **O Postgres tem cada um deles há anos**, dentro do mesmo
banco que já guarda os pedidos, com as mesmas transações e o mesmo backup. Esta seção roda quatro
deles, e depois diz com clareza o que o Postgres não faz tão bem.

## O Postgres ao lado dos outros três

`postgres:16` é a imagem oficial, na rede `nosql` do curso como as outras. A senha é exigida pela
imagem e só é usada dentro do contêiner:

```sh
docker run -d --name postgres --network nosql -e POSTGRES_PASSWORD=lab postgres:16
```

```
ana@vm:~$ docker run -d --name postgres --network nosql -e POSTGRES_PASSWORD=lab postgres:16
15baf0d53a82d3d06169fb4ee7dc8cd805958e71e35cdfa2f9b3983e0c685d5b
ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT version()"
                                                       version                                                        
----------------------------------------------------------------------------------------------------------------------
 PostgreSQL 16.15 (Debian 16.15-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

```

Cada um dos três arquivos abaixo é salvo na VM e passado ao `psql` pela entrada; `-a` ecoa cada linha
do arquivo antes da resposta, então a transcrição se lê como uma sessão.

## Documentos: `jsonb` e um índice GIN

Os pedidos da aula 6, como documentos numa coluna `jsonb`. Um pedido em cinquenta traz um objeto
`gift` que os outros não têm, e essa é a forma variável que supostamente exigiria um banco de
documentos:

```sql
-- documents.sql: the shop's orders as JSON documents, in one column
CREATE TABLE orders (id bigint PRIMARY KEY, doc jsonb NOT NULL);
INSERT INTO orders
SELECT n, jsonb_build_object(
         'customer', (ARRAY['ana', 'bruno', 'carla', 'diego', 'elisa'])[n % 5 + 1] || '@example.com',
         'items', jsonb_build_array(jsonb_build_object(
                    'sku', (ARRAY['KB-101', 'MS-204', 'MN-330', 'CB-012'])[n % 4 + 1],
                    'qty', 1 + n % 3)))
       || CASE WHEN n % 50 = 0 THEN '{"gift": {"wrap": true, "note": "Happy birthday"}}'::jsonb
               ELSE '{}'::jsonb END
FROM generate_series(1, 100000) AS n;
CREATE INDEX orders_doc ON orders USING gin (doc jsonb_path_ops);
ANALYZE orders;
SELECT doc FROM orders WHERE id = 50;
EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
```

```
ana@vm:~$ docker exec -i postgres psql -U postgres -a < documents.sql
-- documents.sql: the shop's orders as JSON documents, in one column
CREATE TABLE orders (id bigint PRIMARY KEY, doc jsonb NOT NULL);
CREATE TABLE
INSERT INTO orders
SELECT n, jsonb_build_object(
         'customer', (ARRAY['ana', 'bruno', 'carla', 'diego', 'elisa'])[n % 5 + 1] || '@example.com',
         'items', jsonb_build_array(jsonb_build_object(
                    'sku', (ARRAY['KB-101', 'MS-204', 'MN-330', 'CB-012'])[n % 4 + 1],
                    'qty', 1 + n % 3)))
       || CASE WHEN n % 50 = 0 THEN '{"gift": {"wrap": true, "note": "Happy birthday"}}'::jsonb
               ELSE '{}'::jsonb END
FROM generate_series(1, 100000) AS n;
INSERT 0 100000
CREATE INDEX orders_doc ON orders USING gin (doc jsonb_path_ops);
CREATE INDEX
ANALYZE orders;
ANALYZE
SELECT doc FROM orders WHERE id = 50;
                                                            doc                                                            
---------------------------------------------------------------------------------------------------------------------------
 {"gift": {"note": "Happy birthday", "wrap": true}, "items": [{"qty": 3, "sku": "MN-330"}], "customer": "ana@example.com"}
(1 row)

EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
                              QUERY PLAN                              
----------------------------------------------------------------------
 Aggregate
   ->  Bitmap Heap Scan on orders
         Recheck Cond: (doc @> '{"gift": {"wrap": true}}'::jsonb)
         ->  Bitmap Index Scan on orders_doc
               Index Cond: (doc @> '{"gift": {"wrap": true}}'::jsonb)
(5 rows)

SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
 count 
-------
  2000
(1 row)

```

`@>` é **contenção**: este documento contém este documento menor? É a pergunta que o
`find({ "gift.wrap": true })` do MongoDB faz, e o plano responde com um **`Bitmap Index Scan on
orders_doc`**, o índice GIN, em vez de ler as 100.000 linhas. Os 2.000 pedidos de presente são um em
cinquenta, como gerado. `jsonb_path_ops` é o sabor de GIN feito exatamente para esse operador: menor e
mais rápido para `@>`, e inútil para perguntar que chaves existem, o que o sabor padrão consegue.

O que o documento ganha **a mais** é tudo o que é relacional: chave primária, um `CHECK` em qualquer
campo, uma chave estrangeira a partir de `doc->>'customer'` se você extraí-lo para uma coluna, e um
join com qualquer outra tabela, na mesma transação que o resto da loja.

## Chave-valor: um upsert, um contador e um cache

```sql
-- keyvalue.sql: a counter, and a cache that does not need to survive a crash
CREATE TABLE page_views (page text PRIMARY KEY, n bigint NOT NULL);
CREATE UNLOGGED TABLE cache (key text PRIMARY KEY, value jsonb NOT NULL, expires_at timestamptz NOT NULL);
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
INSERT INTO cache VALUES ('product:MN-330', '{"name": "27-inch monitor", "price": "1499.00"}', now() + interval '5 minutes')
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, expires_at = EXCLUDED.expires_at;
SELECT value FROM cache WHERE key = 'product:MN-330' AND expires_at > now();
SELECT relname, relpersistence FROM pg_class WHERE relname IN ('page_views', 'cache');
```

```
ana@vm:~$ docker exec -i postgres psql -U postgres -a < keyvalue.sql
-- keyvalue.sql: a counter, and a cache that does not need to survive a crash
CREATE TABLE page_views (page text PRIMARY KEY, n bigint NOT NULL);
CREATE TABLE
CREATE UNLOGGED TABLE cache (key text PRIMARY KEY, value jsonb NOT NULL, expires_at timestamptz NOT NULL);
CREATE TABLE
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
 n 
---
 1
(1 row)

INSERT 0 1
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
 n 
---
 2
(1 row)

INSERT 0 1
INSERT INTO cache VALUES ('product:MN-330', '{"name": "27-inch monitor", "price": "1499.00"}', now() + interval '5 minutes')
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, expires_at = EXCLUDED.expires_at;
INSERT 0 1
SELECT value FROM cache WHERE key = 'product:MN-330' AND expires_at > now();
                      value                      
-------------------------------------------------
 {"name": "27-inch monitor", "price": "1499.00"}
(1 row)

SELECT relname, relpersistence FROM pg_class WHERE relname IN ('page_views', 'cache');
  relname   | relpersistence 
------------+----------------
 page_views | p
 cache      | u
(2 rows)

```

**`INSERT ... ON CONFLICT DO UPDATE` é o upsert**: insere a chave, ou a atualiza se já existir, de
forma atômica. O mesmo comando respondeu 1 e depois 2, que é o `INCR` do Redis em SQL. A entrada do
cache traz a própria expiração, conferida no `WHERE`; ao contrário do Redis, nada apaga as linhas
vencidas por você, então um `DELETE` agendado faz isso.

`relpersistence` diz `p` para permanente e **`u` para unlogged**. Uma tabela unlogged pula o
write-ahead log, o que barateia as escritas, e o preço está escrito na documentação e é fácil de
provar. Mate o servidor como uma queda de energia faria, e suba de novo:

```
ana@vm:~$ docker kill postgres
postgres
ana@vm:~$ docker start postgres
postgres
ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT (SELECT count(*) FROM page_views) AS page_views, (SELECT count(*) FROM cache) AS cache"
 page_views | cache 
------------+-------
          1 |     0
(1 row)

ana@vm:~$ docker logs postgres 2>&1 | grep -E "not properly shut down|redo done|ready to accept" | tail -3
2026-10-11 02:00:59.432 UTC [34] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-11 02:00:59.512 UTC [34] LOG:  redo done at 0/2C002D8 system usage: CPU: user: 0.05 s, system: 0.01 s, elapsed: 0.07 s
2026-10-11 02:00:59.580 UTC [1] LOG:  database system is ready to accept connections
```

A recuperação reaplicou o log, o contador sobreviveu, e **o cache unlogged voltou vazio**, que é o
que um cache pode fazer e o que o Redis sem persistência da aula 13 também faz. A mesma escolha,
feita por tabela.

## Uma fila: `FOR UPDATE SKIP LOCKED`

Três tarefas, e dois workers que nunca podem pegar a mesma:

```sql
-- queue.sql: three jobs, for workers that must not take the same one
CREATE TABLE jobs (id bigserial PRIMARY KEY, task text NOT NULL, done boolean NOT NULL DEFAULT false);
INSERT INTO jobs (task) VALUES ('email order 1001'), ('email order 1002'), ('email order 1003');
```

O primeiro worker pega uma tarefa e a segura por trinta segundos, em segundo plano; o segundo
pergunta enquanto o primeiro ainda a segura:

```
ana@vm:~$ docker exec -i postgres psql -U postgres -q < queue.sql
ana@vm:~$ docker exec -d postgres psql -U postgres -c "BEGIN; SELECT id FROM jobs WHERE NOT done ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED; SELECT pg_sleep(30); COMMIT;"
ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT id, task FROM jobs WHERE NOT done ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED"
 id |       task       
----+------------------
  2 | email order 1002
(1 row)

ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'jobs'::regclass"
 locktype | relation |     mode     | granted 
----------+----------+--------------+---------
 relation | jobs     | RowShareLock | t
(1 row)
```

O segundo worker pegou **a tarefa 2, sem esperar**: `FOR UPDATE` trava a linha que devolve, e `SKIP
LOCKED` pula as linhas que outra transação travou, em vez de entrar na fila atrás delas. O
`RowShareLock` no `pg_locks` é a marca do primeiro worker na tabela, ainda aberta no `pg_sleep`; a
trava da linha em si mora na própria linha. Um worker marca sua tarefa como `done` e confirma; um que
morre faz rollback, e a tarefa fica livre para o próximo. `LISTEN` e `NOTIFY` acrescentam a metade que
falta, acordando os workers quando chega uma tarefa em vez de fazê-los perguntar sem parar.

## O que o Postgres não faz tão bem

Honestidade vale para os dois lados, e as lacunas são reais:

- **Escritas em muitas máquinas ao mesmo tempo.** Um cluster Postgres tem um primário que recebe
  todas as escritas; as réplicas de `db-reliability` leem. Quando o volume de escritas passa da maior
  máquina que dá para comprar, fazer sharding de Postgres é possível com extensões e com trabalho na
  aplicação, e é o que o Cassandra e o sharding do MongoDB foram feitos para fazer desde o início
  (aulas 10 e 16).
- **Escritas em várias regiões ao mesmo tempo.** Aceitar escritas em São Paulo e em Lisboa no mesmo
  instante, sem primário a esperar do outro lado do Atlântico, é a replicação entre datacenters do
  Cassandra (aula 17). A resposta do Postgres é uma região que escreve, e leitores nas outras.
- **Estruturas na velocidade da memória.** Sorted sets, streams com grupos de consumidores e
  contadores abaixo de um milissegundo são o que o Redis é (aula 12); uma tabela com índice é um bom
  contador e um ranking mais lento.

Essas três são a lista honesta. **A maioria das aplicações nunca chega às duas primeiras**, e a
terceira costuma ser resolvida pondo o Redis ao lado do Postgres, e não no lugar dele, que é o
assunto das duas próximas seções.
