---
title: What the snowflake saves, and what it costs
version: 1
---

The argument for normalising a dimension is storage and consistency. In the warehouse, the first is
small and the second is already handled.

**Storage.** How many bytes does the star spend on repeating names?

```sql
-- What the star repeats, in bytes of text, against the size of the fact table.
SELECT sum(strlen(category) + strlen(subcategory) + strlen(department) + strlen(publisher))
           AS repeated_text_bytes,
       (SELECT count(*) FROM fact_sales) AS fact_rows
FROM dim_book;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < repeated.sql
┌─────────────────────┬───────────┐
│ repeated_text_bytes │ fact_rows │
│       int128        │   int64   │
├─────────────────────┼───────────┤
│              130473 │    887477 │
└─────────────────────┴───────────┘
ana@lab:~/wh$ ls -l wh.duckdb
-rw-r--r-- 1 ana ana 46149632 Oct  6 13:29 wh.duckdb
```

130,473 bytes of repeated text: the four names of every book, three thousand times. The whole
warehouse file is 46,149,632 bytes. **The snowflake would save about 0.3% of the file**, and less than
that once lesson 8's compression has had a go at those repeated words, which is the kind of data it
compresses best. A dimension is a few thousand rows; the fact table is nearly nine hundred thousand.
Saving space in the small table does not move the total.

**Consistency.** In the operational database, normalisation stops two rows from disagreeing: rename
a department, and nothing can be left with the old name. In the warehouse **nothing is edited by
hand**. `dim_book` is rebuilt by the load from the source's single copy of each name, so the rows
cannot disagree with each other either. The anomaly the snowflake prevents is one that the load
already prevents.

**What it costs**, on the other side:

- **More joins per question**, and a chain of them a person has to know. Section 05 counted three
  more for one question.
- **Harder report tools.** A tool that offers "department" as a field has to know the three-step path
  to it. Most can be taught; every one of them is simpler on a star.
- **More tables to document and load**: five where there was one, with keys between them that the
  load has to keep consistent.

So the default is the star. The next section is about when the trade turns the other way.
