---
title: Quando quem falha é o etcd
version: 1
---

Tudo acima depende de o etcd responder. Pare-o. Na sua máquina isso é `sudo systemctl stop etcd`; a
máquina de onde vêm estas transcrições não tem `systemd`, e para o mesmo processo com `pkill`:

```
ana@vm:~$ sudo pkill -x etcd
ana@vm:~$ timeout 20 patronictl -c ~/patroni/pg1.yml list > /dev/null 2>&1; echo "exit $?"
exit 124
ana@vm:~$ grep -h -E "demot|read-only|failsafe" ~/patroni/pg1.log | tail -n 3
2026-10-16 01:40:25.234 -03 [14936] LOG:  database system is ready to accept read-only connections
2026-10-16 01:41:38,092 INFO: demoting self because DCS is not accessible and I was a leader
2026-10-16 01:41:39.711 -03 [15114] LOG:  database system is ready to accept read-only connections
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"
t
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (61, 6100, now())"
ERROR:  cannot execute INSERT in a read-only transaction
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  4 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  4 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  4 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

O `patronictl` não consegue listar nada, e fica tentando até o `timeout` pará-lo. Isso era esperado.
As linhas seguintes são a surpresa: **o primário se rebaixou.** O `pg1` não conseguiu renovar a chave
de líder, e a regra diz que um líder que não consegue renovar tem que supor que outro nó está com ela.
Todo PostgreSQL do cluster agora é somente leitura, e o shop não consegue receber um pedido, embora os
três servidores de banco estejam saudáveis. O último `list` acima foi tirado depois de o etcd
ser iniciado de novo (`sudo systemctl start etcd` na sua máquina; o mesmo processo, iniciado à mão,
nesta): o `pg1` pegou a chave de novo, na timeline 4.

Essa é a troca que o design faz, e por padrão é a certa: um cluster inteiro recusando escritas por um
tempo é uma indisponibilidade; dois primários são dados perdidos. Isso também quer dizer que **o etcd
faz parte da disponibilidade do banco**, e um etcd único é um ponto único de falha para os três
servidores. Em produção, o etcd roda com **três ou cinco membros em máquinas separadas**, para que
perder um deles não mude nada e ainda haja uma maioria para concordar.

## Failsafe mode

O Patroni 3 oferece uma regra mais estreita. Com o `failsafe_mode` ligado, um líder que perde o etcd
pergunta diretamente aos outros nós, pelas interfaces REST deles, e continua rodando como primário se
**todos** os membros responderem: se ele enxerga todos, nenhum deles pode ter sido promovido.

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml edit-config --set failsafe_mode=true --force
--- 
+++ 
@@ -1,3 +1,4 @@
+failsafe_mode: true
 loop_wait: 10
 maximum_lag_on_failover: 1048576
 postgresql:
Configuration changed
ana@vm:~$ sudo pkill -x etcd
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"
f
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (62, 6200, now())"
INSERT 0 1
ana@vm:~$ grep -h "failsafe" ~/patroni/pg1.log | tail -n 2
2026-10-16 01:43:45,893 INFO: continue to run as a leader because failsafe mode is enabled and all members are accessible
2026-10-16 01:43:55,901 INFO: continue to run as a leader because failsafe mode is enabled and all members are accessible
```

A mesma falha, e o `pg1` continuou primário e aceitou o pedido. Todos os membros tinham que responder
para isso acontecer; um nó fora do ar, ou isolado, acaba com isso, e o líder se rebaixa como antes. É
uma configuração para um cluster cujo etcd tem mais chance de falhar do que a rede, e não substitui
três membros de etcd.
