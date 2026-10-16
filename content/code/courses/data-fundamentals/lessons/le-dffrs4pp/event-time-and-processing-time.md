---
title: Event time and processing time
version: 1
---

**Every event has two times, when it happened and when it was processed, and the two disagree.** The
first is **event time**, written into the event by whatever produced it: the dock sensor stamps the
second the bicycle left. The second is **processing time**, the clock of the machine handling the event
when it gets there. In `docks.jsonl` the field `arrived` stands in for it.

The wrong picture is a conveyor belt: events leave the docks in order and reach the server in the same
order, a moment later. On a good morning that is nearly true. Then a phone network drops for half an
hour, and a sensor keeps what it records and sends it when the link returns. Half an hour of one
station's events arrive together, after events that happened later at every other station.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Two time axes from 08:15 to 09:00, event time above and arrival below. Lines from other stations are nearly vertical. Ten lines from Parque Barigui start between 08:20 and 08:48 on the upper axis and all end at 08:51:30 on the lower one.\" data-fig=\"two-clocks\"><defs><marker id=\"two-clocks-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"14\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">when it happened: event time</text><text x=\"14\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">when it arrived: processing time</text><line x1=\"96.0\" y1=\"92\" x2=\"681.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"96.0\" y1=\"206\" x2=\"681.0\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"96.0\" y1=\"87\" x2=\"96.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"96.0\" y1=\"206\" x2=\"96.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"96.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><text x=\"96.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><line x1=\"291.0\" y1=\"87\" x2=\"291.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"291.0\" y1=\"206\" x2=\"291.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"291.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><text x=\"291.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><line x1=\"486.0\" y1=\"87\" x2=\"486.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"486.0\" y1=\"206\" x2=\"486.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"486.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><text x=\"486.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><line x1=\"681.0\" y1=\"87\" x2=\"681.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"681.0\" y1=\"206\" x2=\"681.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"681.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><text x=\"681.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"101.8\" y1=\"92\" x2=\"102.5\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"140.0\" y1=\"92\" x2=\"140.8\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"161.9\" y1=\"92\" x2=\"162.5\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"203.9\" y1=\"92\" x2=\"204.6\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"222.3\" y1=\"92\" x2=\"222.8\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"243.1\" y1=\"92\" x2=\"244.0\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"272.8\" y1=\"92\" x2=\"273.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"295.8\" y1=\"92\" x2=\"296.4\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"324.6\" y1=\"92\" x2=\"325.0\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"368.3\" y1=\"92\" x2=\"368.6\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"395.7\" y1=\"92\" x2=\"396.5\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"443.3\" y1=\"92\" x2=\"444.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"479.1\" y1=\"92\" x2=\"479.9\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"505.9\" y1=\"92\" x2=\"506.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"534.5\" y1=\"92\" x2=\"534.8\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"578.3\" y1=\"92\" x2=\"579.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"116.6\" y1=\"92\" x2=\"117.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"116.6\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"117.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"145.0\" y1=\"92\" x2=\"145.2\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"145.0\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"145.2\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"168.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"168.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"233.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"233.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"272.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"272.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"302.5\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"302.5\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"328.5\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"328.5\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"344.3\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"344.3\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"416.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"416.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"423.2\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"423.2\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"452.8\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"452.8\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"522.2\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"522.2\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"161.0\" y1=\"60\" x2=\"570.5\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><line x1=\"161.0\" y1=\"56\" x2=\"161.0\" y2=\"64\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><line x1=\"570.5\" y1=\"56\" x2=\"570.5\" y2=\"64\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"369.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parque Barigui’s link down</text><line x1=\"452\" y1=\"246\" x2=\"476\" y2=\"246\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"482\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parque Barigui (ST08)</text><line x1=\"610\" y1=\"246\" x2=\"634\" y2=\"246\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"640\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">others</text><text x=\"598.0\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">all ten sent</text><text x=\"598.0\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">at 08:51:30</text></svg>", "caption": "Each line joins one event’s two times. Most fall straight down: a few seconds between happening and arriving. Parque Barigui’s fan out to 08:51:30, when its link came back, and cross the events that happened after them."}
```

That is what the generator planted, and a short program finds it without being told where to look.
Save it as `stream/lateness.py`:

```python
# stream/lateness.py
import json
from collections import Counter
from datetime import datetime

newest = None                  # the latest event time seen so far
behind = 0                     # events older than one that arrived before them
delay = Counter()
over_a_minute = Counter()
with open('docks.jsonl') as f:
    for line in f:
        e = json.loads(line)
        happened = datetime.fromisoformat(e['event_time'])
        arrived = datetime.fromisoformat(e['arrived'])
        if newest and happened < newest:
            behind += 1
        newest = max(newest or happened, happened)
        seconds = (arrived - happened).total_seconds()
        if seconds < 5:
            delay['under 5 s'] += 1
        elif seconds < 60:
            delay['5 s to 1 min'] += 1
        else:
            delay['over 1 min'] += 1
            over_a_minute[e['station']] += 1
print(behind, 'events arrived after a later one')
for band in ('under 5 s', '5 s to 1 min', 'over 1 min'):
    print(f'{band:>12}: {delay[band]}')
print('over a minute late, by station:', dict(over_a_minute))
```

It reads the log in the order it was written, which is the order of arrival, and counts every event that
happened earlier than one it has already seen:

```
ana@lab:~/roda/stream$ python lateness.py
21 events arrived after a later one
   under 5 s: 704
5 s to 1 min: 0
  over 1 min: 16
over a minute late, by station: {'ST08': 10, 'ST04': 6}
```

Nearly every event arrived within five seconds. Even so, **out of order is not the same as late**: some
of the events behind a later one are only a few seconds behind, two sensors whose readings crossed on
the way. The sixteen over a minute are the two outages: Parque Barigui's ten, held from 08:20 and sent at
08:51:30, and Passeio Público's six, which arrived the next morning.

## Which clock a question needs

**A question about the world needs event time.** "How many rides started between 08:15 and 08:30?" is
about when bicycles left their docks, and an answer that counts by arrival puts the Parque Barigui rides
into the wrong quarter of an hour. Processing time is the right clock for questions about the system
itself: how far behind the consumer is, how many events reached the server in a minute.

Processing time is easy, because it is the clock on the wall and every event has one the moment it
arrives. Event time is correct, and it brings two costs. The processor has to wait, because an event
from 08:20 can still be on its way at 08:50. And event time is only as good as the clock that wrote it:
a sensor whose clock has drifted stamps the wrong second with complete confidence, which is lesson 4's
problem with devices and has no cure downstream.

Both clocks here are Curitiba's, the `TZ` lesson 1 set. A real system would carry the offset from UTC in
the timestamp, and lesson 1's Wednesday with 27 hours shows what happens when two systems disagree about
which clock they used.
