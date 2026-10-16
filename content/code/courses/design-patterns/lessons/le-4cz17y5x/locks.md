---
title: Locks, and the deadlock they make possible
version: 1
---

**A lock makes a group of steps atomic by letting only one thread inside at a time.** Every other
thread that reaches the door waits until the one inside leaves. It is the oldest fix for a race and
the right one more often than its reputation suggests. It also introduces a failure that a program
without locks cannot have: two threads each waiting for the other, forever.

## The counter, fixed

The only change from `race.py` is a lock created with the counter and a `with` around the three
steps:

```python
# locks.py
import threading
import time


class LoanCounter:
    def __init__(self):
        self.issued = 0
        self._lock = threading.Lock()

    def record(self) -> None:
        with self._lock:
            seen = self.issued
            time.sleep(0)
            self.issued = seen + 1


def desk(counter: LoanCounter, loans: int) -> None:
    for _ in range(loans):
        counter.record()


if __name__ == "__main__":
    counter = LoanCounter()
    desks = [threading.Thread(target=desk, args=(counter, 1000)) for _ in range(4)]
    for d in desks:
        d.start()
    for d in desks:
        d.join()
    print("loans recorded: 4000")
    print("counter says:  ", counter.issued)
```

```
ana@laptop:~/patterns/concurrency$ python3 locks.py
loans recorded: 4000
counter says:   4000
```

The `sleep(0)` is still there, and another thread still gets to run during it. That thread reaches
`with self._lock`, finds it taken and waits, so nobody reads the count while it is between a read
and a write. The lock lives inside `LoanCounter`, next to the state it guards, which is lesson 1's
encapsulation doing a new job: **a caller cannot forget to take a lock it never sees.**

## Two locks, two orders

The trouble starts when one operation needs two locks. Bia wants to hand her reservation of *Vidas
Secas* to Caio, and at the same moment, at another desk, Caio hands one of his to Bia. Each swap
locks the giver, checks the giver's reservations, then locks the taker.

```schooling-example
{"language": "python", "file": "deadlock.py", "parts": [
 {"code": "# deadlock.py\nimport threading\nimport time\n\n\nclass Member:\n    def __init__(self, number: int, name: str):\n        self.number = number\n        self.name = name\n        self.lock = threading.Lock()", "note": "Each member carries a lock of its own, so a swap involving Bia blocks every other change to Bia while it runs."},
 {"code": "\ndef swap_reservation(giver: Member, taker: Member, log: list[str]) -> None:\n    with giver.lock:\n        time.sleep(0.1)  # checking the giver's reservations\n        if taker.lock.acquire(timeout=1):\n            log.append(f\"{giver.name} -> {taker.name}: swapped\")\n            taker.lock.release()\n        else:\n            log.append(f\"{giver.name} -> {taker.name}: gave up waiting for {taker.name}\")", "note": "The giver first, then the taker. `acquire(timeout=1)` is there so the program reports a stuck swap instead of hanging your terminal."},
 {"code": "\nif __name__ == \"__main__\":\n    bia, caio = Member(17, \"Bia\"), Member(42, \"Caio\")\n    log: list[str] = []\n    desks = [threading.Thread(target=swap_reservation, args=(bia, caio, log)),\n             threading.Thread(target=swap_reservation, args=(caio, bia, log))]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"\\n\".join(sorted(log)))", "note": "Two desks, two swaps in opposite directions, started together. The log is sorted so the lines come out in the same order whichever thread wrote first."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 deadlock.py
Bia -> Caio: gave up waiting for Caio
Caio -> Bia: swapped
```

