---
title: Tumbling windows
version: 1
---

**A tumbling window cuts time into equal slices that touch and never overlap, so every event
lands in exactly one.** It is the window people mean when they say "per five minutes" or "per
hour", and it is what lesson 9's `per_minute.py` built: a sale at 10:37 went into the 10:00 hour
and nowhere else.

The rule is one line of arithmetic. With times in seconds and a size of five minutes, 300
seconds, a window starts at the event time rounded **down** to a multiple of the size:

```python
start = t // size * size
end = start + size
```

09:03:55 is 32,635 seconds after midnight; divided by 300 that is 108.78, rounded down 108 (Python's `//` divides and rounds down in one step), times
300 is 32,400 seconds, which is 09:00:00. The window is 09:00:00 to 09:05:00. Every tumbling
window in every engine is that formula, give or take an offset for time zones.

The program the whole lesson runs implements four kinds of window over the ten sales of the last
section. Save it as `~/work/windows.py`:

```schooling-example
{
  "file": "windows.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"windows.py: the same ten sales, cut into windows four different ways.\n\n    python windows.py tumbling SIZE [--by-shop] [--updates]\n    python windows.py hopping SIZE ADVANCE [--by-shop] [--updates]\n    python windows.py sliding SIZE [--by-shop]\n    python windows.py session GAP [--by-shop]\n\nSIZE, ADVANCE and GAP are in minutes. The sales are listed in the order they\nARRIVED; the eighth happened at 09:08:50 and arrived after the seventh.\n\"\"\"\nimport sys\n\nSALES = [  # (when it happened, shop, cents), in the order they arrived\n    (\"09:00:40\", \"recife\", 3990), (\"09:02:10\", \"natal\", 5490),\n    (\"09:03:55\", \"olinda\", 2990), (\"09:05:00\", \"recife\", 7900),\n    (\"09:06:20\", \"natal\", 4490), (\"09:12:30\", \"caruaru\", 6200),\n    (\"09:13:05\", \"recife\", 3500), (\"09:08:50\", \"natal\", 8990),\n    (\"09:14:10\", \"olinda\", 2990), (\"09:21:00\", \"recife\", 5490),\n]\n\n",
      "note": "The usage, and **the ten sales, in the order they arrived**. Times are when each sale happened; money is in cents."
    },
    {
      "code": "def secs(when):\n    h, m, s = map(int, when.split(\":\"))\n    return h * 3600 + m * 60 + s\n\n\ndef clock(t):\n    return f\"{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}\"\n\n",
      "note": "Two helpers: a time of day to seconds since midnight, and back. Everything in between is arithmetic on seconds."
    },
    {
      "code": "def tumbling(t, size):\n    start = t // size * size\n    return [(start, start + size)]\n\n",
      "note": "**A tumbling window starts at the event's time rounded down to a multiple of the size**, and ends one size later. One event, one window."
    },
    {
      "code": "def hopping(t, size, advance):\n    last = t // advance * advance\n    return [(s, s + size) for s in range(last, t - size, -advance)][::-1]\n\n",
      "note": "A hopping window starts every ADVANCE. The windows holding `t` are the ones that started at or before it and have not yet ended, counted back from the latest start."
    },
    {
      "code": "def sliding(sales, size):\n    for t, _, _ in sorted(sales):\n        yield (t - size, t), [x for x in sales if t - size <= x[0] <= t]\n\n",
      "note": "The Kafka Streams kind: for every sale, the window that ENDS at it, holding every sale within SIZE before it, both ends included."
    },
    {
      "code": "def session(sales, gap):\n    found = []  # [first, last, sales] for each session so far\n    for sale in sales:\n        t = sale[0]\n        near = [s for s in found if s[0] - gap < t < s[1] + gap]\n        if len(near) > 1:\n            print(f\"({clock(t)} arrives and joins {len(near)} sessions into one)\")\n        for s in near:\n            found.remove(s)\n        found.append([min([t] + [s[0] for s in near]), max([t] + [s[1] for s in near]),\n                      [sale] + [x for s in near for x in s[2]]])\n    for first, last, inside in sorted(found):\n        yield (first, last), inside\n\n",
      "note": "Sessions are found in arrival order. A sale near an existing session joins it, and **a sale near two sessions joins them into one**, which the program says out loud."
    },
    {
      "code": "def show(window, inside, prefix=\"\"):\n    cents = sum(c for _, _, c in inside)\n    print(f\"{prefix}{clock(window[0])}-{clock(window[1])}  {len(inside):5d}  {cents:6d}\")\n\n\nkind, minutes = sys.argv[1], [int(a) * 60 for a in sys.argv[2:] if a.isdigit()]\nby_shop, updates = \"--by-shop\" in sys.argv, \"--updates\" in sys.argv\nsales = [(secs(w), shop, cents) for w, shop, cents in SALES]\nprint((\"arrived   \" if updates else \"\") + \"window               sales   cents\")\nfor shop in sorted({s[1] for s in sales}) if by_shop else [None]:\n    mine = [s for s in sales if shop in (None, s[1])]\n    if shop:\n        print(shop)\n    if kind == \"sliding\":\n        for window, inside in sliding(mine, *minutes):\n            show(window, inside)\n    elif kind == \"session\":\n        for window, inside in session(mine, *minutes):\n            show(window, inside)\n    else:\n        windows = {}\n        for sale in mine:\n            cut = tumbling if kind == \"tumbling\" else hopping\n            for window in cut(sale[0], *minutes):\n                windows.setdefault(window, []).append(sale)\n                if updates:\n                    show(window, windows[window], prefix=clock(sale[0]) + \"  \")\n        if not updates:\n            for window, inside in sorted(windows.items()):\n                show(window, inside)",
      "note": "The rest prints: one line per window, optionally per shop, or, with `--updates`, one line every time a sale changes a window."
    }
  ]
}
```

The sales are written into the program rather than read from Kafka, which is deliberate: every
question in this lesson is about which window an event belongs to, and that is arithmetic on
times. Lessons 12 and 13 run the same windows in Spark and Flink over a topic.

Five-minute tumbling windows:

```
ubuntu@stream:~/work$ python windows.py tumbling 5
```

Four windows, and the ten sales add up: 3, 3, 3 and 1. There is no line for 09:15 to 09:20,
because no sale happened then. **An engine only creates a window when an event lands in it**, so
a quiet five minutes is an absent row rather than a zero, and a report that needs the zero has
to fill it in itself.

## Where an edge goes

Sale 4 happened at exactly 09:05:00. It is in the second window, 09:05 to 09:10, and not the
first. **A window includes its start and excludes its end**, written `[09:00, 09:05)`: the square
bracket means the edge is inside, the round one that it is not. The choice is arbitrary and the
consistency is not. If both edges were inside, sale 4 would be counted twice; if neither were, it
would vanish. Half-open intervals are the only way to tile time with no gaps and no overlaps, and
Flink, Spark and Kafka Streams all use them for tumbling windows.

The window's own label is a convention too. This program prints both edges. An engine usually
keys a result by the window's start, which reads naturally ("the 09:05 window"), and some
dashboards label it by the end, which is when the result becomes available. Check which before
joining two systems' outputs, or every number will be one window out.

## Choosing the size

The size is a question about the business, not about the engine. Five minutes answers "is a shop
busy right now"; an hour answers "how did the morning go". Smaller windows mean more of them, each
with fewer events, so a count is noisier and the state kept per window is multiplied. The
tumbling window has one limitation the next section removes: a burst that straddles an edge is
cut in two, and neither half looks like a burst.
