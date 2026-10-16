---
title: Adapter and facade: the shape of somebody else's code
version: 1
---

**An adapter makes one interface look like another that your code already expects; a facade puts
one simple interface in front of several objects so callers deal with one thing instead of five.**
Both are structural patterns about a boundary, and both wrap other objects, which is why they get
confused. The difference is the question each answers. An adapter answers "this does what I need
but speaks the wrong language". A facade answers "this subsystem is too much to make every caller
understand".

## An adapter: translating at the border

The library wants to fill in a book's details from a national catalogue service. The service comes
with a client somebody else wrote, and its idea of a book is not ours: it answers with a status and
a record, calls the title `ttl`, and writes authors surname first.

```schooling-example
{"language": "python", "file": "adapter.py", "parts": [
 {"code": "# adapter.py\nfrom dataclasses import dataclass\nfrom typing import Protocol\n\n\n@dataclass(frozen=True)\nclass Book:\n    isbn: str\n    title: str\n    author: str\n\n\nclass Catalogue(Protocol):\n    def find(self, isbn: str) -> Book | None: ...", "note": "Our side. The rest of the program works with `Book` and asks a `Catalogue` for one; it has never seen the service's format."},
 {"code": "\n\nclass OpenShelfClient:\n    _RECORDS = {\n        \"9786555550123\": {\"ttl\": \"Vidas Secas\", \"auth\": [\"Ramos, Graciliano\"]},\n        \"9786555550147\": {\"ttl\": \"Dom Casmurro\", \"auth\": [\"Assis, Machado de\"]},\n    }\n\n    def lookup(self, code: str) -> dict:\n        record = self._RECORDS.get(code.replace(\"-\", \"\"))\n        return {\"status\": \"ok\", \"record\": record} if record else {\"status\": \"not_found\"}", "note": "Their side, standing in for a client you cannot change. The data is two made-up records; a real client would make a network call."},
 {"code": "\n\nclass OpenShelfCatalogue:\n    def __init__(self, client: OpenShelfClient):\n        self._client = client\n\n    def find(self, isbn: str) -> Book | None:\n        answer = self._client.lookup(isbn)\n        if answer[\"status\"] != \"ok\":\n            return None\n        record = answer[\"record\"]\n        surname, given = record[\"auth\"][0].split(\", \")\n        return Book(isbn, record[\"ttl\"], f\"{given} {surname}\")", "note": "The adapter. It implements our protocol and holds their client, and every difference between the two worlds is translated here and nowhere else."},
 {"code": "\n\nif __name__ == \"__main__\":\n    catalogue: Catalogue = OpenShelfCatalogue(OpenShelfClient())\n    print(catalogue.find(\"978-65-5555-012-3\"))\n    print(catalogue.find(\"978-65-5555-099-9\"))", "note": "The caller sees a `Catalogue`. A status string, a `ttl` and a surname-first author never reach it."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 adapter.py
Book(isbn='978-65-5555-012-3', title='Vidas Secas', author='Graciliano Ramos')
None
```

**The adapter is where the foreign model stops.** When the service renames `ttl` to `title`, one
method changes. Without it, `record["ttl"]` would be scattered across every function that showed a
book, and the rename would be a search through the whole program. Lesson 11 gives a larger version
of this a name of its own, the anti-corruption layer, and builds it between two parts of the
library.

## A facade: one door into a subsystem

Lending a book touches several objects: the catalogue to find it, the reservations to check nobody
else is waiting, the ledger to record the loan, the printer for the slip. Every screen that lends
something would have to know all four and call them in the right order.

```schooling-example
{"language": "python", "file": "facade.py", "parts": [
 {"code": "# facade.py\nfrom datetime import date, timedelta\n\nfrom adapter import Catalogue, OpenShelfCatalogue, OpenShelfClient", "note": "The facade reuses the adapter from `adapter.py`, so keep both files in the same directory."},
 {"code": "\n\nclass Ledger:\n    def __init__(self):\n        self.loans = {}\n\n    def record(self, member: str, isbn: str, due: date) -> None:\n        self.loans[isbn] = (member, due)\n\n\nclass Reservations:\n    def __init__(self, waiting: dict[str, list[str]]):\n        self._waiting = waiting\n\n    def first_in_line(self, isbn: str) -> str | None:\n        queue = self._waiting.get(isbn, [])\n        return queue[0] if queue else None\n\n\nclass SlipPrinter:\n    def issue(self, text: str) -> None:\n        print(f\"slip: {text}\")", "note": "Three small subsystems. Each is simple; what is not simple is knowing which to call, when, and what to do with each answer."},
 {"code": "\n\nclass LendingDesk:\n    LOAN_DAYS = 14\n\n    def __init__(self, catalogue: Catalogue, ledger: Ledger,\n                 reservations: Reservations, printer: SlipPrinter):\n        self._catalogue, self._ledger = catalogue, ledger\n        self._reservations, self._printer = reservations, printer\n\n    def lend(self, member: str, isbn: str, today: date) -> str:\n        book = self._catalogue.find(isbn)\n        if book is None:\n            return f\"no such book: {isbn}\"\n        waiting = self._reservations.first_in_line(isbn)\n        if waiting not in (None, member):\n            return f\"{book.title} is reserved for {waiting}\"\n        due = today + timedelta(days=self.LOAN_DAYS)\n        self._ledger.record(member, isbn, due)\n        self._printer.issue(f\"{member} has {book.title} until {due}\")\n        return \"lent\"", "note": "The facade. Its one method holds the order of the steps and the rules between them, and a caller who wants to lend a book calls `lend` and nothing else."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = LendingDesk(OpenShelfCatalogue(OpenShelfClient()), Ledger(),\n                       Reservations({\"978-65-5555-012-3\": [\"Caio\"]}), SlipPrinter())\n    today = date(2026, 5, 4)\n    print(desk.lend(\"Bia\", \"978-65-5555-014-7\", today))\n    print(desk.lend(\"Bia\", \"978-65-5555-012-3\", today))\n    print(desk.lend(\"Caio\", \"978-65-5555-012-3\", today))\n    print(desk.lend(\"Bia\", \"978-65-5555-099-9\", today))", "note": "Four requests through one door: an ordinary loan, a book somebody else reserved, the same book for the person who reserved it, and an ISBN nobody knows."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 facade.py
slip: Bia has Dom Casmurro until 2026-05-18
lent
Vidas Secas is reserved for Caio
slip: Caio has Vidas Secas until 2026-05-18
lent
no such book: 978-65-5555-099-9
```

## Telling them apart

| | adapter | facade |
|---|---|---|
| wraps | one object | several objects |
| its interface is | one the caller already expects | a new, simpler one |
| why it exists | the interfaces do not match | the subsystem is too much to know |
| in this lesson | `OpenShelfCatalogue` | `LendingDesk` |

A facade does not hide the subsystem from those who need it: `Ledger` is still there for the
monthly report that reads every loan. It gives the common case one door. **The risk of a facade is
that it grows into a class that does everything**, so keep it to coordinating, and leave each rule
in the subsystem that owns it. Lesson 4's ports and adapters is the same adapter at the scale of a
whole application: every outside system reaches the core through one.
