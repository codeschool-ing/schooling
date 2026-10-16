---
title: 120 clientes, 20 conexões
version: 1
---

Os mesmos 120 clientes do `pgbench` que o servidor recusou, agora através do PgBouncer na 6433,
durante dez segundos. Enquanto eles rodam, pergunte ao PgBouncer sobre os seus pools, pelo console de
administração (o banco chamado `pgbouncer`), e meça quanto tempo uma consulta a mais espera:

```
ana@vm:~$ pgbench -c 120 -T 10 -n -h 127.0.0.1 -p 6433 -U shop_app bench > ~/bench.out 2>&1 &
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app pgbouncer -c "SHOW POOLS" | cut -c1-80 | head -n 4
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_wait
-----------+-----------+-----------+------------+----------------------+--------
 bench     | shop_app  |        20 |        100 |                    0 |        
 pgbouncer | pgbouncer |         1 |          0 |                    0 |        
ana@vm:~$ time psql -h 127.0.0.1 -p 6433 -U shop_app -XAt bench -c "SELECT 1"
1

real	0m0.143s
user	0m0.041s
sys	0m0.007s
shop=# SELECT count(*) FROM pg_stat_activity WHERE usename = 'shop_app';
 count 
-------
    21
(1 row)
ana@vm:~$ grep -E "number of failed|latency average|tps" ~/bench.out
number of failed transactions: 0 (0.000%)
latency average = 73.210 ms
tps = 1639.120555 (without initial connection time)
```

`cl_active` 20, `cl_waiting` 100: vinte clientes seguram uma conexão com o servidor neste instante e
cem estão na fila esperando uma. No servidor, o `shop_app` tem **21** processos, o pool de 20 do
`bench` e o que atende o `shop`, ainda aberto desde a contagem no fim da seção anterior. Um `SELECT 1` extra que chegou no meio disso esperou atrás da fila e
terminou em **0,143 segundo**. E o próprio `pgbench` reporta **nenhuma transação com falha**: cada um
dos 120 clientes foi atendido, por 20 conexões, porque no **modo transaction** um cliente segura uma
conexão com o servidor só pela duração de uma transação e depois a devolve.

A fila não é de graça. A latência média aqui fica em torno de **73 ms**, contra 2 ms na lição 12 com
quatro clientes; quase todo esse tempo é passado esperando na fila do PgBouncer, que é onde ele deve
ser gasto, em vez de num servidor com 120 processos brigando por quatro núcleos.
