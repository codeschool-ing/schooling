---
title: Restrições sem bloquear
version: 1
---

Acrescentar uma restrição a uma tabela que já tem linhas significa conferir cada linha, e a forma
simples faz a conferência **enquanto segura `ACCESS EXCLUSIVE`**. O PostgreSQL oferece um jeito de
separar as duas coisas: acrescentar a restrição primeiro, só para linhas novas, num instante; conferir
as linhas antigas depois, sob um lock que deixa leituras e escritas continuarem.

## O jeito simples, para comparar

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# BEGIN;
BEGIN
Time: 0.127 ms

shop=*# ALTER TABLE orders_live ADD CONSTRAINT total_positive CHECK (total_cents > 0);
ALTER TABLE
Time: 159.542 ms

shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
        mode         
---------------------
 AccessExclusiveLock
(1 row)

Time: 3.440 ms

shop=*# ROLLBACK;
ROLLBACK
Time: 0.183 ms

shop=# ALTER TABLE orders_live ADD CONSTRAINT total_positive CHECK (total_cents > 0) NOT VALID;
ALTER TABLE
Time: 9.941 ms

shop=# INSERT INTO orders_live (id, customer_id, status, total_cents, created_at) VALUES (0, 1, 'paid', 0, now());
ERROR:  new row for relation "orders_live" violates check constraint "total_positive"
DETAIL:  Failing row contains (0, 1, paid, 0, 2026-10-10 16:40:54.266161-03, null, null, web).
Time: 1.323 ms

shop=# \q
```

O `ADD CONSTRAINT` simples leu o milhão de linhas em uma fração de segundo, segurando
`AccessExclusiveLock`. Nesta tabela isso é inofensivo; numa tabela cem vezes maior é uma tabela
fechada enquanto a leitura durar, mais a fila da primeira seção.

## `NOT VALID`, depois `VALIDATE`

**`NOT VALID` acrescenta a restrição sem conferir as linhas existentes.** Levou milissegundos, e ela
já vale: o insert de um total zero foi recusado por `total_positive`. O que ela ainda não promete é
nada sobre as linhas que já estavam lá.

**`VALIDATE CONSTRAINT` confere essas linhas depois, sob `SHARE UPDATE EXCLUSIVE`**, um lock que
conflita com outras mudanças de esquema e com o `VACUUM`, e não com `SELECT`, `INSERT`, `UPDATE` ou
`DELETE`. Dois terminais mostram isso: o primeiro valida dentro de uma transação e fica nela,
segurando o lock, e o segundo escreve na tabela enquanto isso:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# BEGIN;
BEGIN
Time: 1.244 ms

shop=*# ALTER TABLE orders_live VALIDATE CONSTRAINT total_positive;
ALTER TABLE
Time: 184.590 ms

shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
           mode           
--------------------------
 ShareUpdateExclusiveLock
(1 row)

Time: 1.663 ms

shop=*# COMMIT;
COMMIT
Time: 1.960 ms
```

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# UPDATE orders_live SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 177.627 ms
```

**O `UPDATE` passou direto** enquanto a transação que validava segurava o lock. O tempo dele é o de
ler um milhão de linhas sem índice para achar o id 2, o que a próxima parte conserta; ele não esperou
pelo `COMMIT` do primeiro terminal. Se uma linha falha na conferência, o `VALIDATE` para com um erro
que cita a restrição, nada se perde, e a restrição continua valendo para linhas novas enquanto você
conserta as antigas.

Uma chave estrangeira funciona do mesmo jeito: `ADD CONSTRAINT … FOREIGN KEY … NOT VALID`, depois
`VALIDATE CONSTRAINT`.

## Uma chave primária, construída ao lado da tabela

`orders_live` não tem chave primária, porque `CREATE TABLE … AS` não copia nenhuma. `ADD PRIMARY KEY`
construiria o índice dela sob `ACCESS EXCLUSIVE`, e numa tabela grande isso leva minutos. O índice
pode ser construído antes, com **`CREATE UNIQUE INDEX CONCURRENTLY`**, que deixa as escritas
continuarem enquanto trabalha; depois `ADD CONSTRAINT … PRIMARY KEY USING INDEX` transforma esse
índice na chave num instante.

Uma chave primária também precisa das suas colunas `NOT NULL`, e `SET NOT NULL` lê a tabela sob o
lock forte, a não ser que **um `CHECK (id IS NOT NULL)` válido já prove a regra**. Então esse check é
acrescentado `NOT VALID` e validado antes:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# CREATE UNIQUE INDEX CONCURRENTLY orders_live_id ON orders_live (id);
CREATE INDEX
Time: 1222.423 ms (00:01.222)

shop=# ALTER TABLE orders_live ADD CONSTRAINT id_not_null CHECK (id IS NOT NULL) NOT VALID;
ALTER TABLE
Time: 201.705 ms

shop=# ALTER TABLE orders_live VALIDATE CONSTRAINT id_not_null;
ALTER TABLE
Time: 159.229 ms

shop=# SET client_min_messages = debug1;
SET
Time: 0.225 ms

shop=# ALTER TABLE orders_live ADD CONSTRAINT orders_live_pkey PRIMARY KEY USING INDEX orders_live_id;
DEBUG:  existing constraints on column "orders_live.id" are sufficient to prove that it does not contain nulls
NOTICE:  ALTER TABLE / ADD CONSTRAINT USING INDEX will rename index "orders_live_id" to "orders_live_pkey"
ALTER TABLE
Time: 5.156 ms

shop=# RESET client_min_messages;
RESET
Time: 0.181 ms

shop=# ALTER TABLE orders_live DROP CONSTRAINT id_not_null;
ALTER TABLE
Time: 5.247 ms

shop=# \d orders_live
                         Table "public.orders_live"
   Column    |           Type           | Collation | Nullable |   Default   
-------------+--------------------------+-----------+----------+-------------
 id          | bigint                   |           | not null | 
 customer_id | bigint                   |           |          | 
 status      | character varying(40)    |           |          | 
 total_cents | integer                  |           |          | 
 created_at  | timestamp with time zone |           |          | 
 note        | text                     |           |          | 
 source      | text                     |           |          | 
 channel     | text                     |           | not null | 'web'::text
Indexes:
    "orders_live_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "total_positive" CHECK (total_cents > 0)

shop=# \q
```

A linha `DEBUG` é a prova sendo usada: **`existing constraints on column "orders_live.id" are
sufficient to prove that it does not contain nulls`**, então nada de leitura. O `NOTICE` diz que o
índice foi renomeado para o nome da restrição. O check temporário é removido no fim, já que a coluna
agora é `NOT NULL`, e o `\d` mostra a chave.

Dois cuidados com o `CONCURRENTLY`. Ele não roda dentro de um bloco de transação, então uma
ferramenta de migração que embrulha cada passo num `BEGIN` precisa ser avisada. E se ele falhar no
meio, por um valor duplicado por exemplo, deixa para trás um índice `INVALID` que precisa ser
removido; a lição 17 mostra como isso aparece e como limpar.
