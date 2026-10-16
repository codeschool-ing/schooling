---
title: O shop no cluster, e a chave no etcd
version: 1
---

O cluster está vazio. Carregue o shop no líder com o `shop.sql` da lição 1, conectando como o papel
`postgres` que o Patroni criou, com a senha dele no `~/.pgpass`, e conte os pedidos no `pg3`:

```
ana@vm:~$ echo '127.0.0.1:*:*:postgres:patroni-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass
ana@vm:~$ createdb -h 127.0.0.1 -p 5441 -U postgres shop
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -q -f shop.sql shop
psql:shop.sql:2: NOTICE:  table "orders" does not exist, skipping
psql:shop.sql:2: NOTICE:  table "customers" does not exist, skipping
ana@vm:~$ psql -h 127.0.0.1 -p 5443 -U postgres -XAt shop -c "SELECT count(*) FROM orders"
50000
```

Cinquenta mil numa réplica que ninguém carregou à mão. Agora veja o que o Patroni guarda no etcd:

```
ana@vm:~$ etcdctl get --prefix --keys-only /service/shop/
/service/shop/config

/service/shop/initialize

/service/shop/leader

/service/shop/members/pg1

/service/shop/members/pg2

/service/shop/members/pg3

/service/shop/status

ana@vm:~$ etcdctl get --print-value-only /service/shop/leader
pg1
```

`config` guarda as configurações que todos os nós compartilham, a seção `bootstrap.dcs` do arquivo
depois que o cluster existe. `members/` tem uma entrada por nó, que cada nó reescreve a cada volta do
loop com o seu estado e a sua posição. `status` guarda a última posição do líder no log. `initialize`
registra qual cluster é este, para que um nó apontado para o etcd errado não possa entrar nele. E
`leader`, cujo valor é um nome: **`pg1`**. Essa única string é a resposta para "qual nó é o primário",
e a única resposta em que todos os nós confiam.
