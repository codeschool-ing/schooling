---
title: A primeira página, impressa na hora
version: 1
---

A primeira coisa de que qualquer pessoa precisa no início de um incidente é **o estado de tudo
agora**: qual nó é o líder, para onde o proxy manda as escritas, o que os slots seguram, se o
armazenamento de consenso responde. Escrito numa página, isso fica desatualizado no dia seguinte.
Impresso por um script, está certo toda vez que ele roda. Salve isto como `status.sh`, torne-o
executável e coloque o nome dele no topo do runbook:

```schooling-example
{"language": "sh", "file": "status.sh", "parts": [{"code": "#!/bin/sh\n# status.sh: the first page of the runbook, printed fresh\necho \"== $(date '+%F %T %Z')\"", "note": "Cada parte imprime um título, para que a saída possa ser lida por alguém que não escreveu o script."}, {"code": "echo \"== cluster\"\npatronictl -c ~/patroni/pg1.yml list", "note": "Quem lidera, quem segue e quão atrás: a visão da lição 16."}, {"code": "echo \"== port 5000 leads to\"\npsql -h 127.0.0.1 -p 5000 -U postgres -XAt shop \\\n  -c \"SELECT inet_server_port(), pg_is_in_recovery()\"", "note": "O que a aplicação realmente alcança pelo HAProxy da lição 19: a porta atrás da porta 5000, e se ela aceita escritas."}, {"code": "echo \"== slots on the leader\"\npsql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c \"\n  SELECT slot_name, active,\n         pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn))\n  FROM pg_replication_slots ORDER BY 1\"", "note": "Os slots da lição 11, e quanto log cada um segura no líder."}, {"code": "echo \"== etcd\"\netcdctl endpoint health 2>&1", "note": "O etcd da lição 16: se esta linha não disser healthy, nada mais na página pode mudar."}, {"code": "echo \"== pg_wal on each node\"\ndu -sh ~/patroni/pg*/pg_wal", "note": "O log no disco de cada nó, que é o que enche primeiro quando algo acima está errado."}]}
```

Rode:

```
ana@vm:~$ ./status.sh
== 2026-10-16 03:22:32 -03
== cluster
+ Cluster: shop (7697147027087042659) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
== port 5000 leads to
5441|f
== slots on the leader
pg2|t|0 bytes
pg3|t|0 bytes
== etcd
127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.468964ms
== pg_wal on each node
65M	/home/ana/patroni/pg1/pg_wal
49M	/home/ana/patroni/pg2/pg_wal
49M	/home/ana/patroni/pg3/pg_wal
```

Cada linha responde a uma pergunta das lições 11 a 19, na ordem em que um incidente as faz, e nenhuma
delas foi digitada por quem a está lendo. Essa é a propriedade a manter: o runbook diz **como olhar**,
e o sistema diz o que está lá.
