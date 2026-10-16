---
title: Leituras num standby, e a consulta que é cancelada
version: 1
---

Um standby responde a consultas, então relatórios, buscas e exportações podem ir para lá e deixar o
primário com as escritas; a porta 5001 da lição 19 distribuía exatamente essas. Há um conflito embutido
nisso. O `VACUUM` do primário remove versões antigas de linhas assim que **nenhuma consulta no
primário** ainda pode precisar delas, e o standby reproduz essa remoção. Uma consulta longa no standby
pode ainda precisar delas.

Comece um relatório no `standby2`: uma transação que conta os pedidos, espera um minuto e conta de novo
a partir do mesmo snapshot. Enquanto ela espera, o primário atualiza mil pedidos e roda o VACUUM:

```
ana@vm:~$ psql -p 5435 shop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT count(*) FROM orders' -c 'SELECT pg_sleep(60)' -c 'SELECT count(*) FROM orders' -c 'COMMIT' > report.log 2>&1 &
shop=# UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000;
UPDATE 1000

shop=# VACUUM orders;
VACUUM
ana@vm:~$ cat report.log
BEGIN
 count 
-------
 50000
(1 row)

ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK
```

A segunda contagem nunca rodou: **`canceling statement due to conflict with recovery`**. O standby
esperou `max_standby_streaming_delay`, 30 segundos por padrão, com o replay segurado por causa do
relatório, e então cancelou o relatório para que o replay pudesse seguir. Um standby tem de escolher
entre estar atualizado e deixar uma consulta terminar, e por padrão ele escolhe estar atualizado
depois de trinta segundos.

## Feedback

O `hot_standby_feedback` faz a outra escolha: o standby diz ao seu upstream quais linhas as suas
consultas ainda precisam, e o `VACUUM` do primário as mantém. Numa cascata ele tem de estar ligado em
cada degrau, para que o `standby1` repasse o pedido do `standby2`:

```
ana@vm:~$ sudo -u postgres psql -p 5435 -c 'ALTER SYSTEM SET hot_standby_feedback = on' -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~$ sudo -u postgres psql -p 5434 -c 'ALTER SYSTEM SET hot_standby_feedback = on' -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~$ psql -p 5435 shop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT count(*) FROM orders' -c 'SELECT pg_sleep(45)' -c 'SELECT count(*) FROM orders' -c 'COMMIT' > report.log 2>&1 &
shop=# SELECT slot_name, xmin FROM pg_replication_slots;
 slot_name | xmin 
-----------+------
 standby1  |  739
(1 row)

shop=# UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000;
UPDATE 1000

shop=# VACUUM orders;
VACUUM

shop=# SELECT n_dead_tup FROM pg_stat_user_tables WHERE relname = 'orders';
 n_dead_tup 
------------
       1000
(1 row)
ana@vm:~$ cat report.log
BEGIN
 count 
-------
 50000
(1 row)

 pg_sleep 
----------
 
(1 row)

 count 
-------
 50000
(1 row)

COMMIT
```

O slot `standby1` agora carrega um `xmin`, a transação mais antiga de que uma consulta mais adiante
ainda precisa. Depois do mesmo `UPDATE` e do mesmo `VACUUM`, o primário informa **1000 versões mortas
de linha que ele não removeu**, e o relatório terminou as duas contagens.

Esse é o preço, levado para o primário: **uma consulta longa em qualquer standby segura a limpeza no
primário** enquanto estiver rodando. Um relatório que roda por seis horas num standby de relatórios são
seis horas de linhas mortas se acumulando nas tabelas mais movimentadas do primário. O feedback é o
certo para consultas curtas que não podem ser canceladas; para relatórios longos, um standby separado,
sem feedback e com um `max_standby_streaming_delay` grande, fica para trás em vez de inchar o primário
com bloat.
