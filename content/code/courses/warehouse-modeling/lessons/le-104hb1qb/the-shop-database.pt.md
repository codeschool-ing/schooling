---
title: O banco da rede
version: 1
---

O PostgreSQL está rodando e ainda não conhece ninguém. Três comandos o tornam seu: um papel com o seu
nome de login, um banco chamado `shop` e quatro configurações.

```
ana@lab:~/wh$ sudo -u postgres createuser --superuser $USER
ana@lab:~/wh$ createdb --locale=C.UTF-8 --template=template0 shop
ana@lab:~/wh$ psql -c "ALTER SYSTEM SET timezone = 'America/Sao_Paulo'" -c "ALTER SYSTEM SET shared_buffers = '512MB'" -c "ALTER SYSTEM SET max_parallel_workers_per_gather = 0" -c "ALTER SYSTEM SET jit = off"
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
```

O PostgreSQL do Ubuntu confia no sistema operacional para dizer quem você é, então um papel com o
nome do seu login não precisa de senha. `--superuser` deixa esse papel mudar as configurações do
servidor, que é o que o terceiro comando faz. `--locale=C.UTF-8` faz o texto ser ordenado pelos
bytes, igual em qualquer máquina, para que uma lista ordenada por nome saia na ordem das transcrições.

As quatro configurações fazem o seu servidor se comportar como aquele em que o curso foi gravado.
`timezone` imprime os horários no fuso de São Paulo. `shared_buffers` dá ao PostgreSQL 512 MB de
memória para guardar páginas, e as tabelas mais movimentadas da rede cabem nela. As duas últimas
desligam os processos paralelos e a compilação just-in-time: a lição 1 lê um plano de consulta com
um processo só, a lição 7 cronometra um, e os dois ficam mais claros sem elas. **A configuração de
memória só vale quando o servidor reinicia**, então:

```
ana@lab:~/wh$ sudo pg_ctlcluster 16 main restart
ana@lab:~/wh$ psql -c 'SHOW shared_buffers'
 shared_buffers 
----------------
 512MB
(1 row)
```

## O esquema

Este é o banco da rede inteiro: quinze tabelas, as chaves entre elas e os índices de que os caixas e
o site precisam. Salve-o como `~/wh/oltp.sql`.

