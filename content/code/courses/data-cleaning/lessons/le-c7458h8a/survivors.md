---
title: Joining through a map
version: 1
---

Lesson 5 ended with `survivors.csv`: 49 customer codes that are second records of a person, each
pointing at the record that is kept. A map like that is used through a join, and it is a join
like any other, so it gets the same checks first.

```sql
CREATE TABLE survivors (customer_id text PRIMARY KEY, kept_id text NOT NULL);
\copy survivors FROM 'survivors.csv' WITH (FORMAT csv, HEADER)
SELECT count(*) AS mappings,
       count(*) FILTER (WHERE kept_id IN (SELECT customer_id FROM survivors)) AS two_hops
FROM survivors;
SELECT count(DISTINCT o.customer_id) AS before,
       count(DISTINCT coalesce(s.kept_id, o.customer_id)) AS after
FROM (SELECT DISTINCT * FROM raw.orders) o
LEFT JOIN survivors s ON s.customer_id = o.customer_id;
```

```
ana@lab:~/clean$ head -3 survivors.csv
customer_id,kept_id
C02450,C00519
C02414,C00409
ana@lab:~/clean$ psql -f survivors.sql
CREATE TABLE
COPY 49
 mappings | two_hops 
----------+----------
       49 |        0
(1 row)

 before | after 
--------+-------
   2273 |  2272
(1 row)
```

The table is loaded with `\copy`, which reads the file on ana's side rather than the server's.
Then two checks and one answer.

- **The primary key on `customer_id`** is the uniqueness test, built in: a code mapped twice, to
  two different survivors, would stop the `\copy`.
- **`two_hops` is 0.** No kept code is itself mapped somewhere else. If one were, a customer would
  move one step and stop halfway, so the map would have to be followed until it settles, or,
  better, fixed so that every code points straight at its final survivor.
- **`COALESCE(s.kept_id, o.customer_id)`** is the whole mapping: the survivor where the map has
  one, and the code as it was everywhere else. The left join keeps every order, and the
  `COALESCE` decides which code each one ends up with.

The answer is the one lesson 5 reached in pandas: customers with orders go from 2,273 to 2,272.
Almost none of the duplicate records ever ordered anything: lesson 5 moved two orders in all, so
at most two of the 49 did. **The same number from two tools is the check**, as it was for
the typed table in lesson 10.
