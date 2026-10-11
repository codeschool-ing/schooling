---
title: How often, and what freshness costs
version: 1
---

**How fresh data has to be is a question for the person who reads it, and the honest answer is
nearly always less fresh than the first answer.** "Real time" is what people ask for when nobody has
asked them what they would do differently with data that is one minute old instead of one hour old.

**Freshness** is the age of the newest data a reader can see. It is a different thing from
**granularity**, how finely the data records what happened, and the two are confused all the time.
Caio asked for readings *every minute*. Asked what the model does with them, he says it retrains on
Sunday nights. He needs minute-by-minute readings, delivered once a week; nothing in his question
needs them to arrive within the minute.

## Three readers, three answers

| who reads it | what for | how fresh it has to be |
|---|---|---|
| Marta | the morning report on yesterday | complete for yesterday by 07:00 |
| the app | the map of free bicycles a customer opens | a minute or two, or the customer walks to an empty station |
| Caio | retraining the demand model | the last full week, by Sunday night |

Only one of the three needs data within the minute, and it is the app, which reads the sensors
directly and never asks the data team. The other two are served by a copy made once a day.

## Pull and push

Data reaches you in one of two ways. **Pull**: your program asks the source, on a schedule, whether
anything is new — it *polls* it. **Push**: the source sends each new record to you as it happens,
calling an address you gave it or writing to a queue you read.

Polling is the one you can always build, because it only needs the source to answer questions. Its
price is that it asks whether or not anything happened. This program takes one day of rides ending,
with most of them between six in the morning and eleven at night, and polls for them four ways: every
minute, every quarter of an hour, every hour and once a day. For each, it counts the calls, the calls
that found nothing new, and how long a ride waited between ending and being collected. Save it as
`collect/poll.py`:

```python
# collect/poll.py
import random

random.seed(3)
# one day of rides ending, in seconds after midnight: most between 06:00 and 23:00
ends = sorted(random.randint(6 * 3600, 23 * 3600) for _ in range(1000))
ends += sorted(random.randint(0, 6 * 3600) for _ in range(20))   # a few at night

print("every   calls  empty  mean wait  worst wait")
for minutes in (1, 15, 60, 1440):
    step = minutes * 60
    polls = 24 * 60 // minutes
    waits, busy = [], set()
    for t in ends:
        poll = (t // step + 1) * step          # the first poll after the ride ended
        waits.append(poll - t)
        busy.add(poll)
    empty = polls - len(busy)
    print(f"{minutes:5}m  {polls:5}  {empty:5}  {sum(waits) / len(waits) / 60:6.1f} min"
          f"  {max(waits) / 60:7.1f} min")
```

