---
title: Enrichment in SQL
version: 1
---

In the database, a reference file becomes a table like any other, loaded once and joined many
times. The table definition is where the reference's promises are written down:

```sql
CREATE TABLE ref_states (code int PRIMARY KEY, uf text UNIQUE, name text, region text);
\copy ref_states FROM 'ref/ibge_states.csv' WITH (FORMAT csv, HEADER)
SELECT s.region, count(*) AS customers
FROM (SELECT DISTINCT * FROM raw.customers) c
LEFT JOIN ref_states s ON s.uf = upper(replace(c.state, '.', ''))
GROUP BY s.region
ORDER BY customers DESC;
SELECT s.region, count(*) AS customers
FROM (SELECT DISTINCT * FROM raw.customers) c
LEFT JOIN ref_states s ON s.uf = upper(replace(c.state, '.', ''))
                       OR lower(s.name) = lower(c.state)
GROUP BY s.region
ORDER BY customers DESC;
```

`code` is the primary key and `uf` is `UNIQUE`, so the `\copy` would fail on a reference file with a
repeated state, before any customer is joined to it. **The constraints check the reference, not
just your data**, which matters because a reference you typed in, as this lab did, can carry a typo
of its own.

The two queries differ in one line:

```
ana@lab:~/clean$ psql -f enrich.sql
CREATE TABLE
COPY 27
 region  | customers 
---------+-----------
 Sudeste |      1969
 Sul     |       303
         |       104
(3 rows)

 region  | customers 
---------+-----------
 Sudeste |      2058
 Sul     |       318
(2 rows)
```

The first joins on the two letters alone and is honest about it: **the `LEFT JOIN` keeps the 104
customers whose state is written as a name**, and the blank region in the last row counts them. An
inner join would have reported a company with 2,272 customers in two regions and said nothing
about the rest.

The second adds the name as a second way to match, and every customer finds a region: 2,058 in the
Sudeste and 318 in the Sul, the same split pandas produced. `lower(s.name) = lower(c.state)` works
here because the names in this file are spelled with their accents, as IBGE spells them. A name
typed without its accent, `Parana`, would not match, and the blank row would come back to say so;
lesson 6's `unaccent` is the tool for that case.

**A blank row in an enrichment's summary is not noise to filter out.** It is the count of records
the reference could not place, and it is the number to look at first.
