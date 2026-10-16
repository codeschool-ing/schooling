---
title: Duas medidas que mentem quando nada acontece
version: 1
---

Quando o `pgbench` terminou e ninguém escreve, faça a mesma pergunta de novo:

```
shop=# SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;
 application_name |  behind  |    write_lag    |    flush_lag    |   replay_lag    
------------------+----------+-----------------+-----------------+-----------------
 standby1         | 40 bytes | 00:00:00.000312 | 00:00:00.000797 | 00:00:00.002042
(1 row)
shop=# SELECT now() - pg_last_xact_replay_timestamp() AS since_last_replay;
 since_last_replay 
-------------------
 00:00:00.629138
(1 row)
shop=# SELECT now() - pg_last_xact_replay_timestamp() AS since_last_replay;
 since_last_replay 
-------------------
 00:00:21.356942
(1 row)
shop=# SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
 pg_last_wal_receive_lsn | pg_last_wal_replay_lsn 
-------------------------+------------------------
 0/F6377C8               | 0/F6377C8
(1 row)
shop=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/F6377C8
(1 row)
```

As colunas `_lag` continuam mostrando milissegundos. Elas são **a última medida**, guardada até que
exista uma nova, e não crescem enquanto nada é enviado, então não dizem nada sobre há quanto tempo essa
medida foi feita. Um standby que parou de receber cinco minutos depois do início de uma noite tranquila
pode mostrar os mesmos números pequenos até alguém escrever.

O erro oposto é o mais comum. No standby, `now() - pg_last_xact_replay_timestamp()` é muitas vezes
recomendado como "o atraso em segundos", e acima ele foi de 0,6 segundo para **21 segundos** em vinte
segundos de silêncio. O standby não estava nada atrás: tinha recebido e reaplicado tudo até
`0/F6377C8`, que é exatamente onde o primário estava. A consulta mede o tempo desde a última
**transação**, o que num primário ocioso é o tempo desde que alguém escreveu. Um alerta construído em
cima dela dispara toda noite tranquila e é desligado em menos de uma semana.

A regra a que os dois erros levam: **compare posições, e use tempo só onde alguma coisa está se
movendo.** Bytes de atraso nunca erra sobre um primário ocioso, e uma medida de tempo só tem sentido ao
lado dela.
