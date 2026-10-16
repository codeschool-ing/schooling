---
title: Dois shards numa máquina só, e o que atravessa o fio
version: 1
---

O jeito mais rápido de entender sharding é montar um pequeno e ver o que ele faz com consultas que
você já conhece. Esta seção divide `orders` em dois por `customer_id`, põe cada metade no seu
próprio banco e dá ao `market` uma tabela que parece o todo. **Tudo roda na sua única máquina
virtual**: os dois bancos de shard fazem o papel de dois servidores, e a única coisa que mudaria com
servidores de verdade é um nome de host em duas linhas. O que a demonstração não consegue mostrar é
a rede entre máquinas de verdade, que deixa cada custo abaixo maior, nunca menor.

A ferramenta é o **`postgres_fdw`**, um foreign-data wrapper que vem com o PostgreSQL: ele deixa um
banco ler e gravar uma tabela que mora em outro, mandando SQL por uma conexão. Junto com o
particionamento por hash da aula 17, ele transforma as partições de uma tabela em tabelas em outros
servidores. O `market` vira o **coordenador**, o servidor com que a aplicação fala, e não guarda
nenhuma linha de pedido.

## Os shards

Cada shard ganha a mesma tabela `orders`, sem a coluna identity e sem as chaves estrangeiras: um
shard não pode apontar para `customers` em outro servidor. Escreva o arquivo:

```sh
cat > ~/shard-table.sql <<'SQL'
-- shard-table.sql: the orders table as each shard holds it.
CREATE TABLE orders (
    id          bigint      PRIMARY KEY,
    customer_id integer     NOT NULL,
    seller_id   integer     NOT NULL,
    placed_at   timestamptz NOT NULL,
    status      text        NOT NULL,
    total_cents integer     NOT NULL
);
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
SQL
```

E a metade do coordenador, que o `market` executa:

```sh
cat > ~/coordinator.sql <<'SQL'
-- coordinator.sql: in market, one table whose two halves live on the shards.
CREATE EXTENSION postgres_fdw;

CREATE SERVER shard1 FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'shard1', batch_size '1000');
CREATE SERVER shard2 FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'shard2', batch_size '1000');
CREATE USER MAPPING FOR CURRENT_USER SERVER shard1
    OPTIONS (user 'ana', password 'shard-lab');
CREATE USER MAPPING FOR CURRENT_USER SERVER shard2
    OPTIONS (user 'ana', password 'shard-lab');

CREATE TABLE sharded_orders (
    id          bigint      NOT NULL,
    customer_id integer     NOT NULL,
    seller_id   integer     NOT NULL,
    placed_at   timestamptz NOT NULL,
    status      text        NOT NULL,
    total_cents integer     NOT NULL
) PARTITION BY HASH (customer_id);

CREATE FOREIGN TABLE sharded_orders_1 PARTITION OF sharded_orders
    FOR VALUES WITH (MODULUS 2, REMAINDER 0)
    SERVER shard1 OPTIONS (table_name 'orders');
CREATE FOREIGN TABLE sharded_orders_2 PARTITION OF sharded_orders
    FOR VALUES WITH (MODULUS 2, REMAINDER 1)
    SERVER shard2 OPTIONS (table_name 'orders');
SQL
```

Um `SERVER` diz onde um shard está, e um `USER MAPPING` como entrar nele. A conexão vai por TCP até
`localhost`, como iria para outra máquina, então o seu papel precisa de uma senha, coisa que não
precisou até agora; o último comando desta aula a remove de novo. O `batch_size` deixa o coordenador
mandar linhas de mil em mil em vez de uma por ida e volta. Depois os dois bancos, a tabela em cada
um, a senha e o coordenador:

