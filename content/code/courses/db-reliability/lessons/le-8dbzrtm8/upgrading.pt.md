---
title: Um upgrade como uma troca
version: 1
---

O 17 agora tem todos os pedidos que o 16 tem, no máximo minutos atrás, e um pedido novo no 16 chega
nele em segundos. Passar a aplicação de um para o outro é o upgrade, e, feito nesta ordem, ele custa os
poucos minutos em que a aplicação fica parada, e não as horas que um dump e restore de um banco grande
custariam:

1. **Pare as escritas** no 16: pare a aplicação, ou faça o 16 recusá-las.
2. **Espere até o subscriber ter tudo**: a posição do slot é igual à do publisher.
3. **Mova cada sequência** no 17 para além do maior valor usado no 16.
4. **Pare a subscription**, para que nada escrito no 16 por engano mais tarde chegue ao 17.
5. **Aponte a aplicação para o 17**, e deixe que ela escreva.

Nada escreve no 16 aqui, então o passo 1 já vale. Os passos 2 a 4:

```
shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind FROM pg_replication_slots WHERE slot_name = 'shop_sub';
 behind  
---------
 0 bytes
(1 row)
ana@vm:~$ max=$(psql -XAt shop -c "SELECT max(id) FROM orders")
ana@vm:~$ echo $max
50002
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -XAt shop -c "SELECT setval('orders_id_seq', $max + 1000)"
51002
shop=# ALTER SUBSCRIPTION shop_sub DISABLE;
ALTER SUBSCRIPTION

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (43, 4300, now()) RETURNING id;
  id   
-------
 51003
(1 row)

INSERT 0 1
```

`0 bytes` de atraso. A sequência é movida para o maior id **mais mil**: uma margem é barata, e cobre um
insert que tenha entrado de fininho depois que o máximo foi lido. Com a subscription desabilitada, o
primeiro pedido escrito no 17 recebeu o id 51003 e não colidiu com nada.

Duas coisas que isto não cobre, e um upgrade de verdade tem uma lista para cada uma: outros objetos que
não são linhas, como os papéis, que o `pg_dumpall --roles-only` copia, e as extensões e as versões delas
no servidor novo. E o 16 é mantido, intocado, até o 17 rodar por tempo suficiente para merecer
confiança: ele é o caminho de volta.