```
ana@lab:~/roda/collect$ python poll.py
every   calls  empty  mean wait  worst wait
    1m   1440    779     0.5 min      1.0 min
   15m     96     15     7.7 min     15.0 min
   60m     24      2    29.6 min     60.0 min
 1440m      1      0   573.7 min   1419.8 min
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A time line from 08:00 to 09:00 with seven rides ending. Polled every fifteen minutes, there are four calls: three find rides and one comes back empty, and the ride that ended at 08:03 waits twelve minutes. Polled every minute, there are sixty calls: seven find a ride and fifty-three come back empty.\" data-fig=\"polling\"><defs><marker id=\"polling-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><text x=\"250\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><text x=\"400\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><text x=\"550\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><text x=\"700\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><text x=\"88\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">every 15 min</text><line x1=\"100\" y1=\"100\" x2=\"700\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"250\" y1=\"86\" x2=\"250\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"250\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 new</text><line x1=\"400\" y1=\"86\" x2=\"400\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"400\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">empty</text><line x1=\"550\" y1=\"86\" x2=\"550\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"550\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 new</text><line x1=\"700\" y1=\"86\" x2=\"700\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"700\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 new</text><circle cx=\"130\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"170\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"210\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"440\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"510\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"540\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"620\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><line x1=\"130\" y1=\"70\" x2=\"250\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"130\" y1=\"65\" x2=\"130\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"250\" y1=\"65\" x2=\"250\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"190\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waits 12 min</text><text x=\"400\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 calls: 1 comes back empty, and a ride waits up to 15 minutes</text><text x=\"88\" y=\"195\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">every minute</text><line x1=\"100\" y1=\"195\" x2=\"700\" y2=\"195\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"110\" y1=\"187\" x2=\"110\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"120\" y1=\"187\" x2=\"120\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"130\" y1=\"187\" x2=\"130\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"140\" y1=\"187\" x2=\"140\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"150\" y1=\"187\" x2=\"150\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"160\" y1=\"187\" x2=\"160\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"170\" y1=\"187\" x2=\"170\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"180\" y1=\"187\" x2=\"180\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"190\" y1=\"187\" x2=\"190\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"200\" y1=\"187\" x2=\"200\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"210\" y1=\"187\" x2=\"210\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"220\" y1=\"187\" x2=\"220\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"230\" y1=\"187\" x2=\"230\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"240\" y1=\"187\" x2=\"240\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"250\" y1=\"187\" x2=\"250\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"260\" y1=\"187\" x2=\"260\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"270\" y1=\"187\" x2=\"270\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"280\" y1=\"187\" x2=\"280\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"290\" y1=\"187\" x2=\"290\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"300\" y1=\"187\" x2=\"300\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"310\" y1=\"187\" x2=\"310\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"320\" y1=\"187\" x2=\"320\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"330\" y1=\"187\" x2=\"330\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"340\" y1=\"187\" x2=\"340\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"350\" y1=\"187\" x2=\"350\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"360\" y1=\"187\" x2=\"360\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"370\" y1=\"187\" x2=\"370\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"187\" x2=\"380\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"390\" y1=\"187\" x2=\"390\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"400\" y1=\"187\" x2=\"400\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"410\" y1=\"187\" x2=\"410\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"420\" y1=\"187\" x2=\"420\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"430\" y1=\"187\" x2=\"430\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"440\" y1=\"187\" x2=\"440\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"450\" y1=\"187\" x2=\"450\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"460\" y1=\"187\" x2=\"460\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"470\" y1=\"187\" x2=\"470\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"480\" y1=\"187\" x2=\"480\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"490\" y1=\"187\" x2=\"490\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"500\" y1=\"187\" x2=\"500\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"510\" y1=\"187\" x2=\"510\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"520\" y1=\"187\" x2=\"520\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"530\" y1=\"187\" x2=\"530\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"540\" y1=\"187\" x2=\"540\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"550\" y1=\"187\" x2=\"550\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"560\" y1=\"187\" x2=\"560\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"570\" y1=\"187\" x2=\"570\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"580\" y1=\"187\" x2=\"580\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"590\" y1=\"187\" x2=\"590\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"600\" y1=\"187\" x2=\"600\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"610\" y1=\"187\" x2=\"610\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"620\" y1=\"187\" x2=\"620\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"630\" y1=\"187\" x2=\"630\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"640\" y1=\"187\" x2=\"640\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"650\" y1=\"187\" x2=\"650\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"660\" y1=\"187\" x2=\"660\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"670\" y1=\"187\" x2=\"670\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"680\" y1=\"187\" x2=\"680\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"690\" y1=\"187\" x2=\"690\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"700\" y1=\"187\" x2=\"700\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"130\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"170\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"210\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"440\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"510\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"540\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"620\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"400\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">60 calls: 7 find a ride, 53 come back empty</text></svg>", "caption": "The same seven rides, polled every fifteen minutes and every minute. Fresher data costs calls, and most of the extra calls find nothing."}
```

**Every step towards fresher data is paid for in calls, and most of the extra calls find nothing.**
Polling every minute makes 1,440 calls a day, and 779 of them come back empty, nearly every minute of
the night among them. Once a
day makes one call, and a ride waits 573.7 minutes on average to be collected, more than nine hours.
Fifteen minutes sits between them: 96 calls, a mean wait of 7.7 minutes, and nobody in the table above
needs better.

Push removes both the empty calls and the wait, and it has a price of its own. The source has to
offer it, and many do not. Your side has to be listening whenever the source sends: a receiver that
was down for an hour has missed an hour, unless the source keeps what it sent and tries again. What a
source promises about trying again is lesson 8's subject.

## What freshness costs besides calls

A copy made every minute is 1,440 runs a day, and section 02 counted what that means: 1,440 chances
to fail, each needing somebody to notice. Each run must be safe to repeat, because a retried run is the
normal case at that rate. And it cannot copy everything every time: it has to copy only what changed,
which is the next section. **Fresher is not better; it is more expensive**, and the only reason to pay
is a reader whose decision changes with it. Whether to process data in batches or as it arrives is the
same question asked of the processing rather than the copy, and lesson 8 asks it.
