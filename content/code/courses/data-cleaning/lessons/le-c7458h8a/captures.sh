#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of data-cleaning, as a script that
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
# earlier lesson showed (lines.py and when.py from lessons 7 and 9, keys.py,
# match.py and merge.py from lesson 5, run once to write survivors.csv); and
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
put keys.py <<'PY'
import unicodedata

import pandas as pd


def plain(text):
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return " ".join(text.lower().split())


customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
customers["name_key"] = customers["name"].map(plain)
customers["email_key"] = customers["email"].str.strip().str.lower()
customers["cep_key"] = customers["cep"].str.replace("-", "").str.zfill(8)
PY
put match.py <<'PY'
import itertools

import pandas as pd
from rapidfuzz import fuzz

from keys import customers

customers["block"] = customers["name_key"].str.split().str[-1]
pairs = []
for _, group in customers.groupby("block"):
    for a, b in itertools.combinations(group.to_dict("records"), 2):
        pairs.append({
            "a": a["customer_id"], "b": b["customer_id"],
            "name": fuzz.token_sort_ratio(a["name_key"], b["name_key"]),
            "email": pd.notna(a["email_key"]) and a["email_key"] == b["email_key"],
            "cep": a["cep_key"] == b["cep_key"],
        })
pairs = pd.DataFrame(pairs)

if __name__ == "__main__":
    n = len(customers)
    print(f"{n} customers: {n * (n - 1) // 2} possible pairs, {len(pairs)} compared")
PY
put merge.py <<'PY'
import pandas as pd

from keys import customers
from match import pairs

same = pairs[(pairs["name"] >= 85) & (pairs["email"] | pairs["cep"])]
keep = {}
for a, b in zip(same["a"], same["b"]):
    keep[max(a, b)] = min(a, b)
survivor = pd.Series(keep, name="kept_id").rename_axis("customer_id").reset_index()
survivor.to_csv("survivors.csv", index=False)
print(f"{len(survivor)} records point at an earlier one; first lines of survivors.csv:")
print(survivor.head(3).to_string(index=False))

orders = pd.read_csv("raw/orders.csv", dtype=str).drop_duplicates()
moved = orders["customer_id"].isin(survivor["customer_id"])
print(f"orders that change owner: {moved.sum()}")
before = orders["customer_id"].nunique()
orders["customer_id"] = orders["customer_id"].replace(dict(zip(survivor["customer_id"],
                                                                survivor["kept_id"])))
print(f"customers with orders: {before} before, {orders['customer_id'].nunique()} after")
PY
lab exec "python merge.py" >/dev/null

block order-key
on "python -c \"import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str); print(len(o), o['order_id'].nunique(), o.drop_duplicates()['order_id'].is_unique)\""

block product-key
on "python -c \"import pandas as pd; p = pd.read_csv('raw/products.csv', dtype=str); print(len(p), p['product_code'].nunique()); print(p[p['product_code'].duplicated(keep=False)].sort_values(['product_code', 'price']).to_string(index=False))\""

block sql-key
on "psql -c \"SELECT product_code, count(*) AS rows, string_agg(price, ' / ' ORDER BY price) AS prices FROM raw.products GROUP BY product_code HAVING count(*) > 1 ORDER BY product_code\""

block fan-out
on "python -c \"import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); m = l.merge(p, left_on='code', right_on='product_code', how='left', suffixes=('', '_catalogue')); print(len(l), len(m)); print(l['line_cents'].sum() / 100, m['line_cents'].sum() / 100)\""

block validate
on "python -c \"import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); l.merge(p, left_on='code', right_on='product_code', how='left', validate='many_to_one')\" 2>&1 | grep ^pandas.errors"

put catalogue.py <<'PY'
import pandas as pd

products = pd.read_csv("raw/products.csv", dtype=str)
# Three codes are listed twice, at two prices and with no date. What a line was
# charged is on the line; the catalogue is used for names and categories only.
names = products.groupby("product_code")["name"].nunique()
if (names > 1).any():
    raise ValueError(f"codes with two names: {list(names[names > 1].index)}")
catalogue = (products.drop_duplicates("product_code")
             .rename(columns={"product_code": "code"})[["code", "name", "category"]])
PY

put joins.py <<'PY'
def join(left, right, on, how="left", validate="many_to_one"):
    """Join, and say how many rows went in, came out and found nothing."""
    out = left.merge(right, on=on, how=how, validate=validate, indicator=True)
    alone = (out["_merge"] == "left_only").sum()
    print(f"join on {on}: {len(left)} rows in, {len(out)} out, {alone} with no match")
    return out.drop(columns="_merge")
PY

block checked
on "python -c \"from lines import lines; from catalogue import catalogue; from joins import join; j = join(lines, catalogue, 'code'); print(j[j['name'].isna()].groupby('code').agg(lines=('order_id', 'size'), price=('unit_price', 'first')).to_string())\""

block inner
on "python -c \"from lines import lines as l; from catalogue import catalogue as c; i = l.merge(c, on='code'); print(len(l), len(i)); print(l['line_cents'].sum() / 100, i['line_cents'].sum() / 100)\""

put raw_customers.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
PY

block orphan-orders
on "python -c \"from when import orders; from raw_customers import customers; from joins import join; j = join(orders, customers[['customer_id', 'name']], 'customer_id')\""

put orphans.py <<'PY'
import pandas as pd

from raw_customers import customers
from when import orders

EXPORTED = pd.Timestamp("2025-12-10")  # the CRM file's date, from the person who sent it
alone = orders[~orders["customer_id"].isin(customers["customer_id"])]
first = alone.groupby("customer_id")["placed"].agg(["min", "max", "size"])
first["kind"] = (first["min"] >= EXPORTED).map({True: "new since export", False: "left the CRM"})

if __name__ == "__main__":
    print(first.groupby("kind").agg(customers=("size", "size"), orders=("size", "sum"),
                                    first=("min", "min"), last=("max", "max")).to_string())
PY

block orphans
on "python orphans.py"

block orphans-truth
on "python -c \"import pandas as pd; from orphans import first; e = pd.read_csv('~/clean-data/truth/erased.csv'); gone = first[first['kind'] == 'left the CRM']; print(len(gone), gone.index.isin(e['customer_id']).sum(), len(e))\""

block sql-orphans
on "psql -c 'SELECT count(DISTINCT o.order_id) AS orders, count(DISTINCT o.customer_id) AS customers FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id)'"
on "psql -c 'SELECT count(DISTINCT o.order_id) AS orders FROM raw.orders o LEFT JOIN raw.customers c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL'"

put survivors.sql <<'SQL'
CREATE TABLE survivors (customer_id text PRIMARY KEY, kept_id text NOT NULL);
\copy survivors FROM 'survivors.csv' WITH (FORMAT csv, HEADER)
SELECT count(*) AS mappings,
       count(*) FILTER (WHERE kept_id IN (SELECT customer_id FROM survivors)) AS two_hops
FROM survivors;
SELECT count(DISTINCT o.customer_id) AS before,
       count(DISTINCT coalesce(s.kept_id, o.customer_id)) AS after
FROM (SELECT DISTINCT * FROM raw.orders) o
LEFT JOIN survivors s ON s.customer_id = o.customer_id;
SQL

block survivors
on "head -3 survivors.csv"
on "psql -f survivors.sql"
