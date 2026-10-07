---
title: Rebuilding only what changed
version: 1
---

The point of comparing times is what happens after a change. Ana edits the comment at the top of
`stg_books.sql`, and asks `make` what it *would* do — `-n` prints the commands without running them:

```
ana@vm:~/etl$ sed -i '1s/.*/-- One row per book, as the publishers catalogue it./' shop/models/staging/stg_books.sql
ana@vm:~/etl$ make -n
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-15' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-15.csv.part
mv reports/daily_2026-03-15.csv.part reports/daily_2026-03-15.csv
ana@vm:~/etl$ make
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-15' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-15.csv.part
mv reports/daily_2026-03-15.csv.part reports/daily_2026-03-15.csv
```

`stg_books.sql` is now newer than `.made/models`, so the models are out of date, and so is the
report made from them. Raw is not: nothing it is made from has changed. **`make` skipped the step
whose inputs had not moved, and redid the two whose inputs had**, without being told which.

A new day of the shop moves the clock file, and the whole chain falls out of date from the bottom:

```
ana@vm:~/etl$ sudo shop day 2026-03-16
ana@vm:~/etl$ make -n
mkdir -p .made
python load_raw.py > /dev/null
touch .made/raw
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-16' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-16.csv.part
mv reports/daily_2026-03-16.csv.part reports/daily_2026-03-16.csv
```

`make -n` lists all three steps, and the report's name has moved to the 16th, because `DAY` is
read from the same clock. The rule for raw has the clock as an input precisely so that a new day
means *reload*; that one line is the pipeline's whole idea of *the shop has changed*.

Modification times are a coarse signal. Saving a file without changing it makes everything after it
out of date, and a change that does not touch any file `make` watches — a refund on the 14th, in
the shop's own database — makes nothing out of date at all. The rules are only as good as the
inputs they list; the clock file here is a convenience of the lab, standing in for *new data has
arrived*, which a real pipeline has to detect some other way.
