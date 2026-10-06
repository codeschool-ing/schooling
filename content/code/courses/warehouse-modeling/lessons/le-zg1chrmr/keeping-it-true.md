---
title: Keeping it true
version: 1
---

A dictionary that was complete in October is wrong by December unless something keeps it up to date. The test is
that something. Here a new column arrives, the way columns do, because somebody needs it for one report:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "ALTER TABLE fact_sales ADD COLUMN gift_wrap BOOLEAN DEFAULT false"
ana@lab:~/wh$ python3 check_docs.py; echo "exit status $?"
fact_sales.gift_wrap: no description
problems: 1
exit status 1
```

The column is added and the test fails, naming it. In a pipeline that runs the test on every change, the change that
adds `gift_wrap` does not reach the warehouse until it carries a description and a classification, which means **the
person adding the column writes the description, in the same change**, while they still know what it means.

That is the whole discipline, and it has three parts that only work together:

- **The descriptions live with the code** that builds the tables, in the same repository and the same review.
- **The dictionary is generated**, so nobody edits a copy that can drift.
- **A test fails on a gap**, in the pipeline, so a gap cannot be merged.

Remove any one and the dictionary decays. Kept in a wiki, it drifts from the code. Written by hand, the copy drifts from
the source. Without the test, gaps are merged on busy days, and every warehouse has busy days.

What the test cannot check is whether a description is **true**. A comment saying "without shipping" on a column that
includes shipping passes every check in this lesson. Review is the only defence there, and it is why the descriptions
are in the same change as the SQL: the reviewer sees both at once.
