---
title: Roles as small protocols
version: 1
---

**A role interface is a small protocol named after what one kind of client does with an object:
searching, lending, stocking.** One class can play several roles, and each client depends on the
one it needs. The class stays whole; only the declarations are split.

A common worry is that segregating interfaces means splitting the class too: a `SearchService`, a
`LendingService` and a `StockService`, each with a piece of the catalogue's data. Sometimes that is
right, and the single responsibility principle decides it. Interface segregation does not ask for
it. The library's titles and who has borrowed them are one set of data, and one class can hold it
while showing a different face to each client.

## Three roles, one library

```schooling-example
{"language": "python", "file": "roles.py", "parts": [
 {"code": "# roles.py\nfrom typing import Protocol\n\n\nclass Searching(Protocol):\n    def search(self, words: str) -> list[str]: ...\n\n\nclass Lending(Protocol):\n    def lend(self, title: str, member: str) -> None: ...\n\n\nclass Stocking(Protocol):\n    def add_title(self, title: str) -> None: ...", "note": "Three roles, each named for an activity. The names are what a reader sees in a client's signature, so they say what the client does."},
 {"code": "\n\nclass Library:\n    def __init__(self):\n        self._borrower: dict[str, str | None] = {}\n\n    def search(self, words: str) -> list[str]:\n        return [t for t in self._borrower if words.lower() in t.lower()]\n\n    def lend(self, title: str, member: str) -> None:\n        if self._borrower[title] is not None:\n            raise ValueError(f\"{title!r} is already out\")\n        self._borrower[title] = member\n\n    def add_title(self, title: str) -> None:\n        self._borrower.setdefault(title, None)", "note": "One class, one dictionary of titles, and the methods of all three roles. It names none of the protocols; having the methods is enough."},
 {"code": "\n\ndef back_office(stock: Stocking, titles: list[str]) -> None:\n    for title in titles:\n        stock.add_title(title)\n\n\ndef desk(lending: Lending, title: str, member: str) -> None:\n    lending.lend(title, member)\n    print(f\"lent {title} to {member}\")\n\n\ndef kiosk(catalogue: Searching, words: str) -> None:\n    print(f\"{words!r}:\", catalogue.search(words))", "note": "Each client declares one role. The kiosk can no longer reach `lend` even by accident, and a change to `lend` cannot concern it."},
 {"code": "\n\nclass OneTitle:\n    def search(self, words: str) -> list[str]:\n        return [\"Vidas Secas\"]", "note": "The stand-in that failed in the first section, now three lines and accepted."},
 {"code": "\n\nif __name__ == \"__main__\":\n    library = Library()\n    back_office(library, [\"Vidas Secas\", \"Memórias Póstumas de Brás Cubas\", \"Vidas Paralelas\"])\n    desk(library, \"Vidas Secas\", \"Bia\")\n    kiosk(library, \"vidas\")\n    kiosk(OneTitle(), \"anything\")", "note": "The same `library` object is passed to all three clients, each of which sees only its role."}
]}
```

```
ana@laptop:~/patterns/solid-2$ python3 roles.py
lent Vidas Secas to Bia
'vidas': ['Vidas Secas', 'Vidas Paralelas']
'anything': ['Vidas Secas']
```

The library is stocked, lends a title and answers a search; then the kiosk is handed the stand-in
and works with it just as well. **The kiosk's whole dependency is one method, so the whole of its
test double is one method.**

## Who owns a role

Notice where the protocols could live. `Searching` is what the kiosk needs, so it belongs with the
kiosk: written by the people who write the kiosk, changed when the kiosk's needs change. The
`Library` class satisfies it without importing it, in Python, Go and TypeScript, because those
languages check the shape. That arrangement, where the client defines the interface and the
implementer happens to fit, is ordinary Go practice. The standard library's `io.Reader` has one
method, `Read`, and thousands of types satisfy it without mentioning it; Rob Pike's line for this
is "the bigger the interface, the weaker the abstraction".

| language | a class playing three roles | where the role is usually declared |
|---|---|---|
| Python | has the methods; `Protocol`s describe the roles | anywhere; best next to the client |
| Go | has the methods; small `interface`s describe the roles | in the client's package |
| TypeScript | has the methods; `interface`s describe the roles | anywhere; checked by shape |
| Java | `class Library implements Searching, Lending, Stocking` | beside the class, since it must name them |

Java is the exception, because a class must name each interface it implements. The roles are still
worth splitting there; the cost is that `Library` has to import all three, so the arrow of
dependency points from the class to each role. That arrow, and which way it should point, is the
subject of the next section.

## How small is small enough

The roles here have one method each because each client calls one. If the desk also gives books
back, `Lending` gets `give_back` too, since the same client calls both and they change together.
Splitting `lend` and `give_back` into two protocols would give two names to one client's needs and
buy nothing. A role is the set of methods one kind of client uses, whatever its size.
