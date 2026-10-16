---
title: Eventual consistency, seen from a projection
version: 1
---

**In an event-sourced system the events are written first and every projection learns of them
afterwards, so a projection is always somewhere behind the store, and "eventually consistent" means
that it reaches the store's head once writing pauses.** How far behind, and for how long, depends on
the worker, the load and the store it writes to. The store itself is never behind: a command folds
the stream, which is the truth.

`architecture` lesson 9 covers eventual consistency as a property of replicated systems, and lesson
8 of this course showed the stale window with a pump called by hand. This section adds what event
sourcing changes: a real worker on its own thread, a position that says exactly how far behind a
projection is, and a restart that loses nothing.

```schooling-example
{"language": "python", "file": "lag.py", "parts": [
 {"code": "# lag.py\nimport queue\nimport threading\nimport time\nfrom projections import FinesOwed\nfrom store import EventStore", "note": "The fines projection of two sections ago and the store, with a real thread this time and a queue from the standard library between them."},
 {"code": "\nstore = EventStore(\":memory:\")\nfines = FinesOwed()\ninbox: queue.Queue = queue.Queue()", "note": "One store, one projection, one inbox. Only the main thread touches the store; the worker touches only the projection, which is why no lock is needed."},
 {"code": "\n\ndef worker() -> None:\n    while True:\n        position, event = inbox.get()\n        time.sleep(0.05)  # a projection that is slower than the write\n        fines.apply(position, event)\n        inbox.task_done()", "note": "The worker waits for events, takes a twentieth of a second over each, as a projection writing to a slower store would, applies it and says it is done."},
 {"code": "\n\npublished = 0\n\n\ndef record(stream: str, events: list[dict]) -> None:\n    global published\n    store.append(stream, store.version(stream), events)\n    for published, event in store.read_all(after=published):\n        inbox.put((published, event))", "note": "Recording a change: append to the store, then hand every event the store has not yet handed over to the inbox. `published` is the position of the last one handed over."},
 {"code": "\n\nif __name__ == \"__main__\":\n    threading.Thread(target=worker, daemon=True).start()\n    record(\"member-dani\", [{\"type\": \"CopyLent\", \"copy\": \"C1\", \"title\": \"Dom Casmurro\"},\n                           {\"type\": \"CopyReturned\", \"copy\": \"C1\", \"fine\": 100}])\n    print(\"just after the return:\", fines.owed, \"| projection at\", fines.position, \"of 2\")\n    inbox.join()\n    print(\"after the worker caught up:\", fines.owed, \"| projection at\", fines.position, \"of 2\")\n\n    record(\"member-dani\", [{\"type\": \"FinePaid\", \"amount\": 100}])\n    print(\"just after paying:\", fines.owed, \"| projection at\", fines.position, \"of 3\")\n    inbox.join()\n    print(\"after the worker caught up:\", fines.owed, \"| projection at\", fines.position, \"of 3\")", "note": "Dani returns a book late, and the projection is read at once, then after `inbox.join()`, which waits until the worker has applied everything queued. The same again for her payment."},
 {"code": "\n    restarted = FinesOwed()\n    restarted.position, restarted.owed = 2, {\"dani\": 100}  # its saved checkpoint\n    for position, event in store.read_all(after=restarted.position):\n        restarted.apply(position, event)\n    print(\"restarted from its checkpoint at 2:\", restarted.owed, \"| at\", restarted.position)", "note": "Last, a projection restarted from a checkpoint it had saved at position 2. It reads only what came after, and arrives at the same answer as the one that never stopped."}
]}
```

```
ana@laptop:~/patterns/events$ python3 lag.py
just after the return: {} | projection at 0 of 2
after the worker caught up: {'dani': 100} | projection at 2 of 2
just after paying: {'dani': 100} | projection at 2 of 3
after the worker caught up: {'dani': 0} | projection at 3 of 3
restarted from its checkpoint at 2: {'dani': 0} | at 3
```

Read straight after Dani's late return, the projection is empty and at position 0 of 2: the worker
had not finished its first event. After `join` it shows her 100 cents owed, at 2 of 2. Her payment
repeats the pattern, and the restarted projection, starting from its saved position 2, applies one
event and agrees: Dani owes nothing.

**The timing is real this time, and in principle it varies.** The worker sleeps 50 milliseconds per
event, and the main thread reads after microseconds, so on any ordinary machine the first read
lands before the first event is applied; on a heavily loaded one the numbers could differ. The
positions are what make the window describable: the projection is at 0 while the store is at 2,
whatever the clock says.

## The position is the vocabulary

A projection's checkpoint and the store's head are two numbers, and their difference is the lag,
measured in events. **That number is what a system shows, alerts on and waits for.** A screen can
say "updated to 14:02:31" by carrying the time of the last event applied; a command can return the
position it wrote, and the next page can wait until the projection reaches it, the remedy lesson 8
called waiting for the position. An operator watches the gap: a projection whose checkpoint has not
moved for ten minutes while the head has, is a stuck worker.

## Restarting, and applying twice

A worker that crashes after applying an event but before saving its checkpoint will, on restart,
read that event again. **Delivery from a store to a projection is at least once**, so a projection
must survive seeing an event twice. Two common answers:

| approach | how it works |
|---|---|
| save the checkpoint with the result | write the projection's rows and its position in one transaction, so either both moved or neither did |
| make each apply idempotent | `FinesOwed` would remember the positions it applied and skip a repeat, or set values rather than add to them |

`FinesOwed` here does neither, since it lives in memory and starts from a known checkpoint, and that
is the honest limit of a demonstration this size. In SQLite or PostgreSQL the first approach
is the usual choice: the projection's tables and a one-row `checkpoint` table, updated in the same
transaction, which lesson 10 explains.

## Ordering

Events within one stream are applied in version order, and the store's `position` gives a single
order across streams. A projection that reads by position sees every member's events in the order
they were written, which is what `FinesOwed` relies on. Distributed stores often guarantee order only
within a stream, and then a projection combining two streams has to tolerate seeing a return before
the loan it closes. That is a reason to keep the facts a projection needs inside one event, as
`CopyReturned` carries its own fine.
