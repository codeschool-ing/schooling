---
title: A report that describes a database nobody listed
version: 1
---

Lesson 1's `verify.sql` named the shop's two tables and the columns it summed. That was right for a
first restore and wrong for a drill that runs every week for years: the day somebody adds a table,
the report stops looking at part of the database, and keeps passing. **A drill's report has to find
the tables itself.**

Save this as `report.sql`:

```schooling-example
{"language": "sql", "file": "report.sql", "parts": [{"code": "-- report.sql: describe every table in public, without naming one\nSELECT format(\n  'SELECT %L, count(*), md5(coalesce(string_agg(x::text, %L ORDER BY x::text), %L)) FROM %I AS x',\n  table_name, ',', '', table_name)\nFROM information_schema.tables\nWHERE table_schema = 'public' AND table_type = 'BASE TABLE'\nORDER BY table_name", "note": "One query that writes queries. For every ordinary table in the public schema, it builds a statement counting the rows and fingerprinting their contents."}, {"code": "\\gexec", "note": "\\gexec is psql's own: it runs every row the query above returned, as a statement. A table added next month is in next month's report without anybody editing this file."}, {"code": "SELECT 'indexes', string_agg(indexname, ' ' ORDER BY indexname)\nFROM pg_indexes WHERE schemaname = 'public';", "note": "And the indexes by name, which a restore can lose without losing a row."}]}
```

The fingerprint is the point. `x::text` turns each row into text, `string_agg` joins all of them in
a fixed order, and `md5` reduces the result to 32 characters. **Change one character in one row of
three million, and the fingerprint is different.** Where lesson 1's sums could miss two changes that
cancelled out, this cannot.

```
ana@vm:~$ psql -X -A -t shop -f report.sql
customers|1000|59bcef50f813ab10bc9dd1a77f952779
orders|50000|c6b0e3dce001bde7ecbf7aa7cbccebb5
indexes|customers_pkey orders_customer orders_pkey
ana@vm:~$ time psql -X -A -t bigshop -f report.sql
customers|1000|59bcef50f813ab10bc9dd1a77f952779
orders|3000000|d522ec3f50864e9ad8762c972bfde456
indexes|customers_pkey orders_customer orders_pkey

real	0m5.860s
user	0m0.028s
sys	0m0.002s
```

Two databases, two tables each, and a line of indexes. On `bigshop` it took **a few seconds**,
because fingerprinting means reading and sorting every row: a drill's proof costs time in proportion
to the data, like a logical restore, and that time belongs in the drill's measurements.

On a database of hundreds of gigabytes, fingerprinting every row of every table takes hours, and the
usual compromise is counts for every table, fingerprints for the tables that matter most, and a
sample of rows by primary key for the rest. Whatever the compromise, it is **written down in the
file and applied identically to both sides**, which is what makes the comparison honest.
