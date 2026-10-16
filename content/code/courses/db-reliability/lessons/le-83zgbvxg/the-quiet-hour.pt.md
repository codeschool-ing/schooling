---
title: A hora tranquila, e o archive_timeout
version: 1
---

Um segmento é arquivado quando termina, e termina quando enche. Num banco ocupado, isso é a cada
poucos segundos. Num tranquilo, um segmento pode levar horas para encher, e **cada mudança nele só
existe no servidor até lá.**

Aqui está um shop tranquilo. Chega um pedido, e o segmento em que ele cai não está cheio:

```
shop=# SELECT last_archived_wal, last_archived_time FROM pg_stat_archiver;
    last_archived_wal     |      last_archived_time      
--------------------------+------------------------------
 00000001000000000000000C | 2026-10-10 04:34:18.84311-03
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (7, 1250, now());
INSERT 0 1

shop=# SELECT pg_walfile_name(pg_current_wal_lsn()), now();
     pg_walfile_name      |              now              
--------------------------+-------------------------------
 00000001000000000000000D | 2026-10-10 04:35:24.554325-03
(1 row)
shop=# SELECT last_archived_wal, last_archived_time, now() FROM pg_stat_archiver;
    last_archived_wal     |      last_archived_time      |             now              
--------------------------+------------------------------+------------------------------
 00000001000000000000000C | 2026-10-10 04:34:18.84311-03 | 2026-10-10 04:35:55.24353-03
(1 row)
```

O pedido foi para o segmento `0D`. Trinta segundos depois, o arquivo ainda termina em `0C`,
arquivado um minuto antes de o pedido existir. Se o disco do servidor morresse agora, o backup
terminaria em `0C`, e aquele pedido estaria perdido. Num shop que recebe um pedido por hora, um
segmento de 16 MB pode ficar aberto por dias, e a lacuna também.

O `archive_timeout` fecha um segmento depois de um tempo definido **se algo foi escrito nele**,
então um servidor ocioso não fica cuspindo segmentos vazios, e um tranquilo nunca deixa uma mudança
sem arquivar por mais tempo que o timeout:

```
shop=# ALTER SYSTEM SET archive_timeout = '60s';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (8, 990, now());
INSERT 0 1

shop=# SELECT pg_walfile_name(pg_current_wal_lsn()), now();
     pg_walfile_name      |              now              
--------------------------+-------------------------------
 00000001000000000000000E | 2026-10-10 04:35:56.850466-03
(1 row)
shop=# SELECT last_archived_wal, last_archived_time FROM pg_stat_archiver;
    last_archived_wal     |      last_archived_time       
--------------------------+-------------------------------
 00000001000000000000000E | 2026-10-10 04:36:56.347137-03
(1 row)
```

Algo aconteceu antes mesmo de o novo pedido ser digitado. O segmento `0D` estava aberto havia mais
de um minuto com uma mudança dentro, então no instante em que a configuração chegou o servidor o
fechou e o arquivou; o novo pedido foi para o `0E`. Sessenta segundos depois, pelo
`last_archived_time`, o `0E` também foi fechado e arquivado, alguns kilobytes de log num arquivo de
16 MB.

Essa é a troca. **Cada segmento fechado custa 16 MB de espaço no arquivo**, por menos que tenha
dentro, então um timeout de um minuto num servidor tranquilo pode escrever até 23 GB por dia de
arquivos quase vazios. Eles comprimem para quase nada, o que é mais um motivo para a lição 5
substituir o `cp`. Um timeout de um a cinco minutos é comum; o certo é um número que a lição 8
deriva de quanta perda é aceitável.
