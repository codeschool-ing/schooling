#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of data-cleaning, as a script that
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
exec 9>/var/tmp/clean-capture.lock; flock 9
lab reset >/dev/null

put blanks.py <<'PY'
import glob

import pandas as pd

for path in sorted(glob.glob("raw/*.csv")):
    latin = "store_sales" in path
    df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[""],
                     encoding="latin-1" if latin else "utf-8", sep=";" if latin else ",")
    empty = df.isna().sum()
    for column, n in empty[empty > 0].items():
        print(f"{path:22} {column:18} {n:6} of {len(df)}")
PY
block blanks
on 'python blanks.py'

block not-blank
on "psql -c \"SELECT discount, count(*) FROM raw.orders WHERE channel = 'app' GROUP BY discount ORDER BY count(*) DESC\""
on "psql -c \"SELECT marketing_opt_in, count(*) FROM raw.customers WHERE signup_channel = 'store' GROUP BY marketing_opt_in ORDER BY count(*) DESC\""

block walk-in
on "psql -c \"SELECT cliente IS NULL AS no_customer, count(*), round(avg(replace(substr(total, 4), ',', '.')::numeric), 2) AS avg_total FROM raw.store_sales GROUP BY 1\""

put pattern.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str, keep_default_na=False,
                     na_values=[""]).drop_duplicates()
orders["segment"] = orders["fulfilment"] + " / " + orders["courier"].fillna("-")
share = (orders[["courier", "delivery_minutes", "discount"]].isna()
         .groupby([orders["channel"], orders["segment"]]).mean() * 100)
print(share.round(1))
PY
block pattern
on 'python pattern.py'

block own-by-status
on "psql -c \"SELECT status, count(*) AS orders, count(delivery_minutes) AS timed FROM (SELECT DISTINCT * FROM raw.orders) o WHERE courier = 'propria' GROUP BY status ORDER BY orders DESC\""

put own_fleet.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str, keep_default_na=False,
                     na_values=[""]).drop_duplicates()
own = orders[(orders["courier"] == "propria") & (orders["status"] != "cancelled")].copy()
own["missing"] = own["delivery_minutes"].isna()
own["minutes"] = pd.to_numeric(own["delivery_minutes"])
print(f"own-fleet deliveries: {len(own)}, without a time: {own['missing'].sum()}")
print(own["minutes"].describe().round(1).to_string())
PY
block own-fleet
on 'python own_fleet.py'

put by_hour.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str, keep_default_na=False,
                     na_values=[""]).drop_duplicates()
app = orders[(orders["channel"] == "app") & (orders["courier"] == "propria")
             & (orders["status"] != "cancelled")].copy()
app["hour"] = app["ordered_at"].str[11:13]
app["evening"] = app["hour"].isin(["18", "19", "20"])
rate = app.groupby("evening")["delivery_minutes"].apply(lambda m: m.isna().mean() * 100)
rate.index = ["other hours", "18:00 to 20:59"]
print("% without a time")
print(rate.round(1).to_string())
PY
block by-hour
on 'python by_hour.py'

block near-ceiling
on "psql -c \"SELECT delivery_minutes::int / 10 * 10 AS from_minute, count(*) FROM raw.orders WHERE courier = 'propria' AND delivery_minutes IS NOT NULL GROUP BY 1 ORDER BY 1 DESC LIMIT 4\""

put truth_minutes.py <<'PY'
import pandas as pd

truth = pd.read_csv("/var/lib/clean-data/truth/orders.csv")
real = truth.loc[truth["what"] == "minutes", "value"]
unseen = real[real >= 120]
print(f"deliveries the timer never recorded: {len(unseen)}")
print(f"their real times: {unseen.min()} to {unseen.max()} minutes")
print(f"mean of the recorded times: {real[real < 120].mean():.1f}")
print(f"mean of all the real times: {real.mean():.1f}")
seen = real[real < 120]
print(f"late (90 minutes or more), as recorded: {(seen >= 90).mean() * 100:.1f}%")
print(f"late (90 minutes or more), really:      {(real >= 90).mean() * 100:.1f}%")
PY
block truth-minutes
on 'python truth_minutes.py'

put survey.py <<'PY'
import pandas as pd

survey = pd.read_csv("raw/survey.csv", dtype=str, keep_default_na=False, na_values=[""])
orders = pd.read_csv("raw/orders.csv", dtype=str, keep_default_na=False,
                     na_values=[""]).drop_duplicates()
both = survey.merge(orders[["order_id", "courier", "delivery_minutes"]], on="order_id")
both["answered"] = both["nps"].notna()
print(f"invitations: {len(both)}, answered: {both['answered'].sum()} "
      f"({both['answered'].mean() * 100:.1f}%)")
own = both[both["courier"] == "propria"].copy()
own["band"] = pd.cut(pd.to_numeric(own["delivery_minutes"]), [0, 40, 60, 80, 120],
                     right=False)
print((own.groupby("band", observed=True)["answered"].mean() * 100).round(1).to_string())
PY
block survey
on 'python survey.py'

put nps_truth.py <<'PY'
import pandas as pd


def nps(scores):
    return round(((scores >= 9).mean() - (scores <= 6).mean()) * 100, 1)


survey = pd.read_csv("raw/survey.csv")
truth = pd.read_csv("/var/lib/clean-data/truth/nps.csv")
print("NPS from the answers:      ", nps(survey["nps"].dropna()))
print("NPS of everybody invited:  ", nps(truth["nps"]))
PY
block nps-truth
on 'python nps_truth.py'
