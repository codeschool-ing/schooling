#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of data-cleaning, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed: the lab, as lesson 1 left it; the files
# ana wrote (put below), whose contents the lesson shows in full or which an
# earlier lesson showed (when.py from lesson 7, lines.py, orders.py and
# typos.py from lesson 9, raw_customers.py and years.py from lesson 10); and
# ~/clean-data/truth, which the lab's generator wrote and which no real
# data set has. The lesson says so wherever it reads from it.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.12, pandas 3.0.6,
# TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/clean$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
put() { lab exec "cat > '$1'"; }
lab reset >/dev/null
put when.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str).drop_duplicates()
site = orders["channel"] == "site"
utc = pd.to_datetime(orders.loc[site, "ordered_at"], format="%Y-%m-%dT%H:%M:%SZ", utc=True)
local = pd.to_datetime(orders.loc[~site, "ordered_at"], format="%Y-%m-%d %H:%M:%S")
orders.loc[site, "placed"] = utc.dt.tz_convert("America/Sao_Paulo").dt.tz_localize(None)
orders.loc[~site, "placed"] = local
orders["placed"] = pd.to_datetime(orders["placed"])
PY
put lines.py <<'PY'
import pandas as pd

lines = pd.read_csv("raw/order_items.csv", dtype=str)
UNIT = {"kg": "kg", "KG": "kg", "Kg": "kg", "g": "g", "gr": "g", "un": "un", "UN": "un",
        "unid": "un"}
lines["unit"] = lines["unit"].map(UNIT)
lines["quantity"] = pd.to_numeric(lines["quantity"].str.replace(",", "."))
grams = lines["unit"] == "g"
lines.loc[grams, "quantity"] = lines.loc[grams, "quantity"] / 1000
lines.loc[grams, "unit"] = "kg"
lines["code"] = lines["product_code"].str.zfill(5)
lines["unit_price"] = pd.to_numeric(lines["unit_price"])
lines["line_cents"] = (lines["quantity"] * lines["unit_price"] * 100).round().astype(int)
PY
put orders.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str).drop_duplicates()
orders["total"] = pd.to_numeric(orders["total"])
customers = pd.read_csv("raw/customers.csv", dtype=str).drop_duplicates("customer_id")
customers["name"] = customers["name"].str.normalize("NFC")  # lesson 6
orders = orders.merge(customers[["customer_id", "name"]], on="customer_id", how="left")
PY
put typos.py <<'PY'
import pandas as pd

from lines import lines
from orders import orders

cents = lambda col: (pd.to_numeric(orders[col].fillna("0")) * 100).round().astype(int)
orders["expected"] = (orders["order_id"].map(lines.groupby("order_id")["line_cents"].sum())
                      - cents("discount") + cents("delivery_fee")) / 100
wrong = orders[(orders["total"] - orders["expected"]).abs() > 0.005].copy()
wrong["ratio"] = (wrong["total"] / wrong["expected"]).round(2)

if __name__ == "__main__":
    print(wrong[["order_id", "total", "expected", "ratio", "status"]].to_string(index=False))
PY
put raw_customers.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
PY
put years.py <<'PY'
import pandas as pd

from raw_customers import customers

year = customers["birth_year"].mask(customers["birth_year"] == "1900")
two = year.str.len() == 2
# Customers are adults: a two-digit year above 25 is 19xx, at most 25 is 20xx.
full = year.mask(two & (year > "25"), "19" + year).mask(two & (year <= "25"), "20" + year)
customers["birth"] = pd.to_numeric(full).astype("Int64")
PY

put ready.py <<'PY'
from orders import orders  # lesson 9: totals as numbers, each customer's name from the CRM
from typos import wrong
from when import orders as timed

fix = orders["order_id"].isin(wrong["order_id"])
orders.loc[fix, "total"] = orders.loc[fix, "order_id"].map(wrong.set_index("order_id")["expected"])
orders["total"] = orders["total"].clip(lower=0)  # lesson 9: a coupon above the basket is charged 0
orders["placed"] = orders["order_id"].map(timed.set_index("order_id")["placed"])
PY

put derive.py <<'PY'
from lines import lines
from ready import orders

