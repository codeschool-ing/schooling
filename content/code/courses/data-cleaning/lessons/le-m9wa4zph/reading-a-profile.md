---
title: Reading a profile: what the numbers give away
version: 1
---

**The useful numbers in a profile are the ones that disagree with each other, or with what the
column is for.** Filled against distinct, shortest against longest, empty in one column against
filled in the next. The orders file shows each kind:

```
ana@lab:~/clean$ python profile.py raw/orders.csv
raw/orders.csv: 28551 rows
          column  filled  empty  distinct  shortest  longest          most_common  times
        order_id   28551      0     28526         6        6               102757      2
     customer_id   28551      0      2273         6        6               C00208     54
         channel   28551      0         2         3        4                 site  15755
      ordered_at   28551      0     28519        19       20 2025-02-20T14:22:01Z      2
      fulfilment   28551      0         2         6        8             delivery  22834
           total   28551      0      5741         4        8                15.80    237
        discount   14668  13883         5         1        5                    0  11233
    delivery_fee   28551      0         2         4        4                 9.90  20542
         payment   28551      0         3         3        6                 card  15767
          status   28551      0         3         8        9            delivered  26533
         courier   22834   5717         2         7        7              propria  15971
delivery_minutes   14872  13679       108         2        3                   47    351
```

## Filled against distinct

`order_id` is filled 28,551 times with 28,526 distinct values: the 25 repeated orders. For a key,
**distinct should equal filled**, and any gap is the number of extra copies.

`ordered_at` is the opposite case. It is not a key, so repeats are allowed; two orders can arrive in
the same second. A distinct count close to the row count is what a timestamp looks like, and a
low one would mean many orders stamped with the same moment, typically a batch load that wrote
its own time instead of the order's.

`discount` has 5 distinct values over 14,668 rows. A low count of distinct values on a numeric
column says it is really a category — here, the four coupon values and zero.

## Shortest against longest

`ordered_at` runs from 19 to 20 characters. One format has a fixed length, so two lengths are two
formats: the app's `2025-01-01 07:00:30` and the website's `2025-01-01T11:24:01Z`, one character
longer because of the `Z`. **A spread of lengths in a column that should have one shape is the
cheapest format detector there is.**

`total` runs from 4 characters (`9.90`) to 8 (`26928.50`). An order of nearly twenty-seven thousand
reais at a grocer that sells vegetables by the kilo is either a large customer or a mistake, and
the next section looks at the numbers properly.

## Empty against filled, across columns

Three columns have gaps, and the gaps line up with other columns in ways worth noticing.

**`courier`** is filled 22,834 times, exactly the number of `delivery` orders in `fulfilment`. The
5,717 empty couriers are the pickups. When two counts match exactly, one column explains the
other's blanks, and those blanks are correct.

**`delivery_minutes`** is empty 13,679 times. Pickups explain 5,717 of them and Rapidex several
thousand more; lesson 3 finds what the rest have in common.

**`discount`** is empty 13,883 times, and its most common value is `0`, 11,233 times. Two ways of
writing "no coupon"? Splitting by channel settles it:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str, keep_default_na=False); print(pd.crosstab(o['discount'], o['channel']))"
channel     app   site
discount              
              0  13883
0         11233      0
10.00       392    474
15.00       382    479
20.00       378    463
5.00        411    456
```

The empty string in the first row is the blank. Every blank comes from the website and every `0`
from the app, and the coupons themselves are the same four values in both.

**None of these is visible in `head()`.** The first rows of the file showed one blank discount and
one zero, which looks like two orders with different discounts. The profile shows it is two
systems with one meaning.