```
ana@vm:~$ createdb shard1
ana@vm:~$ createdb shard2
ana@vm:~$ psql -q shard1 -f shard-table.sql
CREATE TABLE
Time: 10.694 ms
CREATE INDEX
Time: 1.669 ms
ana@vm:~$ psql -q shard2 -f shard-table.sql
CREATE TABLE
Time: 8.851 ms
CREATE INDEX
Time: 2.246 ms
ana@vm:~$ psql market -c "ALTER ROLE ana PASSWORD 'shard-lab'"
ALTER ROLE
Time: 10.198 ms
ana@vm:~$ psql market -f coordinator.sql
CREATE EXTENSION
Time: 6.439 ms
CREATE SERVER
Time: 0.900 ms
CREATE SERVER
Time: 0.484 ms
CREATE USER MAPPING
Time: 0.573 ms
CREATE USER MAPPING
Time: 0.465 ms
CREATE TABLE
Time: 1.214 ms
CREATE FOREIGN TABLE
Time: 1.261 ms
CREATE FOREIGN TABLE
Time: 0.851 ms
```

## Carregando pelo coordenador

`sharded_orders` aceita um `INSERT` como qualquer tabela e encaminha cada linha ao shard para onde o
hash do cliente aponta. Copie os dois milhões de pedidos por ela e depois rode `ANALYZE`: o
coordenador não guarda estatística nenhuma sobre linhas que moram em outro lugar até que mandem ele
buscar uma amostra.

```
market=# INSERT INTO sharded_orders SELECT * FROM orders;
INSERT 0 2000000
Time: 26714.135 ms (00:26.714)

market=# ANALYZE sharded_orders;
ANALYZE
Time: 6184.174 ms (00:06.184)
ana@vm:~$ psql shard1 -c 'SELECT count(*) FROM orders'
 count  
--------
 995080
(1 row)

Time: 114.505 ms
ana@vm:~$ psql shard2 -c 'SELECT count(*) FROM orders'
  count  
---------
 1004920
(1 row)

Time: 57.982 ms
```

**26,7 segundos** para gravar dois milhões de linhas por uma conexão, e **995080 e 1004920** nos
dois shards, a divisão igual que a seção 03 prometeu. Em produção ninguém carrega um shard assim;
aqui é o coordenador mostrando que o roteamento funciona.

## Uma consulta que cita a chave, e uma que não cita

O `EXPLAIN (VERBOSE)` mostra, para cada tabela estrangeira, o **Remote SQL**: o comando exato que o
coordenador manda ao shard. Leia para um cliente e para um vendedor:

```
market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT id, placed_at, status FROM sharded_orders WHERE customer_id = 42;
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Foreign Scan on public.sharded_orders_1 sharded_orders
   Output: sharded_orders.id, sharded_orders.placed_at, sharded_orders.status
   Remote SQL: SELECT id, placed_at, status FROM public.orders WHERE ((customer_id = 42))
 Query Identifier: 6590819321667672244
(4 rows)

Time: 5.003 ms

market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT id, placed_at, status FROM sharded_orders WHERE seller_id = 42;
                                          QUERY PLAN                                          
----------------------------------------------------------------------------------------------
 Append
   ->  Foreign Scan on public.sharded_orders_1
         Output: sharded_orders_1.id, sharded_orders_1.placed_at, sharded_orders_1.status
         Remote SQL: SELECT id, placed_at, status FROM public.orders WHERE ((seller_id = 42))
   ->  Foreign Scan on public.sharded_orders_2
         Output: sharded_orders_2.id, sharded_orders_2.placed_at, sharded_orders_2.status
         Remote SQL: SELECT id, placed_at, status FROM public.orders WHERE ((seller_id = 42))
 Query Identifier: 5612305663916782031
(8 rows)

Time: 0.845 ms

market=# SELECT count(*) FROM sharded_orders WHERE customer_id = 42;
 count 
-------
    16
(1 row)

Time: 39.265 ms

market=# SELECT count(*) FROM sharded_orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 261.890 ms
```

