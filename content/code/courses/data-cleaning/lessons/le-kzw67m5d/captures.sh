#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of data-cleaning, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed: the lab itself, built by lab.sh, which
# leaves ~/clean/raw (read-only), ~/clean/ref and the schema `raw` in the
# database `quitanda`, every file loaded with every column as text. The dates
# `ls -l` prints are the day the lab was built and differ on every machine.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, pandas 3.0.6, R 4.3.3,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/clean$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
put() { lab exec "cat > '$1'"; }
exec 9>/var/tmp/clean-capture.lock; flock 9
lab reset >/dev/null

block versions
on 'psql --version'
on 'python --version'
on "python -c 'import pandas; print(pandas.__version__)'"
on 'R --version | head -1'

block disk
on 'du -sh raw ref /var/lib/clean-pg /opt/clean'

block files
on 'ls -l raw'
on 'wc -l raw/*.csv'

block head
on 'head -4 raw/orders.csv'

block naive
on "psql -c \"SELECT count(*) AS orders, sum(total::numeric) AS revenue FROM raw.orders WHERE status = 'delivered'\""

block birth
on "psql -c \"SELECT birth_year, count(*) FROM raw.customers GROUP BY birth_year ORDER BY count(*) DESC LIMIT 4\""

block birth-by-channel
on "psql -c \"SELECT signup_channel, count(*) FILTER (WHERE birth_year = '1900') AS year_1900, count(*) FILTER (WHERE length(birth_year) = 2) AS two_digits FROM raw.customers GROUP BY signup_channel ORDER BY signup_channel\""

block mean-age
on "psql -c \"SELECT round(avg(2025 - birth_year::int), 1) AS with_1900, round(avg(2025 - birth_year::int) FILTER (WHERE birth_year <> '1900'), 1) AS without_1900 FROM raw.customers WHERE length(birth_year) = 4\""

block emails
on "psql -c \"SELECT signup_channel, count(*) AS customers, count(*) - count(email) AS no_email FROM raw.customers GROUP BY signup_channel ORDER BY customers DESC\""

block minutes
on "psql -c \"SELECT fulfilment, courier, count(*) AS orders, count(delivery_minutes) AS timed FROM raw.orders WHERE status = 'delivered' GROUP BY fulfilment, courier ORDER BY orders DESC\""

block cities
on "psql -c \"SELECT count(DISTINCT city) AS spellings FROM raw.customers\""
on "psql -c \"SELECT normalize(city, NFC) AS city_as_shown, octet_length(city) AS bytes, count(*) FROM raw.customers WHERE city ILIKE '%paulo%' GROUP BY city ORDER BY count(*) DESC\""

block repeated
on "psql -c \"SELECT count(*) AS rows, count(DISTINCT order_id) AS order_ids FROM raw.orders\""

block dates-as-text
on "psql -c \"SELECT signup_channel, min(signed_up), max(signed_up) FROM raw.customers GROUP BY signup_channel\""

block site-newest
on "psql -c \"SELECT max(signed_up) FROM raw.customers WHERE signup_channel = 'site'\""

block orphans
on "psql -c \"SELECT count(*) AS orders, count(DISTINCT customer_id) AS customers FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id)\""

block orphans-by-month
on "psql -c \"SELECT left(ordered_at, 7) AS month, count(*) AS orders FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id) GROUP BY 1 ORDER BY 1\""

put scorecard.sql <<'SQL'
-- One rule per dimension, and one number per rule.
WITH rules AS (
  SELECT 'completeness' AS dimension, 'the customer has an e-mail' AS rule,
         count(*) AS tested, count(*) - count(email) AS failing
  FROM raw.customers
  UNION ALL
  SELECT 'validity', 'a birth year has four digits',
         count(*), count(*) FILTER (WHERE birth_year !~ '^[0-9]{4}$')
  FROM raw.customers WHERE birth_year IS NOT NULL
  UNION ALL
  SELECT 'accuracy', 'a birth year is not the form''s 1900',
         count(*), count(*) FILTER (WHERE birth_year = '1900')
  FROM raw.customers WHERE birth_year IS NOT NULL
  UNION ALL
  SELECT 'consistency', 'the order''s customer is in the CRM',
         count(*), count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))
  FROM raw.orders o
  UNION ALL
  SELECT 'uniqueness', 'an order id appears once',
         count(*), count(*) - count(DISTINCT order_id)
  FROM raw.orders
  UNION ALL
  SELECT 'timeliness', 'the CRM knows the last week''s buyers',
         count(DISTINCT customer_id), count(DISTINCT customer_id) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))
  FROM raw.orders o WHERE ordered_at >= '2025-12-25'
)
SELECT dimension, rule, tested, failing,
       round(100.0 * failing / tested, 1) AS pct_failing
FROM rules;
SQL
block scorecard
on 'psql -f scorecard.sql'
