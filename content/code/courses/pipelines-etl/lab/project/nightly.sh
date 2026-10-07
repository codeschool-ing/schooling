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
