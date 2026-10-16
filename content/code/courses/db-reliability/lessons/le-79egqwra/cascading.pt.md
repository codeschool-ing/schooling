---
title: Um standby alimentado por um standby
version: 1
---

Monte um segundo standby na porta 5435 exatamente como a lição 11 montou o primeiro, com uma diferença:
o base backup e a conexão dele apontam para o **`standby1` na 5434**, não para o primário. Um standby
pode ser a origem de um base backup, e pode ter um slot próprio:

```
ana@vm:~$ sudo pg_createcluster 16 standby2 --port 5435 > /dev/null && sudo rm -rf /var/lib/postgresql/16/standby2
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5434 user=replicator application_name=standby2' -D /var/lib/postgresql/16/standby2 -R -C -S standby2 -X stream -c fast
ana@vm:~$ sudo pg_ctlcluster 16 standby2 start
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 standby1         | streaming
(1 row)
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 standby2         | streaming
(1 row)
shop=# SELECT status, sender_port FROM pg_stat_wal_receiver;
  status   | sender_port 
-----------+-------------
 streaming |        5434
(1 row)
```

O primário vê um standby, o `standby1`. O `standby1` também vê um, o `standby2`, fazendo streaming a
partir dele. E o receiver do `standby2` informa `sender_port` 5434. O primário envia o seu log uma vez,
aconteça o que acontecer mais adiante; na figura acima, esta é a cópia que atravessa para a outra
região.

O custo é uma corrente: o `standby2` fica atrás do `standby1` o tanto que o `standby1` estiver atrás,
e se o `standby1` parar, o `standby2` para de receber até ser apontado para outro lugar, o que, depois
de uma promoção, é de novo a mudança de `primary_conninfo` da lição 15.
