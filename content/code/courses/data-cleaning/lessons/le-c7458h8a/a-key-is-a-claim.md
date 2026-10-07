---
title: A key is a claim
version: 1
---

A join matches rows by a key: order lines to orders by `order_id`, lines to the catalogue by
product code, orders to customers by `customer_id`. **Every join assumes that the key on one side
names exactly one row**, and a file can say that about itself without it being true. So the
first thing to do with a key is to test the claim.

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str); print(len(o), o['order_id'].nunique(), o.drop_duplicates()['order_id'].is_unique)"
28551 28526 True
```

The orders file has 28,551 rows and only 28,526 different order numbers. Those are the 25
repeated orders lesson 5 found, copied whole; once the exact copies are dropped, `is_unique` is
`True`, and `order_id` is a key. That order of operations matters: **the key is only a key after
the duplicates are gone**, so lesson 5 comes before this one for a reason.

The catalogue is a different story:

```
ana@lab:~/clean$ python -c "import pandas as pd; p = pd.read_csv('raw/products.csv', dtype=str); print(len(p), p['product_code'].nunique()); print(p[p['product_code'].duplicated(keep=False)].sort_values(['product_code', 'price']).to_string(index=False))"
72 69
product_code                name  category unit  price
       00325              Rúcula  Verduras   un   4.90
       00325              Rúcula  Verduras   un   5.20
       00343 Açúcar mascavo 1 kg Mercearia   un  12.90
       00343 Açúcar mascavo 1 kg Mercearia   un 134.90
       00467        Banana prata    FRUTAS   kg   6.90
       00467        Banana prata    Frutas   kg   7.90
```

72 rows, 69 codes. Lesson 5 met these three: each product appears twice, with two prices. The
rocket went from R$ 4.90 to R$ 5.20 and the banana from R$ 6.90 to R$ 7.90, and lesson 9 showed
that the sugar's R$ 134.90 was a typing slip that the shop went on to charge. Nothing in the file says which price is current or since when, because
the export has no date column. **This is not a duplicate to drop; it is price history flattened
into a list**, and dropping either row would throw away a fact.

The same check in SQL is a `GROUP BY` that keeps only the groups with more than one row:

```
ana@lab:~/clean$ psql -c "SELECT product_code, count(*) AS rows, string_agg(price, ' / ' ORDER BY price) AS prices FROM raw.products GROUP BY product_code HAVING count(*) > 1 ORDER BY product_code"
 product_code | rows |     prices     
--------------+------+----------------
 00325        |    2 | 4.90 / 5.20
 00343        |    2 | 12.90 / 134.90
 00467        |    2 | 6.90 / 7.90
(3 rows)
```

Run it on every key you are about to join on, on both sides. It is one line, and it turns an
assumption into a measurement before anything has been joined.
