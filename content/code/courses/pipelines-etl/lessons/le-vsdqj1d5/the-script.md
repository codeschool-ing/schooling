---
title: The script: every step, every time
version: 1
---

Ana's `nightly.sh` from lesson 7 is the imperative version, and a good one of its kind:

```
#!/bin/sh
# One night: copy the shop into raw, rebuild staging, then load the marts.
set -e
day=${1:?usage: nightly.sh YYYY-MM-DD}
export PGOPTIONS="-c client_min_messages=warning"
python load_raw.py >/dev/null
sh run_sql.sh >/dev/null
psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql
psql -q -v ON_ERROR_STOP=1 -d wh -At -f load/dim_book.sql | sort | uniq -c | sed 's/t$/inserted/; s/f$/updated/'
psql -q -v ON_ERROR_STOP=1 -d wh -v day="$day" -f load/fact_sales.sql
psql -d wh -At -c "SELECT '$day: ' || count(*) || ' fact rows' FROM marts.fact_sales WHERE order_date = '$day'"
```

It is short, it reads top to bottom, and `set -e` stops it at the first command that fails. Anybody
can tell what it does. What it cannot do follows from the same plainness:

- **Run it twice and it does everything twice.** Nothing in it asks whether raw is already loaded
  or the fact table already holds the day. Here that is only wasted time, because every step was
  written to be safe to repeat; a script whose steps were not would double a day's sales.
- **When a step fails, the next run starts from the top.** The script has no idea which steps
  finished last time; it was never told what *finished* would look like.
- **The order is the author's.** `dim_customer` before `dim_book` because that is the order of the
  lines, though neither needs the other. Change one step's inputs, and the script will not notice
  that the order is now wrong.

None of that is a fault while a pipeline is four steps long and runs once a night. It becomes one
when the steps take an hour, or there are forty of them, or a failure at step thirty sends the
whole night back to step one.
