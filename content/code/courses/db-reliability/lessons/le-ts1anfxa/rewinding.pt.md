---
title: O próximo crash, rebobinado
version: 1
---

Com o `wal_log_hints` ligado nos dois servidores, derrube de novo o primário na 5432 e faça failover
para a 5434, sem esperar por nada:

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (54, 5400, now()) RETURNING id;
  id   
-------
 50035
(1 row)

INSERT 0 1
ana@vm:~$ sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)
ana@vm:~$ sudo pg_ctlcluster 16 standby promote
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (55, 5500, now()) RETURNING id;
  id   
-------
 50068
(1 row)

INSERT 0 1
```

O pedido `50035` no primário antigo, depois o crash, depois o pedido `50068` no novo: a mesma
divergência de antes, o mesmo pulo de 32 nos ids. Desta vez o `pg_rewind` consegue fazer o trabalho
dele. Duas opções importam no Ubuntu: `--config-file`, porque o Ubuntu guarda o `postgresql.conf` em
`/etc/postgresql`, e não no diretório de dados, onde o `pg_rewind` o procuraria, e sem ela o comando
falha no primeiro passo; e `--write-recovery-conf`, que faz do resultado um standby do servidor de
origem.

```
ana@vm:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_rewind --target-pgdata=/var/lib/postgresql/16/main --source-server='port=5434 user=postgres dbname=postgres application_name=main' --config-file=/etc/postgresql/16/main/postgresql.conf --write-recovery-conf
pg_rewind: executing "/usr/lib/postgresql/16/bin/postgres" for target server to complete crash recovery
2026-10-16 01:10:29.950 -03 [10480] LOG:  database system was interrupted; last known up at 2026-10-16 01:10:15 -03
2026-10-16 01:10:29.950 -03 [10480] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-16 01:10:29.951 -03 [10480] LOG:  redo starts at 0/60001B8
2026-10-16 01:10:29.951 -03 [10480] LOG:  invalid record length at 0/6006978: expected at least 24, got 0
2026-10-16 01:10:29.951 -03 [10480] LOG:  redo done at 0/6006950 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
2026-10-16 01:10:29.952 -03 [10480] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-16 01:10:29.953 -03 [10480] LOG:  checkpoint complete: wrote 8 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.000 s, total=0.001 s; sync files=0, longest=0.000 s, average=0.000 s; distance=25 kB, estimate=25 kB; lsn=0/6006978, redo lsn=0/6006978

PostgreSQL stand-alone backend 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
backend> 2026-10-16 01:10:29.956 -03 [10480] LOG:  checkpoint starting: shutdown immediate
2026-10-16 01:10:29.956 -03 [10480] LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.001 s, total=0.001 s; sync files=0, longest=0.000 s, average=0.000 s; distance=0 kB, estimate=23 kB; lsn=0/60069F0, redo lsn=0/60069F0
pg_rewind: servers diverged at WAL location 0/6006978 on timeline 3
pg_rewind: rewinding from last common checkpoint at 0/60001F0 on timeline 3
pg_rewind: Done!
ana@vm:~$ sudo grep -E "primary_conninfo|primary_slot_name" /var/lib/postgresql/16/main/postgresql.auto.conf
primary_conninfo = 'user=replicator passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer host=127.0.0.1 port=5432 application_name=standby1 sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
primary_slot_name = 'standby1'
primary_conninfo = 'user=postgres passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer port=5434 application_name=main sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
ana@vm:~$ sudo pg_ctlcluster 16 main start
ana@vm:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-16 01:10:36.209 -03 [10517] FATAL:  could not start WAL streaming: ERROR:  replication slot "standby1" does not exist
2026-10-16 01:10:36.209 -03 [10501] LOG:  waiting for WAL to become available at 0/6002000
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name | state 
------------------+-------
(0 rows)

shop=# SELECT slot_name, active FROM pg_replication_slots;
 slot_name | active 
-----------+--------
 main      | f
(1 row)
ana@vm:~$ psql -XAt shop -c "SELECT pg_is_in_recovery()"
t
```

As primeiras linhas são uma recuperação de crash: o primário antigo tinha sido morto, e o `pg_rewind`
primeiro o leva a um estado consistente e parado de forma limpa, em modo single-user. Depois ele acha
onde as duas histórias **divergiram**, `0/6006978` na timeline 3, e copia de volta do primário novo
tudo o que mudou depois do último checkpoint que os dois tinham em comum. `Done!`: ele copiou os blocos que
mudaram desde aquele checkpoint, não o diretório inteiro, o que num banco grande é a diferença entre minutos
e horas, e o motivo para ter ligado o `wal_log_hints`.

E aí ele não faz streaming. O `grep` mostra por quê: o `pg_rewind` também copia os arquivos de
configuração da origem, então o primário antigo recebeu o `postgresql.auto.conf` do 5434, com o antigo
`primary_slot_name = 'standby1'` do 5434, e o seu próprio `primary_conninfo` novo acrescentado embaixo.
Não existe slot `standby1` no 5434. O slot que existe lá, `main`, é o que a reconstrução desta lição
criou, e ele está inativo. Aponte o standby para ele:

```
ana@vm:~$ sudo -u postgres psql -c "ALTER SYSTEM SET primary_slot_name = 'main'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main reload
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 main             | streaming
(1 row)

shop=# SELECT slot_name, active FROM pg_replication_slots;
 slot_name | active 
-----------+--------
 main      | t
(1 row)
```

Streaming. Duas lições nesse último passo. **Toda ferramenta que copia um diretório de dados copia a
configuração dele**, e as configurações que nomeiam o papel de um servidor e o parceiro dele são as que
acabam erradas. E um failover não termina quando o primário novo aceita escritas; ele termina quando o
antigo é de novo um standby, fazendo streaming, e essa é a verificação com que todo failover deve
terminar.
