---
title: Um líder que para, e um banco de dados que não para
version: 1
---

O cluster da lição 16, reconstruído, com o `pg1` como líder:

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

O `SIGSTOP` congela um processo onde ele está, sem matá-lo, do jeito que uma máquina virtual suspensa
fica congelada. Congele o Patroni do `pg1`, e nada além dele, espere a chave de líder expirar e olhe:

```
ana@vm:~$ pkill -STOP -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697125163435731023) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"
f
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (71, 7100, now()) RETURNING id"
50001
INSERT 0 1
ana@vm:~$ psql -h 127.0.0.1 -p 5442 -U postgres -XAt shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (72, 7200, now()) RETURNING id"
50029
INSERT 0 1
```

O cluster fez o que a lição 16 disse que faria. O `pg1` parou de renovar, a chave dele expirou, **o
`pg2` a pegou e se promoveu** na timeline 2, e o `pg3` segue o `pg2`. Até onde o etcd sabe, o `pg1`
sumiu.

E o PostgreSQL do `pg1` não está em recovery. Ninguém avisou nada a ele: o único processo que poderia
rebaixá-lo está congelado. Um servidor de aplicação que ainda tem uma conexão com a porta 5441 grava o
pedido **50001** ali, e um que já passou para o novo líder grava o pedido **50029** no `pg2`. **Dois
primários, os dois recebendo pedidos**, com cada componente funcionando como foi projetado.
