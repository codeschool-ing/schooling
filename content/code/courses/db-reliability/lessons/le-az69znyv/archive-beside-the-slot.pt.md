---
title: O arquivo ao lado do slot
version: 1
---

A lição 11 limitou o seu slot a 32 MB, perdeu-o, e o standby voltou para um primário que já não tinha o
log de que ele precisava: reconstruído a partir de um base backup novo, a menos que um arquivo pudesse
fornecer o log que faltava. Esta máquina tem um arquivo, o repositório do pgBackRest da lição 5,
recebendo cada segmento que o primário enche. Um standby pode ler dele com um `restore_command`, a
configuração que as lições 5 e 6 encontraram em todo servidor que o pgBackRest restaurou, e aí ele busca
no arquivo o que quer que o primário já não tenha.

Defina um no standby à mão, como `postgres`, já que a configuração do standby pertence a ele:

```
ana@vm:~$ sudo -u postgres psql -p 5434 -c "ALTER SYSTEM SET restore_command = 'pgbackrest --stanza=main archive-get %f \"%p\"'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 standby restart
```

Agora repita o acidente da lição 11: pare o standby, limite o slot, e escreva log suficiente para
passar do limite.

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
shop=# ALTER SYSTEM SET max_slot_wal_keep_size = '32MB';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, wal_status FROM pg_replication_slots;
 slot_name | wal_status 
-----------+------------
 standby1  | lost
(1 row)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info | grep wal
        wal archive min/max (16): 000000010000000000000002/000000010000000000000014
            wal start/stop: 000000010000000000000003 / 000000010000000000000003
```

O slot está `lost`, e o arquivo guarda tudo até o segmento `...14`. Suba o standby e leia o log dele:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ sudo grep -E "ERROR: \[|FATAL" /var/log/postgresql/postgresql-16-standby.log | tail -n 3
ERROR: [032]: PostgreSQL working directory '/var/lib/postgresql/16/standby' is not the same as option pg1-path '/var/lib/postgresql/16/main'
2026-10-16 00:49:29.113 -03 [2182] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 000000010000000000000012 has already been removed
ERROR: [032]: PostgreSQL working directory '/var/lib/postgresql/16/standby' is not the same as option pg1-path '/var/lib/postgresql/16/main'
```

Duas recusas, alternadas. O primário removeu o segmento `...12`, como na lição 11. E **o pgBackRest se
recusou a buscá-lo** no arquivo: a configuração dele diz que a stanza `main` fica em
`/var/lib/postgresql/16/main`, e ele confere se o servidor que está pedindo é esse. O standby é outro
diretório de dados. O `restore_command` que a restauração da lição 5 gerou levava `--pg1-path`
exatamente por isso; digitado à mão, é a parte que fica de fora. Acrescente-a. O `restore_command` pode
ser mudado com um reload:

```
ana@vm:~$ sudo -u postgres psql -p 5434 -c "ALTER SYSTEM SET restore_command = 'pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/standby archive-get %f \"%p\"'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 standby reload
ana@vm:~$ sudo grep -E "restored log|FATAL|started streaming" /var/log/postgresql/postgresql-16-standby.log | tail -n 6
2026-10-16 00:49:29.113 -03 [2182] LOG:  started streaming WAL from primary at 0/12000000 on timeline 1
2026-10-16 00:49:29.113 -03 [2182] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 000000010000000000000012 has already been removed
2026-10-16 00:49:29.465 -03 [2120] LOG:  restored log file "000000010000000000000012" from archive
2026-10-16 00:49:29.622 -03 [2120] LOG:  restored log file "000000010000000000000013" from archive
2026-10-16 00:49:29.902 -03 [2120] LOG:  restored log file "000000010000000000000014" from archive
2026-10-16 00:49:30.110 -03 [2220] LOG:  started streaming WAL from primary at 0/15000000 on timeline 1
```

**Três segmentos restaurados do arquivo, e depois streaming de novo**, a partir de onde o arquivo
terminava. Nada foi reconstruído. Pergunte ao primário:

```
shop=# SELECT application_name, state, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind FROM pg_stat_replication;
 application_name |   state   | behind  
------------------+-----------+---------
 standby1         | streaming | 0 bytes
(1 row)

shop=# SELECT slot_name, active, wal_status FROM pg_replication_slots;
 slot_name | active | wal_status 
-----------+--------+------------
 standby1  | t      | unreserved
(1 row)

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status FROM pg_replication_slots;
 slot_name | active | wal_status 
-----------+--------+------------
 standby1  | t      | unreserved
(1 row)
```

Streaming, 0 bytes de atraso, pelo mesmo slot. O status do slot diz `unreserved` em vez de `reserved`, e
continuou assim depois de um checkpoint, então é uma coisa ruim para usar num alerta depois de um
acidente como este; vigie quanto o slot retém, como a lição 11 fez, e o atraso, como esta lição faz.

## Para que serve cada um

O slot e o arquivo fazem o mesmo trabalho a distâncias diferentes. **O slot** mantém o log recente no
`pg_wal`, para que um standby que cai por alguns minutos retome a partir do primário sem mais nada
envolvido. **O arquivo** guarda tudo, em outro lugar, para que um standby que ficou fora por mais tempo
do que o limite do slot ainda consiga voltar. Um standby com os dois sobrevive barato a uma queda
curta e devagar a uma longa, e o limite garante que o slot não consegue encher o disco do primário.
