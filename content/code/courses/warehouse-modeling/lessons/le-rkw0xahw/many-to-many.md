---
title: A book with three authors
version: 1
---

The manager asks for revenue by author. A book has one row in `dim_book`, and the authors are written
there as one string, `Petra Dahl Torres`, or for some books three names separated by semicolons. That
string is good for printing on a report and useless for grouping, because "Vera Grieg" alone is not
a value of it.

The relation is **many-to-many**: a book can have several authors, an author can write several books.
It cannot be a column of the fact table either, since a sale line has one book and possibly three
authors, which fails the grain test. So it gets a table of its own, one row per book and author pair,
and lesson 2's load built it:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT b.title, a.author_name, ba.position, ba.weight FROM bridge_book_author ba JOIN dim_book b USING (book_key) JOIN dim_author a USING (author_key) WHERE b.book_id = 600"
┌────────────────────┬─────────────────────┬──────────┬────────────────────┐
│       title        │     author_name     │ position │       weight       │
│      varchar       │       varchar       │  int64   │       double       │
├────────────────────┼─────────────────────┼──────────┼────────────────────┤
│ The Silent Road II │ Tomás Paiva Bergman │        3 │ 0.3333333333333333 │
│ The Silent Road II │ Vera Grieg          │        2 │ 0.3333333333333333 │
│ The Silent Road II │ Quentin Lindqvist   │        1 │ 0.3333333333333333 │
└────────────────────┴─────────────────────┴──────────┴────────────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS books, count(*) FILTER (WHERE n > 1) AS with_more_than_one FROM (SELECT book_key, count(*) AS n FROM bridge_book_author GROUP BY book_key)"
┌───────┬────────────────────┐
│ books │ with_more_than_one │
│ int64 │       int64        │
├───────┼────────────────────┤
│  3000 │                468 │
└───────┴────────────────────┘
```

*The Silent Road II* has three authors; 468 of the shop's 3,000 books have more than one. Now join
sales through that table to the authors and add it up:

```sql
-- Revenue by author, through the bridge, with and without its weight.
SELECT round(sum(f.net_cents) / 100, 2)             AS total_through_bridge,
       round(sum(f.net_cents * ba.weight) / 100, 2) AS total_weighted,
       (SELECT round(sum(net_cents) / 100, 2) FROM fact_sales) AS total_sold
FROM fact_sales f
JOIN bridge_book_author ba USING (book_key);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < by-author.sql
┌──────────────────────┬────────────────┬─────────────┐
│ total_through_bridge │ total_weighted │ total_sold  │
│        double        │     double     │   double    │
├──────────────────────┼────────────────┼─────────────┤
│         111745133.05 │    95743898.52 │ 95743898.52 │
└──────────────────────┴────────────────┴─────────────┘
```

**Through the bridge, the shop sold R$ 111,745,133.05. It sold R$ 95,743,898.52.** A sale of *The
Silent Road II* now appears three times, once with each author, and summing all authors counts it
three times. The extra R$ 16,001,234.53 is every sale of a book with several authors, counted again
for each additional author.

The third column, `total_weighted`, already agrees with what was sold. The next section is about the
`weight` column that makes it agree, and about when you want it and when you do not.
