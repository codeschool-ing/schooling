#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of data-cleaning, as a script that
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
block ambiguous
on "python -c \"import pandas as pd; print(pd.to_datetime('03/04/2025'), pd.to_datetime('03/04/2025', dayfirst=True))\""

block proof
on "psql -c \"SELECT signup_channel, count(*) FILTER (WHERE split_part(signed_up, '/', 1)::int > 12) AS first_over_12, count(*) FILTER (WHERE split_part(signed_up, '/', 2)::int > 12) AS second_over_12 FROM raw.customers WHERE signed_up LIKE '%/%' GROUP BY 1\""

put dates.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
FORMATS = {"site": "%Y-%m-%d", "app": "%m/%d/%Y", "store": "%d/%m/%Y"}


def parse(row):
    text = row["signed_up"]
    if row["signup_channel"] in FORMATS:
        return pd.to_datetime(text, format=FORMATS[row["signup_channel"]], errors="coerce")
    # the 2023 migration copied all three systems' records
    if "-" in text:
        return pd.to_datetime(text, format="%Y-%m-%d")
    first, second = int(text[:2]), int(text[3:5])
    if first > 12:
        return pd.to_datetime(text, format="%d/%m/%Y")
    if second > 12:
        return pd.to_datetime(text, format="%m/%d/%Y")
    return pd.NaT  # both readings are dates: nothing in the value decides


customers["signed"] = customers.apply(parse, axis=1)
PY
block parse
on "python -c \"from dates import customers as c; print(c['signed'].isna().sum()); print(c.groupby('signup_channel')['signed'].agg(['min', 'max', 'count']))\""

block migration
on "python -c \"from dates import customers as c; m = c[c['signed'].isna()]; print(m[['customer_id', 'signed_up', 'signup_channel']].head(4).to_string(index=False))\""

block sql-dates
on "psql -c \"SELECT signup_channel, min(d), max(d) FROM (SELECT signup_channel, CASE signup_channel WHEN 'site' THEN to_date(signed_up, 'YYYY-MM-DD') WHEN 'app' THEN to_date(signed_up, 'MM/DD/YYYY') WHEN 'store' THEN to_date(signed_up, 'DD/MM/YYYY') END AS d FROM raw.customers) t GROUP BY 1\""

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
block tz
on "python -c \"from when import orders as o; s = o[o['channel'] == 'site']; print(s[['ordered_at', 'placed']].head(3).to_string(index=False)); print((s['ordered_at'].str[:10] != s['placed'].dt.strftime('%Y-%m-%d')).sum())\""

block sql-tz
on "psql -c \"SELECT ordered_at, (ordered_at::timestamptz AT TIME ZONE 'America/Sao_Paulo') AS placed FROM raw.orders WHERE channel = 'site' LIMIT 3\""

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
block money
on "python -c \"from money import reais; print(reais('R\$ 94,50'), reais('R\$ 1.234,56'), int(reais('R\$ 1.234,56') * 100))\""
on "python -c \"print(float('1.234,56'.replace(',', '.')))\" 2>&1 | tail -1"
on "python -c \"print(0.1 + 0.2, sum([0.1] * 10))\""

block store-total
on "python -c \"import pandas as pd; from money import reais; s = pd.read_csv('raw/store_sales.csv', sep=';', encoding='latin-1', dtype=str); c = s['total'].map(reais).map(lambda v: int(v * 100)); print(len(c), c.sum(), c.min(), c.max())\""

block sql-money
on "psql -c \"SELECT total, replace(replace(substr(total, 4), '.', ''), ',', '.')::numeric(12, 2) AS reais FROM raw.store_sales LIMIT 3\""

block fx
on 'cat raw/fx_rates_2025.csv | head -4'

put invoices.py <<'PY'
import pandas as pd

invoices = pd.read_csv("raw/invoices.csv", dtype=str)
rates = pd.read_csv("raw/fx_rates_2025.csv", dtype=str)
FORMATS = {"Sítio Boa Terra": "%d/%m/%Y", "Cooperativa Vale Verde": "%d/%m/%Y",
           "Fazenda Santa Clara": "%Y-%m-%d", "Green Valley Seeds Inc.": "%m/%d/%Y",
           "Oliveira Hermanos SL": "%d.%m.%Y"}
invoices["issued"] = [pd.to_datetime(d, format=FORMATS[s])
                      for d, s in zip(invoices["issued"], invoices["supplier"])]
invoices["month"] = invoices["issued"].dt.strftime("%Y-%m")
invoices = invoices.merge(rates, on="month", how="left", validate="many_to_one")
invoices["rate"] = 1.0
for currency, column in {"USD": "usd_brl", "EUR": "eur_brl"}.items():
    is_it = invoices["currency"] == currency
    invoices.loc[is_it, "rate"] = pd.to_numeric(invoices.loc[is_it, column])
invoices["amount_brl"] = (pd.to_numeric(invoices["amount"]) * invoices["rate"]).round(2)
KG = {"kg": 1, "t": 1000, "lb": 0.45359237}
invoices["kg"] = (pd.to_numeric(invoices["weight"])
                  * invoices["weight_unit"].map(KG)).round(1)
PY
block invoices
on "python -c \"from invoices import invoices as i; print(i[['invoice', 'currency', 'amount', 'amount_brl', 'weight', 'weight_unit', 'kg']].head(4).to_string(index=False)); print(i.groupby('currency')['amount_brl'].sum().round(2).to_string())\""

block units
on "psql -c 'SELECT unit, count(*) FROM raw.order_items GROUP BY unit ORDER BY count(*) DESC'"
on "psql -c \"SELECT count(*) FILTER (WHERE quantity LIKE '%,%') AS comma, count(*) FILTER (WHERE quantity LIKE '%.%') AS point FROM raw.order_items\""

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
lines["line_cents"] = (lines["quantity"] * pd.to_numeric(lines["unit_price"]) * 100).round().astype(int)
PY
block lines
on "python -c \"from lines import lines as l; print(l['unit'].value_counts(dropna=False).to_string()); print(l[['product_code', 'code', 'quantity', 'unit', 'unit_price', 'line_cents']].head(4).to_string(index=False))\""

block check-total
on "python -c \"import pandas as pd; from lines import lines as l; o = pd.read_csv('raw/orders.csv', dtype=str).drop_duplicates(); o['cents'] = (pd.to_numeric(o['total']) * 100).round().astype(int); o['fee'] = (pd.to_numeric(o['delivery_fee']) * 100).round().astype(int); o['disc'] = (pd.to_numeric(o['discount'].fillna('0')) * 100).round().astype(int); s = l.groupby('order_id')['line_cents'].sum(); o['expected'] = o['order_id'].map(s) - o['disc'] + o['fee']; print((o['cents'] == o['expected']).sum(), (o['cents'] != o['expected']).sum())\""

block codes
on "python -c \"import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); print(l['product_code'].isin(p['product_code']).mean().round(3), l['code'].isin(p['product_code']).mean().round(4)); print(sorted(set(l['code']) - set(p['product_code'])))\""
