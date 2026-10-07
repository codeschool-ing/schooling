#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first fifteen
# days of March before the first block; Ana's project from lessons 6 to 9,
# copied into ~/etl from ../../lab/project, with what lessons 11 and 12 added
# copied over it from ../../lab/after-11 and ../../lab/after-12; raw loaded and
# the dbt project built once with `dbt build --full-refresh`; and the pause of
# two seconds before each edit, so that the file's new modification time is
# visibly later than the last build's. The files are written by `put` and
# shown in the lesson. Airflow is not started.
#
# make prints the commands it runs; the times in dbt's own lines are UTC and,
# like the durations, the recording's own.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, GNU Make 4.3,
# dbt-core 1.12.5, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
A=$(cd "$(dirname "$0")/../../lab/after-11" && pwd)
B=$(cd "$(dirname "$0")/../../lab/after-12" && pwd)
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-15 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
for f in $(cd "$A" && find load_raw.py shop -type f); do put "$f" < "$A/$f"; done
for f in $(cd "$B" && find shop -type f); do put "$f" < "$B/$f"; done
lab exec 'rm -rf ~/.dbt; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$A/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; cd shop && dbt build --full-refresh >/dev/null'

code nightly-sh nightly.sh

put Makefile <<'MK'
# The nightly as a Makefile: each rule says what a file is made from, and how.
# make rebuilds a file only when something it is made from is newer than it.
DAY    := $(shell cat /var/lib/etl-run/clock)
MODELS := $(shell find shop/models shop/tests -name '*.sql' -o -name '*.yml')

report: reports/daily_$(DAY).csv

reports/daily_$(DAY).csv: .made/models
	mkdir -p reports
	psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
	  FROM dbt_marts.daily_sales WHERE order_date = '$(DAY)' ORDER BY 1, 2) \
	  TO STDOUT WITH (FORMAT csv, HEADER)" > $@.part
	mv $@.part $@

.made/models: .made/raw $(MODELS)
	dbt build --project-dir shop --quiet
	touch $@

.made/raw: /var/lib/etl-run/clock load_raw.py
	mkdir -p .made
	python load_raw.py > /dev/null
	touch $@

.PHONY: report
MK
code makefile Makefile

block make-first
on 'make'
on 'ls -l --time-style=+%T .made reports | grep -v total'
block make-again
on 'make'
block make-edit
lab exec 'sleep 2'
on "sed -i '1s/.*/-- One row per book, as the publishers catalogue it./' shop/models/staging/stg_books.sql"
on 'make -n'
on 'make'
block make-day
root 'day 2026-03-16'
on 'make -n'
block make-fail
on 'make 2>&1 | grep -v "^ "'
on 'ls .made'
block make-resume
on 'dbt build --project-dir shop -s fact_sales+ --full-refresh --quiet'
on 'make 2>&1 | grep -v "^ "'

block state
on 'rm -rf prod-state && cp -r shop/target prod-state'
lab exec 'sleep 2'
on "sed -i 's/select book_id, isbn, title, category, publisher, list_price_cents/select book_id, isbn, title, initcap(category) as category, publisher, list_price_cents/' shop/models/staging/stg_books.sql"
shop 'dbt ls -s state:modified --state ../prod-state'
shop 'dbt ls -s state:modified+ --state ../prod-state --resource-type model --resource-type exposure'
shop 'dbt build -s state:modified+ --state ../prod-state 2>&1 | grep -E " OK | PASS | FAIL | WARN |Done"'
