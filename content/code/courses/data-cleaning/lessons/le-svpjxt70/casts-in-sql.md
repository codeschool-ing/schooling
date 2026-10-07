---
title: Casts in SQL fail loudly
version: 1
---

The database behaves differently from pandas, and here the difference is in your favour. **A cast
in PostgreSQL never turns a bad value into a blank.** It stops the whole statement:

```
ana@lab:~/clean$ psql -c 'SELECT sum(total::numeric) FROM raw.store_sales'
ERROR:  invalid input syntax for type numeric: "R$ 94,50"
```

One shop total written as `R$ 94,50` and the query returns nothing at all, not a sum over the
values that happened to parse. That is the loud kind of conversion this lesson asks for, built in.
Its weakness is the opposite one: it tells you about the first bad value, and you want to know
about all of them before you decide anything.

`pg_input_is_valid`, available since PostgreSQL 16, asks the question without raising the error.
It takes a text value and a type name and answers true or false, so it can count:

```
ana@lab:~/clean$ psql -c "SELECT count(*) FILTER (WHERE pg_input_is_valid(birth_year, 'int')) AS ints, count(*) FILTER (WHERE NOT pg_input_is_valid(birth_year, 'int')) AS not_ints, count(*) FILTER (WHERE birth_year IS NULL) AS blank FROM raw.customers"
 ints | not_ints | blank 
------+----------+-------
 2075 |        0 |   338
(1 row)
```

All 2,075 birth years that are written down are valid integers, and the 338 blanks are blanks; the raw table still
holds the repeated rows, which is why pandas counted 332.
Notice what the count does not say: `1900` is a perfectly valid integer, and so is `87`. **A type
check proves a value can be read, never that it is right**, which is why the two-digit rule and
the placeholder rule still have to be written by hand.

The same function checks dates and numbers before they are cast:

```
ana@lab:~/clean$ psql -c "SELECT pg_input_is_valid('31/02/2025', 'date'), pg_input_is_valid('2025-02-28', 'date'), pg_input_is_valid('R\$ 5,00', 'numeric')"
 pg_input_is_valid | pg_input_is_valid | pg_input_is_valid 
-------------------+-------------------+-------------------
 f                 | t                 | f
(1 row)
```

The 31st of February is refused as a date, which a check on the shape `dd/mm/yyyy` would have
accepted. The currency string is refused as a number, which is the shop file's whole format. Run
the checks first, look at what fails, and cast only when the count of failures is the count you
expected.
