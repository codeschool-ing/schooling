#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), copying the course's programs into ~/obs from
# ../../lab/code, and the replay of the week, which lesson 3 shows. The
# programs this lesson writes are put below and shown in full.
#
# The alert rules are evaluated over the replayed week by alerts.py, as an
# alerting system would evaluate them each hour; no alerting system runs here
# and nobody was paged. The exposition is prometheus-client 0.26.0's own
# output; no Prometheus server scrapes it in this lab.
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/obs$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/llmobs-capture.lock; flock 9
lab reset >/dev/null
use telemetry.py redact.py assistant.py replay.py checks.py costs.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl; python replay.py >/dev/null'

put replies.py <<'PY'
"""replies.py: the week's answered and refused customer replies, one record each, from the root spans and the thumbs."""
import json
from datetime import datetime

import checks

thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}


def week():
    out = []
    for s in map(json.loads, open("spans.jsonl")):
        a = s["attributes"]
        if s["name"] != "ask" or a["app.feature"] == "summary":
            continue
        out.append({"at": datetime.fromtimestamp(s["start"] / 1e9), "release": a["app.release"],
                    "feature": a["app.feature"], "refused": checks.is_refusal(a["app.reply"]),
                    "thumb": thumbs.get(s["trace"])})
    return sorted(out, key=lambda r: r["at"])
PY

put series.py <<'PY'
"""series.py: the dashboard's quality panel as numbers: per six hours, how many replies, and how many refused."""
from collections import defaultdict

import replies

slots = defaultdict(list)
for r in replies.week():
    slots[r["at"].strftime("%a %d ") + f"{r['at'].hour // 6 * 6:02d}h"].append(r)
print("six hours from      replies  refused         thumbs down")
for slot, rs in slots.items():
    refused, voted = sum(r["refused"] for r in rs), [r for r in rs if r["thumb"]]
    down = sum(r["thumb"] == "down" for r in voted)
    release = " " + rs[-1]["release"] if rs[0]["release"] != rs[-1]["release"] else ""
    print(f"  {slot:16} {len(rs):8} {refused:6} {refused / len(rs):5.0%}   {down:4} of {len(voted):3}{release}")
PY

put exposition.py <<'PY'
"""exposition.py: the same replies as the counters a metrics system scrapes, in Prometheus's text format."""
from prometheus_client import CollectorRegistry, Counter, disable_created_metrics, generate_latest

import replies

disable_created_metrics()   # a counter's creation time is now, not the week's: leave it out
registry = CollectorRegistry()
answers = Counter("assistant_replies", "Customer replies, by what kind of reply they were.",
                  ["feature", "release", "outcome"], registry=registry)
for r in replies.week():
    answers.labels(r["feature"], r["release"], "refused" if r["refused"] else "answered").inc()
print(generate_latest(registry).decode(), end="")
PY

put alerts.py <<'PY'
"""alerts.py: four rules for "refusals are up", each evaluated every hour of the week as an alerting system would."""
import math
from datetime import datetime, timedelta

import replies

week = replies.week()
RELEASE = datetime(2026, 10, 2, 10)
before = [r["refused"] for r in week if r["at"] < datetime(2026, 10, 1)]
BASELINE = sum(before) / len(before)


def window(now, hours):
    """(refused, replies) in the HOURS before NOW."""
    rs = [r["refused"] for r in week if now - timedelta(hours=hours) <= r["at"] < now]
    return sum(rs), len(rs)


def lower(k, n, z=1.96):
    """The low end of the 95% Wilson interval of k in n, lesson 9's."""
    if n == 0:
        return 0.0
    p = k / n
    return ((p + z * z / (2 * n)) - z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))) / (1 + z * z / n)


RULES = {
    "last hour above 40%": lambda now: (lambda k, n: n > 0 and k / n > 0.40)(*window(now, 1)),
    "last 3 hours above 40%, 30 replies or more": lambda now: (lambda k, n: n >= 30 and k / n > 0.40)(*window(now, 3)),
    "yesterday above 30%, checked at midnight": lambda now: now.hour == 0 and (lambda k, n: n > 0 and k / n > 0.30)(*window(now, 24)),
    "last 6 hours surely above the baseline": lambda now: lower(*window(now, 6)) > BASELINE,
}
print(f"baseline: {sum(before)} refused of {len(before)} replies before 1 October, {BASELINE:.1%}")
hours = [datetime(2026, 9, 29) + timedelta(hours=h) for h in range(24 * 6 + 1)]
for name, rule in RULES.items():
    fired = [h for h in hours if rule(h)]
    early = [h for h in fired if h <= RELEASE]
    late = [h for h in fired if h > RELEASE]
    first = f"{late[0]:%a %d %H:%M}, {(late[0] - RELEASE).total_seconds() / 3600:.0f} h after" if late else "never"
    print(f"{name}\n    false alarms before the release {len(early):3}   first after it: {first}"
          f"   firing in {len(late)} of the {sum(h > RELEASE for h in hours)} hours after")
PY

block series
on 'python series.py'

block exposition
on 'python exposition.py'

block alerts
on 'python alerts.py'
