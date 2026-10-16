---
title: Limitando um slot, e o standby que paga por isso
version: 1
---

O `max_slot_wal_keep_size` define quanto log qualquer slot pode segurar. Passado esse limite, o
primário deixa de cumprir a promessa: o slot é marcado como **lost**, e os segmentos são reciclados
como quaisquer outros. O padrão é `-1`, sem limite, que é a configuração que transforma um standby
esquecido numa indisponibilidade. Defina um limite pequeno, para ver o que acontece:

```
shop=# ALTER SYSTEM SET max_slot_wal_keep_size = '32MB';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status, pg_size_pretty(pg_current_wal_lsn() - restart_lsn) AS held FROM pg_replication_slots;
 slot_name | active | wal_status | held 
-----------+--------+------------+------
 standby1  | f      | lost       | 
(1 row)
ana@vm:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
81M	/var/lib/postgresql/16/main/pg_wal
```

`wal_status: lost`, e nada retido. O primário decidiu, em nome do standby, que o disco do primário
importa mais do que o standby, e essa é a decisão certa. O `pg_wal` não encolheu na hora, porque o
PostgreSQL mantém os arquivos de segmento reciclados por perto para reutilizá-los em vez de apagá-los;
o que mudou é que agora nada obriga a guardá-los.

O custo cai sobre o standby. Suba-o de novo:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-standby.log
2026-10-15 22:03:07.381 -03 [8967] LOG:  started streaming WAL from primary at 0/4000000 on timeline 1
2026-10-15 22:03:07.381 -03 [8967] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 000000010000000000000004 has already been removed
2026-10-15 22:03:07.381 -03 [8951] LOG:  waiting for WAL to become available at 0/4002000
```

Ele se conectou, pediu o log a partir de `0/4000000` e ouviu que **`requested WAL segment
000000010000000000000004 has already been removed`**. Vai esperar por esse log para sempre. Um standby
nesse estado é reconstruído a partir de um base backup novo, o que num banco grande leva horas, e
durante esse tempo não há standby.

Duas coisas amenizam isso, e as configurações de verdade usam as duas:

- **Um limite dimensionado para a queda que você quer aguentar.** Se um standby precisa sobreviver a
  uma queda de rede de quatro horas e o primário escreve 5 GB de log por hora, o limite é de pelo menos
  20 GB, e o disco do primário tem espaço para isso.
- **Um arquivo ao lado do slot.** Um standby com um `restore_command` apontando para o repositório da
  lição 5 busca no arquivo os segmentos que o primário não tem mais, e depois volta ao streaming. O
  slot mantém o log recente por perto; o arquivo guarda todo o resto. A lição 13 monta isso.
