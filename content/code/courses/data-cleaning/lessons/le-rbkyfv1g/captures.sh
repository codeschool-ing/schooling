#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of data-cleaning, as a script that
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
lab reset >/dev/null
block categories
on "psql -c 'SELECT category, count(*) FROM raw.products GROUP BY category ORDER BY lower(category), count(*) DESC'"

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
block keyed
on "python -c \"from keyed import products as p; print(p['category'].nunique(), p['category_key'].nunique()); print(sorted(p['category_key'].unique()))\""

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
block categorise
on "python -c \"from categorise import products as p; print(p.groupby(['department', 'category']).size().to_string())\""

block truth
on "python -c \"import pandas as pd; from categorise import products as p; t = pd.read_csv('/var/lib/clean-data/truth/categories.csv', dtype=str); m = p.merge(t, on='product_code', suffixes=('', '_true')); print(len(m), (m['category'] == m['category_true']).sum())\""

block new-label
on "cp category_map.csv map.bak && grep -v '^emporio' map.bak > category_map.csv && python -c 'import categorise' ; cp map.bak category_map.csv"

block payments
on "psql -c 'SELECT payment, count(*) FROM raw.orders GROUP BY 1 ORDER BY 2 DESC'"
on "psql -c 'SELECT pagamento, count(*) FROM raw.store_sales GROUP BY 1 ORDER BY 2 DESC'"

put payment_map.csv <<'CSV'
source,raw,method
online,card,card
online,pix,pix
online,boleto,boleto
store,Cartão,card
store,cartao,card
store,Pix,pix
store,PIX,pix
store,pix,pix
store,Dinheiro,cash
CSV
put maps.sql <<'SQL'
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE TABLE category_map (
  category_key text PRIMARY KEY, category text NOT NULL, department text NOT NULL);
\copy category_map FROM 'category_map.csv' WITH (FORMAT csv, HEADER true)
CREATE TABLE payment_map (
  source text, raw text, method text NOT NULL, PRIMARY KEY (source, raw));
\copy payment_map FROM 'payment_map.csv' WITH (FORMAT csv, HEADER true)
SQL
block load-maps
on 'psql -f maps.sql'

block sql-categories
on "psql -c 'SELECT m.department, m.category, count(*) FROM raw.products p LEFT JOIN category_map m ON m.category_key = lower(unaccent(trim(p.category))) GROUP BY 1, 2 ORDER BY 1, 2'"

block sql-unmapped
on "psql -c 'SELECT p.category FROM raw.products p LEFT JOIN category_map m ON m.category_key = lower(unaccent(trim(p.category))) WHERE m.category_key IS NULL'"

block sql-payments
on "psql -c \"SELECT m.method, sum(CASE WHEN s.source = 'store' THEN 1 ELSE 0 END) AS store, sum(CASE WHEN s.source = 'online' THEN 1 ELSE 0 END) AS online FROM (SELECT 'store' AS source, pagamento AS raw FROM raw.store_sales UNION ALL SELECT 'online', payment FROM (SELECT DISTINCT * FROM raw.orders) o) s LEFT JOIN payment_map m USING (source, raw) GROUP BY 1 ORDER BY 1\""
