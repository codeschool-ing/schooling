---
title: Windows, the totals a stream can give
version: 1
---

**An unbounded stream has no total, so a stream processor counts per window.** A window is a stretch of
time with a beginning and an end. Each event falls into one or more windows by its timestamp, and each
window gets its own answer: rides started between 08:00 and 08:15, between 08:15 and 08:30, and so on.
The batch job in this lesson used a window too, one day long. A stream just has many more of them, and
has to decide when each one is finished.

Three shapes cover nearly every case:

| window | what it is | at Roda Livre |
|---|---|---|
| **tumbling** | fixed length, back to back, no overlap: every event is in exactly one | rides per quarter of an hour |
| **sliding** | fixed length, starting at a fixed step shorter than its length, so windows overlap and an event is in several | rides in the last 30 minutes, updated every 5 |
| **session** | no fixed length: opens with an event and closes after a gap with none | one customer's use of the app, ending after 10 quiet minutes |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A time axis from 08:00 to 09:00 with rides marked as dots. Tumbling: four adjacent fifteen-minute boxes. Sliding: thirty-minute boxes starting every fifteen minutes, overlapping. Session: one customer’s taps in three clusters, each cluster its own box, separated by gaps of more than ten minutes.\" data-fig=\"windows\"><defs><marker id=\"windows-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><line x1=\"150\" y1=\"28\" x2=\"150\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"285\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><line x1=\"285\" y1=\"28\" x2=\"285\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"420\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><line x1=\"420\" y1=\"28\" x2=\"420\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"555\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><line x1=\"555\" y1=\"28\" x2=\"555\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"690\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"690\" y1=\"28\" x2=\"690\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"14\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">rides</text><line x1=\"150\" y1=\"46\" x2=\"690\" y2=\"46\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><circle cx=\"168\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"195\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"213\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"231\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"258\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"294\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"303\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"330\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"348\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"357\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"384\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"411\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"429\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"447\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"474\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"492\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"519\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"546\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"573\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"618\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"645\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"672\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><text x=\"14\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">tumbling</text><rect x=\"152\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"217.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><rect x=\"287\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"352.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><rect x=\"422\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"487.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><rect x=\"557\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><text x=\"14\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">sliding</text><rect x=\"152\" y=\"122\" width=\"266\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">08:00–08:30</text><rect x=\"422\" y=\"122\" width=\"266\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"555.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">08:30–09:00</text><rect x=\"287\" y=\"154\" width=\"266\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">08:15–08:45</text><text x=\"14\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">session</text><text x=\"14\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one customer</text><rect x=\"169\" y=\"212\" width=\"88\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"177\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"195\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"204\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"231\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"249\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><rect x=\"376\" y=\"212\" width=\"43\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"384\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"393\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"411\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><rect x=\"538\" y=\"212\" width=\"124\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"546\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"573\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"591\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"627\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"654\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><text x=\"316.5\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a 15-minute gap</text><text x=\"478.5\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a 15-minute gap</text><text x=\"420\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a session ends after 10 minutes with no tap</text></svg>", "caption": "The same hour cut three ways. Tumbling windows share no event; sliding ones overlap, so an event is counted in two; sessions are cut where one customer goes quiet."}
```

A tumbling window answers "how many in each period" and its counts add up to the total. A sliding window
answers "how many recently" and smooths the jumps between one quarter and the next; its counts do not add
up, because each event is counted once per window it is in. A session window follows the data rather
than the clock, so two sessions of one customer can be three minutes or three hours long.

## Counting by the wrong clock

Windows are where the two clocks of the last section stop being an idea. Save `stream/windows.py`, which
counts Monday's rides from 08:00 to 09:00 in tumbling windows of fifteen minutes, once by event time and
once by arrival:

```python
# stream/windows.py
import json
from collections import Counter


def window(ts):                                  # '2025-10-06 08:37:12' -> '08:30'
    return f'{ts[11:13]}:{int(ts[14:16]) // 15 * 15:02}'


by_event, by_arrival = Counter(), Counter()
with open('docks.jsonl') as f:
    for line in f:
        e = json.loads(line)
        if e['kind'] != 'undock':
            continue
        if e['event_time'].startswith('2025-10-06 08'):
            by_event[window(e['event_time'])] += 1
        if e['arrived'].startswith('2025-10-06 08'):
            by_arrival[window(e['arrived'])] += 1
print('window  by event time  by arrival time')
for w in ('08:00', '08:15', '08:30', '08:45'):
    print(f'{w}   {by_event[w]:>13}  {by_arrival[w]:>15}')
print('total   ', f'{sum(by_event.values()):>12}  {sum(by_arrival.values()):>15}')
```

The function `window` is the whole of a tumbling window: it rounds a time down to the quarter of an hour
it falls in.

```
ana@lab:~/roda/stream$ python windows.py
window  by event time  by arrival time
08:00              19               19
08:15              21               20
08:30              16               14
08:45               8               11
total              64               64
```

The two columns agree at 08:00 and disagree after it. Counted by arrival, 08:15 and 08:30 each lose rides
and 08:45 gains three: the rides from Parque Barigui that happened earlier and arrived at 08:51:30. **The
total is the same in both columns**, 64, so a report that showed only the hour would never reveal it. The
error is in which window a ride is filed under, and a chart of rides per quarter of an hour drawn from the
second column shows a late surge at 08:45 that did not happen.

The first column is right, and it was computed from a file that had finished arriving. A stream processor
counting the 08:15 window at 08:31 does not have that file. It has to decide when to send its answer,
and that decision is the next section.
