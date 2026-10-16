---
title: Vendo o streaming acontecer
version: 1
---

Suba o standby, e a máquina passa a ter dois servidores rodando, um seguindo o outro:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  standby 5434 online postgres /var/lib/postgresql/16/standby /var/log/postgresql/postgresql-16-standby.log
```

O primário enxerga o standby como uma conexão, em `pg_stat_replication`. O `\x` pede ao `psql` uma
coluna por linha, o que combina com uma view larga assim:

```
shop=# \x
Expanded display is on.

shop=# SELECT application_name, client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, sync_state FROM pg_stat_replication;
-[ RECORD 1 ]----+-----------
application_name | 16/standby
client_addr      | 127.0.0.1
state            | streaming
sent_lsn         | 0/4000000
write_lsn        | 0/4000000
flush_lsn        | 0/4000000
replay_lsn       | 0/4000000
sync_state       | async
```

**`state: streaming`**, e quatro posições no log que dizem até onde chegou cada passo da seção
anterior: enviado pelo primário, escrito, com flush e reaplicado pelo standby. Aqui todas são iguais,
`0/4000000`, porque nada foi escrito desde que o standby se conectou. Quando elas diferem, as
diferenças são o atraso de replicação, e a lição 13 as mede. `sync_state: async` diz que o primário
não espera por este standby antes de confirmar um commit; a lição 12 muda isso.

O standby tem a sua própria visão da mesma conexão:

```
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)

shop=# SELECT status, sender_host, sender_port, slot_name FROM pg_stat_wal_receiver;
  status   | sender_host | sender_port | slot_name 
-----------+-------------+-------------+-----------
 streaming | 127.0.0.1   |        5432 | standby1
(1 row)
```

`pg_is_in_recovery()` é verdadeiro, porque um standby é um servidor permanentemente em recuperação, e
o WAL receiver dele está fazendo streaming de 127.0.0.1:5432 pelo slot `standby1`.

## Leituras, e a escrita que ele recusa

Insira um pedido no primário e leia-o no standby um segundo depois:

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (11, 4200, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1
shop=# SELECT id, total_cents FROM orders ORDER BY id DESC LIMIT 1;
  id   | total_cents 
-------+-------------
 50001 |        4200
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (12, 100, now());
ERROR:  cannot execute INSERT in a read-only transaction
```

O pedido estava lá, com seu id e seu total, num servidor em que ninguém escreveu. E o mesmo insert
mandado ao standby foi recusado: **`cannot execute INSERT in a read-only transaction`**. Uma aplicação
que manda leituras para um standby tem que mandar toda escrita para o primário, e a lição 19 trata de
como ela descobre qual servidor é esse.
