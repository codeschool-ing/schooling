---
title: "Measuring flow: lead time, throughput and the cumulative flow diagram"
version: 1
---

**Kanban measures how work moves rather than how busy people are.** Three numbers carry most of it, and a
tester reads them for something the rest of the team often misses: how much of a card's life is spent
waiting to be tested.

| measure | what it counts | Cine Aurora, March |
|---|---|---|
| **lead time** | from the request to done: what the person who asked experiences | 15 working days on average |
| **cycle time** | from when work starts to done: what the team controls | 9 working days on average |
| **throughput** | cards reaching done per week | 3 |

Lead time is the one Célia cares about; she does not care when Rafael started, only when she asked. Cycle time
is the one the team can change directly. The gap between them is time spent in "ready", waiting for somebody
to start.

## Where the days go

Lia did one more thing with the March cards: for each one, she counted the days it spent in each column.

| column | average days |
|---|---|
| building | 2 |
| waiting for test | 5 |
| testing | 1 |
| waiting to be released | 1 |

Of nine days of cycle time, **two were building and one was testing**. The rest was waiting. The fraction of
time a card is actually being worked on is called **flow efficiency**, and here it is 3 ÷ 9, a third. Teams
measuring it for the first time often find well under half, and are surprised.

For testing this changes the conversation. "Testing is slow" was what everybody believed in March. Testing
took one day. The five days before it were a queue, and a queue is a property of how work is organised, not
of how fast anybody works.

## The cumulative flow diagram

A **cumulative flow diagram** draws, for every day, how many cards have reached each column so far, stacked
in bands. Each band is one column. Read it like this:

- **the vertical thickness** of a band on a given day is how many cards are in that column that day;
- **the horizontal width** of a band, between the line where cards enter it and the line where they leave, is
  roughly how long a card stays there;
