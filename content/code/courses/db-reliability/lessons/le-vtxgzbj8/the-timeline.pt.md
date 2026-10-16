---
title: A linha do tempo, a partir do que ficou no disco
version: 1
---

A memória é a pior fonte para uma linha do tempo: ela é confiante, e põe as coisas na ordem em que
fizeram sentido, não na ordem em que aconteceram. Logs e registros têm as horas. Junte-os:

```
ana@vm:~$ grep -h -E "promoted self|acquired session lock" ~/patroni/pg2.log ~/patroni/pg3.log
2026-10-16 02:47:59,585 INFO: promoted self to leader by acquiring session lock
ana@vm:~$ curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^primary,pg'
primary,pg1,DOWN
primary,pg2,UP
primary,pg3,DOWN
ana@vm:~$ psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c "SELECT count(*) FROM orders WHERE id > 50000"
14
```

O log do Patroni no `pg2` dá a promoção com precisão de milissegundo. A página de status do HAProxy
confirma para onde a porta 5000 manda as conexões agora. E a própria tabela do shop resolve o número
mais importante: **chegaram 14 pedidos, exatamente tantos quantos o `orders.sh` reportou como `ok`**.
Nada que a aplicação ouviu que estava salvo sumiu, e nada que ela ouviu que tinha falhado acabou salvo.

Tudo junto:

| hora | evento | fonte |
|---|---|---|
| 02:47:32 | `pg1` morto (a máquina dele "morreu") | a nota corrente |
| 02:47:35 | primeiro pedido falha | `orders.log` |
| 02:47:59.585 | `pg2` pega a chave de líder e se promove | log do Patroni no `pg2` |
| 02:48:01 | último pedido falha | `orders.log` |
| 02:48:02 | primeiro pedido dá certo, no `pg2` | `orders.log` |

**Trinta segundos sem pedidos**, de 02:47:32 a 02:48:02, e deles, uns 27 esperando a chave de líder
expirar e três para o HAProxy perceber o novo primário. Essa divisão é a parte útil: ela diz a qual
ajuste pertence cada segundo, o `ttl` da lição 16 ou as checagens da lição 19, e portanto qual mudança
encurtaria o próximo, e com que risco.

Por último, a recuperação que a seção de decisão deixou em aberto, feita depois que a causa foi
entendida: iniciar de novo o Patroni do `pg1`.

```
ana@vm:~$ patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697137969997383883) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

O `pg1` é uma réplica na timeline 2. O incidente acaba quando essa linha diz isso, não quando o shop
aceitou o primeiro pedido de novo, e a hora desta linha é a última entrada da linha do tempo.
