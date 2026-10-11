---
title: Um WAL cheio
version: 1
---

O sistema de arquivos do log, de duas seções atrás, tem 116 MB livres, e o `max_wal_size` deixa o
log crescer até cerca de um gigabyte antes que um checkpoint o recicle. Nada impede que essa
diferença seja alcançada. Uma cópia de `orders` e alguns inserts nela escrevem o log rápido o
bastante:

```
shop=# CREATE TABLE walfill AS SELECT * FROM orders;
SELECT 1000000
```

```
ana@db:~$ for i in 1 2 3 4 5 6; do psql shop -c "INSERT INTO walfill SELECT * FROM orders" || break; done
INSERT 0 1000000
INSERT 0 1000000
INSERT 0 1000000
PANIC:  could not write to file "pg_wal/xlogtemp.449": No space left on device
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
connection to server was lost
```

**`PANIC` é a severidade acima de `FATAL`, e ela encerra o servidor inteiro**, não um comando ou uma
sessão. Uma transação que não consegue escrever o seu registro de log não pode se tornar durável, e o
PostgreSQL não segue em frente fingindo o contrário. Todas as conexões com o servidor caíram, não só
esta.

## O servidor não volta sozinho

```
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@db:~$ df -h /srv/wal
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      488M  449M  3.4M 100% /srv/wal
ana@db:~$ sudo grep -E "PANIC|terminated by signal|redo done|FATAL|shut down" /var/log/postgresql/postgresql-16-main.log | tail -n 7
2026-10-10 16:54:42.244 -03 [339] LOG:  database system was shut down at 2026-10-10 16:54:41 -03
2026-10-10 16:54:57.767 -03 [449] ana@shop PANIC:  could not write to file "pg_wal/xlogtemp.449": No space left on device
2026-10-10 16:54:57.785 -03 [336] LOG:  server process (PID 449) was terminated by signal 6: Aborted
2026-10-10 16:54:58.536 -03 [451] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-10 16:55:01.301 -03 [451] LOG:  redo done at 0/33FFFF78 system usage: CPU: user: 1.93 s, system: 0.24 s, elapsed: 2.75 s
2026-10-10 16:55:01.339 -03 [451] FATAL:  could not write to file "pg_wal/xlogtemp.451": No space left on device
2026-10-10 16:55:01.426 -03 [336] LOG:  database system is shut down
```

Leia o log em ordem. O backend que encontrou o disco cheio entrou em pânico e foi morto. O
postmaster fez o que a lição 8 mostrou que ele faz depois de uma queda: jogou fora todos os
processos e começou a recuperação. A recuperação repetiu o log até o fim, `redo done`, e então
precisou **escrever** um arquivo de log novo para terminar, no mesmo sistema de arquivos cheio. Ela
falhou, e o postmaster desistiu e desligou. Iniciá-lo de novo à mão termina do mesmo jeito, pelo
mesmo motivo.

Os 3,4 MB que o `df` mostra livres são de novo a reserva, que o `postgres` não pode usar. Duas
coisas tentam aqui, e as duas estão erradas:

- **Apagar arquivos do `pg_wal`.** Eles parecem logs antigos e são a única cópia de mudanças que
  ainda não estão nos arquivos de dados; remover um perde dados confirmados ou torna o cluster
  impossível de recuperar. O `pg_resetwal` é o programa que joga o log fora de propósito, é um
  último recurso depois que todo o resto falhou, e pode deixar o banco inconsistente.
- **Baixar o `max_wal_size` para abrir espaço.** O servidor tem de estar rodando para reciclar
  qualquer coisa, e ele não consegue iniciar.

## Dando espaço

A saída é espaço. Numa máquina virtual você aumentaria o disco virtual no hipervisor e depois o
sistema de arquivos; aqui o "disco" é um arquivo, então os mesmos dois passos são `truncate` e
`resize2fs`. O ext4 consegue crescer montado, mas nada está usando este agora, então desmonte-o e
verifique-o primeiro:

