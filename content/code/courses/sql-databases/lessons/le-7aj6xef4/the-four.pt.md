---
title: O que os quatro são de fato
version: 1
---

Onze aulas se passaram quase sem um nome de produto dentro delas. Isso não foi esquecimento. O
modelo relacional, `SELECT`, as junções, `GROUP BY`, transações, índices e o plano são um assunto
só, e o motor que roda isso é um detalhe em quase tudo.

Esta aula é sobre o resto — os lugares onde o motor deixa de ser um detalhe. São quatro aqui, e a
primeira coisa a acertar é o que cada um **é**, porque dois deles não são o mesmo tipo de coisa
que os outros dois.

## PostgreSQL

Um servidor de banco de dados, desenvolvido desde 1996 por um grupo distribuído de colaboradores
sem nenhuma empresa por trás, sob uma licença permissiva própria. É o mais rigoroso dos quatro
sobre o que aceita, o mais amplo no que consegue guardar, e o que tem um mecanismo de extensões em
cima do qual outros projetos são construídos — PostGIS para geografia, TimescaleDB para séries
temporais, `pgvector` para embeddings são todos Postgres com algo carregado dentro.

O nome se lê *post-gres-quiu-éle*, e o projeto atende por `postgres` em todo comando que você
digita, que é o que o resto desta aula usa.

## MySQL

Um servidor de banco de dados, lançado em 1995, comprado pela Sun em 2008 e, junto com a Sun, pela
Oracle em 2010. Tem licença dupla: GPL para a edição comunitária, e uma licença comercial para o
resto. É o motor por trás de uma parte enorme da web — WordPress, a maioria das hospedagens
compartilhadas, boa parte do que foi construído entre 2000 e 2015 — e essa base instalada é o
principal motivo pelo qual você vai encontrá-lo.

## MariaDB

O fork do MySQL que os autores originais começaram em 2009, quando a Oracle adquiriu a Sun. É GPL,
sem edição comercial do motor, e por vários anos foi um substituto direto: o mesmo protocolo, o
mesmo cliente, o mesmo SQL. Quinze anos de desenvolvimento separado afastaram os dois, e a seção
sobre o fork é sobre o quanto.

## SQLite

**Não é um servidor.** É uma biblioteca C contra a qual seu programa é ligado, e o banco é um
arquivo no disco. Não há processo para subir, porta para conectar, usuário para criar. Está em
domínio público, é o banco de dados mais instalado do mundo por uma margem enorme — todo celular
Android, todo iPhone, todo navegador, a maioria das aplicações de desktop — e é aquele cujo lugar
na lista é mais mal compreendido.

## A forma da comparação

Três dos quatro são servidores com quem você fala por um socket; um é uma biblioteca dentro do seu
processo. Dois dos servidores compartilham um ancestral e a maior parte de um dialeto; o terceiro
não.

| | PostgreSQL | MySQL | MariaDB | SQLite |
|---|---|---|---|---|
| o que é | servidor | servidor | servidor | biblioteca |
| primeiro lançamento | 1996 | 1995 | 2009 | 2000 |
| licença | licença PostgreSQL | GPL + comercial | GPL | domínio público |
| cuidado por | nenhum dono único | Oracle | MariaDB Foundation e MariaDB plc | nenhum dono único |
| motor de armazenamento padrão | o próprio | InnoDB | InnoDB | o próprio |

Tudo daqui em diante decorre dessa tabela. As versões contra as quais esta aula foi escrita são as
das transcrições: PostgreSQL 16.15, MySQL 8.0.46, MariaDB 10.11.14 e SQLite 3.45.1, cada um
rodando a loja da aula 1 — a pequena, com cinco clientes, e não o milhão de pedidos das aulas 9 a
11.

## Acompanhando

**Você não precisa dos outros três para acompanhar esta aula.** Cada comparação nela está impressa
a partir de cada motor, e a saída é o que importa. O seu PostgreSQL precisa da loja pequena de
volta — as três linhas da aula 1, `dropdb shop`, `createdb shop`, `psql shop -f shop.sql` — e só.

Se quiser rodar os outros, dois deles são um comando cada na sua máquina Ubuntu, e o terceiro
precisa de uma máquina só dele:

```sh
sudo apt install -y sqlite3        # SQLite 3.45
sudo apt install -y mysql-server   # MySQL 8.0
```

O MariaDB é `sudo apt install -y mariadb-server`, e ele **substitui** o MySQL em vez de ficar ao
lado: os pacotes do Ubuntu para os dois não podem ser instalados juntos. Instale-o numa segunda
máquina virtual — um clone da primeira, da aula 1, é o caminho mais rápido — ou depois de remover o
MySQL.

A loja então precisa ser escrita no dialeto de cada motor, que é metade do assunto desta aula. Para
o SQLite:

