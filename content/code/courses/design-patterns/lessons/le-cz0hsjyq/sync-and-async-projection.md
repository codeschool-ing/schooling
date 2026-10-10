---
title: Synchronous and asynchronous projection
version: 1
---

**A projector can run inside the command, so that the read model is current before the command
returns, or after it, so that the command is fast and the read model catches up later.** The first
keeps every screen exact and ties the write's speed and availability to every read model's. The
second frees the write and makes the screen stale for a while. Neither is the CQRS one; choosing is
the decision, and it is made per read model, not per system.

The mistake to avoid is thinking that asynchronous projection makes the system wrong. The write
model is never stale: it refuses a loan of a copy that is out the moment the copy goes out. What can
be stale is a screen, and the question is whether the person reading it can tell, and whether it
matters.

```schooling-example
{"language": "python", "file": "lag.py", "parts": [
 {"code": "# lag.py\nfrom collections import deque\nfrom datetime import date\nfrom commands import Lending, LendCopy, handle\nfrom read_model import CATALOGUE, Availability", "note": "The write model and the availability read model from the two previous programs, unchanged."},
 {"code": "\n\nclass Outbox:\n    def __init__(self, projection: Availability):\n        self.projection = projection\n        self.pending: deque = deque()\n        self.published = 0\n        self.applied = 0\n\n    def publish(self, event) -> None:\n        self.pending.append(event)\n        self.published += 1\n\n    def pump(self) -> None:\n        while self.pending:\n            self.projection.apply(self.pending.popleft())\n            self.applied += 1", "note": "Between them, a queue. `publish` is what the write model calls: it only appends. `pump` is the worker: it applies whatever is waiting. The two counters say how far behind the read model is."},
 {"code": "\n\ndef screen(shelf: Availability, outbox: Outbox, label: str) -> None:\n    rows = {title: n for title, _, n in shelf.available_now()}\n    lag = outbox.published - outbox.applied\n    print(f\"{label:<28} Dom Casmurro on shelf: {rows.get('Dom Casmurro', 0)}\"\n          f\"   ({lag} event{'s' if lag != 1 else ''} behind)\")", "note": "The desk's screen, reading only the read model, and printing how many events it has not seen yet."},
 {"code": "\n\nif __name__ == \"__main__\":\n    day = date(2026, 3, 2)\n\n    print(\"-- synchronous: the projection runs inside the command\")\n    lending, shelf = Lending({\"C1\": \"T1\", \"C2\": \"T1\"}), Availability(CATALOGUE)\n    outbox = Outbox(shelf)\n    lending.listeners += [outbox.publish, lambda e: outbox.pump()]\n    handle(lending, LendCopy(\"C1\", \"bia\", day))\n    screen(shelf, outbox, \"right after lending C1\")", "note": "First the synchronous arrangement: the outbox is pumped inside the same call that published, so the read model is current before `handle` returns."},
 {"code": "\n    print(\"-- asynchronous: the projection runs when the worker gets to it\")\n    lending, shelf = Lending({\"C1\": \"T1\", \"C2\": \"T1\"}), Availability(CATALOGUE)\n    outbox = Outbox(shelf)\n    lending.listeners.append(outbox.publish)\n    handle(lending, LendCopy(\"C1\", \"bia\", day))\n    screen(shelf, outbox, \"right after lending C1\")\n    handle(lending, LendCopy(\"C2\", \"caio\", day))\n    screen(shelf, outbox, \"right after lending C2\")\n    outbox.pump()\n    screen(shelf, outbox, \"after the worker ran\")", "note": "Then the same commands with nobody pumping until the end. In a real system the pump runs in another thread or process and nobody chooses the moment; here it is called by hand so that every run prints the same lines."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 lag.py
-- synchronous: the projection runs inside the command
right after lending C1       Dom Casmurro on shelf: 1   (0 events behind)
-- asynchronous: the projection runs when the worker gets to it
right after lending C1       Dom Casmurro on shelf: 2   (1 event behind)
right after lending C2       Dom Casmurro on shelf: 2   (2 events behind)
after the worker ran         Dom Casmurro on shelf: 0   (0 events behind)
```

