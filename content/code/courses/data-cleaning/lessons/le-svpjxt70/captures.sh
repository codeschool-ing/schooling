#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of data-cleaning, as a script that
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
put raw_customers.py <<'PY'
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
PY
block astype-fails
on "python -c \"from raw_customers import customers as c; c['birth_year'].astype(int)\" 2>&1 | tail -1"

block coerce
on "python -c \"import pandas as pd; from raw_customers import customers as c; n = pd.to_numeric(c['birth_year'], errors='coerce'); print(c['birth_year'].isna().sum(), n.isna().sum()); print(n.head(3).to_string())\""

block coerce-trap
on "python -c \"import pandas as pd; s = pd.Series(['12.90', '1.234,56', 'R\$ 5,00', '7']); print(pd.to_numeric(s, errors='coerce').to_string())\""

put convert.py <<'PY'
import pandas as pd


def to_number(values, name):
    """Convert text to numbers and refuse to lose anything quietly."""
    numbers = pd.to_numeric(values, errors="coerce")
    lost = values.notna() & numbers.isna()
    if lost.any():
        examples = sorted(values[lost].unique())[:5]
        raise ValueError(f"{name}: {lost.sum()} values are not numbers, e.g. {examples}")
    return numbers
PY
block convert-refuses
on "python -c \"import pandas as pd; from convert import to_number; to_number(pd.Series(['12.90', '1.234,56', None]), 'price')\" 2>&1 | tail -1"
on "python -c \"import pandas as pd; from convert import to_number; print(to_number(pd.Series(['12.90', '7', None]), 'price').to_string())\""

block nullable
on "python -c \"import pandas as pd; s = pd.Series(['1987', None, '2001']); print(pd.to_numeric(s).to_string()); print(pd.to_numeric(s).astype('Int64').to_string())\""

put years.py <<'PY'
import pandas as pd

from raw_customers import customers

year = customers["birth_year"].mask(customers["birth_year"] == "1900")
two = year.str.len() == 2
# Customers are adults: a two-digit year above 25 is 19xx, at most 25 is 20xx.
full = year.mask(two & (year > "25"), "19" + year).mask(two & (year <= "25"), "20" + year)
customers["birth"] = pd.to_numeric(full).astype("Int64")
PY
block years
on "python -c \"from years import customers as c; t = c[c['birth_year'].str.len() == 2]; print(t[['birth_year', 'birth']].drop_duplicates().sort_values('birth').head(4).to_string(index=False)); print(c['birth'].min(), c['birth'].max(), c['birth'].isna().sum())\""

block years-truth
on "python -c \"import pandas as pd; from years import customers as c; t = pd.read_csv('~/clean-data/truth/people.csv', dtype={'birth_year': 'Int64'}); m = c[c['birth_year'].str.len() == 2].merge(t[['customer_id', 'birth_year']], on='customer_id', suffixes=('', '_true')); print(len(m), (m['birth'] == m['birth_year_true']).sum())\""

block booleans
on "python -c \"from raw_customers import customers as c; print(c['marketing_opt_in'].value_counts(dropna=False).to_string())\""

block astype-bool
on "python -c \"from raw_customers import customers as c; print(len(c), c['marketing_opt_in'].astype(bool).sum())\""

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
block consent
on "python -c \"from consent import customers as c; print(c['opt_in'].value_counts(dropna=False).to_string()); print(c['opt_in'].dtype)\""

block sql-cast
on "psql -c 'SELECT sum(total::numeric) FROM raw.store_sales'"
on "psql -c \"SELECT count(*) FILTER (WHERE pg_input_is_valid(birth_year, 'int')) AS ints, count(*) FILTER (WHERE NOT pg_input_is_valid(birth_year, 'int')) AS not_ints, count(*) FILTER (WHERE birth_year IS NULL) AS blank FROM raw.customers\""
on "psql -c \"SELECT pg_input_is_valid('31/02/2025', 'date'), pg_input_is_valid('2025-02-28', 'date'), pg_input_is_valid('R\\\$ 5,00', 'numeric')\""

put clean_customers.sql <<'SQL'
CREATE SCHEMA clean;
CREATE TABLE clean.customers (
  customer_id text PRIMARY KEY CHECK (customer_id ~ '^C[0-9]{5}$'),
  birth_year  int  CHECK (birth_year BETWEEN 1920 AND 2010),
  opt_in      boolean
);
INSERT INTO clean.customers
SELECT DISTINCT customer_id,
       CASE WHEN birth_year = '1900' THEN NULL
            WHEN length(birth_year) = 2 AND birth_year > '25' THEN ('19' || birth_year)::int
            WHEN length(birth_year) = 2 THEN ('20' || birth_year)::int
            ELSE birth_year::int END,
       CASE WHEN lower(trim(marketing_opt_in)) IN ('true', '1', 's', 'sim') THEN true
            WHEN lower(trim(marketing_opt_in)) IN ('false', '0', 'n', 'não', 'nao') THEN false
            END
FROM raw.customers;
SQL
block sql-typed
on 'psql -f clean_customers.sql'
on "psql -c 'SELECT count(*), min(birth_year), max(birth_year), count(*) FILTER (WHERE opt_in) AS yes FROM clean.customers'"
on "psql -c \"INSERT INTO clean.customers VALUES ('C99999', 1890, true)\""
