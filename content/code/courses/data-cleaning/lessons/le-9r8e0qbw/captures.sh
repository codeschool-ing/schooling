#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of data-cleaning, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed: the lab, as lesson 1 left it; the files
# ana wrote (put below), whose contents the lesson shows in full; and
# /var/lib/clean-data/truth, which the lab's generator wrote and which no real
# data set has. The lesson says so wherever it reads from it.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, pandas 3.0.6,
# TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/clean$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
put() { lab exec "cat > '$1'"; }
block unmask-sql
on "psql -c \"SELECT count(*) FILTER (WHERE birth_year = '1900') AS was_1900, count(*) FILTER (WHERE NULLIF(birth_year, '1900') IS NULL) AS now_blank FROM raw.customers\""
on "psql -c \"SELECT channel, count(*) FILTER (WHERE discount IS NULL) AS blank, count(*) FILTER (WHERE COALESCE(discount, '0') = '0') AS no_coupon FROM raw.orders GROUP BY channel\""

put customers.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
unusable = customers["birth_year"].eq("1900") | customers["birth_year"].str.len().eq(2)
customers["birth_year"] = pd.to_numeric(customers["birth_year"].mask(unusable))
PY
block drop
on "python -c \"from customers import customers as c; print(len(c)); print((c['signup_channel'].value_counts(normalize=True) * 100).round(1).to_string()); kept = c.dropna(subset=['birth_year']); print(len(kept)); print((kept['signup_channel'].value_counts(normalize=True) * 100).round(1).to_string())\""

put minutes.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str, keep_default_na=False,
                     na_values=[""]).drop_duplicates()
own = orders[(orders["courier"] == "propria") & (orders["status"] != "cancelled")].copy()
own["minutes"] = pd.to_numeric(own["delivery_minutes"])


def report(label, minutes):
    print(f"{label:22} mean {minutes.mean():5.1f}  sd {minutes.std():4.1f}  "
          f"late {(minutes >= 90).mean() * 100:4.1f}%")
PY
put fill_zero.py <<'PY'
from minutes import own, report

report("recorded only", own["minutes"].dropna())
report("blanks as zero", own["minutes"].fillna(0))
PY
block fill-zero
on 'python fill_zero.py'

put fill_centre.py <<'PY'
from minutes import own, report

report("recorded only", own["minutes"].dropna())
report("blanks as the mean", own["minutes"].fillna(own["minutes"].mean()))
report("blanks as the median", own["minutes"].fillna(own["minutes"].median()))
PY
block fill-centre
on 'python fill_centre.py'

put birth_impute.py <<'PY'
import pandas as pd

from customers import customers

truth = pd.read_csv("/var/lib/clean-data/truth/people.csv", dtype={"birth_year": "Int64"})
both = customers.merge(truth[["customer_id", "birth_year"]], on="customer_id",
                       suffixes=("", "_true"))
blank = both["birth_year"].isna()
fills = {
    "true values": both["birth_year_true"],
    "overall median": both["birth_year"].fillna(both["birth_year"].median()),
    "median by channel": both["birth_year"].fillna(
        both.groupby("signup_channel")["birth_year"].transform("median")),
    "random draw": both["birth_year"].fillna(pd.Series(
        both["birth_year"].dropna().sample(blank.sum(), replace=True, random_state=1).values,
        index=both.index[blank])),
}
for label, filled in fills.items():
    error = (filled[blank] - both.loc[blank, "birth_year_true"]).abs().mean()
    print(f"{label:18} mean {filled.mean():6.1f}  sd {filled.std():4.1f}  "
          f"error on the filled rows {error:4.1f}")
PY
block birth-impute
on 'python birth_impute.py'

put daily.py <<'PY'
import pandas as pd

sales = pd.read_csv("raw/store_sales.csv", sep=";", encoding="latin-1", dtype=str)
sales["day"] = pd.to_datetime(sales["data"], format="%d/%m/%Y")
sales["reais"] = pd.to_numeric(sales["total"].str[3:].str.replace(",", "."))
batel = sales[sales["loja"] == "Batel"].groupby("day")["reais"].sum()
days = pd.date_range("2025-04-14", "2025-04-22")
week = batel.reindex(days)
print(pd.DataFrame({"as_found": week, "ffill": week.ffill(), "zero": week.fillna(0)}))
PY
block daily
on 'python daily.py'

put flag.py <<'PY'
from minutes import own, report

own["timing"] = own["minutes"].notna().map({True: "recorded", False: "over 120"})
print(own["timing"].value_counts().to_string())
floor = own["minutes"].fillna(120)
report("blanks as 120, a floor", floor)
PY
block flag
on 'python flag.py'

block truth-again
on "python -c \"import pandas as pd; t = pd.read_csv('/var/lib/clean-data/truth/orders.csv'); m = t.loc[t['what'] == 'minutes', 'value']; print(f'real: mean {m.mean():.1f}, late {(m >= 90).mean() * 100:.1f}%')\""

put fill.sql <<'SQL'
CREATE OR REPLACE VIEW orders_filled AS
SELECT order_id,
       COALESCE(discount, '0')                        AS discount,
       delivery_minutes,
       CASE WHEN fulfilment = 'pickup'    THEN 'no delivery'
            WHEN status = 'cancelled'     THEN 'no delivery'
            WHEN courier = 'Rapidex'      THEN 'not reported'
            WHEN delivery_minutes IS NULL THEN 'over 120'
            ELSE 'recorded' END                       AS timing
FROM (SELECT DISTINCT * FROM raw.orders) o;
SQL
block fill-sql
on 'psql -f fill.sql'
on "psql -c 'SELECT timing, count(*) FROM orders_filled GROUP BY timing ORDER BY count(*) DESC'"
