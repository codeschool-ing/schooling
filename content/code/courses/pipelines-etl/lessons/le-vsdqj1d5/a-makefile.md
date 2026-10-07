---
title: A Makefile: what each file is made from
version: 1
---

The oldest declarative build tool on any Unix machine is `make`, written in 1976 to compile C
programs, and its idea fits a pipeline exactly. A **rule** names a file, the files it is made from,
and the commands that make it. `make` builds a file only when it does not exist **or when something
it is made from has been modified more recently than it**.

A table in a database has no modification time `make` can see, so Ana does what Luigi made her do:
a small file in `.made/` stands for each step, touched when the step succeeds. The difference from
Luigi is in what the files are compared with:

```
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
```

Three rules, each the answer to *what is this made from*. The report is made from the models; the
models from raw **and from every file in the dbt project**. Raw is made from `load_raw.py` **and
from the lab's clock file**, which `lab.sh day` rewrites whenever the shop lives another day. Nothing says
*first do this, then that*: `make` works the order out from the rules, as dbt did from the `ref`s.

```
ana@vm:~/etl$ make
mkdir -p .made
python load_raw.py > /dev/null
touch .made/raw
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-15' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-15.csv.part
mv reports/daily_2026-03-15.csv.part reports/daily_2026-03-15.csv
ana@vm:~/etl$ ls -l --time-style=+%T .made reports | grep -v total
.made:
-rw-r--r-- 1 ana ana 0 03:48:56 models
-rw-r--r-- 1 ana ana 0 03:48:52 raw

reports:
-rw-r--r-- 1 ana ana 1794 03:48:56 daily_2026-03-15.csv
```

All three ran, in dependency order, and the timestamps line up: raw first, then models and the
report a few seconds later. Asked again:

```
ana@vm:~/etl$ make
make: Nothing to be done for 'report'.
```

**Nothing to be done**, and this time it is right for a reason, not by existence alone. Every file
is newer than everything it is made from, so nothing can have changed since it was made.