The first desk took Bia's lock and the second took Caio's. Each then asked for the other's, and
neither could have it, because neither would let go of the one it held. That is a **deadlock**,
and the figure draws it as what it is: a cycle of waiting.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-deadlock\" aria-label=\"Two wait-for graphs side by side. On the left, each desk locks the giver first: desk 1 holds Bia's lock and waits for Caio's, while desk 2 holds Caio's lock and waits for Bia's. The arrows form a closed cycle, so neither desk can move. On the right, both desks take the lower-numbered lock first: desk 1 holds Bia's lock, number 17, and goes on to take Caio's, number 42, while desk 2 waits for lock 17. There is no cycle, so desk 1 finishes and then desk 2 runs.\"><defs><marker id=\"l18-deadlock-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-deadlock-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">each desk locks the giver first</text><rect x=\"105.0\" y=\"51.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia's lock, 17</text><rect x=\"105.0\" y=\"221.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Caio's lock, 42</text><rect x=\"10.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"55.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desk 1</text><rect x=\"240.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desk 2</text><path d=\"M105.0 74.0 L55.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M55.0 166.0 L105.0 228.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-deadlock-dp-ah-amber)\"></path><path d=\"M235.0 228.0 L285.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M285.0 136.0 L235.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-deadlock-dp-ah-amber)\"></path><text x=\"170.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">a cycle: nobody moves</text><path d=\"M360.0 10.0 L360.0 262.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"530.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">both lock the lower number first</text><rect x=\"465.0\" y=\"51.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia's lock, 17</text><rect x=\"465.0\" y=\"221.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Caio's lock, 42</text><rect x=\"370.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desk 1</text><rect x=\"600.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desk 2</text><path d=\"M465.0 74.0 L415.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M465.0 228.0 L415.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M645.0 136.0 L595.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-deadlock-dp-ah-amber)\"></path><text x=\"530.0\" y=\"144.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">no cycle: desk 2 waits,</text><text x=\"530.0\" y=\"157.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">desk 1 finishes</text><path d=\"M190.0 284.0 L230.0 284.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"238.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">holds</text><path d=\"M420.0 284.0 L460.0 284.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"468.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waits for</text></svg>", "caption": "A deadlock is a cycle of waiting. One agreed order for taking locks makes the cycle impossible."}
```

The timeout is the only reason the program ended. One desk gave up after a second and released
the lock it held, which let the other finish. Without `timeout=1` both threads would wait forever,
using no processor and printing nothing, and the program would look exactly like one that is
thinking. Which desk gives up first depends on which thread started a fraction earlier, so on your
machine the names in the output may be the other way round.

## The fix is an order

A deadlock needs a cycle, and a cycle needs two threads taking the same locks in different orders.
**Agree on one order for every lock and the cycle cannot form.** Members have numbers, so take the
lower number first, whoever is giving:

```python
# deadlock.py
import threading
import time


class Member:
    def __init__(self, number: int, name: str):
        self.number = number
        self.name = name
        self.lock = threading.Lock()


def swap_reservation(giver: Member, taker: Member, log: list[str]) -> None:
    first, second = sorted((giver, taker), key=lambda m: m.number)
    with first.lock:
        time.sleep(0.1)  # checking the giver's reservations
        if second.lock.acquire(timeout=1):
            log.append(f"{giver.name} -> {taker.name}: swapped")
            second.lock.release()
        else:
            log.append(f"{giver.name} -> {taker.name}: gave up waiting for {second.name}")


if __name__ == "__main__":
    bia, caio = Member(17, "Bia"), Member(42, "Caio")
    log: list[str] = []
    desks = [threading.Thread(target=swap_reservation, args=(bia, caio, log)),
             threading.Thread(target=swap_reservation, args=(caio, bia, log))]
    for d in desks:
        d.start()
    for d in desks:
        d.join()
    print("\n".join(sorted(log)))
```

```
ana@laptop:~/patterns/concurrency$ python3 deadlock.py
Bia -> Caio: swapped
Caio -> Bia: swapped
```

Both swaps now go through. The second desk waits at Bia's lock, number 17, until the first desk
has finished with both, and then takes its turn.

## Four rules for living with locks

- Keep the work inside a lock short, and never wait on a network or a person while holding one.
- Take several locks in one agreed order, and write the order down beside the locks.
- Never call code you do not control while holding a lock; section 06 shows what that code can do.
- Prefer a timeout to an unbounded wait wherever a stuck thread would be invisible.

Every language has the same tool under a different name. Java has `synchronized` blocks and
`ReentrantLock`, whose `tryLock(1, SECONDS)` is the timeout above. Go has `sync.Mutex`, with no
timeout, and its runtime stops the program with *all goroutines are asleep - deadlock!* when every
goroutine is blocked. Python's `threading.RLock` is a lock the same thread may take twice, which
avoids deadlocking against yourself and hides the question of why you needed to.
