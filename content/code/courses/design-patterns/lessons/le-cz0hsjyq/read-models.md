---
title: "Read models: tables shaped like the screen"
version: 1
---

**A read model is a structure built for one screen, kept current by applying the write side's
events to it, so that answering the screen is a lookup rather than a computation.** The work the
strained class did on every page view, walking every copy for every title, is done once per event
instead, by a small piece of code called a projector. The query that is left is short enough to read
at a glance.

The habit to unlearn is normalisation. In a write model, storing the author's name next to every
count would be a defect: two copies of a fact that can drift apart. In a read model it is the
point, because the read model is derived. If it drifts, it is rebuilt from the events, and nothing
the library knows is lost.

```schooling-example
{"language": "python", "file": "read_model.py", "parts": [
 {"code": "# read_model.py\nimport sqlite3\nfrom datetime import date\nfrom commands import (CopyLent, CopyReturned, TitleReserved, Lending, LendCopy,\n                      ReturnCopy, Reserve, handle)", "note": "The read side imports the event types and, for the demonstration at the bottom, the write side. The projector itself needs only the events."},
 {"code": "\nCATALOGUE = {\"T1\": (\"Dom Casmurro\", \"Machado de Assis\", 2),\n             \"T2\": (\"Vidas Secas\", \"Graciliano Ramos\", 1),\n             \"T3\": (\"A Hora da Estrela\", \"Clarice Lispector\", 1)}", "note": "Names, authors and copy counts: data only the screens care about. It goes into the read model and never into `Lending`."},
 {"code": "\n\nclass Availability:\n    def __init__(self, catalogue: dict[str, tuple[str, str, int]]):\n        self.db = sqlite3.connect(\":memory:\")\n        self.db.execute(\"CREATE TABLE availability (title_id TEXT PRIMARY KEY,\"\n                        \" title TEXT, author TEXT, on_shelf INTEGER, waiting INTEGER)\")\n        self.db.executemany(\"INSERT INTO availability VALUES (?, ?, ?, ?, 0)\",\n                            [(t, name, author, n) for t, (name, author, n) in catalogue.items()])", "note": "A real table in SQLite, held in memory: one row per title, with the author copied in and the counts stored, not computed. That is what *denormalised* means here, and it is deliberate."},
 {"code": "\n    def apply(self, event) -> None:\n        match event:\n            case CopyLent(title_id=t, was_reserved=r):\n                shelf, wait = -1, (-1 if r else 0)\n            case CopyReturned(title_id=t):\n                shelf, wait = 1, 0\n            case TitleReserved(title_id=t):\n                shelf, wait = 0, 1\n            case _:\n                return\n        self.db.execute(\"UPDATE availability SET on_shelf = on_shelf + ?,\"\n                        \" waiting = waiting + ? WHERE title_id = ?\", (shelf, wait, t))", "note": "The projector. Each event becomes one `UPDATE` of two counters, and an event it does not care about is ignored. `match` takes the event apart by its class and fields."},
 {"code": "\n    def available_now(self) -> list[tuple]:\n        return self.db.execute(\"SELECT title, author, on_shelf FROM availability\"\n                               \" WHERE on_shelf > 0 ORDER BY title\").fetchall()\n\n    def waiting_for(self, title_id: str) -> int:\n        return self.db.execute(\"SELECT waiting FROM availability WHERE title_id = ?\",\n                               (title_id,)).fetchone()[0]", "note": "The query the desk runs. No join and no loop over copies: the answer was worked out when the events arrived."},
 {"code": "\n\nclass MemberLoans:\n    def __init__(self, catalogue: dict[str, tuple[str, str, int]]):\n        self.names = {t: name for t, (name, _, _) in catalogue.items()}\n        self.by_member: dict[str, dict[str, str]] = {}\n\n    def apply(self, event) -> None:\n        match event:\n            case CopyLent(copy_id=c, title_id=t, member=m, due=due):\n                self.by_member.setdefault(m, {})[c] = f\"{self.names[t]}, due {due:%d/%m}\"\n            case CopyReturned(copy_id=c, member=m):\n                self.by_member[m].pop(c)\n\n    def of(self, member: str) -> list[str]:\n        return sorted(self.by_member.get(member, {}).values())", "note": "A second read model from the same events, in a different shape: a dictionary per member, with lines already formatted. Nothing stops a third."},
 {"code": "\n\nif __name__ == \"__main__\":\n    lending = Lending({\"C1\": \"T1\", \"C2\": \"T1\", \"C3\": \"T2\", \"C4\": \"T3\"})\n    shelf, loans = Availability(CATALOGUE), MemberLoans(CATALOGUE)\n    lending.listeners += [shelf.apply, loans.apply]\n    day = date(2026, 3, 2)\n    for command in [LendCopy(\"C1\", \"bia\", day), LendCopy(\"C4\", \"bia\", day),\n                    LendCopy(\"C3\", \"caio\", day), Reserve(\"T2\", \"dani\"),\n                    ReturnCopy(\"C4\", date(2026, 3, 10))]:\n        handle(lending, command)\n    for row in shelf.available_now():\n        print(row)\n    print(\"bia:\", loans.of(\"bia\"))\n    print(\"waiting for T2:\", shelf.waiting_for(\"T2\"))\n    handle(lending, ReturnCopy(\"C3\", date(2026, 3, 16)))\n    handle(lending, LendCopy(\"C3\", \"dani\", date(2026, 3, 16)))\n    print(\"waiting for T2:\", shelf.waiting_for(\"T2\"), \"| dani:\", loans.of(\"dani\"))", "note": "Both read models listen to the write model. Five commands, the screen, then Caio returns *Vidas Secas* and Dani, first in the queue, borrows it."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 read_model.py
('A Hora da Estrela', 'Clarice Lispector', 1)
('Dom Casmurro', 'Machado de Assis', 1)
bia: ['Dom Casmurro, due 16/03']
waiting for T2: 1
waiting for T2: 0 | dani: ['Vidas Secas, due 30/03']
```

*Vidas Secas* is missing from the first two rows because its only copy is out; Bia returned *A Hora
da Estrela* on 10 March, so it is back. Bia's loans show one line. Dani's reservation made the
waiting count 1, and the last line shows it fall back to 0 when Dani borrowed the copy.

## The event had to say it

That last line works only because `CopyLent` carries `was_reserved`. Without it, the projector would
see "C3 was lent to dani" and have no way to know whether a reservation was used up: the queue lives
in the write model, which the projector must not read. **A read model can show only what the events
say.** When a screen needs a fact, the fix is in the event. Adding a field to an event is a design
decision about the write side's vocabulary, and lesson 9 treats it with the care it needs once
events are stored for years.

## One write model, many read models

`MemberLoans` reads the same events as `Availability` and keeps an entirely different shape: per
member, keyed by copy, with the due date already formatted as `16/03`. A third screen, "most
borrowed this year", would be a third projector counting `CopyLent` per title, and **adding it does
not touch `Lending` at all**. Compare the strained class, where the same screen meant a new counter
inside `lend`.

Each read model is chosen for its screen, and they do not have to share a technology. The
availability table could sit in SQLite or PostgreSQL, a search screen's model in a full-text index,
and the member's page in a key-value store keyed by member. The projector is the only code that
knows both the events and the store.

## Testing a projector

A projector is a function from events to state, which makes it one of the easiest things in a
system to test: build an `Availability`, call `apply` with a list of events written by hand, and
query. No write model, no rules, no clock. The write side is tested the other way round, by sending
commands and asserting on the events it published, and between the two the event types are the
contract. `testing-cicd` lesson 3's fixtures fit this well: a fixture of events is a scenario.
