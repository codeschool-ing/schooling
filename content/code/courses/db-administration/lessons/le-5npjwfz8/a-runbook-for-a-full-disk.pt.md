---
title: Um runbook para um disco enchendo
version: 1
---

Aqui está um runbook completo para um sintoma, no formato da seção anterior. Ele é um arquivo
Markdown, porque Markdown se lê como texto puro num terminal quando nada o renderiza, e pertence ao
mesmo repositório da configuração de que trata — o `shop-db` da lição 23, em
`runbooks/disk-filling.md`. Todo comando nele ocupa uma linha, então pode ser copiado inteiro numa
hora em que ninguém deveria estar redigitando SQL. Ele está em inglês, como os comandos e as
mensagens que cita; o texto abaixo dele explica cada parte.

```
# Runbook: the disk under PostgreSQL is filling

Applies to: db (PostgreSQL 16 on Ubuntu 24.04, cluster 16/main)
Owner: Ana            Last rehearsed: 2026-10-10

## Symptom
The alert "disk above 85% on /var/lib/postgresql", or clients reporting
errors that contain "No space left on device".

## Impact
Reads and writes still work. At 100% the server can no longer write WAL or
extend a table: writes fail, and the server may stop (lesson 9).
Above 95%, move fast and escalate early.

## Check (read only; write a note after each)
1. How full:            df -h /var/lib/postgresql
2. Where the space is:  sudo du -h -d1 /var/lib/postgresql/16/main | sort -h | tail -4
3. If pg_wal is large, a slot may be holding it:
   psql -c "SELECT slot_name, slot_type, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots;"
4. What the server says: sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log
5. If base is large, what grew:
   psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"
   psql -d DB -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC LIMIT 3;"

## Act
A. A slot with active = f retaining WAL (check 3):
   ask the slot's owner whether a replica still uses it. If none does:
   psql -c "SELECT pg_drop_replication_slot('NAME');"
   psql -c "CHECKPOINT;"
B. A table that grew (check 5): delete nothing. Escalate to its owner.
C. Never delete files from pg_wal by hand. The server needs every one it kept.

## Verify
After A: the slot is gone from check 3, and df stops climbing.
pg_wal does NOT shrink at once: the checkpoint recycles old WAL files for
reuse, up to max_wal_size (1GB here). Space comes back only for WAL beyond it.

## Roll back
A cannot be undone. A replica that was using the slot may have to be rebuilt
(db-reliability lessons 11 to 14). This is why A asks first.

## Escalate
Above 95%, or still climbing 30 minutes after an act: call the second line.
Hand over: the incident log, and the output of checks 1 to 3.
```

Duas coisas nele foram aprendidas do jeito difícil, e não planejadas. **O aviso no Verify está ali
porque o primeiro ensaio esperava que o `pg_wal` encolhesse**, e ele não encolheu; a execução abaixo
mostra por quê. E **a ação C é uma frase de que ninguém precisa de dia.** Apagar arquivos do
`pg_wal` libera espaço na hora e deixa um cluster que não consegue se recuperar da próxima queda.
É também o comando mais tentador que alguém poderia digitar naquela hora, e por isso a página o
proíbe sem rodeios.

## Algo para encontrar

Para rodar o runbook no seu servidor, dê a ele um problema primeiro: um slot de replicação que
nenhuma réplica lê, que guarda cada byte de WAL escrito depois que ele foi criado, e uma tabela
carregada esta noite no banco `ana`:

```sh
psql -c "SELECT pg_create_physical_replication_slot('standby1', true);"
psql -c "CREATE TABLE filler AS SELECT g AS id, repeat('x', 500) AS pad FROM generate_series(1, 600000) AS g;"
```

O `true` faz o slot começar a reter WAL imediatamente, em vez de esperar uma réplica conectar.
Depois siga a página, conferência por conferência.

## Rodando

**Check 1**, quão cheio:

```
ana@db:~$ df -h /var/lib/postgresql
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   35G  4.4G  89% /
```

Na sua máquina virtual este é o disco da própria máquina, e o número é o que o alerta vigia. Na
máquina de gravação o disco do servidor é o do computador de gravação, dividido com outros
trabalhos, então os números dele não dizem nada sobre o PostgreSQL e mudam de uma execução para
outra. Não está em 100%: as escritas ainda funcionam, e há tempo para olhar.

**Check 2**, onde está o espaço:

```
ana@db:~$ sudo du -h -d1 /var/lib/postgresql/16/main | sort -h | tail -4
600K	/var/lib/postgresql/16/main/global
467M	/var/lib/postgresql/16/main/base
657M	/var/lib/postgresql/16/main/pg_wal
1.1G	/var/lib/postgresql/16/main
```

`base` são as tabelas e os índices, e o `pg_wal` é maior que todos eles juntos. Num servidor
tranquilo o registro de mudanças é uma fração dos dados que ele descreve, então este é o achado que
manda você para o check 3.

**Check 3**, os slots:

