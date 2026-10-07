---
title: Streaming: an event at a time
version: 1
---

**Streaming ingestion handles each record as it arrives**, with no period to wait for. The source
is something that never closes — a website writing a click every time somebody clicks, a till
writing a sale, a sensor writing a reading — and the consumer keeps up with it, one event or a
handful at a time.

The lab's website writes its events to a file, one JSON object per line, and during the day the
file grows. `shop day` delivers the day's file whole, the way a batch would receive it, so to watch
one grow you need something that writes it a line at a time. Save this as `~/pontofinal/replay.py`:

```python
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
```

Ana starts it in the background, `python ~/pontofinal/replay.py landing/events/2026-03-01.jsonl
landing/stream.jsonl 600 &`, so it appends each of the day's events to `landing/stream.jsonl` when
its moment comes, six hundred times faster than the day it came from. Her consumer reads the file
as it grows:

```schooling-example
{
  "language": "python",
  "file": "consume.py",
  "parts": [
    {
      "code": "\"\"\"Read the website's events as they land, and say how far behind it is.\"\"\"\nimport datetime as dt\nimport json\nimport os\nimport sys\nimport time\n\n"
    },
    {
      "code": "path, offset_file, seconds = sys.argv[1], sys.argv[2], float(sys.argv[3])\npos = int(open(offset_file).read()) if os.path.exists(offset_file) else 0\nprint(f\"starting at byte {pos}\")\nstop = time.time() + seconds\nseen, purchases, worst, report = 0, 0, 0.0, time.time() + 2\n",
      "note": "Where to start: the byte offset saved by the last run, or the start of the file. **The offset is the consumer's memory**, and it lives outside the program so that a restart does not begin again from zero."
    },
    {
      "code": "with open(path, encoding=\"utf-8\") as f:\n    f.seek(pos)\n    while time.time() < stop:\n",
      "note": "It runs for a fixed number of seconds so the lesson can show it stopping. A real consumer runs until somebody stops it."
    },
    {
      "code": "        line = f.readline()\n        if not line.endswith(\"\\n\"):        # nothing new yet, or half a line\n            f.seek(pos)\n            time.sleep(0.1)\n            continue\n",
      "note": "A line without its newline is one the writer has not finished. Reading it would parse half an event, so the consumer goes back and waits."
    },
    {
      "code": "        pos = f.tell()\n        event = json.loads(line)\n        seen += 1\n        purchases += event[\"type\"] == \"purchase\"\n        happened = dt.datetime.fromisoformat(event[\"occurred_at\"])\n        lag = (dt.datetime.now().astimezone() - happened).total_seconds()\n        worst = max(worst, lag)\n",
      "note": "**Lag is now minus the moment the event happened.** It is the number a streaming pipeline is judged by, the way a batch is judged by how long ago it last ran."
    },
    {
      "code": "        with open(offset_file, \"w\") as o:\n            o.write(str(pos))\n",
      "note": "The offset is written after each event is handled, never before. Written before, a crash in between would skip an event; written after, a crash makes the next run read one event twice."
    },
    {
      "code": "        if time.time() >= report:\n            print(f\"{time.strftime('%H:%M:%S')}  {seen} events, \"\n                  f\"{purchases} purchases, at most {worst:.1f} s behind\")\n            worst, report = 0.0, report + 2\n",
      "note": "Every two seconds, a line: how many events so far, and the worst lag in that window."
    },
    {
      "code": "print(f\"stopped at byte {pos}\")"
    }
  ]
}
```

She starts it for seven seconds, stops it, waits three, and starts it again:

```
ana@vm:~/etl$ python consume.py landing/stream.jsonl stream.offset 7
starting at byte 0
05:24:42  74 events, 5 purchases, at most 1.3 s behind
05:24:44  117 events, 5 purchases, at most 1.1 s behind
05:24:46  152 events, 6 purchases, at most 1.0 s behind
stopped at byte 19649
ana@vm:~/etl$ python consume.py landing/stream.jsonl stream.offset 5
starting at byte 19649
05:24:52  97 events, 4 purchases, at most 3.4 s behind
05:24:54  130 events, 6 purchases, at most 1.0 s behind
stopped at byte 36377
```

The clock times are the recording's own, and a run of yours will show yours. Two things in it are
the point:

- **The lag is about a second.** A purchase is known to the pipeline a second after it happens, not
  the next morning. The one-second floor is the replay's doing: it writes `occurred_at` to the
  whole second, so an event can look up to a second older than it is.
- **The restart did not start again.** The second run began at byte 19649, where the first had
  stopped, and its first window was 3.4 seconds behind: the three seconds of events that arrived
  while nothing was reading, caught up in one go.

## What streaming costs

**Nothing is ever finished.** A batch can say "2 March is loaded". A stream can only say "this is
everything up to the last event I saw", and an event delayed on somebody's phone can arrive after
events that happened later. The day file this lab replays carries a few of those on purpose, and a
few events written twice, the way a collector that retried writes them.

**And the program never stops.** A batch that crashes is rerun in the morning. A consumer that
crashes is a hole in the data from that moment, growing until someone notices, so it needs
something to restart it and something to watch the lag. The offset file is the small version of
the bookkeeping a real streaming platform does for you: Kafka keeps an offset per consumer group,
and lesson 3 says more about it. Kafka is not installed in this lab and nothing here ran on it.
