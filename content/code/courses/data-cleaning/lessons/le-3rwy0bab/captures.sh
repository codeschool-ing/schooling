#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of data-cleaning, as a script that
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
block exact
on "python -c \"import pandas as pd; c = pd.read_csv('raw/customers.csv', dtype=str); print(c.duplicated().sum(), c['customer_id'].duplicated().sum())\""
on "psql -c 'SELECT count(*) AS rows, count(DISTINCT c) AS distinct_rows FROM raw.customers c'"

block row-number
on "psql -c \"SELECT order_id, total, row_number() OVER (PARTITION BY order_id ORDER BY order_id) AS copy FROM raw.orders WHERE order_id IN (SELECT order_id FROM raw.orders GROUP BY order_id HAVING count(*) > 1) ORDER BY order_id LIMIT 6\""

block key-dup
on "psql -c 'SELECT product_code, name, price FROM raw.products WHERE product_code IN (SELECT product_code FROM raw.products GROUP BY product_code HAVING count(*) > 1) ORDER BY product_code, price'"

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
block keys
on "python -c \"from keys import plain; print(repr(plain('  MARIANA  Souza')), repr(plain('Mariana Souza')), repr(plain('Júlia Simões')))\""

block same-key
on "python -c \"from keys import customers as c; print(c['name_key'].duplicated().sum(), c['email_key'].dropna().duplicated().sum())\""

block same-name-example
on "python -c \"from keys import customers as c; d = c[c['name_key'] == c['name_key'].value_counts().index[0]]; print(d[['customer_id', 'name', 'city', 'email']].apply(lambda col: col.str.normalize('NFC')).to_string(index=False))\""

block fuzz
on "python -c \"from rapidfuzz import fuzz; print(fuzz.ratio('ana lima', 'ana lmia'), fuzz.ratio('ana lima', 'lima ana'), fuzz.token_sort_ratio('ana lima', 'lima ana'), fuzz.token_sort_ratio('renato p. gomes', 'renato pires gomes'))\""

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
block match
on 'python match.py'

put score.py <<'PY'
import pandas as pd

from match import pairs

truth = pd.read_csv("~/clean-data/truth/duplicates.csv")
real = {frozenset(p) for p in zip(truth["customer_id"], truth["same_as"])}
pairs["real"] = [frozenset(p) in real for p in zip(pairs["a"], pairs["b"])]
rules = [
    ("name 100", pairs["name"] == 100),
    ("name >= 85", pairs["name"] >= 85),
    ("name >= 85 and email or cep", (pairs["name"] >= 85) & (pairs["email"] | pairs["cep"])),
    ("email or cep, any name", pairs["email"] | pairs["cep"]),
]

if __name__ == "__main__":
    print(f"real duplicates: {len(real)}, of which in a compared block: {pairs['real'].sum()}")
    for rule, chosen in rules:
        found = pairs[chosen]
        print(f"{rule:30} matched {len(found):4}  right {found['real'].sum():3}  "
              f"wrong {(~found['real']).sum():4}")
PY
block score
on 'python score.py'

block homonym
on "python -c \"from score import pairs; from keys import customers as c; w = pairs[(pairs['name'] == 100) & ~pairs['real']].iloc[0]; print(c[c['customer_id'].isin([w['a'], w['b']])][['customer_id', 'name', 'city', 'cep', 'signed_up']].to_string(index=False))\""

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
block merge
on 'python merge.py'
