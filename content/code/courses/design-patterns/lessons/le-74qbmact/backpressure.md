---
title: "Backpressure: when the producer is faster than the consumer"
version: 1
---

**Backpressure is the consumer's way of telling a producer to slow down.** When the producer
cannot slow down, it is the rule for what happens to the values that do not fit. Pull never needed it,
because a consumer that pulls takes only what it can handle. Push does, because the producer
decides when a value moves, and nothing in `on_next` says *not now*.

The usual first answer is a queue between the two. A queue absorbs a burst: the scanner reads ten
books in a minute, the catalogue update handles them over the next five, and nobody notices. **A
queue does not absorb a rate.** If values arrive faster than they leave, on average, for long
enough, the queue grows for as long as that lasts, and the time each value waits grows with it.

Here is the desk on a busy morning, simulated second by second so the numbers are the same on
every run. Scans arrive at five a second and the catalogue keeps up with two:

```python
# flood.py
from collections import deque

PRODUCED_PER_SECOND = 5   # barcode scans arriving at the returns desk
HANDLED_PER_SECOND = 2    # what the catalogue update can keep up with

backlog: deque[int] = deque()
scanned = handled = 0
for second in range(1, 11):
    for _ in range(PRODUCED_PER_SECOND):
        scanned += 1
        backlog.append(scanned)
    for _ in range(HANDLED_PER_SECOND):
        backlog.popleft()
        handled += 1
    if second % 2 == 0:
        print(f"second {second:2}: scanned {scanned:2}, handled {handled:2}, waiting {len(backlog):2}")
print(f"the oldest waiting scan is #{backlog[0]}, from second {(backlog[0] - 1) // PRODUCED_PER_SECOND + 1}")
```

```
ana@laptop:~/patterns/reactive$ python3 flood.py
second  2: scanned 10, handled  4, waiting  6
second  4: scanned 20, handled  8, waiting 12
second  6: scanned 30, handled 12, waiting 18
second  8: scanned 40, handled 16, waiting 24
second 10: scanned 50, handled 20, waiting 30
the oldest waiting scan is #21, from second 5
```

The backlog grows by three every second, which is five in minus two out, and after ten seconds
thirty scans are waiting. The oldest of them is scan 21, read in second 5, so a member who returned
a book at that moment would still see it on loan five seconds later, and the delay grows every
second the rate holds. Left running for an hour, the backlog is over ten thousand scans and each
one waits about an hour and a half. An unbounded queue turns a speed problem into a memory problem
and a staleness problem, and it does so quietly: nothing fails until the process runs out of
memory.

`architecture` lesson 12 met the same problem between services, and `scale` lesson 9 met it at the
front door of a system. This section is the version inside one program, where the producer and the
consumer are two pieces of your own code.

## A bound, and a producer that waits

The simplest backpressure is a queue with a limit and a producer that waits when it is full.
Python's `queue.Queue` does both: `put` blocks while the queue holds `maxsize` items. Here two real
threads, a fast scanner and a slow catalogue, share a queue of three:

```schooling-example
{"language": "python", "file": "blocking.py", "parts": [
 {"code": "# blocking.py\nimport queue\nimport threading\nimport time\n\ndesk: queue.Queue[int | None] = queue.Queue(maxsize=3)\nlargest = 0", "note": "The queue holds at most three scans. `largest` records the biggest backlog the scanner ever saw."},
 {"code": "\n\ndef scanner() -> None:\n    global largest\n    for scan in range(1, 13):\n        desk.put(scan)            # waits here while the queue is full\n        largest = max(largest, desk.qsize())\n    desk.put(None)                # nothing more is coming", "note": "The scanner reads twelve scans as fast as it can. When the queue is full, `put` does not return until the catalogue has taken one, and that wait is the backpressure. `None` at the end is the signal that nothing more is coming, the same job `on_complete` does in an observable."},
 {"code": "\n\ndef catalogue(seen: list[int]) -> None:\n    while (scan := desk.get()) is not None:\n        time.sleep(0.02)          # the slow part\n        seen.append(scan)", "note": "The catalogue takes a scan, spends 20 milliseconds on it, and records it. The walrus `:=` reads the next scan and tests it in one line."},
 {"code": "\n\nseen: list[int] = []\nthreads = [threading.Thread(target=scanner), threading.Thread(target=catalogue, args=(seen,))]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(\"handled:\", seen)\nprint(\"largest backlog:\", largest)\nprint(\"lost:\", 12 - len(seen))", "note": "Two threads, started together and waited for. Lesson 18 is about what threads cost; here they only make the two sides run at their own speeds."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 blocking.py
handled: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
largest backlog: 3
lost: 0
```

All twelve scans arrived, in order, none was lost, and the backlog never passed three. The program
prints no times because they vary from run to run; these three lines do not, because the limit and
the order are guaranteed by the queue, whatever the scheduler does. What the bound cost is the
scanner's time: it spent most of the run waiting inside `put`, at the catalogue's pace instead of
its own.

## Demand: pull for permission, push for data

Blocking a thread is one way to tell the producer to wait. The Reactive Streams specification,
which Java adopted in version 9 as `java.util.concurrent.Flow`, uses another. A subscriber does not
just receive values; it calls `request(n)` on its subscription to say how many more it is ready
for, and the publisher must not send more than the total requested. A subscriber that handles one
scan at a time asks for one, handles it, and asks for the next.

That is the two halves of section 02 joined together. The data is pushed, so the subscriber never
polls, and the permission is pulled, so the producer never overwhelms it. Nobody's thread has to
block: a publisher with no outstanding demand simply holds its next value until a request comes.

**Demand only works when the producer can actually hold back.** A file reader can stop reading and a
database cursor can stop fetching. The barcode scanner at the desk cannot: the book has passed
under it and the member has walked away. When the producer cannot wait, something else has to give,
and the next section counts the four usual choices.
