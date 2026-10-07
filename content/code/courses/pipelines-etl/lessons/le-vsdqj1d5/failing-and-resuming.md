---
title: When a rule fails
version: 1
---

The 16th, for real this time:

```
ana@vm:~/etl$ make 2>&1 | grep -v "^ "
mkdir -p .made
python load_raw.py > /dev/null
touch .made/raw
dbt build --project-dir shop --quiet
06:49:06  14 of 14 FAIL 5 fact_sales_has_not_drifted ..................................... [FAIL 5 in 0.04s]
06:49:06  [ERROR]: in test fact_sales_has_not_drifted (tests/fact_sales_has_not_drifted.sql)
06:49:06    Got 5 results, configured to fail if != 0
make: *** [Makefile:16: .made/models] Error 1
ana@vm:~/etl$ ls .made
models
raw
```

Raw loaded and its marker was touched. Then `dbt build` failed — lesson 12's drift test again, five
older days of `fact_sales` that the shop has changed since — and `make` stopped at once, saying which
rule and which line. The `touch` after `dbt build` never ran, so `.made/models` is still the one
from the 15th: **older than `.made/raw`**, and therefore out of date. The failure left the files
saying exactly what is true: raw is current, the models are not.

Ana does what the drift test asks, a full refresh of the fact table and what follows it, and runs
`make` again — the filter at the end only hides the continuation lines of the long `psql` command:

```
ana@vm:~/etl$ dbt build --project-dir shop -s fact_sales+ --full-refresh --quiet
ana@vm:~/etl$ make 2>&1 | grep -v "^ "
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
mv reports/daily_2026-03-16.csv.part reports/daily_2026-03-16.csv
```

No raw load this time. `.made/raw` was newer than everything it is made from, so that step was
done; the models and the report were not, so they ran. **The declarative version resumed from the
step that failed, and the reason it could is that it was never told the steps** — only what each
file is made from, which stays true whatever happened last night.

That is the same thing Luigi did in lesson 13, with one improvement and one shared limit. The
improvement is the comparison: Luigi would have kept the 15th's models marker and called the models
done; `make` saw it was older than raw. The shared limit is that both decide from files that stand
for the work, not from the data itself. The drift test is what noticed the data.
