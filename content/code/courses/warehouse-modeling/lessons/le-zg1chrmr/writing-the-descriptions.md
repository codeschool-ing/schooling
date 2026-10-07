---
title: Writing the descriptions
version: 1
---

The descriptions for the whole model are one SQL file, run after the tables are built. It begins like this:

```
-- What every table and column of the model means, kept in the database
-- beside the data, where the dictionary is generated from.

COMMENT ON TABLE fact_sales IS 'One row per line of an order that was not cancelled, in a shop or online.';
COMMENT ON COLUMN fact_sales.date_key IS 'Day the order was placed, São Paulo time. Key of dim_date.';
COMMENT ON COLUMN fact_sales.shop_key IS 'Shop the order was placed in; the website is the shop Online. Key of dim_shop.';
COMMENT ON COLUMN fact_sales.book_key IS 'Book sold on this line. Key of dim_book.';
COMMENT ON COLUMN fact_sales.customer_key IS 'Customer as they were when ordering; 0 for a sale nobody identified. Key of dim_customer.';
COMMENT ON COLUMN fact_sales.promotion_key IS 'Promotion applied to the line; 0 when there was none. Key of dim_promotion.';
```

```
ana@lab:~/wh$ grep -c "^COMMENT ON" comments.sql
104
ana@lab:~/wh$ duckdb wh.duckdb < comments.sql
ana@lab:~/wh$ python3 check_docs.py; echo "exit status $?"
problems: 0
exit status 0
```

A hundred and four statements, one for each of the 12 tables and 92 columns, the one written in section 4
included, and the test passes. Writing them took longer than any query in this course, and most of
the time went into deciding rather than typing: what exactly does `days_to_ship` count, and what is it before an order
ships?

A few habits make descriptions worth reading:

- **Say what the reader cannot see.** "Order number" adds nothing to `order_id`. "Order number in the shop system.
  With line_no, identifies the row" tells the reader how to count orders correctly.
- **Name the special values.** Key 0, "Not yet", 9999-12-31: each was chosen in an earlier lesson and each is a trap for
  somebody who was not there.
- **Give the unit and the arithmetic.** `on_hand` says it is semi-additive in so many words: add across shops and books,
  never across dates.
- **Use the glossary's words.** `net_cents` says "Net sales"; `amount_cents` says "Receipts". The two names lesson 11
  gave its two measures are now written on the columns that hold them.
- **Prefer one plain sentence to three clever ones.** A description is read by someone in the middle of something else.

A description that needs a paragraph is usually a sign the column is doing too much. If explaining it takes three
"except when" clauses, the model may want a second column instead.
