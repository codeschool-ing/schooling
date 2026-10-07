---
title: Rows, columns and variables
version: 1
---

Statistics starts with a table, and the words for its parts are worth fixing now, because the rest of
the course uses them without stopping.

Here are twelve orders from **Horta**, the small online grocer this course follows. It delivers
fruit, vegetables and groceries in Campinas, and every number in this course comes from its records.
The company is invented, and so are its orders; what is done with them is not.

| order | neighbourhood | payment | items | basket (R$) | minutes | rating | postcode |
|---|---|---|---|---|---|---|---|
| H-1041 | Cambuí | pix | 7 | 86.40 | 34.5 | 5 | 13025-320 |
| H-1042 | Taquaral | card | 3 | 31.90 | 41.0 | 4 | 13076-010 |
| H-1043 | Barão Geraldo | pix | 12 | 154.75 | 52.5 | 3 | 13084-180 |
| H-1044 | Cambuí | cash | 2 | 18.50 | 29.0 | 5 | 13025-120 |
| H-1045 | Centro | card | 5 | 62.30 | 38.5 | 4 | 13013-050 |
| H-1046 | Taquaral | pix | 9 | 118.20 | 44.0 | 2 | 13076-210 |
| H-1047 | Cambuí | pix | 4 | 47.80 | 31.5 | 5 | 13024-040 |
| H-1048 | Barão Geraldo | card | 15 | 212.60 | 61.0 | 4 | 13083-300 |
| H-1049 | Centro | pix | 6 | 74.10 | 36.0 | 4 | 13010-110 |
| H-1050 | Taquaral | card | 1 | 12.90 | 27.5 | 1 | 13076-150 |
| H-1051 | Cambuí | pix | 8 | 95.00 | 39.0 | 5 | 13025-200 |
| H-1052 | Centro | cash | 3 | 35.60 | 33.0 | 3 | 13015-020 |

**Each row is an observation**: one thing that was looked at, here one order. **Each column is a
variable**: one property recorded for every observation. It is called a variable because it varies
from row to row. A column that held the same value in every row would tell you nothing about any
of them.

The cell where a row meets a column holds a **value**. Order H-1043 has the value `Barão Geraldo`
for the variable *neighbourhood* and the value `52.5` for the variable *minutes*.

## One table, one kind of observation

A table works when every row is the same kind of thing. If Horta mixed orders and customers in one
sheet, a row for a customer would have no *basket* and a row for an order would have no *date of
birth*. Every count you made afterwards would count two different things together.

So the first question about any data set is **what one row is**. "One order" and "one customer" give
different answers to the same question. Ask for the average basket per order and you get one
number. Ask for the average spend per customer and you get another, because a customer who orders
four times is one row in the second table and four in the first.

## The column decides what you may do

Look along the header again. *neighbourhood* holds names of places. *basket* holds amounts of money.
*postcode* holds digits, but nobody adds two postcodes.

These are different **kinds** of variable, and the kind decides which summaries make sense. You can
total the baskets: R$ 950.05 across the twelve orders is the money Horta took. You cannot total the
neighbourhoods, and you should not total the postcodes even though a spreadsheet would let you.

The next three sections sort the columns into the two families every statistics course starts
with, and then look at the columns that pretend to belong to the wrong one.
