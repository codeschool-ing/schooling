#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of data-cleaning, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed: the lab, as lesson 1 left it; and the
# files ana wrote (put below), whose contents the lesson shows in full.
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
exec 9>/var/tmp/clean-capture.lock; flock 9
lab reset >/dev/null

block file
on 'file raw/*.csv'

block utf8-fails
on "python -c \"import pandas as pd; pd.read_csv('raw/store_sales.csv')\" 2>&1 | tail -1"

block bytes
on 'sed -n 2p raw/store_sales.csv | od -An -c'

block read-latin1
on "python -c \"import pandas as pd; print(pd.read_csv('raw/store_sales.csv', sep=';', encoding='latin-1').head(3))\""

put lines_and_rows.py <<'PY'
import csv
import glob

for path in sorted(glob.glob("raw/*.csv")):
    encoding = "latin-1" if "store_sales" in path else "utf-8"
    delimiter = ";" if "store_sales" in path else ","
    with open(path, encoding=encoding, newline="") as f:
        lines = sum(1 for _ in f)
    with open(path, encoding=encoding, newline="") as f:
        rows = sum(1 for _ in csv.reader(f, delimiter=delimiter)) - 1
    print(f"{path:24} {lines:7} lines {rows:7} rows")
PY
block lines-and-rows
on 'python lines_and_rows.py'

block guessed
on "python -c \"import pandas as pd; c = pd.read_csv('raw/customers.csv'); print(c.dtypes); print(c['birth_year'].head(3))\""

block guessed-items
on "python -c \"import pandas as pd; i = pd.read_csv('raw/order_items.csv'); print(i['product_code'].head(4))\""
on "python -c \"import pandas as pd; i = pd.read_csv('raw/order_items.csv', dtype=str); print(i['product_code'].head(4))\""

put profile.py <<'PY'
import sys

import pandas as pd


def profile(df):
    rows = []
    for column in df.columns:
        values = df[column]
        present = values.dropna()
        rows.append({
            "column": column,
            "filled": present.size,
            "empty": values.isna().sum(),
            "distinct": present.nunique(),
            "shortest": present.str.len().min(),
            "longest": present.str.len().max(),
            "most_common": present.value_counts().index[0],
            "times": present.value_counts().iloc[0],
        })
    return pd.DataFrame(rows)


path = sys.argv[1]
df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[""])
print(f"{path}: {len(df)} rows")
print(profile(df).to_string(index=False))
PY
block profile
on 'python profile.py raw/customers.csv'

block profile-orders
on 'python profile.py raw/orders.csv'

block discount-by-channel
on "python -c \"import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str, keep_default_na=False); print(pd.crosstab(o['discount'], o['channel']))\""

block describe
on "python -c \"import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o['total'].describe())\""

block negatives
on "python -c \"import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o.loc[o['total'] < 0, ['order_id', 'total', 'discount', 'delivery_fee', 'fulfilment']])\""

block quantiles
on "python -c \"import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o['total'].quantile([0.5, 0.9, 0.99, 0.999, 1]))\""

put patterns.py <<'PY'
import sys

import pandas as pd


def pattern(values):
    return (values.str.replace(r"[0-9]", "9", regex=True)
                  .str.replace(r"[^\W\d_]", "a", regex=True))


path, column = sys.argv[1], sys.argv[2]
df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[""])
if len(sys.argv) > 3:
    print(pd.crosstab(pattern(df[column]), df[sys.argv[3]]))
else:
    print(pattern(df[column]).value_counts(dropna=False).to_string())
PY
block patterns
on 'python patterns.py raw/customers.csv cep'
on 'python patterns.py raw/customers.csv signed_up'
on 'python patterns.py raw/customers.csv birth_year'

block pattern-by
on 'python patterns.py raw/customers.csv signed_up signup_channel'
on 'python patterns.py raw/customers.csv cep signup_channel'

block sql-profile
on "psql -c \"SELECT count(*) AS rows, count(cep) AS filled, count(DISTINCT cep) AS distinct_values, min(length(cep)) AS shortest, max(length(cep)) AS longest FROM raw.customers\""

block sql-patterns
on "psql -c \"SELECT regexp_replace(regexp_replace(cep, '[0-9]', '9', 'g'), '[[:alpha:]]', 'a', 'g') AS pattern, count(*) FROM raw.customers GROUP BY 1 ORDER BY 2 DESC\""

block sql-patterns-total
on "psql -c \"SELECT regexp_replace(total, '[0-9]', '9', 'g') AS pattern, count(*) FROM raw.store_sales GROUP BY 1 ORDER BY 2 DESC\""
