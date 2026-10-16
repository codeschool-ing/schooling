---
title: Um PostgreSQL 17 ao lado do 16
version: 1
---

Os pacotes do próprio Ubuntu 24.04 têm o PostgreSQL 16 e nada mais novo. O jeito mais simples de rodar
o 17 na mesma máquina, sem mexer no 16 que o resto do curso usa, é **a imagem oficial rodando no
Docker**, que além disso não deixa nada para trás quando é removida. Instale o Docker pelos pacotes do
Ubuntu:

```sh
sudo apt install -y docker.io
```

Depois suba um container de PostgreSQL 17. `--network host` o coloca na própria rede da máquina, então
os dois servidores se alcançam em `127.0.0.1` como todos os outros pares deste curso; `-c port=5440` o
mantém longe das portas já em uso, e a senha é a do papel `postgres` dele. A primeira execução baixa a
imagem, uns 170 MB:

```
ana@vm:~$ sudo docker run -d --name pg17 --network host -e POSTGRES_PASSWORD=pg17-pass-1 postgres:17 -c port=5440 > /dev/null
ana@vm:~$ echo '127.0.0.1:5440:*:postgres:pg17-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -XAt -c "SELECT version()"
PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

O `.pgpass` no seu diretório home poupa você da senha daqui em diante; o `chmod` importa, porque o
`psql` ignora um arquivo de senhas que qualquer outra pessoa consegue ler.

## As tabelas, sem as linhas

Uma subscription copia linhas para tabelas que **já existem**; ela nunca cria uma. O schema é copiado
antes, com o `pg_dump` da lição 2, restrito às definições e sem três coisas que pertencem ao publisher:
os donos e os grants que nomeiam papéis que o 17 não tem, e a própria publicação:

```
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -c "CREATE DATABASE shop"
CREATE DATABASE
ana@vm:~$ pg_dump --schema-only --no-owner --no-privileges --no-publications shop | psql -q -o /dev/null -h 127.0.0.1 -p 5440 -U postgres shop
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres shop -c "\dt"
           List of relations
 Schema |   Name    | Type  |  Owner   
--------+-----------+-------+----------
 public | customers | table | postgres
 public | orders    | table | postgres
(2 rows)
```

## Assinando

A subscription é criada no subscriber, com uma connection string comum que aponta para o publisher:

```
shop=# CREATE SUBSCRIPTION shop_sub CONNECTION 'host=127.0.0.1 port=5432 dbname=shop user=replicator password=replica-pass-1' PUBLICATION shop_pub;
NOTICE:  created replication slot "shop_sub" on publisher
CREATE SUBSCRIPTION
shop=# SELECT count(*) FROM orders;
 count 
-------
 50000
(1 row)

shop=# SELECT subname, received_lsn, latest_end_lsn FROM pg_stat_subscription;
 subname  | received_lsn | latest_end_lsn 
----------+--------------+----------------
 shop_sub | 0/2132E00    | 0/2132E00
(1 row)
```

`created replication slot "shop_sub" on publisher`: uma subscription lógica mantém um slot no
publisher, como o standby da lição 11, com a mesma consequência se ela parar de consumir. Os 50.000
pedidos foram copiados no tempo que se levou para olhar, e o `pg_stat_subscription` mostra o subscriber
acompanhando o log do publisher. Um pedido novo no 16:

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (41, 4100, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1

shop=# SELECT slot_name, plugin, slot_type, active FROM pg_replication_slots;
 slot_name |  plugin  | slot_type | active 
-----------+----------+-----------+--------
 shop_sub  | pgoutput | logical   | t
(1 row)
shop=# SELECT id, customer_id, total_cents FROM orders ORDER BY id DESC LIMIT 1;
  id   | customer_id | total_cents 
-------+-------------+-------------
 50001 |          41 |        4100
(1 row)
```

No 17, um instante depois, com o mesmo id. O slot no 16 é `logical`, e `pgoutput` é o plugin que
transforma o log em linhas.
