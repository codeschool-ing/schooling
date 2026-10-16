---
title: Trazendo o primário antigo de volta como standby
version: 1
---

O 5432 tem um pedido que o 5434 nunca vai ter, e um log que seguiu o próprio caminho depois do ponto
que o standby recebeu por último. Para seguir o primário novo, ele tem que abrir mão disso. O
**`pg_rewind`** faz isso copiando de volta só os blocos que mudaram desde que os dois divergiram, o que
é muito menos do que um base backup novo. Pare o primário antigo e tente:

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_rewind --target-pgdata=/var/lib/postgresql/16/main --source-server='port=5434 user=postgres dbname=postgres'
pg_rewind: error: target server needs to use either data checksums or "wal_log_hints = on"
```

Ele se recusa. Para achar os blocos que mudaram, o `pg_rewind` lê o log do primário antigo, e o log
nomeia um bloco toda vez que ele muda, com uma exceção: marcar os bits que o PostgreSQL guarda numa
linha para lembrar se a transação que a escreveu fez commit, os **hint bits**, não escreve log por
padrão. Tanto o `wal_log_hints` quanto os data checksums fazem essas mudanças irem para o log também, e
o Ubuntu cria clusters sem nenhum dos dois. Um deles tem que estar ativo **antes** da falha: o `wal_log_hints`
exige um restart, os checksums exigem o servidor parado e o `pg_checksums` rodado sobre ele, e nenhum
dos dois ajuda depois do fato.

Então desta vez o primário antigo é reconstruído do zero, como standby do novo, do jeito que a lição 11
construiu o primeiro: um base backup com o próprio nome e o próprio slot na 5434.

```
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/main
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5434 user=replicator application_name=main' -D /var/lib/postgresql/16/main -R -C -S main -X stream -c fast
ana@vm:~$ sudo pg_ctlcluster 16 main start
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

O `main` agora é um standby, fazendo streaming da 5434, e o pedido do cliente 53 se foi junto com o
diretório de dados antigo. Num banco de terabytes, é aqui que vão as horas de um failover.

## Preparando a próxima vez

Ligue o `wal_log_hints`, nos **dois** servidores, já que qualquer um deles pode ser o primário antigo
da próxima vez:

```
shop=# ALTER SYSTEM SET wal_log_hints = on;
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 standby restart
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql -XAt shop -c "SHOW wal_log_hints"
off
shop=# ALTER SYSTEM SET wal_log_hints = on;
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql -XAt shop -c "SHOW wal_log_hints"
on
```

O primeiro `SHOW`, no 5432, ainda diz `off`: o `ALTER SYSTEM` rodou no 5434 e escreveu o
`postgresql.auto.conf` do próprio 5434, um arquivo que a replicação física não transporta. **As
configurações de cada servidor são só dele**, e um standby construído antes de uma mudança, ou um
servidor reconstruído depois de uma, tem que recebê-la de novo. Configurado no próprio 5432 e
reiniciado, ele diz `on`.