Synchronously, the screen shows one copy left the moment C1 is lent. Asynchronously, it still says
2 after C1 goes out, and still 2 after C2 goes out, two events behind; only when the worker runs does
it jump to 0. During that window the desk's screen offers a book that is not on the shelf.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l08-lag\" aria-label=\"A timeline of the asynchronous run of lag.py, left to right. Upper lane, the write model: C1 is lent to Bia, then C2 to Caio, and after each the write model knows the new number of copies on the shelf, 1 and then 0. Lower lane, the read model: it still says 2 after both loans, because the two events are waiting in the outbox. When the worker runs, it applies both and the read model says 0. The stretch between the first loan and the worker run is the window in which a query sees the old value.\"><defs><marker id=\"l08-lag-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-lag-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">write model</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">read model</text><path d=\"M230.0 170.0 L570.0 170.0\" stroke=\"var(--scan)\" stroke-width=\"40\" fill=\"none\"></path><path d=\"M140.0 70.0 L700.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-lag-dp-ah-paper-dim)\"></path><path d=\"M140.0 170.0 L700.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-lag-dp-ah-paper-dim)\"></path><text x=\"690.0\" y=\"248.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><circle cx=\"230.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"230.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend C1</text><text x=\"270.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on shelf 1</text><path d=\"M230.0 76.0 L230.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-lag-dp-ah-amber)\"></path><text x=\"230.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">event queued</text><circle cx=\"380.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"380.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend C2</text><text x=\"420.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on shelf 0</text><path d=\"M380.0 76.0 L380.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-lag-dp-ah-amber)\"></path><text x=\"380.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">event queued</text><text x=\"160.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on shelf 2</text><text x=\"400.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">stale: on shelf 2, events waiting</text><circle cx=\"570.0\" cy=\"170.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"570.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">worker applies both</text><text x=\"630.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on shelf 0</text></svg>", "caption": "The write model is right at once; the read model is right after the worker has run. The shaded stretch is the lag a reader can see."}
```

## What the window costs

**The write side still refuses correctly.** If the desk, misled by the screen, sends `LendCopy` for
C2 a second time, `Lending` refuses it: the rule reads the write model, which knew at once. Stale
reads cause wasted trips and confusing screens, not broken rules, provided that **no rule ever reads
a read model**. A handler that checked availability by querying `Availability` would make the lag a
correctness bug.

The worst case is the person who just acted. Bia borrows a book, the page reloads from the read
model, and her loan is not on it. She tries again and the write side refuses, because she already
has it. That is the *read your own writes* problem `architecture` lesson 9 describes for replicas,
arriving here through a projector. The usual remedies, in order of cost:

| remedy | how it works here |
|---|---|
| show the command's result, not a fresh query | the desk prints "C1 lent, due 16/03" from what it sent, and refreshes the list later |
| wait for the position | the command returns how many events were published; the screen waits until `applied` reaches it |
| project synchronously for this screen only | the member's own loans are pumped in the command; the shelf counts stay asynchronous |

The second remedy is why `Outbox` counts. A version number or a log position travelling from the
write to the screen is how real systems do it, under names such as a *causality token*.

## Choosing

Project synchronously when the write and the read share a database, the read models are few and
cheap to update, and somebody will look at the screen immediately after acting: the loan desk is
that case. Project asynchronously when a read model is slow to update, lives in another store, or
would make every write fail when it is down; a search index rebuilt from loans is that case. Most
systems mix the two, and the table above is the vocabulary for saying which screens tolerate how
much lag.

The outbox here is a list in memory, so a crash between the write and the pump loses the events.
Real outboxes are written in the same transaction as the write, so that an event exists exactly when
its change does, and a separate process sends them on; lesson 10's transactions are what make that
possible.
