---
title: A feed for a processor
version: 1
---

Ipê hires **Rota Certa**, a delivery company, to plan and run its routes in São Paulo and Rio. Every
morning Rota Certa needs the previous day's orders: how many parcels, going where. Under the LGPD Rota
Certa is a **processor** — it handles personal data on Ipê's behalf and following Ipê's instructions
(article 39) — and Ipê, the controller, answers for what it hands over. The GDPR makes the same
relationship require a written contract (article 28); the LGPD expects the instructions to be clear
enough to follow.

The feed is a view that exposes exactly what route planning needs:

```sql
-- What Rota Certa, the delivery company, receives every morning: enough to
-- plan routes, and nothing that names anybody. The labels with names are
-- printed in the shop, not sent in the feed.
CREATE ROLE rota_certa NOLOGIN;
SET ROLE ipe_owner;
CREATE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT sum(i.quantity) FROM sales.order_items i WHERE i.order_id = o.order_id) AS items
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
GRANT USAGE ON SCHEMA share TO rota_certa;
GRANT SELECT ON share.delivery_feed TO rota_certa;
```

Three decisions are in it, and each one is lesson material from earlier:

- **no name, no e-mail.** Planning a route needs the CEP, the city and the number of parcels. The
  driver needs a name on the parcel, and that is printed on the label in the shop. Sending names in a
  file every morning would be sending them to one more company, every day, for nothing — the
  necessity principle of lesson 7;
- **a role that can read the view and nothing else** — lesson 2's least privilege, now for a
  company instead of a person;
- **the order number stays**, because Rota Certa has to tell Ipê which parcel is which. In Ipê's hands
  it is personal data, since Ipê can join it to a customer, and the contract classifies it so.

## The contract

```json
{
  "contract": "delivery-feed",
  "version": "1.0.0",
  "owner": "head of sales",
  "consumer": "Rota Certa Logística, a processor (LGPD art. 39)",
  "purpose": "planning the next day's delivery routes",
  "basis": "LGPD art. 7, V: delivering what the customer bought",
  "kept_by_consumer": "30 days",
  "stays_in": "Brazil",
  "fresh_by": "06:00 every day, with the orders of the day before",
  "relation": "share.delivery_feed",
  "fields": [
    {"name": "order_id",   "type": "integer",   "class": "personal", "source": "sales.orders.order_id"},
    {"name": "ordered_on", "type": "date",      "class": "personal", "source": "sales.orders.ordered_at"},
    {"name": "cep",        "type": "text",      "class": "personal", "source": "sales.customers.cep"},
    {"name": "city",       "type": "text",      "class": "personal", "source": "sales.customers.city"},
    {"name": "state",      "type": "character", "class": "personal", "source": "sales.customers.state"},
    {"name": "items",      "type": "bigint",    "class": "none",     "source": "a count of sales.order_items"}
  ],
  "quality": [
    {"rule": "every cep has the shape 00000-000",
     "sql": "SELECT count(*) FROM share.delivery_feed WHERE cep !~ '^[0-9]{5}-[0-9]{3}$'"},
    {"rule": "every order has at least one item",
     "sql": "SELECT count(*) FROM share.delivery_feed WHERE items IS NULL OR items < 1"}
  ]
}
```

Next to the schema, the contract records **who** the consumer is and in what capacity, **why** the
data is sent and on which basis, **how long** the consumer keeps it, and **where** it stays — the same
facts lesson 7's record of processing needs and lesson 8's transfer rules ask for. Each field names its
**source** column and **class**, and the class is not a fresh opinion: it has to match
`gov.column_class`, which the checker verifies.

```
ana@lab:~/gov$ sudo -u postgres psql -c "CREATE SCHEMA share AUTHORIZATION ipe_owner"
CREATE SCHEMA
ana@lab:~/gov$ psql -f feed.sql
CREATE ROLE
SET
CREATE VIEW
GRANT
GRANT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders, sum(items) AS items FROM share.delivery_feed"
SET
 orders | items 
--------+-------
    119 |   251
(1 row)

ana@lab:~/gov$ python3 check_contract.py delivery-feed.v1.json; echo "exit $?"
delivery-feed 1.0.0: 6 fields and 2 rules, as promised
exit 0
```

119 orders and 251 units for 30 June. The checker agrees with the contract.
