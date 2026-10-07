---
title: First look, and a number nobody should publish
version: 1
---

**Before any cleaning, find out what you were given.** Not what the files are supposed to
contain: what is in them, how big they are, and which system wrote each one. Ana starts with the
directory:

```
ana@lab:~/clean$ ls -l raw
total 6908
-r--r--r-- 1 ana ana  244696 Oct  7 03:03 customers.csv
-r--r--r-- 1 ana ana     286 Oct  7 03:03 fx_rates_2025.csv
-r--r--r-- 1 ana ana    3659 Oct  7 03:03 invoices.csv
-r--r--r-- 1 ana ana 2488556 Oct  7 03:03 order_items.csv
-r--r--r-- 1 ana ana 2405696 Oct  7 03:03 orders.csv
-r--r--r-- 1 ana ana    2790 Oct  7 03:03 products.csv
-r--r--r-- 1 ana ana 1270312 Oct  7 03:03 store_sales.csv
-r--r--r-- 1 ana ana  638586 Oct  7 03:03 survey.csv
-r--r--r-- 1 ana ana     630 Oct  7 03:03 targets_2025.csv
ana@lab:~/clean$ wc -l raw/*.csv
   2414 raw/customers.csv
     13 raw/fx_rates_2025.csv
     61 raw/invoices.csv
  99162 raw/order_items.csv
  28552 raw/orders.csv
     73 raw/products.csv
  23595 raw/store_sales.csv
  26495 raw/survey.csv
      7 raw/targets_2025.csv
 180372 total
```

Nine files and about 180,000 lines. Each one comes from a different place, and the place is what
predicts its defects:

| file | written by | one row is |
|---|---|---|
| `customers.csv` | the CRM, exported on its own schedule | a customer account |
| `orders.csv` | the website and the app | an online order |
| `order_items.csv` | the website and the app | one product in one order |
| `products.csv` | the catalogue, kept by the buyers | a product and its price |
| `store_sales.csv` | the five shops' old till | one sale at a counter |
| `survey.csv` | the satisfaction survey | one invitation, answered or not |
| `invoices.csv` | accounts payable | a supplier's invoice |
| `fx_rates_2025.csv` | finance | the exchange rate booked for a month |
| `targets_2025.csv` | the commercial team's spreadsheet | one shop's targets for the year |

**`wc -l` counts lines, not records**, and the difference is one header line per file at the
least. A field with a line break inside quotes would make it more; these files have none, which
lesson 2 checks rather than assumes.

## The first rows

```
ana@lab:~/clean$ head -4 raw/orders.csv
order_id,customer_id,channel,ordered_at,fulfilment,total,discount,delivery_fee,payment,status,courier,delivery_minutes
100001,C00820,app,2025-01-01 07:00:30,delivery,66.60,0,9.90,card,delivered,Rapidex,
100002,C00223,app,2025-01-01 08:07:08,pickup,46.70,0,0.00,card,delivered,,
100003,C00333,site,2025-01-01T11:24:01Z,delivery,108.30,,9.90,pix,delivered,Rapidex,
```

Three rows are enough to see the shape of the work. The app writes `2025-01-01 07:00:30` and the
website writes `2025-01-01T11:24:01Z` in the same column — two formats, and the `Z` means the
second is in UTC while the first is not. The app writes a discount of `0` and the website leaves
it empty. The pickup order has no courier, which is right, and no delivery time, which is also
right; the Rapidex orders have a courier and no delivery time, which is a different thing
entirely. Lessons 3 and 7 come back to all of it.

## The number

The commercial director wants one figure: revenue from delivered online orders in 2025. The
database will give it without complaint:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS orders, sum(total::numeric) AS revenue FROM raw.orders WHERE status = 'delivered'"
 orders |  revenue   
--------+------------
  26533 | 2502874.70
(1 row)
```

R$ 2,502,874.70 from 26,533 orders. The query is correct SQL and it ran. **And it cannot be
defended**, for reasons this lesson measures one at a time:

- some order numbers appear twice in the file, so some orders are counted twice;
- some totals were typed by hand, and a typed total can be wrong while still being a number;
- the shops sold food too, in a file with a different format, and the query never read it;
- some orders belong to customers the customer file does not contain, so any breakdown by
  customer will lose them.

None of those raises an error. **That is what makes data quality a discipline rather than a
debugging session**: the defects that matter are the ones that produce a plausible number.
