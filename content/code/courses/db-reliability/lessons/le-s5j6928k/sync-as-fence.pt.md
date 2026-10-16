---
title: Replicação síncrona como fence
version: 1
---

A última linha da tabela não precisa de maquinário extra, e o cluster desta lição consegue mostrá-la,
depois que um switchover com o comando único da lição 16 faz do `pg1` o líder de novo.
O `synchronous_mode` do Patroni gerencia o `synchronous_standby_names` da lição 12 por você: ele
escolhe uma réplica como o **standby síncrono**, e o líder espera por ela a cada commit.

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml edit-config --set synchronous_mode=true --force > /dev/null
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ---+-----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader       | running   |  3 |           |
| pg2    | 127.0.0.1:5442 | Replica      | streaming |  3 |         0 |
| pg3    | 127.0.0.1:5443 | Sync Standby | streaming |  3 |         0 |
+--------+----------------+--------------+-----------+----+-----------+
```

O `pg3` é o `Sync Standby`. Agora congele de novo o Patroni do `pg1` e tente a mesma escrita no
primário antigo depois que o failover tiver acontecido:

```
ana@vm:~$ pkill -STOP -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697125163435731023) ---+-----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Sync Standby | streaming |  4 |         0 |
| pg3    | 127.0.0.1:5443 | Leader       | running   |  4 |           |
+--------+----------------+--------------+-----------+----+-----------+
ana@vm:~$ timeout 10 psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (73, 7300, now()) RETURNING id"; echo "exit $?"
exit 124
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SHOW synchronous_standby_names"
pg3
ana@vm:~$ pkill -CONT -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ---+-----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica      | streaming |  4 |         0 |
| pg2    | 127.0.0.1:5442 | Sync Standby | streaming |  4 |         0 |
| pg3    | 127.0.0.1:5443 | Leader       | running   |  4 |           |
+--------+----------------+--------------+-----------+----+-----------+
```

O `pg3` virou o líder, e o `pg2` o standby síncrono dele. No `pg1` o insert **esperou até o `timeout`
desistir**, exit 124: o `synchronous_standby_names` dele ainda diz `pg3`, e o `pg3` não é mais o
standby dele. O primário antigo ainda consegue aceitar uma conexão e um comando, mas não consegue
**confirmar** um commit, então nenhuma aplicação ouve "salvo" sobre uma linha que só ele tem. Quando o
Patroni dele foi descongelado, ele voltou como réplica, como antes.

Dois limites impedem que isso seja a resposta inteira. A transação que espera fica commitada
**localmente**, como a lição 12 mostrou com um cancel, então um cancel descuidado no primário antigo
transforma isso de novo numa escrita perdida. E custa a cada commit uma ida e volta até o standby. É o
fence mais barato que existe, e os designs mais fortes o combinam com o watchdog.
