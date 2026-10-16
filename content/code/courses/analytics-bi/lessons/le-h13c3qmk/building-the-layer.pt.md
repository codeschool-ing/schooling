---
title: Construindo a camada da Lantern
version: 1
---

A camada é um script, `semantic.sql`, e ela é só isso: um schema chamado `semantic`, uma tabelinha e
cinco views. Salve-o na máquina — `nano semantic.sql`, cole, Ctrl+O, Ctrl+X — e leia uma vez antes
de rodar, porque cada linha é uma decisão das aulas 1 e 2:

```sql
-- semantic.sql: the one place Lantern's definitions are written.
DROP SCHEMA IF EXISTS semantic CASCADE;
CREATE SCHEMA semantic;

CREATE TABLE semantic.state_region (
  state  text PRIMARY KEY,
  region text NOT NULL
);
INSERT INTO semantic.state_region VALUES
  ('SP', 'Southeast'), ('RJ', 'Southeast'), ('MG', 'Southeast'),
  ('PR', 'South'), ('RS', 'South'), ('BA', 'Northeast'), ('AC', 'North');

CREATE VIEW semantic.customers AS
SELECT c.customer_id, c.signed_up, c.state, r.region, c.segment,
       c.channel AS acquisition_channel
FROM shop.customers c
JOIN semantic.state_region r USING (state)
WHERE c.customer_id <> 1;

CREATE VIEW semantic.products AS
SELECT product_id, name AS product, category,
       (price_cents / 100.0)::numeric(10,2) AS list_price
FROM shop.products;

CREATE VIEW semantic.calendar AS
SELECT d::date AS day,
       extract(isodow FROM d)::int AS weekday,
       date_trunc('month', d)::date AS month,
       d < date '2026-06-01' AS month_is_complete
FROM generate_series(date '2025-01-01', date '2026-06-30', interval '1 day') AS d;

CREATE VIEW semantic.order_lines AS
SELECT l.order_id, l.line_no, l.product_id, l.quantity,
       (l.quantity * CASE WHEN l.unit_cents = p.price_cents * 100 THEN p.price_cents
                          ELSE l.unit_cents END / 100.0)::numeric(12,2) AS line_value
FROM shop.order_lines l
JOIN shop.products p USING (product_id)
JOIN shop.orders o USING (order_id)
WHERE o.customer_id <> 1;

CREATE VIEW semantic.orders AS
WITH t AS (SELECT order_id, sum(line_value) AS gross FROM semantic.order_lines GROUP BY order_id)
SELECT o.order_id, o.customer_id,
       (o.ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS order_date,
       o.status, t.gross::numeric(12,2) AS gross,
       (floor(t.gross * o.discount_pct) / 100)::numeric(12,2) AS discount,
       (CASE WHEN o.status = 'paid' THEN t.gross - floor(t.gross * o.discount_pct) / 100
             ELSE 0 END)::numeric(12,2) AS net_revenue
FROM shop.orders o
JOIN t USING (order_id);

COMMENT ON VIEW semantic.orders IS
'One row per order, without the test account. Money in reais.';
COMMENT ON COLUMN semantic.orders.order_date IS
'The day the order was placed, in São Paulo, whatever the session''s time zone.';
COMMENT ON COLUMN semantic.orders.net_revenue IS
'Net revenue: gross minus discount for paid orders, zero for refunded ones. Sum it.';
COMMENT ON VIEW semantic.order_lines IS
'One row per product in an order, without the test account. A line priced at 100 times
the list price, a known fault of an import, is counted at the list price until the
source is fixed.';
```

O que cada peça traz:

| peça | a decisão que ela escreve | de onde |
|---|---|---|
| `state_region` | a que região cada estado pertence, como linhas em vez de um `CASE` na consulta de alguém | aula 2 |
| `customers` | a conta de teste não existe; `channel` vira `acquisition_channel` | aulas 1 e 2 |
| `order_lines` | uma linha com preço 100 vezes o de tabela conta pelo preço de tabela | aula 1 |
| `orders` | o dia é o de São Paulo, diga o que disser a sessão; descontos arredondados para baixo; pedido estornado não traz receita | aula 2 |
| os comentários | o que um leitor precisa para usar cada view, guardado onde toda ferramenta mostra | aula 2 |

O dinheiro aqui está em reais e não em centavos, como `numeric`, que soma exato: a camada é para
leitura, e `142.90` é o que uma pessoa espera ver. A correção das linhas com preço errado é o tipo
de coisa para que uma camada serve e o tipo de coisa que ela deve dizer em voz alta, e por isso o
comentário dela diz: é um defeito conhecido, corrigido num lugar só, até a carga que o produziu ser
consertada.

Rode:

```
ana@vm:~$ psql -q lantern -f semantic.sql
psql:semantic.sql:2: NOTICE:  schema "semantic" does not exist, skipping
```

O aviso é o script apagando um schema que ainda não existe, como o `lantern.sql` fez na primeira
vez. O que foi construído:

```
lantern=# \dv semantic.*
           List of relations
  Schema  |    Name     | Type | Owner 
----------+-------------+------+-------
 semantic | calendar    | view | ana
 semantic | customers   | view | ana
 semantic | order_lines | view | ana
 semantic | orders      | view | ana
 semantic | products    | view | ana
(5 rows)
```

Cinco views. `state_region` é uma tabela, então o `\dv` não a lista — o `\dt semantic.*` lista.

**Rodar o `lantern.sql` de novo destrói as views.** As views leem das tabelas de `shop`, e apagar
`shop` com `CASCADE` apaga tudo o que depende dele, inclusive em outros schemas. Então, depois de
reiniciar, rode o `semantic.sql` de novo também, e depois os grants de três seções adiante.