```sql
-- shop-sqlite.sql: lesson 1's shop, for SQLite.
-- Load it with:  sqlite3 shop.db < shop-sqlite.sql

CREATE TABLE customers (
    id     INTEGER PRIMARY KEY,
    name   TEXT    NOT NULL,
    email  TEXT    NOT NULL UNIQUE,
    city   TEXT
);

CREATE TABLE products (
    id     INTEGER PRIMARY KEY,
    sku    TEXT          NOT NULL UNIQUE,
    name   TEXT          NOT NULL,
    price  NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    ordered_on  TEXT    NOT NULL DEFAULT (date('now')),
    total       NUMERIC(10,2) NOT NULL CHECK (total >= 0),
    status      TEXT    NOT NULL DEFAULT 'placed'
                        CHECK (status IN ('placed', 'shipped', 'cancelled'))
);

CREATE TABLE order_lines (
    order_id   INTEGER NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO customers (name, email, city) VALUES
    ('Ana Ribeiro',  'ana@example.com',   'Recife'),
    ('Bruno Costa',  'bruno@example.com', 'Sao Paulo'),
    ('Carla Mendes', 'carla@example.com', 'Recife'),
    ('Diego Alves',  'diego@example.com', 'Curitiba'),
    ('Elisa Fontes', 'elisa@example.com', NULL);

INSERT INTO products (sku, name, price) VALUES
    ('KB-101', 'Mechanical keyboard',  349.90),
    ('MS-204', 'Wireless mouse',       189.00),
    ('MN-330', '27-inch monitor',     1499.00),
    ('CB-012', 'USB-C cable',           39.90);

INSERT INTO orders (customer_id, ordered_on, total) VALUES
    (1, '2026-03-02', 1499.00),
    (4, '2026-03-03', 2998.00),
    (1, '2026-03-04',  268.80),
    (1, '2026-03-09',  349.90);

INSERT INTO order_lines (order_id, product_id, quantity, unit_price) VALUES
    (1, 3, 1, 1499.00),
    (2, 3, 2, 1499.00),
    (3, 4, 2,   39.90),
    (3, 2, 1,  189.00),
    (4, 1, 1,  349.90);
```

E para o MySQL e o MariaDB, que dividem o mesmo:

```sql
-- shop-mysql.sql: lesson 1's shop, for MySQL and MariaDB.
-- Load it with:  sudo mysql -e 'CREATE DATABASE shop' && sudo mysql shop < shop-mysql.sql

CREATE TABLE customers (
    id     int          AUTO_INCREMENT PRIMARY KEY,
    name   varchar(120) NOT NULL,
    email  varchar(120) NOT NULL UNIQUE,
    city   varchar(120)
);

CREATE TABLE products (
    id     int           AUTO_INCREMENT PRIMARY KEY,
    sku    varchar(20)   NOT NULL UNIQUE,
    name   varchar(120)  NOT NULL,
    price  decimal(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          int           AUTO_INCREMENT PRIMARY KEY,
    customer_id int           NOT NULL,
    ordered_on  date          NOT NULL DEFAULT (curdate()),
    total       decimal(10,2) NOT NULL CHECK (total >= 0),
    status      varchar(10)   NOT NULL DEFAULT 'placed'
                              CHECK (status IN ('placed', 'shipped', 'cancelled')),
    FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
);

CREATE TABLE order_lines (
    order_id   int           NOT NULL,
    product_id int           NOT NULL,
    quantity   int           NOT NULL CHECK (quantity > 0),
    unit_price decimal(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders   (id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);

INSERT INTO customers (name, email, city) VALUES
    ('Ana Ribeiro',  'ana@example.com',   'Recife'),
    ('Bruno Costa',  'bruno@example.com', 'Sao Paulo'),
    ('Carla Mendes', 'carla@example.com', 'Recife'),
    ('Diego Alves',  'diego@example.com', 'Curitiba'),
    ('Elisa Fontes', 'elisa@example.com', NULL);

INSERT INTO products (sku, name, price) VALUES
    ('KB-101', 'Mechanical keyboard',  349.90),
    ('MS-204', 'Wireless mouse',       189.00),
    ('MN-330', '27-inch monitor',     1499.00),
    ('CB-012', 'USB-C cable',           39.90);

INSERT INTO orders (customer_id, ordered_on, total) VALUES
    (1, '2026-03-02', 1499.00),
    (4, '2026-03-03', 2998.00),
    (1, '2026-03-04',  268.80),
    (1, '2026-03-09',  349.90);

INSERT INTO order_lines (order_id, product_id, quantity, unit_price) VALUES
    (1, 3, 1, 1499.00),
    (2, 3, 2, 1499.00),
    (3, 4, 2,   39.90),
    (3, 2, 1,  189.00),
    (4, 1, 1,  349.90);
```

As linhas são os `INSERT`s da aula 1, sem mudança — são a parte portável. As transcrições do
`sqlite3` nesta aula são tiradas com `sqlite3 -column -header shop.db`, que desenha os
cabeçalhos, e as do `mysql` com `sudo mysql -t shop`, que desenha as caixas.

Existe um quinto motor que você vai encontrar num emprego corporativo, e ele é diferente o
bastante — no que custa, em como é comprado, e no que faz com a forma de um sistema — para ganhar
a aula 13 só para ele.
