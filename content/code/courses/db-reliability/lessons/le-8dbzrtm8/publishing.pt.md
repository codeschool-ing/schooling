---
title: O publisher
version: 1
---

O log só carrega o suficiente para reconstruir linhas se o `wal_level` mandar. O padrão, `replica`, é o
que a replicação física precisa; a decodificação lógica precisa de `logical`, e mudá-lo exige um
restart:

```
shop=# ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql -XAt shop -c "SHOW wal_level"
logical
```

Uma publicação nomeia as suas tabelas. O subscriber vai se conectar como o papel `replicator` da lição
11, que tem o direito de replicar e nenhum direito de ler uma tabela, e uma subscription lógica começa
com uma cópia simples das linhas de cada tabela, então o papel recebe `SELECT` exatamente nessas duas:

```
shop=# CREATE PUBLICATION shop_pub FOR TABLE customers, orders;
CREATE PUBLICATION

shop=# GRANT SELECT ON customers, orders TO replicator;
GRANT
```

Nada aconteceu ainda: uma publicação é uma oferta, e nada é enviado até alguém assinar.
