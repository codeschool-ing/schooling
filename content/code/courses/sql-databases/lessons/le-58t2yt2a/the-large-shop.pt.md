---
title: Uma loja que vale a pena indexar
version: 1
---

Um índice é invisível contra cinco clientes. Toda consulta na loja da aula 1 volta antes que dê para
medir, o que era o certo enquanto o assunto era o que um join significa, e esconde tudo de que esta
aula trata. Então esta aula e as duas seguintes rodam contra a mesma loja com **um milhão de
pedidos**.

Ninguém digita um milhão de pedidos. Este arquivo os inventa — nomes sorteados de duas listas
curtas, endereços numerados de `user1@example.com` em diante, preços e datas sorteados — a partir
de uma semente fixa, então a sua loja e a das transcrições são as mesmas linhas:

```sql
-- shop-large.sql: the shop of lessons 9 to 11, with a million orders in it.
-- Every row is made up here, from a fixed seed, so two runs make the same shop.
-- Load it into an empty database:  psql shop -f shop-large.sql
SELECT setseed(0.42);

CREATE TABLE customers (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name   text NOT NULL,
    email  text NOT NULL UNIQUE,
    city   text
);

CREATE TABLE products (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku    text          NOT NULL UNIQUE,
    name   text          NOT NULL,
    price  numeric(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer       NOT NULL REFERENCES customers (id),
    placed_at   timestamptz   NOT NULL,
    total       numeric(10,2) NOT NULL CHECK (total >= 0),
    status      text          NOT NULL
);

CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products (id),
    quantity   integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

-- 100,000 customers: a first name and a surname drawn from ten each, an
-- address that is unique by construction, and one of ten cities.
INSERT INTO customers (name, email, city)
SELECT (ARRAY['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa',
              'Fábio', 'Helena', 'Igor', 'Júlia', 'Marcos'])[1 + floor(random() * 10)]
       || ' ' ||
       (ARRAY['Alves', 'Carvalho', 'Costa', 'Fontes', 'Lima',
              'Mendes', 'Oliveira', 'Ribeiro', 'Rocha', 'Santos'])[1 + floor(random() * 10)],
       'user' || n || '@example.com',
       (ARRAY['Belem', 'Belo Horizonte', 'Curitiba', 'Fortaleza', 'Manaus',
              'Porto Alegre', 'Recife', 'Rio de Janeiro', 'Salvador', 'Sao Paulo'])[1 + floor(random() * 10)]
FROM generate_series(1, 100000) AS n;

-- 1,000 products at prices between 5 and 1,000.
INSERT INTO products (sku, name, price)
SELECT 'P-' || lpad(n::text, 4, '0'), 'Product ' || n, round((5 + random() * 995)::numeric, 2)
FROM generate_series(1, 1000) AS n;

-- 1,000,000 orders over 1,000 days from 2023, more of them as the shop grows.
-- Six in ten are paid, three shipped, one cancelled, and a few still pending.
-- total is drawn on its own rather than added up from the lines: these rows
-- exist to be counted and planned, and nothing in lessons 9 to 11 adds them.
INSERT INTO orders (customer_id, placed_at, total, status)
SELECT 1 + floor(random() * 100000),
       timestamptz '2023-01-01 00:00+00' + sqrt(random()) * interval '1000 days',
       round((10 + random() * 990)::numeric, 2),
       CASE WHEN s < 0.600 THEN 'paid'
            WHEN s < 0.897 THEN 'shipped'
            WHEN s < 0.997 THEN 'cancelled'
            ELSE 'pending' END
FROM (SELECT random() AS s FROM generate_series(1, 1000000)) AS draw;

-- One to four lines an order, two and a half on average, each a different product.
INSERT INTO order_lines (order_id, product_id, quantity, unit_price)
SELECT o.id, p.id, 1 + (o.id + k) % 3, p.price
FROM orders AS o
CROSS JOIN generate_series(1, 1 + o.id % 4) AS k
JOIN products AS p ON p.id = 1 + (o.id * 37 + k * 729) % 1000;

-- The two indexes lesson 9 builds its argument on. Nothing on customer_id yet.
CREATE INDEX ON orders (status);
CREATE INDEX ON orders (placed_at);

VACUUM ANALYZE;
```

Três coisas diferem das tabelas da aula 1, e cada uma é de propósito. `orders` tem **`placed_at
timestamptz`** onde a loja pequena tinha `ordered_on date`, porque nesse tamanho um momento importa
e um dia não. **Não há índice em `orders.customer_id`** — a aula 10 o cria e mede o que ele compra.
E `status` tem quatro valores, um deles raro — `pending`, uns três pedidos em mil —, porque a aula
10 precisa de um valor para o qual vale a pena usar um índice e de um para o qual não vale.

## Carregando

Salve como `shop-large.sql` e carregue num `shop` vazio. Isso substitui a loja pequena, que a aula
12 traz de volta:

```
ana@vm:~$ dropdb shop
ana@vm:~$ createdb shop
ana@vm:~$ psql shop -f shop-large.sql
 setseed 
---------
 
(1 row)

CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 100000
INSERT 0 1000
INSERT 0 1000000
INSERT 0 2500000
CREATE INDEX
CREATE INDEX
VACUUM
```

A linha do `setseed` responde com uma linha vazia, que é ela concordando. O resto é um ou dois
minutos de espera — o último `INSERT` escreve dois milhões e meio de linhas e o `VACUUM ANALYZE` lê
todas de volta — e então isto é o que você tem:

```
ana@vm:~$ psql shop -c "SELECT status, count(*) FROM orders GROUP BY status ORDER BY count(*) DESC"
  status   | count  
-----------+--------
 paid      | 600048
 shipped   | 296744
 cancelled | 100285
 pending   |   2923
(4 rows)

ana@vm:~$ psql shop -c "SELECT count(*) AS order_lines FROM order_lines"
 order_lines 
-------------
     2500000
(1 row)

ana@vm:~$ psql shop -c "SELECT pg_size_pretty(pg_database_size('shop')) AS size"
  size  
--------
 311 MB
(1 row)
```

Um milhão de pedidos em quatro situações, dois milhões e meio de linhas, e **311 MB** em disco, que
é quanto a máquina virtual da aula 1 cresce.

> **O prompt e a loja.** Daqui até o fim da aula 11, `shop=#` é este banco. A aula 12 volta para a
> loja pequena com as três linhas do fim da aula 1.
