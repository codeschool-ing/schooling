---
title: A leitura desatualizada, e ler as próprias escritas
version: 1
---

Um standby responde a consultas, e isso é metade do atrativo dele: relatórios e buscas vão para lá e
deixam o primário com as escritas. O preço é que **toda leitura num standby vem do passado**, na medida
de quanto ele estiver atrás. Um standby pode ser congelado de propósito com `pg_wal_replay_pause()`,
que é como esta seção faz o passado durar o bastante para ser examinado. Pause-o, deixe o primário
escrever, e faça um pedido:

```
shop=# SELECT pg_wal_replay_pause();
 pg_wal_replay_pause 
---------------------
 
(1 row)
ana@vm:~$ pgbench -c 4 -T 10 -n bench > /dev/null 2>&1
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (31, 3100, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1
shop=# SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;
 application_name | behind  |    write_lag    |    flush_lag    |   replay_lag    
------------------+---------+-----------------+-----------------+-----------------
 standby1         | 9967 kB | 00:00:00.000416 | 00:00:00.000733 | 00:00:10.372016
(1 row)
shop=# SELECT count(*) FROM orders WHERE customer_id = 31 AND total_cents = 3100;
 count 
-------
     0
(1 row)
```

O standby recebeu o log (`write_lag` e `flush_lag` continuam abaixo de um milissegundo) e não o
aplicou: 9967 kB atrás e `replay_lag` acima de dez segundos, crescendo enquanto durar a pausa. E o
pedido, `50001`, **não está lá**. Um cliente que faz um pedido e é levado a uma página que lê do
standby não vê pedido nenhum, e faz o pedido de novo.

## Lendo as próprias escritas

A correção que a maioria das aplicações usa é a mais simples: **depois de uma escrita, leia do
primário** por um tempo, ou pelo resto daquela requisição. Outra é o `remote_apply` da lição 12, que
faz o commit esperar até que o standby o tenha reaplicado, para que qualquer leitura depois do commit o
enxergue, com um preço em todo commit.

A precisa é comparar posições. Depois da escrita, a aplicação pergunta ao primário onde está o log;
antes de ler do standby, pergunta ao standby se ele já reaplicou até ali:

```
ana@vm:~$ lsn=$(psql -XAt shop -c "SELECT pg_current_wal_lsn()")
ana@vm:~$ echo $lsn
0/FFF3378
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
f
```

`f`: o standby ainda não chegou lá, então esta leitura vai para o primário, ou espera. Retome o replay e
pergunte de novo:

```
shop=# SELECT pg_wal_replay_resume();
 pg_wal_replay_resume 
----------------------
 
(1 row)
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT pg_last_wal_replay_lsn() >= '$(psql -XAt shop -c 'SELECT pg_current_wal_lsn()')'"
t
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT count(*) FROM orders WHERE customer_id = 31 AND total_cents = 3100"
1
```

`t`, e o pedido aparece. Duas consultas pequenas, e o standby só é lido quando se sabe que ele está
atualizado o bastante. É a mesma comparação que a lição 11 fez a olho no `pg_stat_replication`, feita
pela aplicação no momento em que importa.
