---
title: Strings
version: 1
---

Text is the hardest kind of column to compress and usually the largest. The fact table has none, which is
one reason it compresses so well; the dimensions are full of it. DuckDB, asked how it stored four text
columns of `dim_book`:

```sql
SELECT column_name, compression, count(*) AS segments
FROM pragma_storage_info('dim_book')
WHERE column_name IN ('title', 'department', 'format', 'authors')
  AND segment_type <> 'VALIDITY'
GROUP BY ALL ORDER BY column_name;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < strings.sql
┌─────────────┬─────────────┬──────────┐
│ column_name │ compression │ segments │
│   varchar   │   varchar   │  int64   │
├─────────────┼─────────────┼──────────┤
│ authors     │ FSST        │        1 │
│ department  │ Dictionary  │        1 │
│ format      │ Dictionary  │        1 │
│ title       │ FSST        │        1 │
└─────────────┴─────────────┴──────────┘
```

Two different answers, because the columns are different kinds of text.

**`department` and `format` got a dictionary.** Four departments and three formats across 3,000 books: the
same few strings over and over, and a dictionary stores each once with a small number per row, exactly as
for `shop_key`.

**`title` and `authors` got FSST**, *Fast Static Symbol Table*. Almost every title is different, so a
dictionary of whole titles would be as large as the column. But titles share pieces: `The `, ` of `, `Season`,
`Harbour`. FSST builds a table of up to 255 frequent fragments of up to eight bytes and replaces each
occurrence with one byte. Decompressing it is a table lookup per byte, fast enough that a filter can run
on the compressed text and decode only the rows that match.

Two consequences for modelling:

- **Long, repeated strings in a fact table cost less than they used to**, as lesson 6 measured. A column
  store encodes them by dictionary. They still cost something, and they still carry lesson 6's update
  problem.
- **A string identifier that could be an integer should be one.** An e-mail address as a key took 66% more
  space than an integer in lesson 4, after compression. An integer key is smaller in every encoding there
  is.
