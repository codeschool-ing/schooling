#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first
# twenty-one days of March before the first block; Ana's project from lessons
# 6 to 9, copied into ~/etl from ../../lab/project, with what lessons 11 to 17
# changed copied over it from ../../lab/after-11 to after-17; raw loaded, the
# test fixture cut with tests/make_fixture.sh, and the leftovers of earlier
# lessons' runs (target/, logs/, .made/, reports/) removed so that the first
# commit is of source only. The files are written by `put` and shown in the
# lesson, and her edits to existing files are applied from here and shown
# with `git diff`. Airflow is not started.
#
# Commit hashes depend on the moment of the commit and are the recording's
# own, like dbt's clock and its durations.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, git 2.43,
# dbt-core 1.12.5, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
L=$(cd "$(dirname "$0")/../../lab" && pwd)
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
prod() { printf 'ana@vm:~/etl-prod$ %s\n' "$*"; lab exec "cd ~/etl-prod && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-21 >/dev/null
for f in $(cd "$L/project" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$L/project/$f"; done
for o in after-11 after-12 after-15 after-16 after-17; do
  for f in $(cd "$L/$o" && find . -type f ! -name README ! -name profiles.yml | sed 's|^\./||'); do put "$f" < "$L/$o/$f"; done
done
lab exec 'rm -rf ~/.dbt ~/etl-prod ~/.gitconfig; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$L/after-17/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; sh tests/make_fixture.sh 2026-03-02 >/dev/null'
lab exec 'rm -rf shop/target shop/logs .made reports quarantine prod-state'

put .gitignore <<'TXT'
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
TXT
code gitignore .gitignore
block init
on 'git config --global user.name "Ana" && git config --global user.email "ana@ponto-final.example"'
on 'git init -q -b main && git add . && git commit -q -m "The nightly as it runs today" && git log --oneline'
on 'git ls-files | sed "s|/.*|/…|" | sort | uniq -c'

# ------------------------------------------------------------ two targets
lab exec 'cat > ~/.dbt/profiles.yml' <<'YML'
ponto_final:
  target: dev                   # what dbt builds when nobody says otherwise
  outputs:
    dev:                        # Ana's own schemas, beside production's
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt_ana
      threads: 4
    prod:                       # what the reports read; built only by the nightly
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt
      threads: 4
    test:                       # the integration tests' own warehouse
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh_test
      schema: dbt
      threads: 4
YML
block profiles
on 'cat ~/.dbt/profiles.yml'

block prod-checkout
on 'git tag -a v1.0.0 -m "The nightly as it runs today" && git worktree add -q ~/etl-prod v1.0.0 && git worktree list'
prod 'dbt build --project-dir shop --target prod --quiet && dbt ls --project-dir shop --target prod --resource-type model -q --output name'
on 'psql -d wh -c "\dn dbt*"'

# ------------------------------------------------------------ a change
block branch
on 'git switch -q -c initcap-categories && git branch'
lab exec "sed -i 's/select book_id, isbn, title, category, publisher, list_price_cents/select book_id, isbn, title, initcap(category) as category, publisher, list_price_cents/' shop/models/staging/stg_books.sql"
on 'git diff'
block dev-build
shop 'dbt build --quiet; echo "exit status $?"'
on 'psql -d wh -c "\dn dbt*"'
put compare.sql <<'SQL'
-- Rows of daily_sales that only one of the two environments has.
SELECT 'only in dev'  AS where_, count(*) FROM (TABLE dbt_ana_marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS d
UNION ALL
SELECT 'only in prod' AS where_, count(*) FROM (TABLE dbt_marts.daily_sales EXCEPT TABLE dbt_ana_marts.daily_sales) AS p;
SQL
code compare-sql compare.sql
block defer
on 'cp -r ~/etl-prod/shop/target prod-manifest'
shop 'dbt build -s state:modified+ --state ../prod-manifest --defer 2>&1 | grep -E " OK | PASS | FAIL |Done"'
on 'psql -d wh -f compare.sql'
block categories
on 'psql -d wh -c "SELECT DISTINCT category FROM dbt_ana_marts.daily_sales EXCEPT SELECT DISTINCT category FROM dbt_marts.daily_sales ORDER BY 1"'
lab exec "sed -i 's/initcap(category) as category/upper(left(category, 1)) || substr(category, 2) as category/' shop/models/staging/stg_books.sql"
block second-try
on 'git diff'
shop 'dbt build -s state:modified+ --state ../prod-manifest --defer 2>&1 | grep -E " OK | PASS | FAIL |Done"'
on 'psql -d wh -f compare.sql'
block tests-pass
on 'python -m pytest -q tests'
block merge
on 'git add shop && git commit -q -m "stg_books: categories start with a capital, whatever the publisher sends" && git switch -q main && git merge -q --ff-only initcap-categories && git log --oneline'
on 'git tag -a v1.1.0 -m "Categories start with a capital" && git tag -n'
block deploy
prod 'git checkout -q v1.1.0 && git describe --tags'
prod 'dbt build --project-dir shop --target prod 2>&1 | grep -E "stg_books|daily_sales |Done"'
block rollback
prod 'git checkout -q v1.0.0 && git describe --tags && dbt build --project-dir shop --target prod --quiet; echo "exit status $?"'
prod 'git checkout -q v1.1.0 && dbt build --project-dir shop --target prod --quiet; git describe --tags'
