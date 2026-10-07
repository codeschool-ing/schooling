---
title: Completeness: present where it should be
version: 1
---

**Completeness is the share of values that are present out of the values that should be
present.** The second half of that sentence is the whole difficulty. A count of empty cells is
easy; deciding which empty cells are defects needs you to know why each row exists.

Start with the e-mail addresses:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, count(*) AS customers, count(*) - count(email) AS no_email FROM raw.customers GROUP BY signup_channel ORDER BY customers DESC"
 signup_channel | customers | no_email 
----------------+-----------+----------
 site           |      1020 |        0
 app            |       730 |        0
 store          |       618 |      280
 import-2023    |        45 |        2
(4 rows)
```

The website and the app refuse to create an account without an address, so their columns are
full. The shops ask for one and accept a refusal, and 280 of 618 customers who signed up at a
counter have none: **45% missing in one channel, 0% in two others**. Averaged over the file it
would be about 12%, a number that describes no part of the business.

Whether those 280 blanks are a defect depends on the use. For a campaign by e-mail they are 280
customers you cannot reach, and nothing will make them appear. For counting customers per city
they do not matter at all. **Completeness is measured against a purpose**, which is why the same
column can be complete enough for one report and useless for the next.

## A blank that is correct

The delivery time is the sharper case:

```
ana@lab:~/clean$ psql -c "SELECT fulfilment, courier, count(*) AS orders, count(delivery_minutes) AS timed FROM raw.orders WHERE status = 'delivered' GROUP BY fulfilment, courier ORDER BY orders DESC"
 fulfilment | courier | orders | timed 
------------+---------+--------+-------
 delivery   | propria |  14847 | 14406
 delivery   | Rapidex |   6371 |     0
 pickup     |         |   5315 |     0
(3 rows)
```

Of the 26,533 delivered orders, 14,406 have a delivery time, which is 54%. Read that way, the
column is half empty. Read by row, it is three different situations:

- **pickups** have no delivery, so no time. A blank there is the right answer, and filling it would
  be the defect;
- **Rapidex**, the partner courier, never reports times to Quitanda Verde at all. The blank is a gap in
  what the company collects, the same on every row;
- **the company's own couriers** time 14,406 of 14,847 deliveries, 97%. The 441 without a time are
  the only blanks here that nobody can explain from the row, and lesson 3 finds out what they have
  in common.

The denominator decides the number. **Measured over the rows where a value should exist, the
column is 97% complete; measured over everything, 54%.** Both are arithmetic, and only one of them
measures anything.

A note on how those blanks got there. These files left their systems as CSV, and in CSV an empty
field is just two commas side by side. PostgreSQL's loader reads an unquoted empty field as
`NULL`, which is why `count(email)` skips them; pandas reads it as `NaN`. **Neither tool knows
what the blank meant to the person who left it**, and lesson 3 is about the many things it can
mean.