Para o cliente 42, o plano tem **um** `Foreign Scan`, em `sharded_orders_1`. O coordenador podou a
outra partição como a aula 18 poda uma local, e o `WHERE` viaja dentro do SQL remoto, então o shard
usa o próprio índice e devolve 16 linhas. Para o vendedor 42 há um `Append` sobre **os dois** shards,
cada um recebendo o mesmo `WHERE seller_id = 42`. Nenhum shard tem índice em `seller_id`, então cada
um lê a tabela inteira, e a resposta levou **262 milissegundos** contra **39**. A aula 1 seção 05
mediu esta mesma contagem em 0,8 ms com um índice num servidor só; aqui é o preço de perguntar por
uma coluna que não é a chave.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três painéis, cada um com o coordenador acima de dois shards. Pedindo o cliente 42, o coordenador manda a consulta só ao shard 1 e voltam 16 linhas em 39 milissegundos. Pedindo o vendedor 42, manda aos dois shards, cada um lê a tabela inteira, e a resposta leva 262 milissegundos. Contando pedidos por status, os dois shards mandam de volta o status de cada linha, dois milhões de valores, e a resposta leva 2961 milissegundos.\"><rect x=\"8\" y=\"8\" width=\"224\" height=\"254\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"120\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">customer_id = 42</text><rect x=\"58\" y=\"44\" width=\"124\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">coordenador</text><rect x=\"22\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"66\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard1</text><path d=\"M100 78 L58 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M58.0 150.0 L57.6 142.8 L64.5 146.8 Z\" fill=\"var(--amber)\"></path><path d=\"M74 150 L112 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M112.0 78.0 L112.7 85.2 L105.7 81.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"130\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"174\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">shard2</text><text x=\"120\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">16 linhas de volta</text><text x=\"120\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--amber)\">39 ms</text><rect x=\"248\" y=\"8\" width=\"224\" height=\"254\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"360\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">seller_id = 42</text><rect x=\"298\" y=\"44\" width=\"124\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">coordenador</text><rect x=\"262\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"306\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard1</text><path d=\"M340 78 L298 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M298.0 150.0 L297.6 142.8 L304.5 146.8 Z\" fill=\"var(--amber)\"></path><path d=\"M314 150 L352 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M352.0 78.0 L352.7 85.2 L345.7 81.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"370\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"414\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard2</text><path d=\"M380 78 L406 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M406.0 150.0 L400.2 145.7 L407.7 143.0 Z\" fill=\"var(--amber)\"></path><path d=\"M422 150 L392 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M392.0 78.0 L398.0 82.0 L390.6 85.1 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">os dois leem tudo</text><text x=\"360\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--amber)\">262 ms</text><rect x=\"488\" y=\"8\" width=\"224\" height=\"254\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"600\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">GROUP BY status</text><rect x=\"538\" y=\"44\" width=\"124\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">coordenador</text><rect x=\"502\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"546\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard1</text><path d=\"M580 78 L538 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M538.0 150.0 L537.6 142.8 L544.5 146.8 Z\" fill=\"var(--amber)\"></path><path d=\"M554 150 L592 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M592.0 78.0 L592.7 85.2 L585.7 81.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"610\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"654\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard2</text><path d=\"M620 78 L646 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M646.0 150.0 L640.2 145.7 L647.7 143.0 Z\" fill=\"var(--amber)\"></path><path d=\"M662 150 L632 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M632.0 78.0 L638.0 82.0 L630.6 85.1 Z\" fill=\"var(--phosphor)\"></path><text x=\"600\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2.000.000 valores de volta</text><text x=\"600\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--amber)\">2961 ms</text></svg>", "caption": "O custo de uma consulta depende de ela citar a chave de shard, e do que os shards precisam mandar de volta."}
```

## Um total sobre todos os shards

A pergunta da tela de operações, quantos pedidos há em cada status, não tem nada a ver com cliente
nenhum:

```
market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT status, count(*) FROM sharded_orders GROUP BY status;
                         QUERY PLAN                         
------------------------------------------------------------
 HashAggregate
   Output: sharded_orders.status, count(*)
   Group Key: sharded_orders.status
   ->  Append
         ->  Foreign Scan on public.sharded_orders_1
               Output: sharded_orders_1.status
               Remote SQL: SELECT status FROM public.orders
         ->  Foreign Scan on public.sharded_orders_2
               Output: sharded_orders_2.status
               Remote SQL: SELECT status FROM public.orders
 Query Identifier: -6308360315943311234
(11 rows)

Time: 5.791 ms

market=# SELECT status, count(*) FROM sharded_orders GROUP BY status;
  status   |  count  
