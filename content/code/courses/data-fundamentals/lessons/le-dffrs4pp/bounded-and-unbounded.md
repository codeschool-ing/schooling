---
title: Bounded and unbounded data
version: 1
---

**Batch and stream are not a slow way and a fast way of doing the same thing. They answer a different
question first: does the data end?**

The common picture sorts them by speed. Batch is the old overnight job, stream is the modern real-time
one, and a stream is what you build when batch is too slow. Speed does follow from the difference, but
it is not the difference. A job that runs every five minutes over the last five minutes of data is
still batch, and a stream processor can be told to wait an hour before it answers anything.

The difference is in the input:

- **bounded** data has an end. Yesterday's rides, the September export, a file somebody uploaded: you
  can wait until all of it is there, read it from the first row to the last, and give one answer that
  will not change;
- **unbounded** data has none. The dock sensors at Roda Livre report every bicycle that leaves or
  returns, and they will keep doing so for as long as the company exists. There is no "all of it" to
  wait for, so every answer is an answer about the data so far.

**Batch processing** works on bounded data. It waits until a piece is complete and then processes all
of it at once. **Stream processing** works on unbounded data. It handles each event as it arrives and
keeps its answer up to date.

Most data a company produces is unbounded: the sensors, the taps in the app, the payments. Batch makes
it bounded by cutting it into pieces, one day or one hour, and processing each piece once it is
closed. Nearly everything in this lesson follows from that cut: where it falls, when it is made, and
what happens to an event that turns up after it.

## Three mornings of dock events

Every program in this lesson works in its own directory, `~/roda/stream`, on the machine lesson 1
built:

```sh
mkdir -p ~/roda/stream
cd ~/roda/stream
```

The data comes from a program, like everything in this course. Save it as `stream/sensors.py`. It
writes three mornings of dock events, Monday 6 to Wednesday 8 October 2025, into one file,
`docks.jsonl`, with one JSON object per line.

```schooling-example
{"language": "python", "file": "stream/sensors.py", "parts": [
{"code": "# stream/sensors.py\nimport json\nimport random\nfrom datetime import datetime, timedelta\n\nrandom.seed(8)\nSTATIONS = [f'ST{i:02}' for i in range(1, 13)]\nevents = []\nfor day in ('2025-10-06', '2025-10-07', '2025-10-08'):\n    opening = datetime.fromisoformat(day + ' 07:00:00')\n    for _ in range(120):                          # 120 rides a morning\n        start = opening + timedelta(seconds=int(random.triangular(0, 10800, 5400)))\n        end = start + timedelta(minutes=random.randint(4, 40))\n        bike = f'B{random.randint(1, 90):03}'\n        events.append((start, random.choice(STATIONS), bike, 'undock'))\n        events.append((end, random.choice(STATIONS), bike, 'dock'))\nevents.sort()\n", "note": "Three mornings, from 07:00 to 10:00, with 120 rides each. A ride is two events: an `undock` where it starts and a `dock` where it ends, at a station picked at random. `triangular` puts most starts near 08:30, the middle of the morning, and the fixed seed makes your file the same as the one in this lesson."},
{"code": "\n\ndef arrival(t, station):\n    \"\"\"When the reading reached the server: seconds later, unless a link was down.\"\"\"\n    s = str(t)\n    if station == 'ST08' and '2025-10-06 08:20' <= s < '2025-10-06 08:51:30':\n        return datetime.fromisoformat('2025-10-06 08:51:30')\n    if station == 'ST04' and '2025-10-06 09:20' <= s < '2025-10-07 07:02':\n        return datetime.fromisoformat('2025-10-07 07:02:00')\n    return t + timedelta(seconds=random.randint(1, 4))\n", "note": "When each event reached the server: one to four seconds after it happened, unless a link was down. Two outages are planted. Parque Barigui (`ST08`) loses its link on Monday at 08:20 and sends what it held at 08:51:30; Passeio Público (`ST04`) loses its link at 09:20 and sends everything at 07:02 the next morning."},
{"code": "\n\nrows = [{'id': f'EV{n:05}', 'station': st, 'bike': bike, 'kind': kind,\n         'event_time': str(t), 'arrived': str(arrival(t, st))}\n        for n, (t, st, bike, kind) in enumerate(events, 1)]\nrows.sort(key=lambda r: (r['arrived'], r['id']))  # the log is in order of arrival\nwith open('docks.jsonl', 'w') as f:\n    for r in rows:\n        f.write(json.dumps(r) + '\\n')\nprint(len(rows), 'events written to docks.jsonl')\n", "note": "Every event gets an id in the order the events happened, `EV00001` upwards. Then the file is sorted by arrival, because that is the order a server receives events in: a line's position says when it arrived, not when it happened."}
]}
```

```
ana@lab:~/roda/stream$ python sensors.py
720 events written to docks.jsonl
ana@lab:~/roda/stream$ head -3 docks.jsonl
{"id": "EV00001", "station": "ST10", "bike": "B058", "kind": "undock", "event_time": "2025-10-06 07:15:18", "arrived": "2025-10-06 07:15:20"}
{"id": "EV00002", "station": "ST05", "bike": "B088", "kind": "undock", "event_time": "2025-10-06 07:18:55", "arrived": "2025-10-06 07:18:59"}
{"id": "EV00003", "station": "ST05", "bike": "B065", "kind": "undock", "event_time": "2025-10-06 07:22:47", "arrived": "2025-10-06 07:22:48"}
```

Each line is one event, and **each event carries two times**: `event_time`, when the bicycle left or
reached the dock, and `arrived`, when the reading reached the server. On the first line they are two
seconds apart. Two outages are written into the program on purpose, the kind a mobile link has, and the
rest of the lesson finds them the way a data team would.

The file is bounded, because the program stopped writing. The rest of the lesson reads it two ways. The
batch job in the next section treats it as a finished file. The consumer after that treats it as a log
that could still be growing, and reads it one line after another.
