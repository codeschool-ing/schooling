---
title: What the purge keeps
version: 1
---

Deleting 950 orders loses something the business wants: how much was sold, of what, and when. Article
16, IV of the LGPD allows keeping data after its purpose ends **for the controller's exclusive use,
with no access by third parties, as long as it is anonymised**. So before the orders go, the purge
writes what they say about sales into a table that says nothing about anybody:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders_kept_by_the_hold FROM sales.orders WHERE customer_id = 4407 AND ordered_at < DATE '2021-01-01'" -c "SELECT * FROM gov.sales_monthly WHERE month = DATE '2020-03-01' ORDER BY category"
SET
 orders_kept_by_the_hold 
-------------------------
                      13
(1 row)

   month    |    category    | orders | units | revenue_cts 
------------+----------------+--------+-------+-------------
 2020-03-01 | analgesic      |      4 |     4 |        6060
 2020-03-01 | antibiotic     |      7 |     8 |       25920
 2020-03-01 | baby           |      2 |     2 |        9980
 2020-03-01 | cardiovascular |      8 |     9 |       15810
 2020-03-01 | contraceptive  |      1 |     2 |        4980
 2020-03-01 | diabetes       |      8 |    10 |       36900
 2020-03-01 | diagnostic     |      2 |     3 |        5970
 2020-03-01 | first aid      |     12 |    14 |       18760
 2020-03-01 | neurology      |      1 |     1 |        3190
 2020-03-01 | personal care  |      9 |     9 |       20610
 2020-03-01 | psychiatric    |      5 |     7 |       25030
 2020-03-01 | supplement     |      5 |     5 |       24050
 2020-03-01 | thyroid        |      1 |     1 |        1690
(13 rows)
```

The last result above is March 2020: thirteen product categories, how many orders, how many units,
how much revenue. No customer, no order number, no day finer than the month, no state. It is classified
`none` in `gov.column_class`, with the reason, so the classification check of lesson 6 agrees that it
holds nothing about a person.

## Is it really anonymous?

Lesson 5's question applies here, and the honest answer has two parts.

**Inside Ipê, yes.** There is no column that joins a row back to anybody, and the orders it came from
no longer exist. Nobody at Ipê can ask "who bought the one contraceptive in March 2020?" because no
record that could answer it is left.

**Published, it would need another look.** Three rows of March 2020 count **one** order. A cell of one
is not personal data by itself, but combined with outside knowledge — a small town, a known customer —
a count of one can say something about a person. Lesson 5's rule was to suppress or merge small cells
before data leaves the company. The table is fine for Ipê's own use, which is what article 16, IV
allows; a report built from it for anybody else would apply the rule first.

## The general move

**Aggregate, then delete** is the pattern for most history a business wants to keep: the statistics
survive and the people leave them. It is the same design as the platform you are studying on, where
erasing a person deletes the rows that give their identifiers a meaning and leaves the counts intact.