- **a band that keeps getting thicker** is a queue that is growing: cards come in faster than they go out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" data-fig=\"l13-cfd\" aria-label=\"A cumulative flow diagram over twenty working days. Five bands are stacked from the bottom: done, testing, waiting for test, building and ready. Done grows steadily. Testing, building and ready stay the same thickness. The waiting for test band starts thin and swells to about four and a half cards by day twenty.\"><path d=\"M60.0 220.0 L83.0 214.5 L106.0 209.1 L129.0 203.6 L152.0 198.2 L175.0 192.7 L198.0 187.3 L221.0 181.8 L244.0 176.4 L267.0 170.9 L290.0 165.5 L313.0 160.0 L336.0 154.5 L359.0 149.1 L382.0 143.6 L405.0 138.2 L428.0 132.7 L451.0 127.3 L474.0 121.8 L497.0 116.4 L520.0 110.9 L520.0 220.0 L497.0 220.0 L474.0 220.0 L451.0 220.0 L428.0 220.0 L405.0 220.0 L382.0 220.0 L359.0 220.0 L336.0 220.0 L313.0 220.0 L290.0 220.0 L267.0 220.0 L244.0 220.0 L221.0 220.0 L198.0 220.0 L175.0 220.0 L152.0 220.0 L129.0 220.0 L106.0 220.0 L83.0 220.0 L60.0 220.0 Z\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\"0.55\"></path><path d=\"M60.0 210.9 L83.0 205.5 L106.0 200.0 L129.0 194.5 L152.0 189.1 L175.0 183.6 L198.0 178.2 L221.0 172.7 L244.0 167.3 L267.0 161.8 L290.0 156.4 L313.0 150.9 L336.0 145.5 L359.0 140.0 L382.0 134.5 L405.0 129.1 L428.0 123.6 L451.0 118.2 L474.0 112.7 L497.0 107.3 L520.0 101.8 L520.0 110.9 L497.0 116.4 L474.0 121.8 L451.0 127.3 L428.0 132.7 L405.0 138.2 L382.0 143.6 L359.0 149.1 L336.0 154.5 L313.0 160.0 L290.0 165.5 L267.0 170.9 L244.0 176.4 L221.0 181.8 L198.0 187.3 L175.0 192.7 L152.0 198.2 L129.0 203.6 L106.0 209.1 L83.0 214.5 L60.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor)\" fill-opacity=\"0.55\"></path><path d=\"M60.0 206.4 L83.0 199.1 L106.0 191.8 L129.0 184.5 L152.0 177.3 L175.0 170.0 L198.0 162.7 L221.0 155.5 L244.0 148.2 L267.0 140.9 L290.0 133.6 L313.0 126.4 L336.0 119.1 L359.0 111.8 L382.0 104.5 L405.0 97.3 L428.0 90.0 L451.0 82.7 L474.0 75.5 L497.0 68.2 L520.0 60.9 L520.0 101.8 L497.0 107.3 L474.0 112.7 L451.0 118.2 L428.0 123.6 L405.0 129.1 L382.0 134.5 L359.0 140.0 L336.0 145.5 L313.0 150.9 L290.0 156.4 L267.0 161.8 L244.0 167.3 L221.0 172.7 L198.0 178.2 L175.0 183.6 L152.0 189.1 L129.0 194.5 L106.0 200.0 L83.0 205.5 L60.0 210.9 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\" fill-opacity=\"0.8\"></path><path d=\"M60.0 197.3 L83.0 190.0 L106.0 182.7 L129.0 175.5 L152.0 168.2 L175.0 160.9 L198.0 153.6 L221.0 146.4 L244.0 139.1 L267.0 131.8 L290.0 124.5 L313.0 117.3 L336.0 110.0 L359.0 102.7 L382.0 95.5 L405.0 88.2 L428.0 80.9 L451.0 73.6 L474.0 66.4 L497.0 59.1 L520.0 51.8 L520.0 60.9 L497.0 68.2 L474.0 75.5 L451.0 82.7 L428.0 90.0 L405.0 97.3 L382.0 104.5 L359.0 111.8 L336.0 119.1 L313.0 126.4 L290.0 133.6 L267.0 140.9 L244.0 148.2 L221.0 155.5 L198.0 162.7 L175.0 170.0 L152.0 177.3 L129.0 184.5 L106.0 191.8 L83.0 199.1 L60.0 206.4 Z\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"var(--wire)\" fill-opacity=\"0.55\"></path><path d=\"M60.0 174.5 L83.0 167.3 L106.0 160.0 L129.0 152.7 L152.0 145.5 L175.0 138.2 L198.0 130.9 L221.0 123.6 L244.0 116.4 L267.0 109.1 L290.0 101.8 L313.0 94.5 L336.0 87.3 L359.0 80.0 L382.0 72.7 L405.0 65.5 L428.0 58.2 L451.0 50.9 L474.0 43.6 L497.0 36.4 L520.0 29.1 L520.0 51.8 L497.0 59.1 L474.0 66.4 L451.0 73.6 L428.0 80.9 L405.0 88.2 L382.0 95.5 L359.0 102.7 L336.0 110.0 L313.0 117.3 L290.0 124.5 L267.0 131.8 L244.0 139.1 L221.0 146.4 L198.0 153.6 L175.0 160.9 L152.0 168.2 L129.0 175.5 L106.0 182.7 L83.0 190.0 L60.0 197.3 Z\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"var(--scan)\" fill-opacity=\"0.55\"></path><text x=\"52.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"52.0\" y=\"174.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"52.0\" y=\"129.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"52.0\" y=\"83.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"52.0\" y=\"38.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 220.0 L520.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 220.0 L60.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M175.0 220.0 L175.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"175.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M290.0 220.0 L290.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"290.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M405.0 220.0 L405.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"405.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M520.0 220.0 L520.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"290.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">working day</text><path d=\"M60.0 20.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"12.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cards</text><text x=\"530.0\" y=\"165.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">done</text><text x=\"530.0\" y=\"106.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">testing</text><text x=\"530.0\" y=\"81.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">waiting for test</text><text x=\"530.0\" y=\"56.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">building</text><text x=\"530.0\" y=\"39.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ready</text></svg>", "caption": "March at Cine Aurora. One band swelling while its neighbours stay thin is a queue growing, and it is visible before anybody complains."}
```

The March diagram showed one band swelling, "waiting for test", while the bands either side of it stayed thin.
That was the picture that made the team adopt limits, because it showed the queue growing before anyone had
complained about it. A tester who can read this diagram can show a team its bottleneck in one picture rather
than argue about it.

## A measure is a question, not a target

None of these numbers says whether the work was any good. A team told to cut its lead time can do it by
moving cards to "done" before they are tested, and the diagram will look wonderful. Lesson 22 is about
exactly that failure. For now: flow measures say where work waits, and the answer to *why* is still somebody's
job.