```
ana@db:~$ sudo systemctl stop postgresql@16-main
ana@db:~$ sudo umount /srv/wal
ana@db:~$ sudo truncate -s 2G /srv/wal.img
ana@db:~$ sudo e2fsck -f -p /srv/wal.img
/srv/wal.img: 41/32768 files (7.3% non-contiguous), 121043/131072 blocks
ana@db:~$ sudo resize2fs /srv/wal.img
resize2fs 1.47.0 (5-Feb-2023)
Resizing the filesystem on /srv/wal.img to 524288 (4k) blocks.
The filesystem on /srv/wal.img is now 524288 (4k) blocks long.

ana@db:~$ sudo mount -o loop /srv/wal.img /srv/wal
ana@db:~$ df -h /srv/wal
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      2.0G  449M  1.4G  24% /srv/wal
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:55:05.448 -03 [533] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-10 16:55:05.449 -03 [533] LOG:  redo starts at 0/18F7F9E8
2026-10-10 16:55:08.001 -03 [533] LOG:  redo done at 0/33FFFF78 system usage: CPU: user: 1.59 s, system: 0.21 s, elapsed: 2.55 s
2026-10-10 16:55:08.069 -03 [531] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-10 16:55:08.618 -03 [531] LOG:  checkpoint complete: wrote 16386 buffers (100.0%); 0 WAL file(s) added, 0 removed, 28 recycled; write=0.087 s, sync=0.374 s, total=0.553 s; sync files=27, longest=0.218 s, average=0.014 s; distance=442881 kB, estimate=442881 kB; lsn=0/34000058, redo lsn=0/34000058
2026-10-10 16:55:08.643 -03 [530] LOG:  database system is ready to accept connections
ana@db:~$ psql shop -c "SELECT count(*) FROM walfill"
  count  
---------
 4000000
(1 row)
```

O cluster já estava parado; o `stop` faz o systemd concordar antes que o sistema de arquivos saia.
Com espaço para escrever, a recuperação rodou exatamente como antes e então terminou: um
**checkpoint de fim de recuperação**, que reciclou 28 arquivos de log, e `ready to accept
connections`.

**Quatro milhões de linhas: a cópia e os três inserts que confirmaram.** O quarto insert estava
rodando quando o servidor entrou em pânico, nunca confirmou e não está lá. Nada que foi informado
como confirmado se perdeu, que é o WAL cumprindo a promessa que a lição 7 descreveu, até nisso.

## Por que encheu, e o que vigia isso

Este disco encheu porque era menor que o `max_wal_size`, de propósito. Num servidor de verdade, as
causas de costume são um slot de replicação que ninguém está lendo, que a lição 7 nomeou, e um
comando de arquivamento que falha sem parar, que o `db-reliability` trata junto com o arquivamento;
nos dois casos, o log é guardado porque alguma coisa ainda precisa dele, e cresce até o disco
acabar. **Vigie o espaço livre do sistema de arquivos do log e dispare um alerta bem antes de ele
encher**, e quando ele encher mesmo assim, a lição 24 escreve o runbook para essa noite.

## Pondo tudo de volta

O resto do curso espera o `pg_wal` dentro do diretório de dados e nenhum sistema de arquivos extra:

```
shop=# DROP TABLE walfill;
DROP TABLE

shop=# DROP TABLE filler;
DROP TABLE

shop=# DROP TABLESPACE small;
DROP TABLESPACE
```

```
ana@db:~$ sudo systemctl stop postgresql@16-main
ana@db:~$ sudo rm /var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo mv /srv/wal/pg_wal /var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo umount /srv/wal /srv/small
ana@db:~$ sudo rm /srv/wal.img /srv/small.img && sudo rmdir /srv/wal /srv/small
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

O `rm` no `pg_wal` removeu só o link, e o diretório para onde ele apontava voltou para onde estava.
