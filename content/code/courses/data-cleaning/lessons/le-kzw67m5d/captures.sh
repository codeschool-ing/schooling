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
# What is STAGED rather than typed: the machine as section `the-lab` builds it
# and the data as section `your-data` makes and loads it, which is what
# lab.sh does, with the generator and the loader read out of your-data.md.
# The user `bia` exists only for the length of one transcript, as somebody
# who skipped `createuser`. The dates `ls -l` prints are the day the data was
# made and differ on every machine.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.12, pandas 3.0.6, R 4.3.3,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/clean$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
at() { local dir=$1; shift; printf 'ana@lab:%s$ %s\n' "$dir" "$*"; lab exec "cd $dir && $*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
put() { lab exec "cat > '$1'"; }
exec 9>/var/tmp/clean-capture.lock; flock 9
lab reset >/dev/null

block versions
at '~' 'psql --version'
at '~' 'python --version'
at '~' "python -c 'import pandas; print(pandas.__version__)'"
at '~' 'R --version | head -1'

block disk
at '~' 'du -sh venv /usr/lib/R /usr/lib/postgresql'

block cluster
at '~' 'pg_lsclusters'

block generate
at '~/clean-data' 'python3 generate.py .'
at '~/clean-data' 'ls'
at '~/clean-data' 'du -sh raw ref truth'

block checksums
at '~/clean-data' 'sha256sum raw/*.csv ref/*.csv'

block load
on 'psql -f ~/clean-data/raw.sql'

block bashrc
at '~' 'tail -4 .bashrc'

block fail-server
lab stop >/dev/null 2>&1
at '~' 'psql -c "SELECT 1"'
at '~' 'pg_lsclusters'

block fail-start
printf 'ana@lab:~$ sudo service postgresql start\n'
lab start 2>&1
at '~' 'pg_lsclusters'
at '~' 'psql -c "SELECT 1"'

block fail-role
id bia >/dev/null 2>&1 || useradd -m -s /bin/bash bia
printf 'bia@lab:~$ psql\n'
runuser -u bia -- env -i HOME=/home/bia USER=bia LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c 'cd && psql' 2>&1 || true
userdel -r bia 2>/dev/null

block fail-pip
# A shell without lesson 1's lines, so without the venv: Ubuntu's own Python.
# /usr/local/lib/clean-stock is lab.sh's python3 -> python3.12, which is what
# `python3` is on a stock Ubuntu 24.04; python3-pip is installed on this one.
printf 'ana@lab:~$ python3 -m pip install pandas==3.0.6\n'
runuser -u ana -- env -i HOME=/home/ana USER=ana LANG=C.UTF-8 COLUMNS=100 PATH=/usr/local/lib/clean-stock:/usr/local/bin:/usr/bin:/bin bash -c 'cd && python3 -m pip install pandas==3.0.6' 2>&1 || true

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
