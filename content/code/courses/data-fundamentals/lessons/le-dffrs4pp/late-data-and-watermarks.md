---
title: Late data and watermarks
version: 1
---

**A window counted by event time has to be sent at some point, and at that point the processor is
betting that nothing older is still on its way.** Wait too little and rides that were merely delayed are
lost. Wait too long and the answer for 08:00 arrives when nobody needs it any more. There is no setting
that avoids both, only a choice of which to pay.

The bet has a name. A **watermark** is the processor's running estimate of how far event time has got:
a moment such that it does not expect any more events from before it. When the watermark passes the end
of a window, the window is sent. An event that turns up afterwards for a window already sent is **late
data**. Lesson 7 used the same word for something simpler, the newest change an incremental copy has
seen; both mark how far the data has been read, and they are not the same thing.

The simplest watermark, and the one used here, is the newest event time seen so far minus an
**allowed lateness**. If the newest event happened at 08:40 and the allowed lateness is two minutes, the
watermark is 08:38, and every window ending at or before 08:38 is sent. Real stream processors build it
in more careful ways, from what each source reports about its own progress, but every version is an
estimate and none of them can see an event that has not arrived yet. Save `stream/watermark.py`:

```schooling-example
{"language": "python", "file": "stream/watermark.py", "parts": [
{"code": "# stream/watermark.py\nimport json\nimport sys\nfrom collections import Counter\nfrom datetime import datetime, timedelta\n\nLATENESS = timedelta(minutes=int(sys.argv[1]))   # how late an event may be\nSTART, SIZE = datetime(2025, 10, 6, 8, 0), timedelta(minutes=15)\nrides, closed, dropped = Counter(), set(), []\nwatermark = datetime.min\n", "note": "The allowed lateness comes from the command line, in minutes. The windows are the four quarters of an hour from 08:00 on Monday. `closed` holds the windows already sent, and `watermark` starts as early as a time can be."},
{"code": "with open('docks.jsonl') as f:\n    for line in f:                               # in order of arrival\n        e = json.loads(line)\n        happened = datetime.fromisoformat(e['event_time'])\n        if e['kind'] == 'undock' and START <= happened < START + 4 * SIZE:\n            w = (happened - START) // SIZE\n            if w in closed:\n                dropped.append(e['id'])          # its window has already been sent\n            else:\n                rides[w] += 1\n", "note": "Each event in order of arrival, which is the order a stream sees them in. An undock inside the hour goes to its window `w`, numbered 0 to 3, unless that window has already been sent: then the event is late, and its id goes into `dropped`."},
{"code": "        watermark = max(watermark, happened - LATENESS)\n        for w in range(4):\n            if w not in closed and watermark >= START + (w + 1) * SIZE:\n                closed.add(w)\n                begins = START + w * SIZE\n                print(f'{begins:%H:%M} window sent at {e[\"arrived\"][11:]}: {rides[w]} rides')\n", "note": "After each event the watermark moves to the newest event time minus the allowed lateness, and never moves back. Every window whose end it has passed is sent: its count is printed with the arrival time of the event that moved the watermark past it."},
{"code": "print('dropped as late:', dropped)\n", "note": "Last, the late events that were dropped."}
]}
```

Run it twice, allowing two minutes of lateness and then twenty-five:

```
ana@lab:~/roda/stream$ python watermark.py 2
08:00 window sent at 08:17:27: 19 rides
08:15 window sent at 08:32:10: 20 rides
08:30 window sent at 08:47:37: 14 rides
08:45 window sent at 09:03:32: 8 rides
dropped as late: ['EV00087', 'EV00116', 'EV00137']
ana@lab:~/roda/stream$ python watermark.py 25
08:00 window sent at 08:40:08: 19 rides
08:15 window sent at 08:55:02: 21 rides
08:30 window sent at 09:10:37: 16 rides
08:45 window sent at 09:26:10: 8 rides
dropped as late: []
```

With two minutes, every window goes out about two minutes after it closes, and the price is three rides.
The Parque Barigui events reached the server at 08:51:30, after the windows they belonged to had been
sent, and the program dropped them; the 08:15 and 08:30 counts went out wrong and stayed wrong.

With twenty-five minutes nothing is dropped and all four counts match the event-time column of the last
section. The price is time: the 08:00 window, which closed at 08:15, is sent at 08:40. **Every answer is
now about twenty-five minutes old when it appears, including the answers for all the mornings without an
outage.**

## What to do with a late event

Dropping is the simplest choice and the one the program makes. A stream processor offers others, and a
team chooses per question:

- update the window: send a corrected count when a late ride arrives, which is right when whoever
  reads the answer can take a correction, like a table that is overwritten;
- set it aside: write late events somewhere of their own, so they are counted and somebody can see
  how many there were;
- leave it to batch: let the stream give a fast answer and let the nightly job, which reads a closed
  day from the raw events, give the correct one.

No allowed lateness short of a day would have caught Passeio Público's events, which arrived more than
twenty-one hours after they happened. That is why the last option is common, and it is the shape of the
architecture two sections on.