```sql
-- The operational database of Ponto Final: what the tills and the website
-- write to, one transaction at a time. Third normal form, keys enforced, and
-- the CURRENT state of everything: a customer's city is where they live now,
-- a book's price is what it costs today.

CREATE TABLE shops (
    shop_id    integer PRIMARY KEY,
    name       text NOT NULL,
    city       text,
    state      char(2),
    channel    text NOT NULL CHECK (channel IN ('store', 'online')),
    opened_on  date NOT NULL
);

CREATE TABLE categories (
    category_id integer PRIMARY KEY,
    name        text NOT NULL,
    parent_id   integer REFERENCES categories
);

CREATE TABLE publishers (
    publisher_id integer PRIMARY KEY,
    name         text NOT NULL
);

CREATE TABLE authors (
    author_id integer PRIMARY KEY,
    name      text NOT NULL,
    country   char(2) NOT NULL
);

CREATE TABLE books (
    book_id          integer PRIMARY KEY,
    isbn             char(13) NOT NULL UNIQUE,
    title            text NOT NULL,
    category_id      integer NOT NULL REFERENCES categories,
    publisher_id     integer NOT NULL REFERENCES publishers,
    format           text NOT NULL CHECK (format IN ('paperback', 'hardcover', 'ebook')),
    list_price_cents integer NOT NULL CHECK (list_price_cents > 0),
    published_on     date NOT NULL
);

CREATE TABLE book_authors (
    book_id   integer NOT NULL REFERENCES books,
    author_id integer NOT NULL REFERENCES authors,
    position  smallint NOT NULL,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    email       text NOT NULL UNIQUE,
    name        text NOT NULL,
    city        text NOT NULL,
    state       char(2) NOT NULL,
    tier        text NOT NULL CHECK (tier IN ('reader', 'regular', 'patron')),
    created_at  timestamptz NOT NULL,
    updated_at  timestamptz NOT NULL
);

-- Written by the application beside every UPDATE of a customer, because the
-- row itself only remembers the latest value.
CREATE TABLE customer_changes (
    change_id   bigint PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers,
    changed_at  timestamptz NOT NULL,
    field       text NOT NULL,
    old_value   text NOT NULL,
    new_value   text NOT NULL
);

CREATE TABLE promotions (
    promotion_id integer PRIMARY KEY,
    code         text NOT NULL UNIQUE,
    name         text NOT NULL,
    percent_off  integer NOT NULL,
    starts_on    date NOT NULL,
    ends_on      date NOT NULL,
    category     text
);

CREATE TABLE orders (
    order_id       bigint PRIMARY KEY,
    shop_id        integer NOT NULL REFERENCES shops,
    customer_id    integer REFERENCES customers,
    ordered_at     timestamptz NOT NULL,
    status         text NOT NULL,
    shipping_cents integer NOT NULL DEFAULT 0,
    paid_at        timestamptz,
    shipped_at     timestamptz,
    delivered_at   timestamptz
);

CREATE TABLE order_lines (
    order_id         bigint NOT NULL REFERENCES orders,
    line_no          smallint NOT NULL,
    book_id          integer NOT NULL REFERENCES books,
    quantity         smallint NOT NULL CHECK (quantity > 0),
    unit_price_cents integer NOT NULL,
    discount_cents   integer NOT NULL DEFAULT 0,
    promotion_id     integer REFERENCES promotions,
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE payments (
    payment_id   bigint PRIMARY KEY,
    order_id     bigint NOT NULL REFERENCES orders,
    method       text NOT NULL,
    installments smallint NOT NULL,
    amount_cents integer NOT NULL
);

-- The count somebody makes at the end of every month, shelf by shelf.
CREATE TABLE stock_counts (
    count_date date NOT NULL,
    shop_id    integer NOT NULL REFERENCES shops,
    book_id    integer NOT NULL REFERENCES books,
    on_hand    integer NOT NULL,
    PRIMARY KEY (count_date, shop_id, book_id)
);

CREATE TABLE events (
    event_id  integer PRIMARY KEY,
    shop_id   integer NOT NULL REFERENCES shops,
    author_id integer NOT NULL REFERENCES authors,
    held_on   date NOT NULL
);

CREATE TABLE event_attendance (
    event_id    integer NOT NULL REFERENCES events,
    customer_id integer NOT NULL REFERENCES customers,
    PRIMARY KEY (event_id, customer_id)
);

CREATE INDEX ON orders (customer_id);
CREATE INDEX ON orders (ordered_at);
CREATE INDEX ON order_lines (book_id);
CREATE INDEX ON payments (order_id);
CREATE INDEX ON customer_changes (customer_id);
```

É o formato que `sql-databases` constrói, e o resto do curso discute com ele. Duas tabelas merecem
atenção desde já. `customers` guarda onde cada cliente mora *agora*, e `books` guarda quanto um livro
custa *hoje*; a história dos dois só sobrevive porque a aplicação escreve em `customer_changes` a cada
atualização, e porque a linha de um pedido guarda o preço pelo qual o livro foi vendido. A seção 11
volta aos dois.

```
ana@lab:~/wh$ psql -q -f oltp.sql
ana@lab:~/wh$ psql -c '\dt'
             List of relations
 Schema |       Name       | Type  | Owner 
--------+------------------+-------+-------
 public | authors          | table | ana
 public | book_authors     | table | ana
 public | books            | table | ana
 public | categories       | table | ana
 public | customer_changes | table | ana
 public | customers        | table | ana
 public | event_attendance | table | ana
 public | events           | table | ana
 public | order_lines      | table | ana
 public | orders           | table | ana
 public | payments         | table | ana
 public | promotions       | table | ana
 public | publishers       | table | ana
 public | shops            | table | ana
 public | stock_counts     | table | ana
(15 rows)
```

Quinze tabelas, todas vazias. A próxima seção as enche.
