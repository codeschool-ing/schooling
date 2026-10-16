---
title: Um switchover, que não perde nada
version: 1
---

Agora a direção planejada, da 5434 de volta para a 5432. Um shutdown limpo de um primário faz uma
coisa que um crash não faz: antes de parar, ele escreve um **checkpoint de shutdown** final e espera
até que os standbys conectados tenham recebido o log até ele. Então pare o primário de forma limpa, e
compare onde ele parou com o que o standby reaplicou:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ sudo /usr/lib/postgresql/16/bin/pg_controldata /var/lib/postgresql/16/standby | grep -E 'cluster state|Latest checkpoint location'
Database cluster state:               shut down
Latest checkpoint location:           0/6000110
shop=# SELECT pg_last_wal_replay_lsn();
 pg_last_wal_replay_lsn 
------------------------
 0/6000188
(1 row)
ana@vm:~$ sudo pg_ctlcluster 16 main promote
shop=# SELECT pg_create_physical_replication_slot('standby1');
 pg_create_physical_replication_slot 
-------------------------------------
 (standby1,)
(1 row)
ana@vm:~$ sudo -u postgres touch /var/lib/postgresql/16/standby/standby.signal
ana@vm:~$ sudo grep -E "primary_conninfo|primary_slot_name" /var/lib/postgresql/16/standby/postgresql.auto.conf
primary_conninfo = 'user=replicator passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer host=127.0.0.1 port=5432 application_name=standby1 sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
primary_slot_name = 'standby1'
ana@vm:~$ sudo pg_ctlcluster 16 standby start
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 standby1         | streaming
(1 row)
```

O último registro de checkpoint do primário parado começa em `0/6000110`; o standby reaplicou até
`0/6000188`, passando do fim desse registro. **O standby tem cada byte que o primário escreveu**, e é
isso que faz disto um switchover e não um failover: nada se perde, e nada precisa ser rebobinado.

O primário antigo precisa só do que todo standby deste curso teve: um `standby.signal` vazio, e um
`primary_conninfo` com um slot. Ele ainda tem essas duas configurações no `postgresql.auto.conf`,
escritas ali pelo `pg_basebackup -R` lá no começo e deixadas como estavam quando ele foi promovido,
apontando para a porta 5432 com o nome `standby1`. Um servidor promovido as ignora, então elas estavam
esperando. Só faltavam o slot no primário novo, criado antes, e o arquivo de sinal. Ele subiu, e fez
streaming.

A ordem de um switchover, então, que a lição 23 transforma num ensaio:

1. Pare as escritas, ou aceite que as poucas em andamento vão falhar e ser repetidas.
2. Pare o primário **de forma limpa**.
3. Confirme que o standby reaplicou além do último checkpoint do primário.
4. Promova o standby.
5. Faça do primário antigo um standby do novo, e suba-o.
6. Aponte a aplicação para o primário novo.
