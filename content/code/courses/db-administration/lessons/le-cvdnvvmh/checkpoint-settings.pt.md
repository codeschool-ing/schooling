---
title: Quando os checkpoints acontecem
version: 1
---

Um checkpoint custa uma rajada de escrita, então dá vontade de pensar que menos é sempre melhor, ou
que checkpoints pequenos e frequentes seriam mais suaves. Nenhuma das duas coisas vale.
**Checkpoints raros deixam a recuperação longa e o `pg_wal` grande; frequentes fazem o servidor
escrever muito mais**, por um motivo que a seção depois desta mede. Três configurações os
posicionam:

```
shop=# SELECT name, setting, unit FROM pg_settings
shop-#  WHERE name IN ('checkpoint_timeout', 'max_wal_size', 'checkpoint_completion_target',
shop(#                 'checkpoint_warning', 'log_checkpoints');
             name             | setting | unit 
------------------------------+---------+------
 checkpoint_completion_target | 0.9     | 
 checkpoint_timeout           | 300     | s
 checkpoint_warning           | 30      | s
 log_checkpoints              | on      | 
 max_wal_size                 | 1024    | MB
(5 rows)
```

**Um checkpoint começa no que vier primeiro: `checkpoint_timeout` desde o último, ou log suficiente
escrito.** O primeiro tipo aparece no log como `time` e o segundo como `wal`. Cinco minutos é o
intervalo padrão, e um servidor sem nada para escrever pula o checkpoint por tempo em vez de fazer
um vazio.

"Log suficiente" não é o próprio `max_wal_size`. O servidor quer que o ciclo inteiro — o log escrito
enquanto um checkpoint roda mais o log escrito antes do próximo — caiba dentro do `max_wal_size`,
então ele começa um checkpoint um pouco abaixo da metade disso. Com o padrão de 1 GB, são uns 500 MB
de log entre checkpoints.

O `checkpoint_completion_target`, 0.9, espalha a gravação de um checkpoint de rotina por nove
décimos do intervalo em vez de fazer tudo de uma vez, então o disco vê um fio constante e não uma
enxurrada a cada cinco minutos. O `checkpoint_warning` é o alarme que esta seção dispara.

## Checkpoints frequentes demais, de propósito

O jeito comum de errar isso é um `max_wal_size` que servia para um servidor calmo e é pequeno demais
para a carga de escrita que ele recebe agora. Monte essa situação. O `pgbench`, que vem com o
PostgreSQL, cria um banco próprio e roda contra ele uma carga de escrita padronizada; `-s 20` dá dois
milhões de linhas de contas:

```
ana@db:~$ createdb bench
ana@db:~$ pgbench -i -s 20 -q bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
2000000 of 2000000 tuples (100%) done (elapsed 1.54 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.47 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 1.56 s, vacuum 0.16 s, primary keys 0.74 s).
```

As linhas `NOTICE` são o `pgbench` limpando tabelas que nunca existiram. Agora diminua o
`max_wal_size` com `ALTER SYSTEM`, como a lição 5 fez, recarregue e zere as duas visões de
estatística que esta seção lê, para que o que elas contarem depois seja só esta execução:

```
bench=# ALTER SYSTEM SET max_wal_size = '64MB';
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
```

Depois rode uma quantidade fixa de trabalho: quatro clientes (`-c 4`), dez mil transações cada
(`-t 10000`), e `-n` para pular o vacuum com que o `pgbench` começaria. Cada transação dele atualiza
três tabelas e insere numa quarta:

```
ana@db:~$ pgbench -n -c 4 -t 10000 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 20
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
number of transactions per client: 10000
number of transactions actually processed: 40000/40000
number of failed transactions: 0 (0.000%)
latency average = 1.540 ms
initial connection time = 10.716 ms
tps = 2597.530956 (without initial connection time)
ana@db:~$ sudo tail -n 5 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:28:24.044 -03 [102] LOG:  checkpoint starting: wal
2026-10-10 04:28:24.918 -03 [102] LOG:  checkpoint complete: wrote 3999 buffers (24.4%); 0 WAL file(s) added, 0 removed, 2 recycled; write=0.852 s, sync=0.009 s, total=0.874 s; sync files=18, longest=0.004 s, average=0.001 s; distance=32780 kB, estimate=106635 kB; lsn=0/40EAE6C8, redo lsn=0/3F004310
2026-10-10 04:28:24.953 -03 [102] LOG:  checkpoints are occurring too frequently (0 seconds apart)
2026-10-10 04:28:24.953 -03 [102] HINT:  Consider increasing the configuration parameter "max_wal_size".
2026-10-10 04:28:24.954 -03 [102] LOG:  checkpoint starting: wal
```

`tps` é transações por segundo, e sozinho diz pouco: esta execução mediu 2597 numa máquina cujos
quatro processadores e disco eram divididos com outro trabalho. O log diz mais. **Cada checkpoint
começou por causa de `wal`, e o seguinte começou no instante em que o anterior terminou.** A
`distance` é 32780 kB: com o `max_wal_size` em 64 MB, um checkpoint vencia a cada 32 MB de log, mais
ou menos, um pouco abaixo da metade, como acima. E como dois deles começaram com menos de
`checkpoint_warning` de distância, o servidor avisou, com uma dica dizendo qual configuração
aumentar.

As estatísticas contam a mesma história:

```
bench=# SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;
 checkpoints_timed | checkpoints_req 
-------------------+-----------------
                 0 |              14
(1 row)

bench=# SELECT wal_records, wal_fpi, pg_size_pretty(wal_bytes) AS wal FROM pg_stat_wal;
 wal_records | wal_fpi |  wal   
-------------+---------+--------
      269350 |   59334 | 461 MB
(1 row)
```

**Catorze checkpoints numa execução curta, nenhum deles por tempo.** O `checkpoints_req` conta todo
checkpoint que o temporizador não começou: os forçados pelo log, e qualquer comando `CHECKPOINT`.
Num servidor saudável quase todos os checkpoints são por tempo, e um `checkpoints_req` que não para
de subir, ou um log com aquele `HINT`, diz que o `max_wal_size` é pequeno demais para o trabalho.
**Aumentar o `max_wal_size` é a correção, e custa disco**: o diretório pode crescer até mais ou menos
esse tamanho, e a recuperação depois de uma queda tem mais log para refazer.

O `pg_stat_wal` é a segunda metade da evidência, e a próxima seção roda o mesmo trabalho com a
configuração padrão para comparar.
