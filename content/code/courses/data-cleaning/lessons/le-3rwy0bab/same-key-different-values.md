---
title: The same key with different values
version: 1
---

**A key that appears twice with different values is not a duplicate to remove; it is a
contradiction to resolve.** Removing one copy at random picks a value at random. The catalogue has
three:

```
ana@lab:~/clean$ psql -c 'SELECT product_code, name, price FROM raw.products WHERE product_code IN (SELECT product_code FROM raw.products GROUP BY product_code HAVING count(*) > 1) ORDER BY product_code, price'
 product_code |        name         | price  
--------------+---------------------+--------
 00325        | Rúcula              | 4.90
 00325        | Rúcula              | 5.20
 00343        | Açúcar mascavo 1 kg | 12.90
 00343        | Açúcar mascavo 1 kg | 134.90
 00467        | Banana prata        | 6.90
 00467        | Banana prata        | 7.90
(6 rows)
```

Three products each listed twice with two prices. The buyers changed the price of three products on
1 July and the catalogue export lists the old and the new price without saying which is which.
**Nothing in the file says which price is current**, and any join from the order lines to this
table will match each of those lines twice — lesson 11 measures exactly what that does to revenue.

Two of the pairs look like ordinary price changes: rúcula from R$ 4.90 to R$ 5.20, bananas from
R$ 6.90 to R$ 7.90. The third does not. Sugar going from R$ 12.90 to R$ 134.90 is a rise of more than
ten times for one kilo of sugar, and it looks far more like a price typed with an extra digit.
Lesson 9 is about telling those apart, and follows this one into the orders.

What resolving it takes is information the file lacks: **a date from which each price applies**.
With it, the table becomes a price history and each order line joins to the price in force on its
day. Without it, the honest options are to ask the buyers, or to infer the date from the orders —
the unit price on each order line says which price was charged and when.