```
ana@db:~$ psql -c "SELECT slot_name, slot_type, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots;"
 slot_name | slot_type | active | wal_status | retained 
-----------+-----------+--------+------------+----------
 standby1  | physical  | f      | reserved   | 649 MB
(1 row)
```

**`active = f` com WAL retido é a causa clássica.** O `restart_lsn` é o ponto mais antigo do WAL de
que o slot ainda precisa, e o `pg_wal_lsn_diff` transforma a distância dali até agora em bytes: 649
MB que o servidor tem de guardar para uma réplica que não está conectada. O `wal_status` diz
`reserved`, o que quer dizer que o WAL retido ainda cabe abaixo do `max_wal_size`; ele vira
`extended` depois disso, e o disco continua enchendo enquanto o slot existir. Este é o momento em
que a ação A manda perguntar, e a nota a escrever é a quem você perguntou.

**Check 4**, o que o servidor diz:

```
ana@db:~$ sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:34:08.725 -03 [98] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 04:34:08.728 -03 [104] LOG:  database system was shut down at 2026-10-10 03:18:41 -03
2026-10-10 04:34:08.733 -03 [98] LOG:  database system is ready to accept connections
2026-10-10 04:34:28.499 -03 [102] LOG:  checkpoints are occurring too frequently (20 seconds apart)
2026-10-10 04:34:28.499 -03 [102] HINT:  Consider increasing the configuration parameter "max_wal_size".
2026-10-10 04:34:28.499 -03 [102] LOG:  checkpoint starting: wal
```

Nenhum `ERROR`, nenhum `PANIC`, nenhum `No space left on device`: nada falhou ainda. O que há é um
checkpoint disparado pela quantidade de WAL escrita, e não pelo relógio (`starting: wal`, lição 8),
e o servidor reclamando que isso está acontecendo com frequência demais. As duas coisas dizem que
muito WAL foi escrito há pouco, o que bate com o check 2.

**Check 5**, o que cresceu em `base`:

```
ana@db:~$ psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"
  datname  |  size   
-----------+---------
 ana       | 320 MB
 shop      | 125 MB
 postgres  | 7503 kB
 template1 | 7503 kB
 template0 | 7345 kB
(5 rows)

ana@db:~$ psql -d ana -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC LIMIT 3;"
  relname   |  size   
------------+---------
 filler     | 313 MB
 pg_proc    | 1216 kB
 pg_rewrite | 728 kB
(3 rows)
```

O banco `ana` é maior que o `shop`, o que ninguém esperava, e uma tabela é quase tudo dele. O
`pg_total_relation_size` conta a tabela com os índices e o TOAST, que é o que ocupa o disco. **A
ação B diz para não apagar nada**: uma tabela que você não criou pertence a alguém, e o trabalho do
runbook é achar essa pessoa e passar o assunto adiante. O `DB` no segundo comando do runbook é
trocado pelo banco que o primeiro apontou.

## Agir, verificar

O dono do `standby1` disse que nenhuma réplica o usa mais, então, a ação A:

```
ana@db:~$ psql -c "SELECT pg_drop_replication_slot('standby1');"
 pg_drop_replication_slot 
--------------------------
 
(1 row)

ana@db:~$ psql -c "CHECKPOINT;"
CHECKPOINT
```

E a verificação:

```
ana@db:~$ psql -c "SELECT count(*) AS slots FROM pg_replication_slots;"
 slots 
-------
     0
(1 row)

ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
673M	/var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:34:33.546 -03 [102] LOG:  checkpoint complete: wrote 1086 buffers (6.6%); 0 WAL file(s) added, 0 removed, 40 recycled; write=0.011 s, sync=0.009 s, total=0.086 s; sync files=5, longest=0.007 s, average=0.002 s; distance=128710 kB, estimate=495458 kB; lsn=0/29E45150, redo lsn=0/29E45118
```

O slot sumiu, e **o `pg_wal` não está menor.** A própria linha do checkpoint diz por quê: `0
removed, 40 recycled`. Um arquivo de WAL de que o servidor não precisa mais é renomeado e guardado
para escritas futuras, enquanto o `pg_wal` ficar abaixo do `max_wal_size`, porque reaproveitar um
arquivo é mais barato que criar um. Os 649 MB que o slot retinha cabiam todos abaixo do limite de 1
GB, então tudo foi reciclado. O que mudou é que nada mais está retendo WAL, então o `pg_wal` para de
crescer. Numa noite de verdade o slot teria retido bem mais que o `max_wal_size`, e tudo o que
passasse disso teria sido removido neste checkpoint. Um runbook cujo verify dissesse "o pg_wal
encolhe" mandaria você procurar um segundo problema que não existe, e é por isso que o aviso está
na página.

## Desfazendo

O slot já foi embora. Remova a tabela que você carregou, e o seu servidor fica como a lição 5 o
deixou:

```
ana@db:~$ psql -c "DROP TABLE filler;"
DROP TABLE
```
