#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of data-cleaning, as a script that
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
# earlier lesson showed (cities.py, cascade.py and abbreviations.csv from
# lesson 6, when.py from lesson 7); and
# ~/clean-data/truth, which the lab's generator wrote and which no real
# data set has. The lesson says so wherever it reads from it. The reference
# files in ref/ are real: IBGE's codes and the federal holidays of 2025, typed
# into the generator from the published lists.
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
put cities.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
city = customers["city"]
PY
put cascade.py <<'PY'
import unicodedata

from cities import city


def fix_mojibake(text):
    if "Ã" in text:
        return text.encode("latin-1").decode("utf-8")
    return text


def without_accents(text):
    text = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in text if not unicodedata.combining(ch))


steps = [
    ("as exported", lambda s: s),
    ("spaces trimmed", lambda s: s.str.strip().str.replace(r"\s+", " ", regex=True)),
    ("Unicode to NFC", lambda s: s.str.normalize("NFC")),
    ("mojibake repaired", lambda s: s.map(fix_mojibake)),
    ("lower case", lambda s: s.str.lower()),
    ("accents removed", lambda s: s.map(without_accents)),
]
values = city
for label, step in steps:
    values = step(values)
    if __name__ == "__main__":
        print(f"{label:18} {values.nunique():3} distinct")
if __name__ == "__main__":
    print(sorted(values.unique()))
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
put abbreviations.csv <<'CSV'
spelling,city
s. paulo,São Paulo
sao paulo,São Paulo
campinas,Campinas
rio de janeiro,Rio de Janeiro
rio,Rio de Janeiro
rj,Rio de Janeiro
belo horizonte,Belo Horizonte
b. horizonte,Belo Horizonte
bh,Belo Horizonte
curitiba,Curitiba
curitiba - pr,Curitiba
CSV

block ref-files
on "head -4 ref/ibge_states.csv; wc -l ref/ibge_states.csv"
on "cat ref/ibge_cities.csv"

block state-spellings
on "python -c \"from cities import customers; print(customers['state'].value_counts(dropna=False).to_string())\""

put places.py <<'PY'
import unicodedata

import pandas as pd

from cascade import values  # lesson 6: each city trimmed, repaired, lower case, unaccented
from cities import customers


def plain(text):
    text = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in text if not unicodedata.combining(ch)).lower().strip()


states = pd.read_csv("ref/ibge_states.csv", dtype=str)
cities = pd.read_csv("ref/ibge_cities.csv", dtype=str)
spellings = pd.read_csv("abbreviations.csv", dtype=str)

# A state is written as its two letters, with or without dots, or as its name.
by_name = dict(zip(states["name"].map(plain), states["uf"]))
letters = customers["state"].str.replace(".", "", regex=False).str.strip().str.upper()
customers["uf"] = letters.where(letters.isin(states["uf"]), customers["state"].map(plain).map(by_name))
customers["city_name"] = values.map(dict(zip(spellings["spelling"], spellings["city"])))

for found, written in [("uf", "state"), ("city_name", "city")]:
    lost = customers[found].isna() & customers[written].notna()
    if lost.any():
        raise ValueError(f"{written}: {sorted(customers.loc[lost, written].unique())} match no reference")

customers = customers.merge(cities.rename(columns={"code": "city_code", "name": "city_name",
                                                   "uf": "city_uf"}),
                            on="city_name", how="left", validate="many_to_one")
customers = customers.merge(states[["uf", "region"]], on="uf", how="left", validate="many_to_one")
PY

block places
on "python -c \"from places import customers as c; print(c[['customer_id', 'state', 'uf', 'city', 'city_name', 'city_code', 'region']].head(4).to_string(index=False))\""
on "python -c \"from places import customers as c; print(c['region'].value_counts(dropna=False).to_string()); print((c['uf'] != c['city_uf']).sum())\""

put days.py <<'PY'
import pandas as pd

from when import orders

holidays = pd.read_csv("ref/holidays_2025.csv", parse_dates=["date"])
shops = pd.read_csv("raw/store_sales.csv", sep=";", encoding="latin-1", dtype=str)
shops["day"] = pd.to_datetime(shops["data"], format="%d/%m/%Y")
orders["day"] = orders["placed"].dt.normalize()

holidays["weekday"] = holidays["date"].dt.day_name()
holidays["shop_sales"] = holidays["date"].map(shops.groupby("day").size()).fillna(0).astype(int)
holidays["online"] = holidays["date"].map(orders.groupby("day").size()).fillna(0).astype(int)

if __name__ == "__main__":
    print(holidays.drop(columns="name").to_string(index=False))
PY

block days
on "python days.py"

block ordinary
on "python -c \"from days import shops, orders, holidays; s = shops.groupby('day').size(); print(round(s.mean(), 1), s.index.dayofweek.max()); o = orders.groupby('day').size(); h = o.index.isin(holidays.loc[holidays['kind'] == 'holiday', 'date']); print(round(o[~h].mean(), 1), round(o[h].mean(), 1), round(o[~h & (o.index.dayofweek == 5)].mean(), 1))\""

put sources.csv <<'CSV'
file,publisher,document,obtained,valid_for,terms
ref/ibge_states.csv,IBGE,codes of the 27 federative units,typed from the published list,stable since 1988,public data; cite IBGE
ref/ibge_cities.csv,IBGE,7-digit municipal codes,typed from the published list,stable; a new municipality gets a new code,public data; cite IBGE
ref/holidays_2025.csv,federal government,holiday laws and the 2025 calendar of optional days,typed from the published calendar,2025 only,laws are not subject to copyright
CSV

put enrich.sql <<'SQL'
CREATE TABLE ref_states (code int PRIMARY KEY, uf text UNIQUE, name text, region text);
\copy ref_states FROM 'ref/ibge_states.csv' WITH (FORMAT csv, HEADER)
SELECT s.region, count(*) AS customers
FROM (SELECT DISTINCT * FROM raw.customers) c
LEFT JOIN ref_states s ON s.uf = upper(replace(c.state, '.', ''))
GROUP BY s.region
ORDER BY customers DESC;
SELECT s.region, count(*) AS customers
FROM (SELECT DISTINCT * FROM raw.customers) c
LEFT JOIN ref_states s ON s.uf = upper(replace(c.state, '.', ''))
                       OR lower(s.name) = lower(c.state)
GROUP BY s.region
ORDER BY customers DESC;
SQL

block sql
on "psql -f enrich.sql"
