---
title: O base backup: uma cópia da qual o servidor participa
version: 1
---

O `pg_basebackup` copia um servidor em funcionamento do jeito certo. Ele se conecta ao servidor
pelo protocolo de replicação, avisa que um backup está começando, recebe cada arquivo e recebe
**o write-ahead log escrito enquanto a cópia rodava**, para que a cópia possa ser consertada até
virar um único momento consistente. Faça um num diretório chamado `base`:

```
ana@vm:~$ pg_basebackup -D base -X stream -c fast -v
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 0/2C000028 on timeline 1
pg_basebackup: starting background WAL receiver
pg_basebackup: created temporary replication slot "pg_basebackup_4189"
pg_basebackup: write-ahead log end point: 0/2C000100
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: syncing data to disk ...
pg_basebackup: renaming backup_manifest.tmp to backup_manifest
pg_basebackup: base backup completed
ana@vm:~$ ls base
PG_VERSION
backup_label
backup_manifest
base
global
pg_commit_ts
pg_dynshmem
pg_logical
pg_multixact
pg_notify
pg_replslot
pg_serial
pg_snapshots
pg_stat
pg_stat_tmp
pg_subtrans
pg_tblspc
pg_twophase
pg_wal
pg_xact
postgresql.auto.conf
```

Cada linha é um passo da conversa:

1. **Um checkpoint.** O servidor grava em disco toda página alterada, para que a recuperação da
   cópia possa partir de um ponto conhecido. O `-c fast` pede isso na hora; sem ele, o servidor faz
   no seu ritmo e o backup espera. Num servidor ocupado, o rápido provoca uma rajada de escritas, e
   é por isso que ele não é o padrão.
2. **O ponto de início**, `0/2C000028`, uma posição no write-ahead log. Tudo o que pode faltar à
   cópia foi escrito depois dele.
3. **Um receptor de WAL em segundo plano**, por um slot de replicação temporário. O `-X stream` faz
   o backup coletar o log por uma segunda conexão enquanto os arquivos são copiados, e o slot
   impede o servidor de reciclar qualquer parte dele antes de ela chegar.
4. **O ponto final**, `0/2C000100`. Uma cópia consertada com o log do ponto de início até o ponto
   final é consistente; uma consertada com menos não é.
5. **O manifesto**, uma lista de cada arquivo com o tamanho e o checksum, usado pela seção depois
   desta.

O resultado parece um diretório de dados, porque é um. Dois arquivos fazem dele um backup em vez do
diretório de um servidor: o `backup_manifest`, e este aqui:

```
ana@vm:~$ cat base/backup_label
START WAL LOCATION: 0/2C000028 (file 00000001000000000000002C)
CHECKPOINT LOCATION: 0/2C000060
BACKUP METHOD: streamed
BACKUP FROM: primary
START TIME: 2026-10-10 04:14:52 -03
LABEL: pg_basebackup base backup
START TIMELINE: 1
```

O `backup_label` é o bilhete que a cópia carrega para quem for subi-la. A primeira linha diz **onde
a recuperação tem que começar**, e o segmento de WAL em que essa posição fica. Um servidor que
encontra esse arquivo no diretório de dados sabe que é um backup e reaplica o log a partir desse
ponto, em vez de confiar no que o arquivo de controle diz, que é justamente o que o `cp` da seção
anterior não conseguia fazer. O `START TIME` é o momento em que a cópia começou, e o `-X stream`
pôs o log necessário para chegar à consistência dentro de `base/pg_wal`, então esse diretório é um
backup completo sozinho.

A lição 4 tira o `-X stream` e guarda o log em outro lugar, continuamente, que é o que transforma
um base backup de um momento em qualquer momento. Até lá, um base backup com o próprio log é o
equivalente físico do dump da lição 2: um instante consistente, restaurável sozinho.
