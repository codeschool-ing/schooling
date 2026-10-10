---
title: Um banco para cuidar
version: 1
---

Um servidor vazio não tem nada para administrar. A partir desta lição, o curso cuida de um banco
chamado **`shop`**: os clientes de uma loja e os pedidos deles. Ele é pequeno o bastante para ser
feito em um quarto de minuto e grande o bastante para que seus arquivos tenham tamanhos que valem
ler — um milhão de pedidos.

Ele inteiro é um arquivo de SQL. Salve-o na sua pasta pessoal no servidor como `shop.sql`; o jeito
mais fácil é abrir um editor com `nano shop.sql`, colar e salvar com Ctrl+O e Ctrl+X.

```sql
-- shop.sql: the course's database. Run it with: psql shop -f shop.sql
CREATE TABLE customers (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      text NOT NULL UNIQUE,
    name       text NOT NULL,
    country    text NOT NULL,
    created_at timestamptz NOT NULL
);

CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id bigint NOT NULL REFERENCES customers (id),
    status      text NOT NULL,
    total_cents integer NOT NULL,
    created_at  timestamptz NOT NULL
);

CREATE INDEX orders_customer_id ON orders (customer_id);
CREATE INDEX orders_created_at ON orders (created_at);

-- 50,000 customers and a million orders, made by arithmetic rather than
-- random(), so every run of this file makes exactly the same rows.
INSERT INTO customers (email, name, country, created_at)
SELECT 'customer' || i || '@example.com',
       'Customer ' || i,
       (ARRAY['BR', 'PT', 'AR', 'MX', 'ES'])[1 + i % 5],
       timestamptz '2025-01-01 00:00-03' + (i % 365) * interval '1 day'
FROM generate_series(1, 50000) AS i;

INSERT INTO orders (customer_id, status, total_cents, created_at)
SELECT 1 + (i * 7919::bigint) % 50000,
       (ARRAY['paid', 'paid', 'paid', 'shipped', 'cancelled'])[1 + i % 5],
       500 + (i * 37) % 50000,
       timestamptz '2026-01-01 00:00-03' + (i % 240) * interval '1 day'
                                         + (i % 86400) * interval '1 second'
FROM generate_series(1, 1000000) AS i;

ANALYZE;
```

**Nada nele é aleatório.** Todo valor é calculado a partir do número da linha: o cliente 7 sempre
mora em `AR`, o pedido 10 sempre pertence ao cliente 29.191. Isso é de propósito. Quando este curso
cita uma contagem, um tamanho ou um plano, seu servidor deve imprimir o mesmo, porque guarda as
mesmas linhas.

`GENERATED ALWAYS AS IDENTITY` é o jeito padrão de dizer "o banco numera estas linhas", e as duas
linhas `CREATE INDEX` dão a `orders` os índices de que uma aplicação precisaria para buscar os
pedidos de um cliente ou os da semana passada. O `ANALYZE` no fim coleta as estatísticas que o
planejador usa; a lição 16 é sobre o que acontece quando ninguém o roda.

Crie o banco e rode o arquivo dentro dele:

```
ana@db:~$ createdb shop
ana@db:~$ time psql shop -f shop.sql
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
INSERT 0 50000
INSERT 0 1000000
ANALYZE

real	0m13.972s
user	0m0.028s
sys	0m0.000s
```

O `psql` ecoa uma linha por comando, e as contagens são as linhas que cada `INSERT` criou. O `time`
é do shell, e a linha a ler é `real`: cerca de catorze segundos na máquina de gravação. O seu pode
demorar um pouco mais numa máquina virtual com dois processadores.

Agora pergunte ao banco o que ele guarda:

```
ana@db:~$ psql shop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
Type "help" for help.

shop=# \dt+
                                    List of relations
 Schema |   Name    | Type  | Owner | Persistence | Access method |  Size   | Description 
--------+-----------+-------+-------+-------------+---------------+---------+-------------
 public | customers | table | ana   | permanent   | heap          | 4576 kB | 
 public | orders    | table | ana   | permanent   | heap          | 65 MB   | 
(2 rows)

shop=# \di+
                                               List of relations
 Schema |        Name         | Type  | Owner |   Table   | Persistence | Access method |  Size   | Description 
--------+---------------------+-------+-------+-----------+-------------+---------------+---------+-------------
 public | customers_email_key | index | ana   | customers | permanent   | btree         | 4272 kB | 
 public | customers_pkey      | index | ana   | customers | permanent   | btree         | 1112 kB | 
 public | orders_created_at   | index | ana   | orders    | permanent   | btree         | 12 MB   | 
 public | orders_customer_id  | index | ana   | orders    | permanent   | btree         | 9408 kB | 
 public | orders_pkey         | index | ana   | orders    | permanent   | btree         | 21 MB   | 
(5 rows)

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)

shop=# \q
```

O `\dt+` lista as tabelas com seus tamanhos e o `\di+` os índices. **Os índices de `orders` somam
quase tanto quanto a própria tabela** — 12 MB, 9408 kB e 21 MB contra 65 MB —, o que é normal e vale
lembrar da próxima vez que alguém propuser um quinto índice. É o `+` que acrescenta a coluna `Size`;
sem ele os comandos só listam nomes.

Esse é o banco de que o resto do curso cuida. Se um dia quiser ele de volta exatamente como era,
apague-o e rode os mesmos dois comandos de novo:

```sh
dropdb shop
createdb shop
psql shop -f shop.sql
```
