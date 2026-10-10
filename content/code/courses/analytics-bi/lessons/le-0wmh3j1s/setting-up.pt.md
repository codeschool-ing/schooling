---
title: Instalando o PostgreSQL e carregando a loja
version: 1
---

Conectado à sua máquina, veja se o PostgreSQL já está lá:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Se os dois responderem assim, e o `psql` já deixar você entrar como você mesmo — vai deixar, na
máquina que `sql-databases` montou —, vá direto ao banco abaixo. Se o `psql` não for encontrado,
instale o servidor e dê a si mesmo um papel no banco com o seu nome:

```sh
sudo apt update
sudo apt install -y postgresql
sudo -u postgres createuser --superuser $USER
```

O `createuser` não imprime nada quando dá certo. `--superuser` deixa o seu papel fazer qualquer
coisa neste servidor, o que é certo numa máquina que é só sua, e errado em qualquer outro lugar.

## O banco da loja

Um servidor guarda muitos bancos, e este curso usa um chamado `lantern`:

```
ana@vm:~$ createdb lantern
```

A loja é o script abaixo. Abra um editor na máquina — `nano lantern.sql` —, cole o bloco inteiro,
salve com Ctrl+O e saia com Ctrl+X. Não precisa lê-lo hoje: toda tabela dele é apresentada nas
próximas seções, e as linhas que plantam os defeitos são o que o resto desta aula encontra.

