"""Replay a day of the website's events as if it were happening now.

    python3 replay.py EVENTS.jsonl OUT.jsonl [SPEED]

appends each event of EVENTS.jsonl to OUT.jsonl when its moment comes, with
`occurred_at` moved to today, SPEED times faster than the day it came from (60
by default: a minute of the shop's day each second). It is the lab's stand-in
for a website that is open: what a streaming consumer reads is a file that
keeps growing. Written for the course; standard library only.
"""
import datetime as dt
import json
import sys
import time

src, out = sys.argv[1], sys.argv[2]
speed = float(sys.argv[3]) if len(sys.argv) > 3 else 60.0
events = [json.loads(line) for line in open(src, encoding="utf-8")]
first = dt.datetime.fromisoformat(events[0]["occurred_at"])
start = time.time()
now0 = dt.datetime.now().astimezone()
with open(out, "a", encoding="utf-8") as f:
    for ev in events:
        due = (dt.datetime.fromisoformat(ev["occurred_at"]) - first).total_seconds() / speed
        wait = start + due - time.time()
        if wait > 0:
            time.sleep(wait)
        ev["occurred_at"] = (now0 + dt.timedelta(seconds=due)).isoformat(timespec="seconds")
        f.write(json.dumps(ev, separators=(",", ":")) + "\n")
        f.flush()
