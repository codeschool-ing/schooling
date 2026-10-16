---
title: Expandir, preencher, contrair
version: 1
---

Algumas mudanças não têm como ficar baratas. `orders_live.total_cents` é um `integer`, vai estourar
em 2.147.483.647 centavos, e transformá-lo em `bigint` reescreve a tabela, como a penúltima seção
mediu. **O jeito de contornar uma reescrita é nunca pedir uma**: acrescentar a coluna nova ao lado da
antiga, preenchê-la aos poucos, passar a usá-la e só então remover a antiga. Cada passo é curto, e
cada passo deixa uma tabela que a aplicação consegue usar.

Os passos têm nome. **Expandir**: acrescentar o que é novo, ao lado do que existe. **Preencher**:
copiar as linhas antigas para lá em lotes. **Trocar**: fazer da nova a que está em uso. **Contrair**:
remover a antiga. Num sistema real a aplicação também muda entre eles, primeiro para escrever nas
duas colunas e depois para ler só a nova. Aqui um trigger faz esse papel.

## Expandir

Salve isto como `expand.sql`:

```sql
-- expand.sql: a bigint column beside total_cents, kept in step by a trigger.
-- Run it with: psql shop -f expand.sql
SET lock_timeout = '2s';

ALTER TABLE orders_live ADD COLUMN total_cents_new bigint;

CREATE FUNCTION orders_live_sync() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.total_cents_new := NEW.total_cents;
    RETURN NEW;
END $$;

CREATE TRIGGER orders_live_sync
    BEFORE INSERT OR UPDATE ON orders_live
    FOR EACH ROW EXECUTE FUNCTION orders_live_sync();
```

A coluna não tem default, então acrescentá-la é do tipo instantâneo. O trigger copia `total_cents`
para a coluna nova em cada insert e update daqui em diante, então **toda linha escrita a partir deste
ponto já está certa**, e só as linhas antigas precisam do preenchimento.

```
ana@db:~$ psql shop -f expand.sql
SET
ALTER TABLE
CREATE FUNCTION
CREATE TRIGGER
ana@db:~$ psql shop
shop=# UPDATE orders_live SET total_cents = total_cents + 1 WHERE id = 5 RETURNING id, total_cents, total_cents_new;
 id | total_cents | total_cents_new 
----+-------------+-----------------
  5 |         686 |             686
(1 row)

UPDATE 1

shop=# SELECT id, total_cents, total_cents_new FROM orders_live WHERE id IN (5, 6);
 id | total_cents | total_cents_new 
----+-------------+-----------------
  5 |         686 |             686
  6 |         722 |                
(2 rows)

shop=# \q
```

A linha 5 foi escrita e tem os dois valores. A linha 6 ainda não foi tocada, e a coluna nova dela é
NULL.

## Preencher, em lotes

Um único `UPDATE orders_live SET total_cents_new = total_cents` faria o preenchimento num comando, e
seria uma transação só que trava cada linha que muda até o fim, escreve um milhão de versões novas
de uma vez e segura o `VACUUM` o tempo todo (lição 14). **Lotes mantêm cada transação pequena**: uma
faixa de ids, commit, a próxima faixa. Uma procedure consegue fazer commit entre lotes, e uma função
não. Salve isto como `backfill.sql`:

```sql
-- backfill.sql: copy total_cents into total_cents_new, one range of ids at a time.
-- Run it with: psql shop -f backfill.sql, then CALL backfill_total_cents(100000);
CREATE PROCEDURE backfill_total_cents(batch bigint)
LANGUAGE plpgsql AS $$
DECLARE
    next_id bigint := 0;
    last_id bigint;
BEGIN
    SELECT max(id) INTO last_id FROM orders_live;
    WHILE next_id <= last_id LOOP
        UPDATE orders_live SET total_cents_new = total_cents
         WHERE id >= next_id AND id < next_id + batch
           AND total_cents_new IS NULL;
        COMMIT;
        RAISE NOTICE 'ids below % done', next_id + batch;
        next_id := next_id + batch;
    END LOOP;
END $$;
```

As faixas de `id` usam a chave primária que a seção anterior construiu, então cada lote acha as suas
linhas pelo índice em vez de ler a tabela. `total_cents_new IS NULL` pula as linhas que o trigger já
preencheu, e torna seguro rodar a procedure de novo depois de uma interrupção.

```
ana@db:~$ psql shop -f backfill.sql
CREATE PROCEDURE
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# CALL backfill_total_cents(100000);
NOTICE:  ids below 100000 done
NOTICE:  ids below 200000 done
NOTICE:  ids below 300000 done
NOTICE:  ids below 400000 done
NOTICE:  ids below 500000 done
NOTICE:  ids below 600000 done
NOTICE:  ids below 700000 done
NOTICE:  ids below 800000 done
NOTICE:  ids below 900000 done
NOTICE:  ids below 1000000 done
NOTICE:  ids below 1100000 done
CALL
Time: 9609.684 ms (00:09.610)

shop=# SELECT count(*) FROM orders_live WHERE total_cents_new IS DISTINCT FROM total_cents;
 count 
-------
     0
(1 row)

Time: 432.123 ms

shop=# \q
```

