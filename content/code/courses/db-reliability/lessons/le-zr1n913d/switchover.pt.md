---
title: Um switchover num comando
version: 1
---

A mudança planejada é um comando só, que nomeia o líder atual e o nó que vai assumir:

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml switchover --leader pg3 --candidate pg1 --force
Current cluster topology
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
2026-10-16 01:40:57.53320 Successfully switched over to "pg1"
+ Cluster: shop (7697120517756803320) --------+----+-----------+
| Member | Host           | Role    | State   | TL | Lag in MB |
+--------+----------------+---------+---------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running |  2 |           |
| pg2    | 127.0.0.1:5442 | Replica | running |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | stopped |    |   unknown |
+--------+----------------+---------+---------+----+-----------+
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  3 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  3 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  3 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

O `patronictl` imprimiu a topologia que encontrou, fez o switchover que a lição 15 fez à mão (uma
parada limpa do `pg3`, depois a promoção do `pg1` assim que ele tinha tudo) e imprimiu a topologia um
instante depois: o `pg3` ainda `stopped` enquanto reiniciava como réplica. Alguns segundos depois
disso, está tudo `streaming` na timeline 3, com o `pg1` de novo como líder.

A lição 23 ensaia exatamente isso, e é a primeira coisa a testar em qualquer cluster novo: um
switchover que funciona diz que as réplicas estão em dia, que todo nó alcança todos os outros e que a
aplicação, assunto da lição 19, segue o líder.
