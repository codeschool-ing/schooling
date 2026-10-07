#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of data-cleaning, as a script that
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
# lesson 9, raw_customers.py, years.py and consent.py from lesson 10, ready.py
# and derive.py from lesson 12, sources.csv from lesson 14, and keys.py,
# match.py and merge.py from lesson 5, run once to write survivors.csv); and
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
put consent.py <<'PY'
import pandas as pd

from raw_customers import customers

YES = {"true", "1", "s", "sim"}
NO = {"false", "0", "n", "não", "nao"}
key = customers["marketing_opt_in"].str.strip().str.lower()
unknown = key.notna() & ~key.isin(YES | NO)
if unknown.any():
    raise ValueError(f"unmapped consent values: {sorted(key[unknown].unique())}")
customers["opt_in"] = key.map(lambda v: True if v in YES else False if v in NO else pd.NA)
customers["opt_in"] = customers["opt_in"].astype("boolean")
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
put sources.csv <<'CSV'
file,publisher,document,obtained,valid_for,terms
ref/ibge_states.csv,IBGE,codes of the 27 federative units,typed from the published list,stable since 1988,public data; cite IBGE
ref/ibge_cities.csv,IBGE,7-digit municipal codes,typed from the published list,stable; a new municipality gets a new code,public data; cite IBGE
ref/holidays_2025.csv,federal government,holiday laws and the 2025 calendar of optional days,typed from the published calendar,2025 only,laws are not subject to copyright
CSV
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

block read-only
on "ls -ld raw; ls -l raw | head -4"
on "touch raw/notes.txt"
on "sed -i 's/Pepino/Pepino japonês/' raw/products.csv"

block manifest
on "sha256sum raw/*.csv > raw.sha256 && head -3 raw.sha256"
on "sha256sum --check --quiet raw.sha256 && echo all raw files match"

put run.py <<'PY'
"""Rebuild the clean tables from raw/, in order, and record every value that changed."""
import logging
import pathlib

import pandas as pd

logging.basicConfig(level=logging.INFO, format="%(name)s: %(message)s")
OUT = pathlib.Path("out")


def change(table, keys, column, before, after, rule):
    return pd.DataFrame({"table": table, "key": keys, "column": column,
                         "before": before, "after": after, "rule": rule})


def build_customers():
    log = logging.getLogger("customers")
    from consent import customers  # lesson 10: consent as True, False or blank
    from years import customers as same  # lesson 10: the same table, with the century rule
    assert customers is same
    written = customers["birth_year"]
    placeholder = written == "1900"
    two = written.str.len() == 2
    log.info(f"{len(customers)} rows, {placeholder.sum()} placeholders blanked, "
             f"{two.sum()} years given a century, {customers['opt_in'].isna().sum()} consents unknown")
    changes = pd.concat([
        change("customers", customers.loc[placeholder, "customer_id"], "birth_year", "1900", "",
               "placeholder, lesson 4"),
        change("customers", customers.loc[two, "customer_id"], "birth_year", written[two],
               customers.loc[two, "birth"].astype(str), "century rule, lesson 10")])
    table = customers[["customer_id", "birth", "opt_in"]].rename(columns={"birth": "birth_year"})
    return table, changes


def build_orders():
    log = logging.getLogger("orders")
    from derive import orders  # lesson 12: decided totals, derived columns, corporate flag
    from typos import wrong  # lesson 9: the seven totals typed ten times too big
    raw = pd.read_csv("raw/orders.csv", dtype=str).drop_duplicates().set_index("order_id")
    before = pd.to_numeric(raw["total"])
    after = orders.set_index("order_id")["total"]
    moved = after.index[after != before]
    typo = moved.isin(wrong["order_id"])
    survivors = pd.read_csv("survivors.csv", dtype=str)  # lesson 5
    owner = orders["customer_id"].map(dict(zip(survivors["customer_id"], survivors["kept_id"])))
    rekeyed = owner.notna()
    log.info(f"{len(orders)} rows, {typo.sum()} totals recomputed from lines, "
             f"{(~typo).sum()} negative totals set to 0, {rekeyed.sum()} moved to a surviving "
             f"customer, {orders['corporate'].sum()} flagged corporate")
    changes = pd.concat([
        change("orders", moved, "total", before[moved].astype(str), after[moved].astype(str),
               ["typed total, lesson 9" if t else "coupon above basket, lesson 9" for t in typo]),
        change("orders", orders.loc[rekeyed, "order_id"], "customer_id",
               orders.loc[rekeyed, "customer_id"], owner[rekeyed], "same person, lesson 5")])
    orders.loc[rekeyed, "customer_id"] = owner[rekeyed]
    columns = ["order_id", "customer_id", "channel", "placed", "status", "total", "items",
               "corporate"]
    return orders[columns], changes


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    customers, c1 = build_customers()
    orders, c2 = build_orders()
    changes = pd.concat([c1, c2])
    customers.to_csv(OUT / "customers.csv", index=False)
    orders.to_csv(OUT / "orders.csv", index=False)
    changes.to_csv(OUT / "changes.csv", index=False)
    logging.getLogger("run").info(f"{len(changes)} changes recorded in out/changes.csv")
PY

block run
on "python run.py"
on "ls out"

block changes
on "python -c \"import pandas as pd; c = pd.read_csv('out/changes.csv', dtype=str); print(c.groupby(['table', 'column', 'rule']).size().to_string()); print(c[c['rule'].str.startswith('typed')].head(3).to_string(index=False))\""

put checks.py <<'PY'
"""Checks on the clean tables. Each one is a promise the pipeline makes."""
import sys

import pandas as pd

customers = pd.read_csv("out/customers.csv", dtype={"customer_id": str, "birth_year": "Int64"})
orders = pd.read_csv("out/orders.csv", dtype={"order_id": str, "customer_id": str})
changes = pd.read_csv("out/changes.csv", dtype=str)

checks = {
    "customer_id is unique": customers["customer_id"].is_unique,
    "birth years are blank or between 1920 and 2010":
        customers["birth_year"].dropna().between(1920, 2010).all(),
    "order_id is unique": orders["order_id"].is_unique,
    "no total is negative": (orders["total"] >= 0).all(),
    "every order has at least one line": (orders["items"] >= 1).all(),
    "every change names its rule": changes["rule"].notna().all(),
}
failed = [name for name, ok in checks.items() if not ok]
for name in failed:
    print(f"FAILED: {name}")
print(f"{len(checks) - len(failed)} of {len(checks)} checks passed")
sys.exit(1 if failed else 0)
PY

block checks
on "python checks.py"

block checks-fail
on "cp out/orders.csv /tmp/orders.csv && tail -1 /tmp/orders.csv >> out/orders.csv"
on "python checks.py; echo exit status \$?"
on "python run.py > /dev/null 2>&1; python checks.py"

block rerun
on "sha256sum out/*.csv > /tmp/first.sha256 && python run.py 2>/dev/null && sha256sum --check /tmp/first.sha256"

put .gitignore <<'TXT'
raw/
ref/
out/
__pycache__/
*.png
TXT

block git
on "git init -q && git config user.name 'Ana' && git config user.email ana@lab.example"
on "cat .gitignore"
on "git add . && git status --short"
on "git commit -q -m 'Cleaning pipeline for the 2025 data, as of lesson 17' && git log --format='%an: %s'"