Onze lotes de até 100.000 linhas, cada um com o seu commit. **A última consulta é a conferência**:
nenhuma linha em que as duas colunas discordem. `IS DISTINCT FROM` trata dois NULLs como iguais e um
NULL contra um número como diferentes, o que o `<>` não faz.

Numa tabela de produção movimentada você escolheria um lote menor, faria pausas entre os lotes e
acompanharia o atraso de replicação, se houver réplicas. O formato é o mesmo.

## Not null, sem leitura da tabela

A coluna antiga não tem `NOT NULL`, porque o `CREATE TABLE … AS` o descartou, mas um `total_cents` de
verdade teria, e a coluna nova deveria igualar. O truque da seção anterior se aplica:

```
ana@db:~$ psql shop
shop=# ALTER TABLE orders_live ADD CONSTRAINT total_cents_new_not_null CHECK (total_cents_new IS NOT NULL) NOT VALID;
ALTER TABLE

shop=# ALTER TABLE orders_live VALIDATE CONSTRAINT total_cents_new_not_null;
ALTER TABLE

shop=# SET client_min_messages = debug1;
SET

shop=# ALTER TABLE orders_live ALTER COLUMN total_cents_new SET NOT NULL;
DEBUG:  existing constraints on column "orders_live.total_cents_new" are sufficient to prove that it does not contain nulls
ALTER TABLE

shop=# RESET client_min_messages;
RESET

shop=# ALTER TABLE orders_live DROP CONSTRAINT total_cents_new_not_null;
ALTER TABLE

shop=# \q
```

Toda restrição e todo índice da coluna antiga precisam do mesmo tratamento na nova antes da troca.
Aqui a coluna antiga carrega `total_positive`; numa tabela real isso seria mais um `NOT VALID` e um
`VALIDATE` a fazer em `total_cents_new` agora.

## Trocar

A troca renomeia as colunas, para que `total_cents` seja o `bigint` daqui em diante, e remove o
trigger, numa transação curta. Salve-a como `switch.sql`:

```sql
-- switch.sql: make the bigint column the one called total_cents.
-- Run it with: psql shop -f switch.sql
BEGIN;
SET LOCAL lock_timeout = '2s';
ALTER TABLE orders_live RENAME COLUMN total_cents TO total_cents_old;
ALTER TABLE orders_live RENAME COLUMN total_cents_new TO total_cents;
DROP TRIGGER orders_live_sync ON orders_live;
COMMIT;
```

```
ana@db:~$ psql shop -f switch.sql
BEGIN
SET
ALTER TABLE
ALTER TABLE
DROP TRIGGER
COMMIT
```

Renomear uma coluna só edita o catálogo, então a transação segura `ACCESS EXCLUSIVE` por
milissegundos, e o `lock_timeout` a impede de ficar na fila por mais de dois segundos. Se ela
desistir, nada mudou, e você a roda de novo.

Num sistema real a aplicação já teria sido mudada para ler a coluna nova a esta altura, e a
renomeação seria substituída por esse deploy. **A renomeação funciona aqui porque nada mais usa
`orders_live`**; numa tabela compartilhada, renomear uma coluna debaixo de uma aplicação rodando
quebra toda consulta que cita o nome dela.

## Contrair

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# ALTER TABLE orders_live DROP COLUMN total_cents_old;
ALTER TABLE
Time: 7.555 ms

shop=# \d orders_live
                         Table "public.orders_live"
   Column    |           Type           | Collation | Nullable |   Default   
-------------+--------------------------+-----------+----------+-------------
 id          | bigint                   |           | not null | 
 customer_id | bigint                   |           |          | 
 status      | character varying(40)    |           |          | 
 created_at  | timestamp with time zone |           |          | 
 note        | text                     |           |          | 
 source      | text                     |           |          | 
 channel     | text                     |           | not null | 'web'::text
 total_cents | bigint                   |           | not null | 
Indexes:
    "orders_live_pkey" PRIMARY KEY, btree (id)

shop=# \q
```

Remover uma coluna é instantâneo: o PostgreSQL a marca como removida no catálogo e deixa os bytes nas
linhas até a próxima vez que forem reescritas. O check `total_positive` foi junto, já que citava só
aquela coluna. `total_cents` é um `bigint`, todo valor atravessou, e em nenhum momento a tabela ficou
fechada por mais tempo que uma renomeação.

## Arrumar a casa

`orders_live` era a cópia desta lição, e nada adiante a lê:

```
ana@db:~$ psql shop
shop=# DROP TABLE orders_live;
DROP TABLE

shop=# DROP FUNCTION orders_live_sync();
DROP FUNCTION

shop=# DROP PROCEDURE backfill_total_cents(bigint);
DROP PROCEDURE

shop=# \dt
         List of relations
 Schema |   Name    | Type  | Owner 
--------+-----------+-------+-------
 public | customers | table | ana
 public | orders    | table | ana
(2 rows)

shop=# \q
```

O `shop` voltou às duas tabelas que a lição 4 criou, intactas.
