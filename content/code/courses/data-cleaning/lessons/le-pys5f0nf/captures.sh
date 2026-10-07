#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of data-cleaning, as a script that
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
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.12, pandas 3.0.6, R 4.3.3,
# dplyr 1.1.4, readr 2.1.5,
# TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/clean$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
put() { lab exec "cat > '$1'"; }
lab reset >/dev/null
# Excel and Power Query cannot run in this lab, and the lesson says so where it
# describes them: nothing attributed to them below was captured.

put task.sql <<'SQL'
WITH orders AS (
  SELECT DISTINCT * FROM raw.orders
), delivered AS (
  SELECT channel, greatest(total::numeric, 0) AS total,
         CASE WHEN channel = 'site'
              THEN ordered_at::timestamptz AT TIME ZONE 'America/Sao_Paulo'
              ELSE ordered_at::timestamp END AS placed
  FROM orders
  WHERE status = 'delivered'
)
SELECT channel, count(*) AS orders, sum(total) AS revenue,
       sum(total) FILTER (WHERE placed >= '2025-12-01') AS december
FROM delivered
GROUP BY channel
ORDER BY channel;
SQL

block sql
on "psql -f task.sql"

put task.py <<'PY'
import pandas as pd

orders = pd.read_csv("raw/orders.csv", dtype=str).drop_duplicates()
orders = orders[orders["status"] == "delivered"].copy()
orders["total"] = pd.to_numeric(orders["total"]).clip(lower=0)
site = orders["channel"] == "site"
utc = pd.to_datetime(orders.loc[site, "ordered_at"], format="%Y-%m-%dT%H:%M:%SZ", utc=True)
orders.loc[site, "placed"] = utc.dt.tz_convert("America/Sao_Paulo").dt.tz_localize(None)
orders.loc[~site, "placed"] = pd.to_datetime(orders.loc[~site, "ordered_at"],
                                              format="%Y-%m-%d %H:%M:%S")
december = pd.to_datetime(orders["placed"]) >= "2025-12-01"

result = orders.groupby("channel").agg(orders=("total", "size"), revenue=("total", "sum"))
result["december"] = orders[december].groupby("channel")["total"].sum()
print(result.round(2).to_string())
PY

block pandas
on "python task.py"

put task.R <<'R'
suppressPackageStartupMessages(library(dplyr))
library(readr)

orders <- read_csv("raw/orders.csv", col_types = cols(.default = col_character())) |>
  distinct()

result <- orders |>
  filter(status == "delivered") |>
  mutate(
    total = pmax(as.numeric(total), 0),
    placed = if_else(
      channel == "site",
      format(as.POSIXct(ordered_at, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
             tz = "America/Sao_Paulo", format = "%Y-%m-%d %H:%M:%S"),
      ordered_at)
  ) |>
  group_by(channel) |>
  summarise(orders = n(), revenue = sum(total),
            december = sum(total[placed >= "2025-12-01"]))

print(as.data.frame(result), digits = 10)
R

block dplyr
on "Rscript task.R"

block guessed
on "python -c \"import pandas as pd; text = pd.read_csv('raw/order_items.csv', dtype=str); guess = pd.read_csv('raw/order_items.csv'); five = text['product_code'].str.len() == 5; print(text.loc[five, 'product_code'].head(3).tolist(), guess.loc[five, 'product_code'].head(3).tolist(), guess['product_code'].dtype)\""
