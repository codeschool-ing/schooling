#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of data-cleaning, as a script that
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
put orders.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str).drop_duplicates()
orders["total"] = pd.to_numeric(orders["total"])
customers = pd.read_csv("raw/customers.csv", dtype=str).drop_duplicates("customer_id")
customers["name"] = customers["name"].str.normalize("NFC")  # lesson 6
orders = orders.merge(customers[["customer_id", "name"]], on="customer_id", how="left")
PY
put rules.py <<'PY'
from orders import orders

total = orders["total"]
q1, q3 = total.quantile([0.25, 0.75])
fence = q3 + 1.5 * (q3 - q1)
z = (total - total.mean()) / total.std()
median = total.median()
mad = (total - median).abs().median()
robust = (total - median) / (1.4826 * mad)
print(f"IQR fence at R$ {fence:.2f}: {(total > fence).sum()} orders above it")
print(f"z-score above 3 (mean {total.mean():.2f}, sd {total.std():.2f}): {(z > 3).sum()} orders")
print(f"robust z above 3.5 (median {median:.2f}, MAD {mad:.2f}): {(robust > 3.5).sum()} orders")
PY
block rules
on 'python rules.py'

block top
on "python -c \"from orders import orders as o; print(o.nlargest(12, 'total')[['order_id', 'ordered_at', 'name', 'total', 'status']].to_string(index=False))\""

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
block typos
on 'python typos.py'

block corporate
on "python -c \"from orders import orders as o; big = o[o['total'] > 1000]; print(big.groupby('name')['total'].agg(['count', 'min', 'max']).round(2).to_string()); print(big['ordered_at'].str[:10].min(), big['ordered_at'].str[:10].max())\""

block corporate-lines
on "python -c \"from lines import lines as l; from orders import orders as o; big = o[(o['total'] > 1000) & o['name'].str.contains('Ltda', na=False)]['order_id'].iloc[0]; print(l[l['order_id'] == big][['code', 'quantity', 'unit', 'unit_price', 'line_cents']].to_string(index=False))\""

put refunds.py <<'PY'
import pandas as pd

from orders import orders

orders["placed"] = pd.to_datetime(orders["ordered_at"].str[:19].str.replace("T", " "))
per = orders.groupby("customer_id").agg(
    orders=("order_id", "count"),
    refunded=("status", lambda s: (s == "refunded").sum()),
    first=("placed", "min"),
    last=("placed", "max"),
)
per["refund_rate"] = (per["refunded"] / per["orders"]).round(2)
print(f"customers: {len(per)}, median refund rate: {per['refund_rate'].median():.2f}")
print(per.sort_values("refunded", ascending=False).head(4).to_string())
PY
block refunds
on 'python refunds.py'

block refund-account
on "psql -c \"SELECT DISTINCT customer_id, signed_up, signup_channel, normalize(city, NFC) AS city FROM raw.customers WHERE customer_id = (SELECT customer_id FROM raw.orders WHERE status = 'refunded' GROUP BY 1 ORDER BY count(*) DESC LIMIT 1)\""

block sugar
on "python -c \"from lines import lines as l; s = l[l['code'] == '00343'].copy(); s['month'] = s['order_id'].astype(int); import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str).drop_duplicates(); s = s.merge(o[['order_id', 'ordered_at']], on='order_id'); s['month'] = s['ordered_at'].str[:7]; print(s.groupby(['month', 'unit_price']).size().to_string())\""

block sugar-cost
on "python -c \"from lines import lines as l; s = l[(l['code'] == '00343') & (l['unit_price'] > 100)]; print(len(s), s['order_id'].nunique(), round(s['line_cents'].sum() / 100, 2), round((s['quantity'] * (134.90 - 12.90)).sum(), 2))\""

block sql-fence
on "psql -c \"WITH t AS (SELECT DISTINCT order_id, total::numeric AS total FROM raw.orders), q AS (SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY total) AS q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY total) AS q3 FROM t) SELECT round((q3 + 1.5 * (q3 - q1))::numeric, 2) AS fence, (SELECT count(*) FROM t WHERE total > q3 + 1.5 * (q3 - q1)) AS above FROM q\""

put decide.py <<'PY'
import pandas as pd

from orders import orders
from typos import wrong

decided = orders.copy()
decided["flag"] = "none"
fix = decided["order_id"].isin(wrong["order_id"])
decided.loc[fix, "total"] = decided.loc[fix, "order_id"].map(
    wrong.set_index("order_id")["expected"])
decided.loc[fix, "flag"] = "total recomputed from lines"
negative = decided["total"] < 0
decided.loc[negative, "total"] = 0.0
decided.loc[negative, "flag"] = "coupon above basket: charged 0"
corporate = decided["name"].str.contains("Ltda|Escritório|Clínica|Colégio|Agência|Studio", na=False)
decided.loc[corporate, "flag"] = "corporate order"
delivered = decided["status"] == "delivered"
for label, frame in [("as exported", orders[orders["status"] == "delivered"]),
                     ("decided", decided[delivered]),
                     ("decided, households only", decided[delivered & ~corporate])]:
    print(f"{label:25} revenue {frame['total'].sum():12,.2f}  mean {frame['total'].mean():6.2f}  "
          f"median {frame['total'].median():6.2f}")
print(decided["flag"].value_counts().to_string())
PY
block decide
on 'python decide.py'
