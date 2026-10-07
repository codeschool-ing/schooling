#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first twenty
# days of March before the first block; Ana's project from lessons 6 to 9,
# copied into ~/etl from ../../lab/project, with what lessons 11, 12 and 15
# changed copied over it from ../../lab/after-11, after-12 and after-15; the
# price API started with `lab.sh api` and every price fetched into
# landing/prices.jsonl with lesson 3's prices.py; raw loaded and the dbt
# project built once with `dbt build --full-refresh`. And THE INCIDENT: before
# the `incident` block the website's event file for the 20th is cut to its
# first 400 lines, standing for a collector that delivered part of a day and
# stopped. The lesson says so where it happens. The files are written by `put`
# and shown in the lesson. Airflow is not started.
#
# dbt's clock in its own lines is UTC; times and durations are the recording's
# own.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, dbt-core 1.12.5,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
A=$(cd "$(dirname "$0")/../../lab/after-11" && pwd)
B=$(cd "$(dirname "$0")/../../lab/after-12" && pwd)
C=$(cd "$(dirname "$0")/../../lab/after-15" && pwd)
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-20 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
for f in $(cd "$A" && find load_raw.py shop -type f); do put "$f" < "$A/$f"; done
for f in $(cd "$B" && find shop -type f); do put "$f" < "$B/$f"; done
for f in $(cd "$C" && find shop -type f); do put "$f" < "$C/$f"; done
lab exec 'rm -rf ~/.dbt; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$A/profiles.yml"
lab api >/dev/null
lab exec 'python prices.py 2026-01-01 landing/prices.jsonl >/dev/null; python load_raw.py >/dev/null; cd shop && dbt build --full-refresh >/dev/null'

put validate_prices.py <<'PY'
"""Check every price the publishers sent before it is loaded.

Each record is fixed where the fix is certain, rejected where it is not, and
counted either way. The good records go on to be loaded; the rejected ones go
to quarantine with the reason; and if too many are rejected, nothing is loaded."""
import json
import sys
from collections import Counter

MAX_REJECTED = 0.05          # more than 5% rejected: the batch is wrong, not the records


def isbn13_ok(isbn):
    """The last digit of an ISBN-13 is a check digit over the other twelve."""
    if len(isbn) != 13 or not isbn.isdigit():
        return False
    total = sum(int(d) * (3 if i % 2 else 1) for i, d in enumerate(isbn[:12]))
    return (10 - total % 10) % 10 == int(isbn[12])


def check(rec, fixed):
    """Return the reason to reject rec, or None; fix what can be fixed, in place."""
    if "-" in rec["isbn"]:
        rec["isbn"] = rec["isbn"].replace("-", "")
        fixed["isbn written with hyphens"] += 1
    if not isbn13_ok(rec["isbn"]):
        return "isbn fails its check digit"
    if rec["publisher"] != rec["publisher"].strip():
        rec["publisher"] = rec["publisher"].strip()
        fixed["publisher with stray spaces"] += 1
    if rec["currency"] != "BRL":
        if rec["currency"].upper() != "BRL":
            return f"currency {rec['currency']!r}"
        rec["currency"] = "BRL"
        fixed["currency in lower case"] += 1
    price = rec["list_price_cents"]
    if price is None:
        return "price missing"
    if isinstance(price, str):
        if not price.isdigit():
            return f"price {price!r} is not a number"
        rec["list_price_cents"] = int(price)
        fixed["price sent as text"] += 1
    if not 100 <= rec["list_price_cents"] <= 100_000:
        return f"price {rec['list_price_cents']} out of range"
    return None


src, good_path, bad_path = sys.argv[1:4]
fixed, rejected, good, bad = Counter(), Counter(), [], []
for line in open(src, encoding="utf-8"):
    rec = json.loads(line)
    reason = check(rec, fixed)
    if reason:
        rejected[reason] += 1
        bad.append({"reason": reason, "record": json.loads(line)})
    else:
        good.append(rec)

total = len(good) + len(bad)
print(f"{total} records: {len(good)} accepted, {len(bad)} rejected")
for what, n in sorted(fixed.items()):
    print(f"  fixed     {n:4}  {what}")
for why, n in sorted(rejected.items()):
    print(f"  rejected  {n:4}  {why}")
with open(bad_path, "w", encoding="utf-8") as out:
    out.writelines(json.dumps(b, ensure_ascii=False) + "\n" for b in bad)
if len(bad) > MAX_REJECTED * total:
    print(f"STOP: {len(bad) / total:.0%} rejected is more than {MAX_REJECTED:.0%}; nothing loaded")
    sys.exit(1)
with open(good_path, "w", encoding="utf-8") as out:
    out.writelines(json.dumps(g, ensure_ascii=False) + "\n" for g in good)
