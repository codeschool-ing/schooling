---
title: Um failover à mão
version: 1
---

Faça um pedido e depois mate o primário como um crash mataria, com `kill -9` no processo principal
dele: sem shutdown, sem checkpoint, nada dito ao standby. O ID do processo é a primeira linha do
`postmaster.pid` no diretório de dados.

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (51, 5100, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1
ana@vm:~$ sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  standby 5434 online postgres /var/lib/postgresql/16/standby /var/log/postgresql/postgresql-16-standby.log
```

`down`. Antes de promover, faça ao standby a segunda pergunta:

```
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)

shop=# SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
 pg_last_wal_receive_lsn | pg_last_wal_replay_lsn 
-------------------------+------------------------
 0/4006608               | 0/4006608
(1 row)

shop=# SELECT max(id) FROM orders;
  max  
-------
 50001
(1 row)

shop=# SELECT status FROM pg_stat_wal_receiver;
 status 
--------
(0 rows)
```

Ainda em recuperação, e as posições recebida e reaplicada são iguais, então nada do que ele tem está
esperando para ser aplicado. O pedido `50001` está lá. Se o primário escreveu alguma coisa depois do
último byte que o standby recebeu, não dá para saber daqui, e esse é o limite honesto de um failover
assíncrono: o standby sabe o que tem, nunca o que perdeu. O `pg_stat_wal_receiver` está vazio, porque
o receiver não tem de quem receber.

Promova-o:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby promote
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 f
(1 row)

shop=# SELECT timeline_id FROM pg_control_checkpoint();
 timeline_id 
-------------
           2
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (52, 5200, now()) RETURNING id;
  id   
-------
 50034
(1 row)

INSERT 0 1
```

Fora da recuperação, aceitando escritas, na **timeline 2**. Uma promoção começa uma nova timeline, como
a recuperação da lição 6 fez, para que o log escrito daqui em diante nunca possa ser confundido com o do
primário antigo. O id do pedido novo é `50034`, não `50002`: uma sequência registra os seus valores no
log adiantados, em lotes de 32, e o standby reaplicou o lote, não o último valor entregue. Os ids pulam
depois de toda promoção, e nada deveria depender de eles serem consecutivos.

A aplicação ainda aponta para a porta 5432, onde não há nada. Mudá-la é o assunto da lição 19; aqui, o
primário novo está na 5434.
