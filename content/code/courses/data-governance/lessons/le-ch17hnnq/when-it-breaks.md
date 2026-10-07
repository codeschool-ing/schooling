---
title: Breaking it, twice
version: 1
---

## A field nobody agreed to

A ticket says the drivers would like the customer's name on their screen. Somebody adds it to the
view:

```
ana@lab:~/gov$ cat labels.sql
-- "The driver needs the name for the label", says a ticket. Nobody asks the
-- owner, nobody changes the contract.
SET ROLE ipe_owner;
CREATE OR REPLACE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT sum(i.quantity) FROM sales.order_items i WHERE i.order_id = o.order_id) AS items,
       c.full_name
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
ana@lab:~/gov$ psql -f labels.sql
SET
CREATE VIEW
ana@lab:~/gov$ python3 check_contract.py delivery-feed.v1.json; echo "exit $?"
delivery-feed 1.0.0: 1 problem(s)
  full_name: served, and not in the contract
exit 1
```

The view changed without complaint — `CREATE OR REPLACE VIEW` accepts a new column at the end. The
checker did not: `full_name` is served and not in the contract, and it exits with 1. In a pipeline, the
change stops there.

What should happen next is not "add `full_name` to the contract". It is the question the contract
exists to force: Rota Certa is a processor, the name is identifying data, and the purpose was route
planning. If drivers really need names on screen, that is a **new purpose**, decided by the owner,
written in the contract's purpose and basis, and probably a reason for lesson 7's DPO to look at it.
The check does not decide that. It makes sure somebody does.

## A change that looked harmless

A second developer tidies the view, and on the way changes how `items` is computed — lines of the order
instead of the units ordered — with a cast to `integer` for neatness:

```sql
-- Back to the contract's columns, and one "harmless" change: items counted
-- as lines rather than summed as units, and cast to integer on the way.
SET ROLE ipe_owner;
DROP VIEW share.delivery_feed;
CREATE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT count(*) FROM sales.order_items i WHERE i.order_id = o.order_id)::integer AS items
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
GRANT SELECT ON share.delivery_feed TO rota_certa;
```

```
ana@lab:~/gov$ psql -f typechange.sql
SET
DROP VIEW
CREATE VIEW
GRANT
ana@lab:~/gov$ python3 check_contract.py delivery-feed.v1.json; echo "exit $?"
delivery-feed 1.0.0: 1 problem(s)
  items: contract says bigint, served as integer
exit 1
```

The checker caught it, **by luck**. The type changed from `bigint` to `integer` only because of the
cast. Without it, `count(*)` returns `bigint`, the same as `sum()`, and the check would have passed while
every number in the feed changed meaning: the CSV in section 8 shows 3, 6 and 1 units where this
version would send 2, 3 and 1 lines. Rota Certa would plan the vans for half the parcels.

This is why a contract is more than a schema. Two things would have caught it without luck:

- **the semantics written down** — `items` described as *units ordered*, so that a reviewer reading
  the diff sees `count(*)` and knows it is wrong;
- **a quality rule that tests the meaning**, not the shape: the feed's total for a day equals the sum of
  `sales.order_items.quantity` for that day's orders. Rules like this are cheap, and they are the only
  kind that notices a column that kept its name and changed its mind.
