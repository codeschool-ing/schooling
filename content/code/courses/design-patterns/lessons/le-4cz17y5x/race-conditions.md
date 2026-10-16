---
title: Race conditions: two threads, one number, a lost update
version: 1
---

**A race condition is a result that depends on how two threads happen to interleave.** It is
usually pictured as rare and exotic, a bug for operating-system authors. It is the most ordinary
bug in concurrent code, and it needs nothing more than two threads that read a shared value,
change it and write it back.

The library counts the loans it issues. Four desks record loans at the same time, a thousand each,
into one counter. Each `record` is three steps: read the count, add one, write it. The program
widens the gap between reading and writing with `time.sleep(0)`, which does no waiting and only
tells the interpreter that another thread may run now. In real code that gap is a database call, a
log line or simply bad luck.

```schooling-example
{"language": "python", "file": "race.py", "parts": [
 {"code": "# race.py\nimport threading\nimport time\n\n\nclass LoanCounter:\n    def __init__(self):\n        self.issued = 0", "note": "The counter is an ordinary object with an integer in it, like a hundred classes in lessons 2 to 15."},
 {"code": "\n    def record(self) -> None:\n        seen = self.issued      # read\n        time.sleep(0)           # let another thread run here\n        self.issued = seen + 1  # write", "note": "Read, pause, write. Between the first line and the third, any other desk can read the same old value."},
 {"code": "\ndef desk(counter: LoanCounter, loans: int) -> None:\n    for _ in range(loans):\n        counter.record()", "note": "One desk records its loans one after another. Inside a single thread nothing is wrong with this code."},
 {"code": "\nif __name__ == \"__main__\":\n    counter = LoanCounter()\n    desks = [threading.Thread(target=desk, args=(counter, 1000)) for _ in range(4)]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"loans recorded: 4000\")\n    print(\"counter says:  \", counter.issued)", "note": "Four threads, a thousand loans each. `join` waits for each thread to finish before the count is printed."}
]}
```

Run it twice:

```
ana@laptop:~/patterns/concurrency$ python3 race.py
loans recorded: 4000
counter says:   1006
ana@laptop:~/patterns/concurrency$ python3 race.py
loans recorded: 4000
counter says:   1004
```

Four thousand loans went in and about a thousand came out. The exact figure can move by a few from
one run to the next, so yours may differ from these. No exception was raised and no line of
`record` is wrong on its own. **Three quarters of the updates
were lost, and the program finished as if nothing had happened.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" data-fig=\"l18-lost-update\" aria-label=\"A timeline of a lost update, read from top to bottom. Desk A is on the left, the shared counter in the middle and desk B on the right. First desk A reads the counter, 7. Then desk B reads it, also 7. Desk A writes 7 plus 1, so the counter becomes 8. Desk B writes 7 plus 1 as well, and the counter is 8 again. Two loans were recorded and the counter moved by one.\"><defs><marker id=\"l18-lost-update-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l18-lost-update-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"55.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desk A</text><rect x=\"255.0\" y=\"16.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">issued</text><rect x=\"435.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desk B</text><path d=\"M130.0 44.0 L130.0 65.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 91.0 L130.0 153.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 179.0 L130.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 44.0 L320.0 65.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 91.0 L320.0 109.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 135.0 L320.0 153.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 179.0 L320.0 197.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 223.0 L320.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M510.0 44.0 L510.0 109.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M510.0 135.0 L510.0 197.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M510.0 223.0 L510.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M28.0 60.0 L28.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-paper-dim)\"></path><text x=\"40.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">time</text><rect x=\"55.0\" y=\"65.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read: seen = 7</text><rect x=\"297.0\" y=\"65.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><path d=\"M297.0 78.0 L205.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-paper-dim)\"></path><rect x=\"435.0\" y=\"109.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read: seen = 7</text><rect x=\"297.0\" y=\"109.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><path d=\"M343.0 122.0 L435.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-paper-dim)\"></path><rect x=\"55.0\" y=\"153.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write: 7 + 1</text><rect x=\"297.0\" y=\"153.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><path d=\"M205.0 166.0 L297.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-phosphor)\"></path><rect x=\"435.0\" y=\"197.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write: 7 + 1</text><rect x=\"297.0\" y=\"197.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><path d=\"M435.0 210.0 L343.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-phosphor)\"></path><text x=\"320.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">two loans recorded, the counter moved by one</text><text x=\"320.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">B wrote over A: the update A made is lost</text></svg>", "caption": "A lost update. Both desks read before either writes, so the second write erases the first."}
```

The figure is the whole mechanism. Desk A reads 7. Before it writes, desk B also reads 7. A writes
8, then B writes 8 over it. Two loans were issued and the counter moved by one. With four desks
and the gap forced open, almost every write lands on top of another one, which is why the count
ends near a thousand: roughly one desk's worth of updates survives.

## Why the obvious line seems to work

Take the pause out and write the update the way anybody would:

```python
# plus_equals.py
import threading


class LoanCounter:
    issued = 0


counter = LoanCounter()


def desk() -> None:
    for _ in range(1_000_000):
        counter.issued += 1


desks = [threading.Thread(target=desk) for _ in range(4)]
for d in desks:
    d.start()
for d in desks:
    d.join()
print("expected 4000000, got", counter.issued)
```

```
ana@laptop:~/patterns/concurrency$ python3 plus_equals.py
expected 4000000, got 4000000
```

Four million increments and none lost. That is the trap. `counter.issued += 1` is still a read, an
addition and a write, and on Python 3.12 the interpreter happens never to switch threads in the
middle of those few bytecodes. **Nothing in the language promises that.** Python 3.9 and earlier
did switch there, the free-threaded build runs the threads truly at once, and the moment the line
grows a function call between the read and the write, the window is back. A test that passes a thousand
times proves only that the window was not hit in those thousand runs.

## The shape to look for

A race needs three things together: **state shared** between threads, **at least one writer**, and
an operation that is not atomic, meaning it can be interrupted halfway. The common shapes are
read-modify-write, as here, and check-then-act: *if there is a copy on the shelf, lend it*, where
two desks can both see the last copy. The singleton in section 05 and the observer in section 06
are both check-then-act in disguise.

In Java the same counter loses updates with plain threads, and the language offers
`AtomicInteger` or `synchronized`. Go ships a detector for exactly this, `go test -race`, which
reports the two goroutines and the lines they raced on. JavaScript in a browser or Node has one
thread per event loop, so this program cannot be written there without workers. Across an
`await`, though, the same read-pause-write bug appears in a single thread, because an `await` is a
place where something else runs.

Take away any one of the three and the race is gone. The next three sections take away the third
with a lock; section 07 takes away the first and the second.
