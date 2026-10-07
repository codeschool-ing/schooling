#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of data-cleaning, as a script that
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
# earlier lesson showed (when.py from lesson 7, keyed.py, categorise.py and
# category_map.csv from lesson 8, lines.py, orders.py and typos.py from
# lesson 9, ready.py and derive.py from lesson 12); and
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
put keyed.py <<'PY'
import unicodedata

import pandas as pd


def plain(text):
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return " ".join(text.lower().split())


products = pd.read_csv("raw/products.csv", dtype=str)
products["category_key"] = products["category"].map(plain)
PY
put categorise.py <<'PY'
import pandas as pd

from keyed import products

mapping = pd.read_csv("category_map.csv", dtype=str)
if mapping["category_key"].duplicated().any():
    raise SystemExit("category_map.csv lists a spelling twice")
products = products.merge(mapping, on="category_key", how="left",
                          suffixes=("_raw", ""), validate="many_to_one")
unmapped = products[products["category"].isna()]
if len(unmapped):
    raise SystemExit(f"{len(unmapped)} products have a category the map does not know: "
                     f"{sorted(unmapped['category_raw'].unique())}")
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
put derive.py <<'PY'
from lines import lines
from ready import orders

CORPORATE = "Ltda|Escritório|Clínica|Colégio|Agência|Studio"  # lesson 9's December buyers

orders["hour"] = orders["placed"].dt.hour
orders["weekday"] = orders["placed"].dt.day_name()
orders["items"] = orders["order_id"].map(lines.groupby("order_id").size())
orders["corporate"] = orders["name"].str.contains(CORPORATE, na=False)
PY
put category_map.csv <<'CSV'
category_key,category,department
frutas,Frutas,Hortifruti
fruta,Frutas,Hortifruti
fruits,Frutas,Hortifruti
verduras,Verduras,Hortifruti
folhas,Verduras,Hortifruti
legumes,Legumes,Hortifruti
legume,Legumes,Hortifruti
ovos e laticinios,Ovos e laticínios,Frios
laticinios,Ovos e laticínios,Frios
graos e cereais,Grãos e cereais,Mercearia
graos,Grãos e cereais,Mercearia
mercearia,Mercearia,Mercearia
emporio,Mercearia,Mercearia
cestas,Cestas,Cestas
cesta,Cestas,Cestas
CSV

put explore.py <<'PY'
from categorise import products  # lesson 8: one category and department per product
from derive import orders  # lesson 12: decided totals, hour, weekday, items, corporate
from lines import lines

delivered = orders[orders["status"] == "delivered"].copy()
delivered["month"] = delivered["placed"].dt.to_period("M")
catalogue = products.drop_duplicates("product_code").rename(columns={"product_code": "code"})
sold = lines[lines["order_id"].isin(delivered["order_id"])].merge(
    catalogue[["code", "category", "department"]], on="code", how="left", validate="many_to_one")
PY

block one-column
on "python -c \"from explore import delivered as d; print(d[['total', 'items']].describe().round(2).to_string()); print(round(d['total'].skew(), 1), round(d['items'].skew(), 1))\""

block hours
on "python -c \"from explore import delivered as d; print(d.groupby('hour').size().to_string()); print(round(d['hour'].mean(), 1))\""

block months
on "python -c \"from explore import delivered as d; t = d.pivot_table(index='month', columns='corporate', values='total', aggfunc='sum', fill_value=0); t.columns = ['households', 'corporate']; print(t.round(2).to_string())\""

block sugar
on "python -c \"from explore import sold, delivered; s = sold[sold['code'] == '00343'].merge(delivered[['order_id', 'month']], on='order_id'); print(s.groupby('month')['unit_price'].agg(['size', 'min', 'max']).to_string())\""

block categories
on "python -c \"from explore import sold; r = sold.groupby('category', dropna=False)['line_cents'].sum() / 100; print(r.sort_values(ascending=False).to_string()); print(round(r.sum(), 2))\""

block relationships
on "python -c \"from explore import delivered as d; print(round(d['items'].corr(d['total']), 3), round(d['items'].rank().corr(d['total'].rank()), 3)); h = d[~d['corporate']]; print(round(h['items'].corr(h['total']), 3))\""
on "python -c \"import pandas as pd; from explore import delivered as d; print(pd.crosstab(d['channel'], d['payment'], normalize='index').round(3).to_string())\""

put plots.py <<'PY'
import matplotlib

matplotlib.use("Agg")  # draw to a file; there is no screen here
import matplotlib.pyplot as plt

from explore import delivered

monthly = delivered.pivot_table(index="month", columns="corporate", values="total",
                                aggfunc="sum", fill_value=0)
fig, ax = plt.subplots(figsize=(8, 4))
monthly.plot.bar(stacked=True, ax=ax, color=["#4a7fd4", "#e0a030"])
ax.set_xlabel("")
ax.set_ylabel("revenue, R$")
ax.legend(["households", "corporate"])
fig.tight_layout()
fig.savefig("months.png", dpi=120)
print("months.png:", monthly.shape[0], "months")
PY

block plots
on "python plots.py"
on "file months.png"

block sql
on "python -c \"from explore import delivered as d; print(d.groupby('channel')['total'].agg(['size', 'median', 'mean']).round(2).to_string())\""
on "psql -c \"SELECT channel, count(*), percentile_cont(0.5) WITHIN GROUP (ORDER BY total::numeric) AS median, round(avg(total::numeric), 2) AS mean FROM (SELECT DISTINCT * FROM raw.orders) o WHERE status = 'delivered' GROUP BY channel\""
on "psql -c \"SELECT corr(n.items, o.total::numeric) AS pearson FROM (SELECT DISTINCT * FROM raw.orders) o JOIN (SELECT order_id, count(*) AS items FROM raw.order_items GROUP BY order_id) n USING (order_id) WHERE o.status = 'delivered'\""
