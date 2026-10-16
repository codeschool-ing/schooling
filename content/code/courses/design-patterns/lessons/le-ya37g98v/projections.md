---
title: "Projections: read models from the whole history"
version: 1
---

**A projection in an event-sourced system is lesson 8's read model, fed from the event store instead
of from a live listener, and the difference is that it can start from the first event ever
written.** It keeps a checkpoint, the position of the last event it applied, and to catch up it reads
everything after that. A projection added today reads from position 0 and knows everything that
happened before it existed.

That last property is the one that changes how teams work, and the belief it replaces is that a
report can only show data somebody decided to collect in advance. With events kept, a question
nobody asked last year can be answered about last year.

```schooling-example
{"language": "python", "file": "projections.py", "parts": [
 {"code": "# projections.py\nfrom collections import Counter\nfrom store import EventStore", "note": "Two projections over the same store. Neither imports anything from the write side except the store it reads."},
 {"code": "\n\nclass FinesOwed:\n    def __init__(self):\n        self.owed: dict[str, int] = {}\n        self.position = 0\n\n    def apply(self, position: int, event: dict) -> None:\n        member = event[\"stream\"].removeprefix(\"member-\")\n        if event[\"type\"] == \"CopyReturned\":\n            self.owed[member] = self.owed.get(member, 0) + event[\"fine\"]\n        elif event[\"type\"] == \"FinePaid\":\n            self.owed[member] = self.owed.get(member, 0) - event[\"amount\"]\n        self.position = position", "note": "A read model of what each member owes. It remembers the position of the last event it applied: its checkpoint, which says how far through the history it has read."},
 {"code": "\n\nclass MostBorrowed:\n    def __init__(self):\n        self.count: Counter = Counter()\n        self.position = 0\n\n    def apply(self, position: int, event: dict) -> None:\n        if event[\"type\"] == \"CopyLent\":\n            self.count[event[\"title\"]] += 1\n        self.position = position", "note": "A second read model, counting loans per title. It ignores every event that is not a loan, and still moves its checkpoint past them."},
 {"code": "\n\ndef catch_up(store: EventStore, projection) -> None:\n    for position, event in store.read_all(after=projection.position):\n        projection.apply(position, event)", "note": "One function serves both, and any future projection: read every event after the checkpoint, in order, and apply it. Run from position 0, it builds a projection from the whole of history."},
 {"code": "\n\nif __name__ == \"__main__\":\n    store = EventStore(\":memory:\")\n    lent = lambda copy, title: {\"type\": \"CopyLent\", \"copy\": copy, \"title\": title}\n    returned = lambda copy, fine: {\"type\": \"CopyReturned\", \"copy\": copy, \"fine\": fine}\n    store.append(\"member-bia\", 0, [lent(\"C1\", \"Dom Casmurro\"), returned(\"C1\", 150),\n                                   {\"type\": \"FinePaid\", \"amount\": 150}, lent(\"C3\", \"Vidas Secas\")])\n    store.append(\"member-caio\", 0, [lent(\"C2\", \"Dom Casmurro\"), returned(\"C2\", 0)])\n    store.append(\"member-dani\", 0, [lent(\"C1\", \"Dom Casmurro\"), returned(\"C1\", 100)])\n\n    fines = FinesOwed()\n    catch_up(store, fines)\n    print(\"fines owed:\", fines.owed, \"at position\", fines.position)\n\n    store.append(\"member-caio\", 2, [lent(\"C4\", \"A Hora da Estrela\")])\n    popular = MostBorrowed()\n    catch_up(store, popular)\n    print(\"most borrowed:\", popular.count.most_common(2), \"at position\", popular.position)\n    catch_up(store, fines)\n    print(\"fines owed:\", fines.owed, \"at position\", fines.position)", "note": "Three members' histories, the fines projection built and printed, one more loan, then a projection that did not exist when any of those loans happened, built from all of them. Finally the fines projection catches up from where it stopped."}
]}
```

```
ana@laptop:~/patterns/events$ python3 projections.py
fines owed: {'bia': 0, 'caio': 0, 'dani': 100} at position 8
most borrowed: [('Dom Casmurro', 3), ('Vidas Secas', 1)] at position 9
fines owed: {'bia': 0, 'caio': 0, 'dani': 100} at position 9
```

Bia's 150 cents were paid, Caio was on time, and Dani owes 100, as of position 8, the last event in
the store. Then Caio borrows *A Hora da Estrela*, position 9. `MostBorrowed` is created only now,
yet it reports that *Dom Casmurro* was borrowed three times, by three members, all before it
existed. The fines projection catches up from 8 to 9 and its numbers do not move, because a loan
owes nothing.

## The checkpoint is the projection's own business

**Each projection keeps its own position, and none of them is ever "the" state.** They can be at
different points of the history, and in a running system they usually are, because each one reads
at its own pace. A projection that crashes resumes from its checkpoint; a projection that turns out
to be wrong is deleted and rebuilt from 0, with the fix in its code. Neither touches the events.

That is the reason the read side of lesson 8 could be called derived data with a straight face. Here
the claim is literal: `FinesOwed()` with its position set back to 0 and `catch_up` called again
produces exactly the same dictionary, from exactly the same events, every time.

## What a projection may and may not do

A projection reads events and writes its own store. It must not append events, because then reading
history would change history, and two rebuilds could differ. It must not call the write side to ask
for more, for the same reason lesson 8 gave: if it needs a fact, the event should carry it.

It must also be **deterministic in the events**: no `date.today()`, no random numbers, no lookups in
a table that may have changed since. A projection computing "days overdue" from the clock gives a
different answer on every rebuild. The date it needs belongs in the event, the way `CopyReturned`
here carries its fine rather than leaving the projection to work it out from today's date.

## Read models that outlive their screens

Because projections are cheap to throw away, a team can try one for a single screen, change its
shape twice in a month, and delete it when the screen goes. Nothing about the write side moves. The
cost is time: rebuilding from 0 over millions of events takes minutes or hours, and while a new
projection is catching up its screen shows a partial history. Real systems rebuild beside the old
projection and switch over when the new one reaches the head of the store.
