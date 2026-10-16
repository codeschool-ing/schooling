---
title: Perdendo o líder
version: 1
---

Mate o `pg1` como a queda de uma máquina mataria: primeiro o Patroni dele, depois o PostgreSQL, os dois
com `kill -9`, para que nada seja limpo. O `[.]` no padrão faz com que ele case com `pg1.yml` sem casar
com a própria linha de comando do `pkill`. Depois pergunte o que o cluster acha:

```
ana@vm:~$ date +%T
01:39:37
ana@vm:~$ pkill -9 -f 'patroni/pg1[.]yml'; kill -9 $(head -n 1 ~/patroni/pg1/postmaster.pid)
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ date +%T
01:40:22
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ grep -h -E "promoted self|acquired session lock" ~/patroni/pg2.log ~/patroni/pg3.log
2026-10-16 01:40:05,976 INFO: promoted self to leader by acquiring session lock
```

Logo depois do kill, **nada mudou**: o `pg1` continua `Leader` e `running`, porque a chave de líder não
expirou e a entrada `members/pg1` é a última que o `pg1` escreveu. Quarenta e cinco segundos depois o
`pg3` é o líder, na timeline 2, e o `pg2` o segue; o `pg1` saiu da lista, já que a entrada dele no etcd
expirou junto. O log diz quando: 01:40:05, **28 segundos depois do kill**, que é o `ttl` de 30 segundos
da chave contado a partir da última renovação antes do kill.

O `pg3` venceu, e não o `pg2`. Os dois estavam em dia, então qualquer um podia vencer, e o etcd deu a
chave a quem pediu primeiro. Quem vence não é algo de que se possa depender.

Esse é o preço de a decisão ser segura: **por até `ttl` segundos depois que um primário morre, nada
aceita escritas**, porque a única alternativa é promover antes de a reivindicação do líder antigo
expirar. Um `ttl` mais curto faz o failover mais cedo e é enganado com mais facilidade por um primário
que só está lento, que é de novo o problema de medição da lição 13.

## O nó morto volta

Inicie de novo o Patroni do `pg1`, como um reboot da máquina faria:

```
ana@vm:~$ patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ grep -E "rewind" ~/patroni/pg1.log | head -n 3
2026-10-16 01:40:23,884 INFO: running pg_rewind from pg3
2026-10-16 01:40:23,940 INFO: running pg_rewind from dbname=postgres user=postgres host=127.0.0.1 port=5443 target_session_attrs=read-write
2026-10-16 01:40:24,744 INFO: pg_rewind exit code=0
```

O reboot da lição 15 criou um segundo primário. Este voltou como **réplica**, na timeline 2, fazendo
streaming do `pg3`: antes de iniciar o PostgreSQL, o Patroni leu a chave de líder, viu que ela nomeava
outro nó e rodou o **`pg_rewind`** para trazer os dados do `pg1` de volta ao ponto em que as histórias
se separaram, com os checksums que o `initdb` ligou e a configuração que ele sabe onde achar. Tudo o que
a lição 15 fez à mão para reintegrar um primário, em menos de um segundo de log.
