---
title: O que o subscriber não recebe
version: 1
---

## Uma coluna de que ninguém lhe falou

A aplicação ganha uma release nova, e a release acrescenta uma coluna. No publisher:

```
shop=# ALTER TABLE orders ADD COLUMN note text;
ALTER TABLE

shop=# INSERT INTO orders (customer_id, total_cents, placed_at, note) VALUES (42, 4200, now(), 'gift wrap');
INSERT 0 1
ana@vm:~$ sudo docker logs pg17 2>&1 | grep ERROR | tail -n 2
2026-10-16 03:56:50.736 UTC [71] ERROR:  logical replication target relation "public.orders" is missing replicated column: "note"
2026-10-16 03:56:50.763 UTC [76] ERROR:  logical replication target relation "public.orders" is missing replicated column: "note"
shop=# SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS held FROM pg_replication_slots;
 slot_name | active |   held    
-----------+--------+-----------
 shop_sub  | f      | 336 bytes
(1 row)
```

O insert deu certo no 16, e o 17 se recusou a aplicá-lo: **a tabela do subscriber não tem a coluna
`note`**, porque `ALTER TABLE` não é uma mudança de linha e a replicação lógica não o transporta. O
worker da subscription para, tenta de novo e para outra vez, e enquanto isso o slot no publisher fica
`active: f` e segura cada byte de log daquela mudança em diante. Os 336 bytes equivalem a alguns
segundos numa máquina ociosa; numa máquina movimentada, isto é o disco cheio da lição 11, chegando por
uma mudança de schema.

A ordem das operações, portanto, é fixa: **acrescente uma coluna primeiro no subscriber**, depois no
publisher. Feito ao contrário, como aqui, basta acrescentá-la no subscriber depois:

```
shop=# ALTER TABLE orders ADD COLUMN note text;
ALTER TABLE
shop=# SELECT id, total_cents, note FROM orders ORDER BY id DESC LIMIT 2;
  id   | total_cents |   note    
-------+-------------+-----------
 50002 |        4200 | gift wrap
 50001 |        4100 | 
(2 rows)
```

As duas linhas chegaram, `gift wrap` inclusive.

## Uma sequência que ficou em 1

Os ids dos pedidos vêm de uma sequência, e o valor de uma sequência não é uma linha:

```
ana@vm:~$ psql -XAt shop -c "SELECT last_value FROM orders_id_seq"
50002
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -XAt shop -c "SELECT last_value FROM orders_id_seq"
1
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (43, 4300, now());
ERROR:  duplicate key value violates unique constraint "orders_pkey"
DETAIL:  Key (id)=(1) already exists.
```

O 16 já distribuiu ids até 50002; a sequência do 17 nunca foi usada, porque cada linha que ele guarda
chegou com o id já preenchido. **O primeiro insert que uma aplicação faz no subscriber colide** com o
pedido 1. No dia em que a aplicação passar para o 17, isso vale para todo insert, até alguém mover as
sequências à mão, e a troca da última seção desta lição faz exatamente isso.
