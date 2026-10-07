#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of data-cleaning, as a script that
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
# earlier lesson showed (when.py and money.py from lesson 7, lines.py,
# orders.py and typos.py from lesson 9, ready.py from lesson 12); and
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
put money.py <<'PY'
from decimal import Decimal


def reais(text):
    """'R$ 1.234,56' -> Decimal('1234.56'). Refuses anything else."""
    digits = text.removeprefix("R$").strip().replace(".", "").replace(",", ".")
    value = Decimal(digits)
    if value != value.quantize(Decimal("0.01")):
        raise ValueError(f"more than two decimals: {text!r}")
    return value
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
put ready.py <<'PY'
from orders import orders  # lesson 9: totals as numbers, each customer's name from the CRM
from typos import wrong
from when import orders as timed

fix = orders["order_id"].isin(wrong["order_id"])
orders.loc[fix, "total"] = orders.loc[fix, "order_id"].map(wrong.set_index("order_id")["expected"])
orders["total"] = orders["total"].clip(lower=0)  # lesson 9: a coupon above the basket is charged 0
orders["placed"] = orders["order_id"].map(timed.set_index("order_id")["placed"])
PY

block wide
on "head -3 raw/targets_2025.csv"

block melt-total
on "python -c \"import pandas as pd; w = pd.read_csv('raw/targets_2025.csv'); long = w.melt(id_vars='loja', var_name='month', value_name='target'); print(len(long)); print(long['target'].sum(), w['Total'].sum())\""

block month-locale
on "python -c \"import pandas as pd; print(pd.to_datetime('fev/25', format='%b/%y'))\" 2>&1 | grep ^ValueError"

put targets.py <<'PY'
import pandas as pd

wide = pd.read_csv("raw/targets_2025.csv", dtype=str).set_index("loja").astype(int)
MONTHS = [c for c in wide.columns if c != "Total"]
# The Total column is a second record of the same targets: check it, then leave it behind.
off = wide[MONTHS].sum(axis=1) != wide["Total"]
if off.any():
    raise ValueError(f"Total disagrees with the months for {list(wide.index[off])}")

MES = {"jan": 1, "fev": 2, "mar": 3, "abr": 4, "mai": 5, "jun": 6,
       "jul": 7, "ago": 8, "set": 9, "out": 10, "nov": 11, "dez": 12}
targets = wide[MONTHS].reset_index().melt(id_vars="loja", var_name="header", value_name="target")
number = targets["header"].str[:3].map(MES)
if number.isna().any():
    raise ValueError(f"unknown month headers: {sorted(targets.loc[number.isna(), 'header'].unique())}")
year = 2000 + targets["header"].str[-2:].astype(int)
targets["month"] = pd.PeriodIndex.from_fields(year=year, month=number, freq="M")
targets = targets.drop(columns="header")
PY

block targets
on "python -c \"from targets import targets; print(len(targets), targets['target'].sum()); print(targets.head(3).to_string(index=False)); print(targets['month'].dtype)\""

put actuals.py <<'PY'
import pandas as pd

from money import reais
from ready import orders

shops = pd.read_csv("raw/store_sales.csv", sep=";", encoding="latin-1", dtype=str)
shops["month"] = pd.to_datetime(shops["data"], format="%d/%m/%Y").dt.to_period("M")
shops["amount"] = shops["total"].map(reais).astype(float)

online = orders[orders["status"] == "delivered"].copy()
online["loja"] = "Online"
online["month"] = online["placed"].dt.to_period("M")
online["amount"] = online["total"]

sales = pd.concat([shops[["loja", "month", "amount"]], online[["loja", "month", "amount"]]])
actuals = sales.groupby(["loja", "month"], as_index=False)["amount"].sum()
PY

block pivot-fails
on "python -c \"from actuals import sales; sales.pivot(index='loja', columns='month', values='amount')\" 2>&1 | tail -1"
on "python -c \"from actuals import sales; print(len(sales), len(sales[['loja', 'month']].drop_duplicates()))\""

block pivot-table
on "python -c \"from actuals import sales; w = sales.pivot_table(index='loja', columns='month', values='amount', aggfunc='sum'); print(w.shape); print(w.iloc[:, :3].round(2).to_string())\""

put attainment.py <<'PY'
from actuals import actuals
from targets import targets

both = targets.merge(actuals, on=["loja", "month"], how="left", validate="one_to_one",
                     indicator=True)
missing = both[both["_merge"] == "left_only"]
if len(missing):
    raise ValueError(f"targets with no sales: {missing[['loja', 'month']].values.tolist()}")
both["attainment"] = both["amount"] / both["target"]

if __name__ == "__main__":
    year = both.groupby("loja")[["target", "amount"]].sum()
    year["attainment"] = (year["amount"] / year["target"]).round(3)
    print(year.round(2).sort_values("attainment").to_string())
PY

block attainment
on "python attainment.py"

put unpivot.sql <<'SQL'
SELECT t.loja, m.month, m.target::int AS target
FROM raw.targets_2025 t
CROSS JOIN LATERAL (VALUES
  ('2025-01', t."jan/25"), ('2025-02', t."fev/25"), ('2025-03', t."mar/25"),
  ('2025-04', t."abr/25"), ('2025-05', t."mai/25"), ('2025-06', t."jun/25"),
  ('2025-07', t."jul/25"), ('2025-08', t."ago/25"), ('2025-09', t."set/25"),
  ('2025-10', t."out/25"), ('2025-11', t."nov/25"), ('2025-12', t."dez/25")
) AS m(month, target)
ORDER BY t.loja, m.month;
SQL

block sql-unpivot
on "psql -c \"CREATE VIEW targets_long AS \$(cat unpivot.sql | tr -d ';')\""
on "psql -c 'SELECT count(*), sum(target) FROM targets_long'"
on "psql -c \"SELECT * FROM targets_long WHERE loja = 'Batel' LIMIT 3\""

block sql-pivot
on "psql -c \"SELECT loja, sum(target) FILTER (WHERE month = '2025-01') AS jan, sum(target) FILTER (WHERE month = '2025-02') AS feb, sum(target) FILTER (WHERE month = '2025-03') AS mar, sum(target) AS year FROM targets_long GROUP BY loja ORDER BY year DESC\""