CORPORATE = "Ltda|Escritório|Clínica|Colégio|Agência|Studio"  # lesson 9's December buyers

orders["hour"] = orders["placed"].dt.hour
orders["weekday"] = orders["placed"].dt.day_name()
orders["items"] = orders["order_id"].map(lines.groupby("order_id").size())
orders["corporate"] = orders["name"].str.contains(CORPORATE, na=False)
PY

block derived
on "python -c \"from derive import orders; print(orders[['order_id', 'placed', 'hour', 'weekday', 'items', 'total', 'corporate']].head(4).to_string(index=False))\""
on "python -c \"from derive import orders; print(orders['items'].isna().sum(), orders['corporate'].sum()); print(orders.groupby('weekday')['total'].agg(['size', 'median']).round(2).to_string())\""

put per_customer.py <<'PY'
import pandas as pd

from derive import orders
from years import customers

per = orders.groupby("customer_id").agg(orders=("order_id", "size"), revenue=("total", "sum"),
                                         first=("placed", "min"), last=("placed", "max"))
per["days_since"] = (pd.Timestamp("2026-01-01") - per["last"]).dt.days
per = per.join(customers.set_index("customer_id")["birth"])
per["age"] = 2025 - per["birth"]  # the age reached during 2025
PY

block grain
on "python -c \"from per_customer import per; print(len(per)); print(per.head(3).to_string())\""
on "python -c \"from derive import orders; from per_customer import per; wrong = orders.merge(per[['revenue']], left_on='customer_id', right_index=True); print(round(orders['total'].sum(), 2), round(wrong['revenue'].sum(), 2))\""

block cut-default
on "python -c \"import pandas as pd; from per_customer import per; a = per['age']; print((a == 25).sum()); print(pd.cut(a[a == 25], [18, 25, 35]).value_counts().to_string())\""

put bands.py <<'PY'
import pandas as pd

from per_customer import per

EDGES = [18, 25, 35, 45, 55, 65, 75]
LABELS = ["18-24", "25-34", "35-44", "45-54", "55-64", "65-74"]
per["age_band"] = pd.cut(per["age"], EDGES, right=False, labels=LABELS)
if per["age_band"].isna().sum() != per["age"].isna().sum():
    raise ValueError("an age fell outside the edges")
per["spend_tier"] = pd.qcut(per["revenue"], 4, labels=["low", "mid-low", "mid-high", "high"])

if __name__ == "__main__":
    print(per["age_band"].value_counts(sort=False, dropna=False).to_string())
    print(per.groupby("spend_tier", observed=True)["revenue"].agg(["size", "min", "max"]).round(2).to_string())
PY

block bands
on "python bands.py"

block bins-sql
on "psql -c \"SELECT width_bucket(total::numeric, 0, 200, 4) AS bucket, min(total::numeric), max(total::numeric), count(*) FROM (SELECT DISTINCT * FROM raw.orders) o GROUP BY 1 ORDER BY 1\""

put scale.py <<'PY'
from per_customer import per

r = per["revenue"]
per["minmax"] = (r - r.min()) / (r.max() - r.min())
per["z"] = (r - r.mean()) / r.std()
per["pct"] = r.rank(pct=True)

if __name__ == "__main__":
    print(per[["revenue", "minmax", "z", "pct"]].describe().round(3).to_string())
    print(per.nlargest(2, "revenue")[["revenue", "minmax", "z", "pct"]].round(3).to_string())
PY

block scale
on "python scale.py"

block log-zero
on "python -c \"import numpy as np; from ready import orders; t = orders['total']; print((t == 0).sum()); print(np.log10(t).min())\" 2>&1"

put logs.py <<'PY'
import numpy as np

from ready import orders

paid = orders["total"] > 0  # 137 orders were charged nothing (lesson 9)
orders["log_total"] = np.log10(orders["total"].where(paid))

if __name__ == "__main__":
    t, lg = orders["total"], orders["log_total"]
    print(f"blank logs: {lg.isna().sum()}")
    print(f"mean {t.mean():.2f}  median {t.median():.2f}  geometric mean {10 ** lg.mean():.2f}")
    print(f"skew: total {t.skew():.1f}, log_total {lg.skew():.2f}")
PY

block logs
on "python logs.py"