```sql
-- lantern.sql: Lantern Coffee, a roastery in São Paulo that sells online.
-- Every row is generated, and the seed makes it the same rows on every run.
DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA shop;
SET search_path = shop;
SET seed TO 0.2025;

CREATE TABLE products (
  product_id  int PRIMARY KEY,
  name        text NOT NULL,
  category    text NOT NULL,
  price_cents int  NOT NULL
);
INSERT INTO products VALUES
  ( 1, 'Daily Blend 250 g',         'beans',     3490),
  ( 2, 'Daily Blend 1 kg',          'beans',    11990),
  ( 3, 'Cerrado Single Origin 250 g','beans',    4590),
  ( 4, 'Sul de Minas 250 g',        'beans',     4790),
  ( 5, 'Decaf 250 g',               'beans',     3990),
  ( 6, 'Espresso Roast 1 kg',       'beans',    12990),
  ( 7, 'Ground Daily Blend 250 g',  'ground',    3290),
  ( 8, 'Ground Espresso 250 g',     'ground',    3490),
  ( 9, 'Paper Filters x100',        'accessory', 1590),
  (10, 'Pour-over Dripper',         'equipment', 8900),
  (11, 'Hand Grinder',              'equipment',24900),
  (12, 'Travel Mug',                'equipment', 6900);

-- 2,400 customers who arrived over eighteen months, more of them each month,
-- and 250 more in the Black Friday campaign of November 2025.
CREATE TABLE customers AS
WITH d AS MATERIALIZED (
  SELECT id, random() AS r_day, random() AS r_state, random() AS r_channel,
         random() AS r_segment
  FROM generate_series(1, 2650) AS id ORDER BY id
)
SELECT id AS customer_id,
       CASE WHEN id <= 2400 THEN date '2025-01-01' + floor(533 * sqrt(r_day))::int
            ELSE date '2025-11-24' + floor(7 * r_day)::int END AS signed_up,
       CASE WHEN r_state < 0.46 THEN 'SP' WHEN r_state < 0.62 THEN 'RJ'
            WHEN r_state < 0.75 THEN 'MG' WHEN r_state < 0.84 THEN 'PR'
            WHEN r_state < 0.92 THEN 'RS' WHEN r_state < 0.996 THEN 'BA'
            ELSE 'AC' END AS state,
       CASE WHEN id > 2400 THEN 'social'
            WHEN r_channel < 0.40 THEN 'search' WHEN r_channel < 0.65 THEN 'social'
            WHEN r_channel < 0.85 THEN 'referral' ELSE 'email' END AS channel,
       CASE WHEN id > 2400 OR r_segment < 0.92 THEN 'home' ELSE 'office' END AS segment
FROM d;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);
UPDATE customers SET state = 'SP', channel = 'email', segment = 'home',
       signed_up = date '2025-01-02' WHERE customer_id = 1;  -- the shop's own test account

-- Each customer orders again after a gap until they stop; how soon they stop
-- depends on who they are.
CREATE TABLE orders AS
WITH d AS MATERIALIZED (
  SELECT c.customer_id, c.signed_up, c.segment, k,
         CASE WHEN c.customer_id > 2400 THEN 0.62
              WHEN c.segment = 'office' THEN 0.10
              WHEN c.channel = 'referral' THEN 0.17
              ELSE 0.27 END AS p_stop,
         random() AS r_stop, random() AS r_gap, random() AS r_hour, random() AS r_sun,
         random() AS r_status, random() AS r_coupon
  FROM customers c CROSS JOIN generate_series(1, 40) AS k
  ORDER BY c.customer_id, k
), s AS (
  SELECT *,
         bool_and(k = 1 OR r_stop > p_stop) OVER w AS still_buying,
         sum(CASE WHEN k = 1 THEN 0 ELSE 9 + floor(-ln(1 - r_gap) * 30) END) OVER w AS day_n
  FROM d
  WINDOW w AS (PARTITION BY customer_id ORDER BY k)
), t AS (
  SELECT *, signed_up + day_n::int AS day0 FROM s WHERE still_buying
)
SELECT row_number() OVER (ORDER BY day, customer_id, k)::int AS order_id,
       customer_id,
       ((day + make_interval(mins => floor(420 + 1019 * sqrt(r_hour))::int))
          AT TIME ZONE 'America/Sao_Paulo') AS ordered_at,
       CASE WHEN r_status < 0.04 THEN 'refunded' ELSE 'paid' END AS status,
       CASE WHEN segment = 'office' THEN 15
            WHEN k = 1 AND r_coupon < 0.45 THEN 10
            WHEN r_coupon < 0.08 THEN 5 ELSE 0 END AS discount_pct
FROM (SELECT *, CASE WHEN extract(dow FROM day0) = 0 AND r_sun < 0.45
                     THEN day0 + 1 ELSE day0 END AS day FROM t) AS u
WHERE day <= date '2026-06-17'
  AND day <> date '2025-08-14';   -- the extract for that day never arrived
ALTER TABLE orders ADD PRIMARY KEY (order_id);

CREATE TABLE order_lines AS
WITH d AS MATERIALIZED (
  SELECT o.order_id, o.customer_id, c.segment, n, random() AS r_product, random() AS r_qty
  FROM orders o JOIN customers c USING (customer_id)
  CROSS JOIN LATERAL generate_series(1, 1 + (o.order_id * 7 % 10 < 4)::int
                                         + (o.order_id * 3 % 10 < 2)::int) AS n
  ORDER BY o.order_id, n
)
SELECT d.order_id, d.n AS line_no, p.product_id,
       CASE WHEN d.customer_id = 1 THEN 1
            WHEN d.segment = 'office' THEN 3 + floor(12 * r_qty * r_qty)::int
            WHEN r_qty < 0.8 THEN 1 ELSE 2 END AS quantity,
       CASE WHEN d.customer_id = 1 THEN 1 ELSE p.price_cents END AS unit_cents
FROM d JOIN products p
  ON p.product_id = CASE WHEN d.customer_id = 1 THEN 1
                         WHEN r_product < 0.24 THEN 1 WHEN r_product < 0.34 THEN 2
                         WHEN r_product < 0.46 THEN 3 WHEN r_product < 0.56 THEN 4
                         WHEN r_product < 0.62 THEN 5 WHEN r_product < 0.70 THEN 6
                         WHEN r_product < 0.78 THEN 7 WHEN r_product < 0.84 THEN 8
                         WHEN r_product < 0.92 THEN 9 WHEN r_product < 0.96 THEN 10
                         WHEN r_product < 0.98 THEN 11 ELSE 12 END;
ALTER TABLE order_lines ADD PRIMARY KEY (order_id, line_no);
-- Three lines written by the March 2025 import with the price in cents twice.
UPDATE order_lines SET unit_cents = unit_cents * 100
 WHERE line_no = 1 AND order_id IN (412, 415, 431);

-- Visits to the shop's website, and how far down the way to a purchase each got.
CREATE TABLE web_sessions AS
WITH d AS MATERIALIZED (
  SELECT id, random() AS r_day, random() AS r_channel, random() AS r_device,
         random() AS r1, random() AS r2, random() AS r3, random() AS r4, random() AS r_min
  FROM generate_series(1, 60000) AS id ORDER BY id
), s AS (
  SELECT *, date '2025-01-01' + floor(533 * sqrt(r_day))::int AS day FROM d
), c AS (
  SELECT *,
         CASE WHEN day < date '2026-01-01' THEN
                CASE WHEN r_channel < 0.42 THEN 'search' WHEN r_channel < 0.60 THEN 'social'
                     WHEN r_channel < 0.82 THEN 'referral' ELSE 'email' END
              ELSE
                CASE WHEN r_channel < 0.22 THEN 'search' WHEN r_channel < 0.74 THEN 'social'
                     WHEN r_channel < 0.87 THEN 'referral' ELSE 'email' END
         END AS channel
  FROM s
), v AS (
  SELECT *, CASE WHEN r_device < (CASE WHEN channel = 'social' THEN 0.90 ELSE 0.45 END)
                 THEN 'mobile' ELSE 'desktop' END AS device,
            (day >= date '2026-01-01')::int AS new_checkout
  FROM c
)
SELECT id AS session_id,
       ((day + make_interval(mins => floor(1439 * r_min)::int)) AT TIME ZONE 'America/Sao_Paulo') AS started_at,
       channel, device,
       1 + (r1 < CASE device WHEN 'mobile' THEN 0.42 ELSE 0.58 END)::int
         + (r1 < CASE device WHEN 'mobile' THEN 0.42 ELSE 0.58 END
            AND r2 < CASE device WHEN 'mobile' THEN 0.30 ELSE 0.40 END)::int
         + (r1 < CASE device WHEN 'mobile' THEN 0.42 ELSE 0.58 END
            AND r2 < CASE device WHEN 'mobile' THEN 0.30 ELSE 0.40 END
            AND r3 < CASE device WHEN 'mobile' THEN 0.50 ELSE 0.62 END + 0.04 * new_checkout)::int
         + (r1 < CASE device WHEN 'mobile' THEN 0.42 ELSE 0.58 END
            AND r2 < CASE device WHEN 'mobile' THEN 0.30 ELSE 0.40 END
            AND r3 < CASE device WHEN 'mobile' THEN 0.50 ELSE 0.62 END + 0.04 * new_checkout
            AND r4 < CASE device WHEN 'mobile' THEN 0.62 ELSE 0.78 END + 0.03 * new_checkout)::int
         AS steps
FROM v;
ALTER TABLE web_sessions ADD PRIMARY KEY (session_id);

CREATE TABLE web_events AS
SELECT s.session_id,
       s.started_at + make_interval(mins => 2 * (e.step - 1)) AS happened_at,
       (ARRAY['visit','product_view','add_to_cart','checkout','purchase'])[e.step] AS event
FROM web_sessions s CROSS JOIN LATERAL generate_series(1, s.steps) AS e(step);

SELECT 'products' AS "table", count(*) AS "rows" FROM products
UNION ALL SELECT 'customers', count(*) FROM customers
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'order_lines', count(*) FROM order_lines
UNION ALL SELECT 'web_events', count(*) FROM web_events;
```