-----------+---------
 pending   |    7319
 shipped   |   43422
 cancelled |   58372
 delivered | 1890887
(4 rows)

Time: 2961.308 ms (00:02.961)

market=# SELECT status, count(*) FROM orders GROUP BY status;
  status   |  count  
-----------+---------
 cancelled |   58372
 delivered | 1890887
 pending   |    7319
 shipped   |   43422
(4 rows)

Time: 564.862 ms
```

O SQL remoto é `SELECT status FROM public.orders`, sem `GROUP BY`: **cada shard manda o status de
cada linha ao coordenador**, dois milhões de valores ao todo, e o coordenador conta. **2961
milissegundos**, contra **565** para a mesma contagem na tabela local. Nada na resposta exigia que
as linhas viajassem; o coordenador simplesmente não conseguia pedir a cada shard os seus quatro
números e somá-los.

Consegue quando o agrupamento é pela chave de shard. A aula 18 apresentou o
`enable_partitionwise_aggregate`; aqui ele decide se a agregação roda nos shards:

```
market=# SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;
 customer_id | count 
-------------+-------
       70802 |    27
      147415 |    27
      152389 |    27
(3 rows)

Time: 5172.718 ms (00:05.173)

market=# SET enable_partitionwise_aggregate = on;
SET
Time: 0.185 ms

market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Limit
   Output: sharded_orders.customer_id, (count(*))
   ->  Sort
         Output: sharded_orders.customer_id, (count(*))
         Sort Key: (count(*)) DESC
         ->  Append
               ->  Foreign Scan
                     Output: sharded_orders.customer_id, (count(*))
                     Relations: Aggregate on (public.sharded_orders_1 sharded_orders)
                     Remote SQL: SELECT customer_id, count(*) FROM public.orders GROUP BY 1
               ->  Foreign Scan
                     Output: sharded_orders_1.customer_id, (count(*))
                     Relations: Aggregate on (public.sharded_orders_2 sharded_orders_1)
                     Remote SQL: SELECT customer_id, count(*) FROM public.orders GROUP BY 1
 Query Identifier: -3135224596345591721
(15 rows)

Time: 2.346 ms

market=# SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;
 customer_id | count 
-------------+-------
      152389 |    27
       70802 |    27
      147415 |    27
(3 rows)

Time: 1972.322 ms (00:01.972)
```

Com a configuração ligada, cada `Foreign Scan` agora é **`Aggregate on`** um shard, e o SQL remoto
leva o `GROUP BY`. Cada shard conta os próprios clientes, e só volta uma linha por cliente: **5173
milissegundos viraram 1972**. Funciona aqui porque cada cliente mora em exatamente um shard, então a
contagem de cada shard para um cliente já é final. Agrupar por `status` não dá para fazer assim,
porque cada shard guarda parte de cada status, e o coordenador no PostgreSQL 16 não manda agregações
parciais para serem combinadas: aquele plano puxou as linhas. **Agrupe pela chave e o trabalho fica
onde os dados estão; agrupe por qualquer outra coisa e os dados vão até o trabalho.**

## O que um servidor só fazia por você, e um shard não faz

Três coisas em que você confiou desde a primeira aula deixam de funcionar, e cada uma falha de um
jeito.

**Uma restrição de unicidade entre shards.** Cada shard garante que os próprios `id`s são únicos.
Nada garante isso entre os dois:

```
market=# CREATE UNIQUE INDEX ON sharded_orders (id);
ERROR:  cannot create unique index on partitioned table "sharded_orders"
DETAIL:  Table "sharded_orders" contains partitions that are foreign tables.
Time: 4.323 ms

market=# INSERT INTO sharded_orders VALUES (1, 3, 7, now(), 'pending', 1990);
INSERT 0 1
Time: 42.124 ms

market=# SELECT tableoid::regclass AS shard, id, customer_id FROM sharded_orders WHERE id = 1;
      shard       | id | customer_id 
------------------+----+-------------
 sharded_orders_1 |  1 |      144681
 sharded_orders_2 |  1 |           3
(2 rows)

