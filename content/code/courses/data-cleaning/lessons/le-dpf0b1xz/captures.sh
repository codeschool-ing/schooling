#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of data-cleaning, as a script that
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
put cities.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
city = customers["city"]
PY
block spaces
on "python -c \"from cities import city; print(city.nunique(), (city != city.str.strip()).sum(), city.str.strip().nunique())\""

block repr
on "python -c \"from cities import city; print(sorted({ascii(v) for v in city if 'Paulo' in v and 'Ã' not in v}))\""

block nfd-bytes
on "python -c \"import unicodedata; a = 'S\\u00e3o'; b = unicodedata.normalize('NFD', a); print(a == b, len(a), len(b), [hex(ord(ch)) for ch in b], unicodedata.normalize('NFC', b) == a)\""

block casefold
on "python -c \"print('Straße'.lower(), 'Straße'.casefold(), 'DA SILVA'.title(), 'mcdonald'.title())\""

block mojibake
on "python -c \"from cities import city; bad = city[city.str.contains('Ã')]; print(bad.value_counts().to_string()); print(bad.iloc[0].encode('latin-1').decode('utf-8'))\""

block mojibake-names
on "python -c \"from cities import customers as c; bad = c[c['name'].str.contains('Ã')]['name']; print(len(bad)); print(bad.head(3).to_string(index=False))\""

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
block cascade
on 'python cascade.py'

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
block abbrev
on 'cat abbreviations.csv'
on "python -c \"import pandas as pd; from cascade import values; m = pd.read_csv('abbreviations.csv'); out = values.map(dict(zip(m['spelling'], m['city']))); print(out.value_counts(dropna=False).to_string())\""

put city_key.sql <<'SQL'
CREATE EXTENSION IF NOT EXISTS unaccent;
SELECT lower(unaccent(regexp_replace(trim(normalize(
         convert_from(convert_to(city, 'LATIN1'), 'UTF8'), NFC)), '\s+', ' ', 'g'))) AS city_key,
       count(*)
FROM raw.customers
WHERE city LIKE '%Ã%'
GROUP BY 1;
SQL
block sql-mojibake
on 'psql -f city_key.sql'

block sql-cascade
on "psql -c \"SELECT count(DISTINCT city) AS raw, count(DISTINCT trim(city)) AS trimmed, count(DISTINCT normalize(trim(city), NFC)) AS nfc, count(DISTINCT lower(unaccent(normalize(trim(city), NFC)))) AS plain FROM raw.customers WHERE city NOT LIKE '%Ã%'\""
