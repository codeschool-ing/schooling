"""replay.py: a week of data/traffic.jsonl through the assistant, in a few minutes.

    python replay.py [--from 2026-09-28] [--to 2026-10-05] [--workers 8] [--processor MODULE:CLASS]

Each request runs for real: the embedding, the search, the streamed reply, all
measured. What is simulated is the calendar and the people. The calendar:
every span is stamped with the moment the traffic file gives its request, and
the durations inside it are the measured ones. The people: what a customer
does after reading a reply is decided by the rules below, which the course
wrote, with a generator seeded by the request's id so that a rerun decides
the same way. They are written down so that nobody mistakes them for a
measurement of how people behave.

  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic
    the documents do not answer, if it is the refusal.
  - 18% of customers rate a reply. A wrong reply gets a thumbs down 85% of the
    time; a right one gets a thumbs up 92% of the time.
  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds
    later, in the same session. If that is wrong too, 60% ask for a person.
  - Summaries are for the support team, who do not rate them.

Feedback is appended to feedback.jsonl, keyed by the trace id of the reply it
is about.
"""
import argparse
import importlib
import json
import random
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

import assistant
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--traffic", default="data/traffic.jsonl")
p.add_argument("--from", dest="since", default="0000")
p.add_argument("--to", dest="until", default="9999")
p.add_argument("--workers", type=int, default=8)
p.add_argument("--spans", default="spans.jsonl")
p.add_argument("--processor", action="append", default=[], help="MODULE:CLASS, a span processor to add")
a = p.parse_args()

TOPICS = json.load(open("data/topics.json"))
LOCK = threading.Lock()
counts = {"requests": 0, "errors": 0, "feedback": 0}


def right(reply, topic):
    facts = TOPICS[topic - 1]["facts"]
    if not facts:
        return reply.startswith(assistant.REFUSAL)
    return any(f.lower() in reply.lower() for f in facts)


def record(**row):
    with LOCK, open("feedback.jsonl", "a") as f:
        f.write(json.dumps(row) + "\n")
        counts["feedback"] += 1


def one(row, at, text):
    """Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed."""
    t = datetime.fromisoformat(at)
    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())
    try:
        reply, _, trace_id = assistant.ask(text, user=row["user"], session=row["session"],
                                           feature=row["feature"], at=at)
        return reply, trace_id
    except Exception:
        with LOCK:
            counts["errors"] += 1
        return None, None
    finally:
        telemetry.OFFSET_NS.reset(token)
        with LOCK:
            counts["requests"] += 1


def person(row):
    rng = random.Random(row["id"])
    reply, trace_id = one(row, row["at"], row["text"])
    if row["feature"] == "summary" or reply is None:
        return
    ok = right(reply, row["topic"])
    t = datetime.fromisoformat(row["at"])
    if rng.random() < 0.18:
        up = rng.random() < 0.92 if ok else rng.random() >= 0.85
        record(trace=trace_id, request=row["id"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),
               kind="thumbs", value="up" if up else "down")
    if ok or rng.random() >= 0.45:
        return
    t += timedelta(seconds=rng.randrange(40, 121))
    others = [x for x in TOPICS[row["topic"] - 1]["phrasings"] if x != row["text"]] or [row["text"]]
    again = rng.choice(others)
    record(trace=trace_id, request=row["id"], at=t.isoformat(), kind="rephrase", value=again)
    reply2, trace2 = one(row, t.isoformat(timespec="seconds"), again)
    if reply2 is not None and not right(reply2, row["topic"]) and rng.random() < 0.6:
        record(trace=trace2, request=row["id"], at=(t + timedelta(seconds=20)).isoformat(),
               kind="escalate", value="asked for a person")


telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in
                                     (x.split(":") for x in a.processor)])
rows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r["at"] < a.until]
with ThreadPoolExecutor(a.workers) as pool:
    list(pool.map(person, rows))
print(f"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, "
      f"{counts['errors']} failed, {counts['feedback']} feedback events")