Time: 30.329 ms
```

O PostgreSQL recusa o índice de cara. O `INSERT` do pedido 1 para o cliente 3 dá certo, porque foi
encaminhado ao shard que não guarda o pedido 1. **Dois pedidos agora têm o id 1**, um em cada shard,
e todo sistema que liga a um pedido pelo id acabou de ficar ambíguo.

**Uma transação entre shards.** O coordenador abre uma transação em cada shard que toca e, no
`COMMIT`, confirma uma **depois da outra**. Para ver o que isso significa, dê aos dois shards uma
restrição que só é verificada na hora do commit, e faça uma transação quebrá-la de cada lado:

```
ana@vm:~$ for s in shard1 shard2; do psql $s -c 'ALTER TABLE orders ADD CONSTRAINT one_order_per_instant UNIQUE (customer_id, placed_at) DEFERRABLE INITIALLY DEFERRED'; done
ALTER TABLE
Time: 1225.333 ms (00:01.225)
ALTER TABLE
Time: 1388.368 ms (00:01.388)
market=# BEGIN;
BEGIN
Time: 0.237 ms

market=*# INSERT INTO sharded_orders VALUES (2000001, 1, 7, now(), 'pending', 1990);
INSERT 0 1
Time: 45.638 ms

market=*# INSERT INTO sharded_orders SELECT 2000002, customer_id, 7, placed_at, 'pending', 1990 FROM sharded_orders WHERE customer_id = 3 ORDER BY id LIMIT 1;
INSERT 0 1
Time: 30.251 ms

market=*# COMMIT;
ERROR:  duplicate key value violates unique constraint "one_order_per_instant"
DETAIL:  Key (customer_id, placed_at)=(3, 2023-04-06 02:16:12.841473+00) already exists.
CONTEXT:  remote SQL command: COMMIT TRANSACTION
Time: 9.517 ms

market=# BEGIN;
BEGIN
Time: 0.112 ms

market=*# INSERT INTO sharded_orders VALUES (2000003, 3, 7, now(), 'pending', 1990);
INSERT 0 1
Time: 96.317 ms

market=*# INSERT INTO sharded_orders SELECT 2000004, customer_id, 7, placed_at, 'pending', 1990 FROM sharded_orders WHERE customer_id = 1 ORDER BY id LIMIT 1;
INSERT 0 1
Time: 415.017 ms

market=*# COMMIT;
ERROR:  duplicate key value violates unique constraint "one_order_per_instant"
DETAIL:  Key (customer_id, placed_at)=(1, 2024-06-06 22:04:01.455383+00) already exists.
CONTEXT:  remote SQL command: COMMIT TRANSACTION
Time: 1.510 ms

market=# SELECT tableoid::regclass AS shard, id, customer_id FROM sharded_orders WHERE id > 2000000;
      shard       |   id    | customer_id 
------------------+---------+-------------
 sharded_orders_1 | 2000001 |           1
(1 row)

Time: 136.903 ms
```

Os dois `COMMIT`s relatam o mesmo erro, e no coordenador as duas transações parecem ter falhado.
Não são iguais. Na primeira, o shard 1 já tinha confirmado o pedido 2000001 quando o shard 2 recusou
a sua metade, e **o pedido 2000001 continua lá**: meia transação, confirmada, com um erro na tela. Na
segunda, o shard 2 calhou de ser chamado primeiro, recusou, e nada foi gravado. Qual shard é
confirmado primeiro é escolha do coordenador, não sua. Um cluster de banco de verdade fecha essa
brecha com **commit em duas fases**, preparando todos os shards antes de confirmar qualquer um, e o
`postgres_fdw` no PostgreSQL 16 não o usa.

**Um join.** Um join entre duas tabelas divididas pela mesma chave pode rodar dentro de cada shard,
que é o motivo de a seção 03 ter colocalizado `order_lines` com `orders`. Um join por qualquer outra
coisa, ou com uma tabela que mora no coordenador, puxa linhas pelo fio antes, exatamente como fez a
contagem por status. O planejador faz isso sem reclamar e sem avisar; o `EXPLAIN (VERBOSE)` e o seu
SQL remoto são como você descobre.

Mantenha os shards por enquanto: a seção 05 os usa para a conta.
