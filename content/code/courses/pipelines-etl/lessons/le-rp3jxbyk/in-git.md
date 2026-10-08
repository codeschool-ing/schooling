---
title: Everything that is written, in git
version: 1
---

Until now, `~/etl` has been one directory that is at once the code Ana is editing and the code the
nightly runs. Every edit in the last ten lessons was live the moment it was saved. That works while
one person edits and nothing important reads the result. It stops working the first time an edit
half-finished at five in the afternoon is what runs at two in the morning.

The first step is to know which version of the code is which, and that is **version control**. Ana
puts the project in git, starting with what does *not* belong in it:

```
# What is made by running the pipeline, not written by a person.
shop/target/
shop/logs/
__pycache__/
.made/
reports/
# What arrives from outside, and the decisions about it: data, not code.
landing/
inbox/
quarantine/
```

Two kinds of thing stay out. What running the pipeline **makes** — dbt's `target/`, the logs, the
markers, the reports — can always be made again, and in git it would only produce changes nobody
wrote. What **arrives** from outside — the landing files, the stock files, the quarantine — is data:
it changes every night, it can be large, and it may be personal. Code is what a person wrote and
would want to see the history of.

The connection details are not in the list because they are not in the project at all: they live in
`~/.dbt/profiles.yml`, and the price API's key is an environment variable. **A secret that is never
in the directory cannot be committed by mistake**, which is the only kind of never that holds.

```
ana@vm:~/etl$ git config --global user.name "Ana" && git config --global user.email "ana@ponto-final.example"
ana@vm:~/etl$ git init -q -b main && git add . && git commit -q -m "The nightly as it runs today" && git log --oneline
cdef2c0 The nightly as it runs today
ana@vm:~/etl$ git ls-files | sed "s|/.*|/…|" | sort | uniq -c
      1 .gitignore
      1 dags/…
      3 load/…
      1 load_raw.py
      1 load_stock.py
      1 nightly.sh
      1 prices.py
      1 run_sql.sh
     15 shop/…
      9 sql/…
     10 tests/…
      1 trace.sh
      1 validate_prices.py
```

Fifteen files of the dbt project, ten of tests and their fixture, and the scripts, SQL and DAG of the
earlier lessons. One commit, *the nightly as it runs today*: from here on, every change has a
before.
