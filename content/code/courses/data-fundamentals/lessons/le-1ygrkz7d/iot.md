---
title: IoT, or sensors with clocks of their own
version: 1
---

**A sensor is a small computer with a cheap clock on an unreliable network, and its readings arrive
late, twice, out of order or not at all.** Every dock at Roda Livre has one. Once a minute it reports
whether it holds a bicycle, and the readings travel over the mobile network to a server the vendor
runs. IoT, the internet of things, is the name for sources like this: many small devices, each sending
a little, often, from places nobody can reach in a hurry.

The common picture is a tidy table, one row per sensor per minute. What arrives is that table after a
bad journey. A reading can be lost on the way. It can be held up by the network and overtaken by the
next one. It can be sent twice, because the sensor did not hear that the first got through, which is
the same at-least-once delivery as the app's events. And it carries the time the sensor's own clock
said, which drifts unless something corrects it.

Two things in each reading make all of that countable. A **sequence number**, which the sensor adds
one to for every reading, turns a gap into a missing number and a duplicate into a number seen twice.
And **two times**, the one the sensor stamped and the one the server received it at, turn a wrong clock
into a difference you can measure.

## An hour of three docks

This program makes an hour of readings from three docks, from a fixed seed, the way the vendor's server
would receive them, and then counts what went wrong:

```schooling-example
{"language": "python", "file": "sources/docks.py", "parts": [
{"code": "# sources/docks.py\nimport random\nfrom datetime import datetime, timedelta\n\n"},
{"code": "rng = random.Random(7)\nSTART = datetime(2025, 9, 15, 8, 0)\nCLOCK = {\"ST02-D01\": 0, \"ST02-D02\": 47, \"ST05-D01\": 0}   # seconds fast; one clock drifted\narrived = []\n", "note": "A fixed seed, so every run makes the same hour. Three docks; `ST02-D02`'s clock runs 47 seconds fast."},
{"code": "for sensor, fast in CLOCK.items():\n    for seq in range(60):                                 # one reading a minute, for an hour\n        if rng.random() < 0.04:\n            continue                                      # lost before it was sent\n        taken = START + timedelta(minutes=seq)\n        stamped = taken + timedelta(seconds=fast)         # what the sensor writes on it\n        delay = 130 if rng.random() < 0.05 else rng.choice([1, 2, 3])   # a network hiccup\n        received = taken + timedelta(seconds=delay)\n        arrived.append((sensor, seq, stamped, received))\n        if rng.random() < 0.05:                           # no acknowledgement, so sent again\n            arrived.append((sensor, seq, stamped, received + timedelta(seconds=10)))\n", "note": "Sixty readings per dock. A few are lost; each one gets the time the sensor stamps on it and the time the server receives it, usually a second or three later and now and then 130. A few are sent twice."},
{"code": "arrived.sort(key=lambda r: r[3])                          # the order the server saw them in\n\n", "note": "The server sees them in the order they arrived, not the order they were taken."},
{"code": "seen, highest, dupes, late, ahead = set(), {}, 0, 0, 0\nfor sensor, seq, stamped, received in arrived:\n    if (sensor, seq) in seen:\n        dupes += 1\n        continue\n    seen.add((sensor, seq))\n    if seq < highest.get(sensor, -1):\n        late += 1\n    highest[sensor] = max(seq, highest.get(sensor, -1))\n    if stamped > received:\n        ahead += 1\n\n", "note": "One pass, the way a loader would make it: a key seen before is a duplicate; a sequence number below the highest seen from that sensor arrived late; a stamp after the arrival is a clock that is ahead."},
{"code": "print(len(arrived), \"readings arrived;\", len(CLOCK) * 60, \"were due\")\nprint(len(CLOCK) * 60 - len(seen), \"never arrived\")\nprint(dupes, \"arrived twice\")\nprint(late, \"arrived after a later reading from the same sensor\")\nprint(ahead, \"are stamped later than the moment they arrived\")\n", "note": "Everything that never arrived is the difference between what was due and the distinct keys seen."}
]}
```

```
ana@lab:~/roda/sources$ python docks.py
185 readings arrived; 180 were due
6 never arrived
11 arrived twice
6 arrived after a later reading from the same sensor
57 are stamped later than the moment they arrived
```

**More readings arrived than were due, and six are still missing.** That one line is why counting rows
is not checking a source: 185 against 180 looks like everything and a bit more. Remove the 11 that came
twice and 174 are left, six short of 180, and only the sequence numbers say which six.

Six arrived after a reading the same sensor took later, so a program that kept "the latest reading"
per dock would sometimes keep an older one. And 57 readings carry a time later than the moment they
reached the server, which no reading can honestly do. All of them come from `ST02-D02`, whose clock
runs 47 seconds fast. On a map that is invisible. In a question about how long Rua XV had no bicycles,
it moves every empty spell at one dock by most of a minute.

## What the owner can fix and what you must handle

Some of this is the vendor's to fix, and worth asking for. Devices can keep their clocks right with
NTP, the protocol computers use to set their time from a server. They can number their readings. They
can keep readings they could not send and send them later, rather than dropping them. A common
protocol for sensors, MQTT, lets a device ask for at-least-once delivery, which trades lost readings
for duplicates.

The rest is permanent and the data side handles it. **Duplicates are removed by key**, here the sensor
and its sequence number. **Gaps are counted, not filled** by inventing a reading. And **both times are
kept**, because which one a question should use, and how long to wait for a late reading before
counting a minute as finished, is lesson 8's subject.
