---
title: Session, transaction, statement
version: 1
---

O `pool_mode` decide quando um cliente devolve a sua conexão com o servidor:

| modo | a conexão volta quando | o que quebra | quantos clientes 20 conexões atendem |
|---|---|---|---|
| `session` | o cliente se desconecta | nada | 20 por vez |
| `transaction` | cada transação termina | o estado da sessão, como acima | muitos, se as transações forem curtas |
| `statement` | cada comando termina | transações com mais de um comando | muitos, em cargas só de autocommit |

Mude o pool para o modo `session`, que o PgBouncer relê com um `SIGHUP` sem derrubar ninguém, e
repita os dois testes:

```
ana@vm:~$ sed -i 's/^pool_mode = transaction/pool_mode = session/' ~/pgbouncer/pgbouncer.ini
ana@vm:~$ kill -HUP $(cat ~/pgbouncer/pgbouncer.pid)
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SET statement_timeout = '1ms'"
SET
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"
 statement_timeout 
-------------------
 0
(1 row)

ana@vm:~$ pgbench -c 120 -T 5 -n -h 127.0.0.1 -p 6433 -U shop_app bench > ~/bench.out 2>&1 &
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app pgbouncer -c "SHOW POOLS" | cut -c1-80 | head -n 4
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_wait
-----------+-----------+-----------+------------+----------------------+--------
 bench     | shop_app  |        20 |        100 |                    0 |        
 pgbouncer | pgbouncer |         1 |          0 |                    0 |        
ana@vm:~$ time psql -h 127.0.0.1 -p 6433 -U shop_app -XAt bench -c "SELECT 1"
1

real	0m1.982s
user	0m0.033s
sys	0m0.009s
```

A configuração **não vazou**: no modo session o PgBouncer roda `DISCARD ALL` numa conexão com o
servidor antes de entregá-la ao próximo cliente, e a sessão pertence a um cliente durante toda a sua
vida. E o `SELECT 1` extra agora esperou **1,982 segundo** em vez de 0,143: vinte clientes do
`pgbench` seguraram cada um uma conexão durante toda a sua sessão de cinco segundos, então a consulta
esperou uma dessas sessões terminar, e não uma transação.

O modo session é seguro e faz pool só de **conexões**, o que ainda ajuda com o custo de iniciar um
processo a cada conexão. O modo transaction faz pool de **trabalho**, e pede à aplicação que mantenha
o seu estado de sessão dentro das transações. Escolha-o de propósito, teste a aplicação com ele antes
que a produção teste, e lembre que um failover derruba todas as conexões com o servidor no pool: a
lição 19 trata de como o pool, e a aplicação, encontram o novo primário.
