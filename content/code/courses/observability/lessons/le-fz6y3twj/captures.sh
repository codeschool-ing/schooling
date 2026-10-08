#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the scripts in ~/shop/scratch, whose
# contents the lesson shows; and simulated customers, five requests a second,
# started in the background. Times, ids and dates differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@obs:~/shop$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
quiet() { lab as "$*" >/dev/null 2>&1 || true; }
put() { lab put "$1"; }
block() { printf '##### %s\n' "$1"; }

lab reset
put scratch/two_ways.py <<'PY'
import json
import random

random.seed(3)
with open("plain.log", "w") as plain, open("json.log", "w") as structured:
    for n in range(1, 2001):
        took = round(random.expovariate(1 / 40))
        order = 5000 + n
        plain.write(f"INFO checkout finished for order {order} in {took}ms (kettle, paid)\n")
        structured.write(json.dumps({"level": "INFO", "message": "checkout finished", "order_id": order,
                                     "sku": "kettle", "outcome": "paid", "duration_ms": took}) + "\n")
PY
put scratch/levels.py <<'PY'
import logging
import os

from common import logs

log = logs.setup()
log.debug("cache lookup", extra={"fields": {"key": "price:kettle"}})
log.info("checkout finished", extra={"fields": {"order_id": 7}})
log.warning("payments slow", extra={"fields": {"took_ms": 1500}})
log.error("payments unreachable", extra={"fields": {"attempt": 3}})
PY
put scratch/crash.py <<'PY'
import json


def load(text):
    return json.loads(text)


load("{not json")
PY
put scratch/caught.py <<'PY'
import json

from common import logs

log = logs.setup()
try:
    json.loads("{not json")
except ValueError:
    log.exception("could not read the order")
PY
put scratch/sampled.py <<'PY'
import logging
import random

from common import logs


class OneIn(logging.Filter):
    """Keep every WARNING and above; keep one INFO or DEBUG line in `n`."""

    def __init__(self, n):
        super().__init__()
        self.n = n

    def filter(self, record):
        return record.levelno >= logging.WARNING or random.random() < 1 / self.n


log = logs.setup()
logging.getLogger().handlers[0].addFilter(OneIn(10))
random.seed(1)
for n in range(1000):
    if n % 100 == 99:
        log.warning("payments slow", extra={"fields": {"n": n}})
    else:
        log.info("checkout finished", extra={"fields": {"n": n}})
PY
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1200"
sleep 60

block two-ways
on "docker compose run --rm sandbox python two_ways.py 2>/dev/null; head -2 scratch/plain.log scratch/json.log"
on "grep -cE 'in (1[5-9][0-9]|[2-9][0-9]{2}|[0-9]{4,})ms' scratch/plain.log"
on "jq -c 'select(.duration_ms >= 150)' scratch/json.log | wc -l"
on "jq -c 'select(.duration_ms >= 150 and .outcome == \"paid\") | {order_id, duration_ms}' scratch/json.log | head -3"

block levels
on "docker compose run --rm -e PYTHONPATH=/app sandbox python levels.py 2>/dev/null | jq -c '{level, message}'"
on "docker compose run --rm -e PYTHONPATH=/app -e LOG_LEVEL=DEBUG sandbox python levels.py 2>/dev/null | jq -c '{level, message}'"
on "docker compose run --rm -e PYTHONPATH=/app -e LOG_LEVEL=ERROR sandbox python levels.py 2>/dev/null | jq -c '{level, message}'"

block correlation
on "docker compose logs --no-log-prefix mailer | head -1 | jq -c ."
on "docker compose logs --no-log-prefix storefront orders payments mailer | jq -r 'select(has(\"trace_id\") | not) | .message' | sort | uniq -c"

block crash
on "docker compose run --rm sandbox python crash.py 2>&1 | grep -v Container | wc -l"
on "docker compose run --rm sandbox python crash.py 2>&1 | grep -v Container | head -4"
on "docker compose run --rm -e PYTHONPATH=/app sandbox python caught.py 2>/dev/null | wc -l"
on "docker compose run --rm -e PYTHONPATH=/app sandbox python caught.py 2>/dev/null | jq -r '.message, .exception'"

block volume
on "docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | wc -l"
on "docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | wc -c"
on "docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | jq -r .message | sort | uniq -c | sort -rn"

block sampling
on "docker compose run --rm -e PYTHONPATH=/app sandbox python sampled.py 2>/dev/null | jq -r .level | sort | uniq -c"
