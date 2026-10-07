---
title: The same steps in SQL
version: 1
---

**Every step of this lesson has a PostgreSQL function**, and composing them gives the same key the
pandas cascade builds:

| step | pandas | PostgreSQL |
|---|---|---|
| trim and collapse spaces | `.str.strip()`, `.str.replace(r"\s+", " ", regex=True)` | `trim()`, `regexp_replace(…, '\s+', ' ', 'g')` |
| Unicode to NFC | `.str.normalize("NFC")` | `normalize(…, NFC)` |
| repair mojibake | `.encode("latin-1").decode("utf-8")` | `convert_from(convert_to(…, 'LATIN1'), 'UTF8')` |
| lower case | `.str.lower()` | `lower()` |
| remove accents | NFKD, drop combining marks | `unaccent()`, from the extension of that name |

Counting the distinct values after each step, for the cities without mojibake:

```
ana@lab:~/clean$ psql -c "SELECT count(DISTINCT city) AS raw, count(DISTINCT trim(city)) AS trimmed, count(DISTINCT normalize(trim(city), NFC)) AS nfc, count(DISTINCT lower(unaccent(normalize(trim(city), NFC)))) AS plain FROM raw.customers WHERE city NOT LIKE '%Ã%'"
 raw | trimmed | nfc | plain 
-----+---------+-----+-------
  26 |      23 |  21 |    11
(1 row)
```

26, 23, 21 and 11: the same drops as pandas, on the 26 spellings left once the two mangled ones are
set aside.

The mojibake repair is the step that needs care in SQL too, because `convert_to(…, 'LATIN1')` fails
on any character Latin-1 cannot hold. Applied only to the rows that carry the signature, the whole
chain runs:

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
SELECT lower(unaccent(regexp_replace(trim(normalize(
         convert_from(convert_to(city, 'LATIN1'), 'UTF8'), NFC)), '\s+', ' ', 'g'))) AS city_key,
       count(*)
FROM raw.customers
WHERE city LIKE '%Ã%'
GROUP BY 1;
```

```
ana@lab:~/clean$ psql -f city_key.sql
psql:city_key.sql:1: NOTICE:  extension "unaccent" already exists, skipping
CREATE EXTENSION
 city_key  | count 
-----------+-------
 sao paulo |    10
(1 row)
```

The ten mangled rows all come out as `sao paulo`, the same key as every other spelling of the city,
and from there the abbreviations table maps it to `São Paulo` exactly as in pandas.

`CREATE EXTENSION` needs the right to create one, which the lab's user has because it owns the
database. On a shared server, ask whoever administers it; `unaccent` ships with PostgreSQL and is
one of the most commonly enabled extensions.
