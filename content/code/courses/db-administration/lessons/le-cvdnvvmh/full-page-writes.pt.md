---
title: Full-page writes, e o que os checkpoints custam
version: 1
---

A lição 7 descobriu que a primeira alteração de uma página depois de um checkpoint leva uma cópia da
página inteira, para que a recuperação consiga consertar uma página que a queda de energia rasgou
ao meio. **Cada checkpoint reinicia essa regra para todas as páginas**, e esse é o preço escondido
de ter muitos deles. A seção anterior rodou 40.000 transações com checkpoints vencendo a cada 32 MB
de log. Volte o `max_wal_size`, zere os contadores e rode exatamente o mesmo trabalho:

```
bench=# ALTER SYSTEM RESET max_wal_size;
ALTER SYSTEM

bench=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

bench=# CHECKPOINT;
CHECKPOINT

bench=# SELECT pg_stat_reset_shared('bgwriter'), pg_stat_reset_shared('wal');
 pg_stat_reset_shared | pg_stat_reset_shared 
----------------------+----------------------
                      | 
(1 row)
ana@db:~$ pgbench -n -c 4 -t 10000 bench | tail -n 1
tps = 2648.746484 (without initial connection time)
bench=# SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;
 checkpoints_timed | checkpoints_req 
-------------------+-----------------
                 0 |               0
(1 row)

bench=# SELECT wal_records, wal_fpi, pg_size_pretty(wal_bytes) AS wal FROM pg_stat_wal;
 wal_records | wal_fpi |  wal   
-------------+---------+--------
      251257 |   27489 | 224 MB
(1 row)
```

O `ALTER SYSTEM RESET` tira a linha do `postgresql.auto.conf`, então o servidor volta ao 1 GB do
`postgresql.conf`. Lado a lado, as duas execuções fizeram as mesmas 40.000 transações:

| | `max_wal_size = 64MB` | padrão, 1 GB |
| --- | --- | --- |
| checkpoints durante a execução | 14 | 0 |
| registros de WAL (`wal_records`) | 269350 | 251257 |
| imagens de página inteira (`wal_fpi`) | 59334 | 27489 |
| WAL escrito | 461 MB | 224 MB |
| transações por segundo | 2597 | 2648 |

**Os checkpoints frequentes escreveram o dobro de log para o mesmo trabalho**, e quase todo o extra
são imagens de página: o número de registros quase não mudou, o número de imagens mais que dobrou.
Cada checkpoint fez toda página que a carga tocava pagar uma imagem nova na alteração seguinte. Até
a execução calma tirou 27489 imagens, porque começou logo depois de um `CHECKPOINT` e cada página
que ela tocou pagou uma vez.

A velocidade quase não mudou nesta máquina, e essa é a armadilha. O custo aparece como WAL: o dobro
de escrita em disco, o dobro de tráfego para cada réplica, o dobro de segmentos para arquivar. Nada
do lado da aplicação teria percebido.

## Por que ela fica ligada

A configuração é `full_page_writes`, e está ligada:

```
bench=# SHOW full_page_writes;
 full_page_writes 
------------------
 on
(1 row)

bench=# SHOW wal_compression;
 wal_compression 
-----------------
 off
(1 row)
```

Desligá-la tira as imagens e a maior parte do volume que a tabela mostra. **Ela também tira o único
conserto para uma página rasgada.** Depois de uma queda de energia no meio da gravação de uma
página, a recuperação refaria um registro pequeno em cima de uma página metade velha e metade nova,
e o resultado é uma página corrompida que nada denuncia até uma consulta lê-la. A configuração
existe para um armazenamento que pode prometer que uma página nunca é rasgada — um sistema de
arquivos como o ZFS, que nunca sobrescreve um bloco no lugar — e no ext4 ou no XFS, que a lição 9
examina, ela fica ligada.

As alavancas seguras são as que você já viu: **menos checkpoints**, com um `max_wal_size` que caiba
na carga, e imagens menores, com o `wal_compression`, que troca tempo de processador por volume de
log e vale a pena medir num servidor que escreve muito.
