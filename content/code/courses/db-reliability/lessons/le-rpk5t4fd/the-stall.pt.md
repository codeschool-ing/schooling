---
title: Quando o standby some, o primário para
version: 1
---

A garantia "um commit confirmado está em dois servidores" tem uma consequência fácil de passar batido:
**quando não há segundo servidor, nada pode ser confirmado.** O primário não volta sozinho para o modo
assíncrono. Ele espera, o tempo que for preciso, e o mesmo acontece com toda aplicação que escreve
nele. Pare o standby e tente registrar um pedido:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ timeout 10 psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (21, 777777, now())"; echo "exit $?"
exit 124
shop=# SELECT state, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE wait_event = 'SyncRep';
 state  | wait_event_type | wait_event |                  query                   
--------+-----------------+------------+------------------------------------------
 active | IPC             | SyncRep    | INSERT INTO orders (customer_id, total_c
(1 row)

shop=# SELECT count(*) FROM orders WHERE total_cents = 777777;
 count 
-------
     0
(1 row)
```

O `timeout` desistiu depois de dez segundos e matou o `psql`, que é o que `exit 124` quer dizer; sem
ele, o prompt ainda estaria esperando agora. De uma segunda sessão, o primário mostra o que está
fazendo: um `INSERT` no estado `active`, esperando em `SyncRep`. E o pedido **não está lá**, `count` 0,
embora o primário já o tenha escrito no próprio log e feito o flush. Uma transação que espera o seu
standby fica invisível para todo mundo até a espera acabar.

## Um timeout não encerra a espera

A defesa óbvia é um timeout de statement, para que nenhuma requisição espere mais de três segundos:

```
ana@vm:~$ PGOPTIONS='-c statement_timeout=3s' timeout 10 psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (23, 888888, now())"; echo "exit $?"
exit 124
```

Esperou os dez segundos inteiros de novo, e a sessão dele agora é um segundo `INSERT` esperando em `SyncRep`, ao lado do primeiro. O `statement_timeout` limita o statement, e o statement já
tinha terminado: o que sobra é o commit, e o commit espera fora dele. Nada que a aplicação configure na
própria conexão põe limite nessa espera.

## Cancelando, e o que a aplicação ouve

A espera termina de três jeitos: o standby volta, alguém muda `synchronous_standby_names`, ou a sessão
que espera é cancelada. Comece mais um pedido em segundo plano, com a saída indo para um arquivo, e
cancele todas as sessões esperando em `SyncRep`:

```
ana@vm:~$ psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (24, 999999, now())" > insert.log 2>&1 &
shop=# SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event = 'SyncRep';
 pg_cancel_backend 
-------------------
 t
 t
 t
(3 rows)

shop=# SELECT total_cents, count(*) FROM orders WHERE total_cents > 700000 GROUP BY 1 ORDER BY 1;
 total_cents | count 
-------------+-------
      777777 |     1
      888888 |     1
      999999 |     1
(3 rows)
ana@vm:~$ cat insert.log
WARNING:  canceling wait for synchronous replication due to user request
DETAIL:  The transaction has already committed locally, but might not have been replicated to the standby.
INSERT 0 1
```

Três canceladas, e **três pedidos na tabela.** Os três tinham sido commitados no primário antes de
começar a esperar, e cancelar a espera não desfaz um commit; só deixa de esperar o standby. A aplicação
que continuou conectada foi avisada, num warning, e depois recebeu `INSERT 0 1`: **sucesso, numa linha
que existe em um servidor só.** É exatamente o estado que a replicação síncrona foi configurada para
impedir, e o código da aplicação muito provavelmente lê o `INSERT 0 1` e ignora o warning. Os dois cujos
clientes o `timeout` tinha matado não ouviram nada.

Então a descrição honesta de `synchronous_standby_names = 'standby1'` não é "todo commit está em dois
servidores". É **"todo commit está em dois servidores, ou o banco para de aceitar escritas"**: uma queda
do standby é uma queda do primário. Um standby só é uma configuração que dobra o número de máquinas cuja
falha para o shop. A próxima seção resolve isso.