Rode. O `-q` impede o `psql` de anunciar cada instrução, então o que sobra é um aviso e a tabela
com que o script termina:

```
ana@vm:~$ psql -q lantern -f lantern.sql
psql:lantern.sql:3: NOTICE:  schema "shop" does not exist, skipping
    table    |  rows  
-------------+--------
 products    |     12
 customers   |   2650
 orders      |   7102
 order_lines |  11362
 web_events  | 108987
(5 rows)
```

Um `NOTICE` não é erro. O script começa apagando o que uma execução anterior deixou, e na
primeira vez não há nada para apagar. **Compare as cinco contagens com as suas.** Se uma for
diferente, o script que você colou não é o script acima — uma linha perdida no caminho é o motivo
de sempre — e todo número do curso vai diferir junto.

## Duas configurações que fazem toda transcrição bater

A loja fica em São Paulo, e os timestamps dela significam o horário de São Paulo. O relógio da
sua máquina provavelmente está em UTC, que é o que o instalador do Ubuntu deixa, e um timestamp
impresso em UTC mostra um pedido feito às 22:00 de uma terça como quarta. Então diga ao banco onde
ele mora, e em que schema procurar primeiro, para que `orders` signifique `shop.orders` sem
prefixo:

```sql
ALTER DATABASE lantern SET timezone TO 'America/Sao_Paulo';
ALTER DATABASE lantern SET search_path TO shop, public;
```

Digite as duas no `psql lantern`. Uma configuração do banco vale para toda sessão aberta
**depois** dela, então saia com `\q`, volte e pergunte:

```
ana@vm:~$ psql lantern
lantern=# SHOW timezone;
     TimeZone      
-------------------
 America/Sao_Paulo
(1 row)

lantern=# SHOW search_path;
 search_path  
--------------
 shop, public
(1 row)
```

**Rodar o script de novo recomeça a loja.** Ele apaga o schema `shop` com tudo dentro, inclusive
o que você tiver criado ali, e constrói as mesmas linhas:

```
ana@vm:~$ psql -q lantern -f lantern.sql
psql:lantern.sql:3: NOTICE:  drop cascades to 6 other objects
DETAIL:  drop cascades to table products
drop cascades to table customers
drop cascades to table orders
drop cascades to table order_lines
drop cascades to table web_sessions
drop cascades to table web_events
    table    |  rows  
-------------+--------
 products    |     12
 customers   |   2650
 orders      |   7102
 order_lines |  11362
 web_events  | 108987
(5 rows)
```

É um botão de reiniciar, e você vai querê-lo no dia em que uma consulta sua mudar dados que ela só
deveria ter lido. As duas configurações pertencem ao banco, e não ao schema, então sobrevivem.
