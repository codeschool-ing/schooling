---
title: Quanto o pg_wal cresce, e o que o mantém grande
version: 1
---

A lição 4 encontrou o `pg_wal` maior que os dados e prometeu dizer o que o limita. Duas imagens
erradas são comuns: que o diretório cresce para sempre até alguém limpar, e que ele é uma cota fixa
que o servidor nunca passa. **O log é aparado a cada checkpoint, até um tamanho que as configurações
guiam mas não travam.**

## Reciclado, não apagado

Assim que um checkpoint termina, todo segmento mais antigo que o ponto de onde ele começou deixa de
ser necessário para a recuperação de queda. O servidor então cuida de cada um: ou o **recicla**,
renomeando o arquivo para um nome que o log vai alcançar mais tarde, para ser sobrescrito em vez de
criado, ou o **remove**. As configurações que guiam essa escolha:

```
shop=# SELECT name, setting, unit FROM pg_settings
shop-#  WHERE name IN ('max_wal_size', 'min_wal_size', 'wal_keep_size',
shop(#                 'max_slot_wal_keep_size', 'wal_segment_size');
          name          | setting  | unit 
------------------------+----------+------
 max_slot_wal_keep_size | -1       | MB
 max_wal_size           | 1024     | MB
 min_wal_size           | 80       | MB
 wal_keep_size          | 0        | MB
 wal_segment_size       | 16777216 | B
(5 rows)
```

| configuração | aqui | o que decide |
| --- | --- | --- |
| `max_wal_size` | 1 GB | quanto o log pode crescer antes de o servidor forçar um checkpoint para baixá-lo. Um alvo, não um muro: uma rajada de escritas, ou uma das coisas abaixo, leva o `pg_wal` além dele, e a lição 8 mostra o que acontece quando ele é pequeno demais |
| `min_wal_size` | 80 MB | o mínimo que o servidor guarda para reciclar, para que uma hora calma não apague arquivos que uma hora cheia vai ter de criar de novo |
| `wal_keep_size` | 0 | log extra guardado para réplicas que possam ficar para trás; zero não guarda nada |
| `max_slot_wal_keep_size` | -1 | quanto os slots de replicação podem segurar, e -1 quer dizer sem limite. O resto desta seção é sobre esse |

As duas atualizações grandes da seção anterior deixaram o diretório maior do que a lição 4 o
encontrou. Meça, peça um checkpoint, leia a linha que o checkpoint registrou e meça de novo:

```
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
417M	/var/lib/postgresql/16/main/pg_wal
shop=# CHECKPOINT;
CHECKPOINT
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:48.342 -03 [102] LOG:  checkpoint complete: wrote 7 buffers (0.0%); 0 WAL file(s) added, 0 removed, 25 recycled; write=0.453 s, sync=0.305 s, total=1.220 s; sync files=8, longest=0.203 s, average=0.039 s; distance=414064 kB, estimate=414064 kB; lsn=0/3489B300, redo lsn=0/3489B2C8
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
417M	/var/lib/postgresql/16/main/pg_wal
```

**`25 recycled`, e o diretório está exatamente do mesmo tamanho.** Vinte e cinco segmentos antigos
foram renomeados e esperam para ser sobrescritos; nenhum foi removido, porque o servidor acabou de
ver que precisa de mais ou menos isso entre checkpoints — é o `estimate` perto do fim da linha. Se
as próximas horas forem calmas, os checkpoints seguintes removem as sobras até perto do
`min_wal_size`. Então um `pg_wal` grande depois de uma rajada é normal, e é limitado pela rajada. A
lição 8 lê o resto dessa linha do log.

## O slot que ninguém lê

Uma réplica que recebe o log por streaming pode pedir ao primário que guarde todo segmento que ela
ainda não recebeu, para que uma réplica desligada durante a noite consiga se atualizar de manhã.
Essa promessa é um **slot de replicação**, e ele segura o log a partir da sua posição **esteja ou
não alguém conectado a ele**. Crie um à mão, sem nada por trás, do jeito que uma réplica removida
depois deixa um para trás:

```
shop=# SELECT pg_create_physical_replication_slot('forgotten', true);
 pg_create_physical_replication_slot 
-------------------------------------
 (forgotten,0/3489B2C8)
(1 row)

shop=# CREATE TABLE orders_copy AS SELECT * FROM orders;
SELECT 1000000

shop=# UPDATE orders_copy SET total_cents = total_cents + 1;
UPDATE 1000000

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status,
shop-#        pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS held
shop-#   FROM pg_replication_slots;
 slot_name | active | wal_status |  held  
-----------+--------+------------+--------
 forgotten | f      | reserved   | 260 MB
(1 row)
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:52.231 -03 [102] LOG:  checkpoint complete: wrote 15937 buffers (97.3%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.056 s, sync=0.126 s, total=0.188 s; sync files=24, longest=0.110 s, average=0.006 s; distance=266516 kB, estimate=399309 kB; lsn=0/44CE06E8, redo lsn=0/44CE06B0
```

O `true` pede que o slot comece a segurar o log na hora. `active` é `f`, nada está conectado, e o
slot está segurando 260 MB. **O checkpoint não reciclou nada**: `0 removed, 0 recycled`, porque todo
segmento desde a criação do slot está prometido a um leitor que não existe. Mais nada acontece.
Nenhum erro, nenhum aviso no log, e o servidor continua funcionando perfeitamente até o disco
encher, e aí ele para.

Remova o slot e faça outro checkpoint:

```
shop=# SELECT pg_drop_replication_slot('forgotten');
 pg_drop_replication_slot 
--------------------------
 
(1 row)

shop=# CHECKPOINT;
CHECKPOINT
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:54.232 -03 [102] LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 16 recycled; write=0.001 s, sync=0.001 s, total=0.013 s; sync files=0, longest=0.000 s, average=0.000 s; distance=0 kB, estimate=359378 kB; lsn=0/44CE0798, redo lsn=0/44CE0760
```

**`16 recycled` no instante em que a promessa acaba.** Num servidor de verdade aquele slot poderia
estar segurando havia semanas. Dois hábitos decorrem disso. Procure em `pg_replication_slots` um slot
que não esteja `active` sempre que o `pg_wal` estiver maior do que você espera; a lição 24 põe essa
verificação no runbook de disco cheio. E considere configurar o `max_slot_wal_keep_size`, que deixa
o servidor desistir de um slot que segura mais do que isso: a réplica por trás dele então precisa
ser reconstruída, que é a troca que as lições de replicação do db-reliability pesam.

Limpe o que esta lição criou:

```
shop=# DROP TABLE orders_copy;
DROP TABLE

shop=# DROP TABLE notes;
DROP TABLE
```