PY
code validate-py validate_prices.py
block validate
on 'mkdir -p quarantine; python validate_prices.py landing/prices.jsonl landing/prices.valid.jsonl quarantine/prices.jsonl'
on 'cat quarantine/prices.jsonl'
block stop
on "sed 's/\"list_price_cents\": \\(\"[0-9]*\"\\|[0-9][0-9]*\\)/\"list_price_cents\": null/' landing/prices.jsonl | head -100 > /tmp/half_broken.jsonl; tail -100 landing/prices.jsonl >> /tmp/half_broken.jsonl"
on 'python validate_prices.py /tmp/half_broken.jsonl /tmp/out.jsonl /tmp/bad.jsonl; echo "exit status $?"; ls /tmp/out.jsonl'

put shop/models/marts/schema.yml <<'YML'
version: 2

models:
  - name: daily_sales
    description: >
      Books and revenue by day, shop and category, counting completed sales only.
      One row per combination that sold anything. Read by the morning report.
    config:
      contract:
        enforced: true            # these columns, with these types, or the build fails
    columns:
      - name: order_date
        data_type: date
        description: The day of the sale in São Paulo, not in UTC.
        constraints:
          - type: not_null
      - name: shop_id
        data_type: integer
      - name: category
        data_type: text
      - name: books
        data_type: integer
      - name: revenue_cents
        data_type: bigint
        description: Sum of quantity times unit price, in cents of a real.
  - name: fact_sales
    description: >
      One row per order line sold. Incremental: each run replaces the last thirty
      days it has, so changes older than that need a full refresh.
    columns:
      - name: customer_id
        description: Null for a sale at a till to nobody, and for a customer erased on request.
YML
code contract-yml shop/models/marts/schema.yml
block contract
shop 'dbt build -s daily_sales 2>&1 | grep -E " OK | PASS |ERROR|Done"'
on "sed -i 's/sum(s.line_cents)::bigint as revenue_cents/sum(s.line_cents) \\/ 100.0 as revenue_cents/' shop/models/marts/daily_sales.sql"
on 'grep -n revenue_cents shop/models/marts/daily_sales.sql'
shop 'dbt build -s daily_sales 2>&1 | grep -vE "^[0-9:]{8}  (Running|Registered|Found|Concurrency|Finished|$)" | grep -v "^$"'
on "sed -i 's/sum(s.line_cents) \\/ 100.0 as revenue_cents/sum(s.line_cents)::bigint as revenue_cents/' shop/models/marts/daily_sales.sql"

put shop/models/staging/stg_events.sql <<'SQL'
-- One row per website event, however many times the collector delivered it,
-- dated by when it happened in São Paulo.
select event_id, occurred_at, event_date, session, type, book_id
  from (select doc->>'event_id'                   as event_id,
               (doc->>'occurred_at')::timestamptz as occurred_at,
               ((doc->>'occurred_at')::timestamptz
                  at time zone 'America/Sao_Paulo')::date as event_date,
               doc->>'session'                    as session,
               doc->>'type'                       as type,
               (doc->>'book_id')::integer         as book_id,
               row_number() over (partition by doc->>'event_id' order by file) as copy
          from {{ source('raw', 'events') }}) as delivered
 where copy = 1
SQL
put shop/tests/event_volume_is_plausible.sql <<'SQL'
-- An expectation, not a rule: each day of March has between half and twice the
-- events of the seven days before it, on average. A day outside that range is
-- not impossible, but it is worth a person's look before anything is built on it.
with daily as (
    select event_date, count(*) as events
      from {{ ref('stg_events') }}
     group by 1
), compared as (
    select event_date, events,
           avg(events) over (order by event_date rows between 7 preceding and 1 preceding)
             as usual
      from daily
)
select event_date, events, round(usual) as usual
  from compared
 where event_date >= date '2026-03-01'
   and (events < usual / 2 or events > usual * 2)
SQL
lab exec "sed -i 's/      - name: books$/      - name: books\\n      - name: events/' shop/models/staging/sources.yml"
code sources-yml shop/models/staging/sources.yml
code stg-events shop/models/staging/stg_events.sql
code volume-sql shop/tests/event_volume_is_plausible.sql
block volume
shop 'dbt build -s stg_events+ 2>&1 | grep -E " OK | PASS | FAIL |Done"'
lab exec 'head -400 landing/events/2026-03-20.jsonl > /tmp/e && cp /tmp/e landing/events/2026-03-20.jsonl'
block incident
on 'wc -l landing/events/2026-03-19.jsonl landing/events/2026-03-20.jsonl'
on 'python load_raw.py >/dev/null'
shop 'dbt build -s stg_events+ 2>&1 | grep -E " OK | PASS | FAIL |Done"'
on 'psql -d wh -f shop/target/compiled/shop/tests/event_volume_is_plausible.sql'
