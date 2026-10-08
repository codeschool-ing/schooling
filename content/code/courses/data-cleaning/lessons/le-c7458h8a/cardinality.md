---
title: One, many, and the join you meant
version: 1
---

**Cardinality** is how many rows on each side can share a key value. Three cases cover almost
every join in practice:

- **one-to-one**: each customer has one row in the CRM and one row in a loyalty table;
- **many-to-one**: many order lines point at one product, many orders at one customer;
- **many-to-many**: products and promotions, where a product is in several promotions and a
  promotion covers several products.

The first two are what joins are for. **The third is almost never what you meant**: it returns
every combination of matching rows, so a key value with three rows on one side and four on the
other produces twelve. When it is meant, there is a table in the middle saying which pairs
exist, and two many-to-one joins through it.

Joining order lines to the catalogue is meant to be many-to-one: many lines, one product. The
catalogue's three repeated codes make it quietly many-to-many for those products. pandas can be
told what you meant, and it checks:

```
ana@lab:~/clean$ python -c "import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); l.merge(p, left_on='code', right_on='product_code', how='left', validate='many_to_one')" 2>&1 | grep ^pandas.errors
pandas.errors.MergeError: Merge keys are not unique in right dataset; not a many-to-one merge
```

`validate="many_to_one"` makes `merge` test the right side's key before joining, and refuse if it
repeats. **The cost is one argument, and it turns a silent copy into an error with a sentence.**
The other values are `"one_to_one"`, `"one_to_many"` and `"many_to_many"`; the last checks nothing
and only says out loud that you expect copies.

SQL has no such argument. The equivalent is the `GROUP BY … HAVING count(*) > 1` from the previous
section, run on the side that should be unique, before the join and as its own step. A unique
constraint on that column, like the primary key lesson 10 put on `clean.customers`, makes the
database hold the promise for good.
