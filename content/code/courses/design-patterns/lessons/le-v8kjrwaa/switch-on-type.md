---
title: "Switch on type: replace the conditional with polymorphism"
version: 1
---

**One `if` on a type code is fine. The same `if` in two places is a promise that the next new kind
will be added to one of them and forgotten in the other.** `due_date` and `label` both branch on
`kind == "book"` and `kind == "film"`, and the knowledge *what kinds exist and how each behaves* is
split between them. A third function, say one that decides whether an item may be renewed, would
grow a third copy.

The move is **replace conditional with polymorphism**, the idea of lesson 1's notices applied to
code that already exists: one class per kind, each answering the questions the branches answered,
and the callers asking the object instead of testing the code.

## First, widen the net

The previous sections never touched the `else` branches, and the safety net never reached them:
both tests use books and films. This move rewrites those branches, so the net has to cover them
first. Add a third characterisation test with a kind that is neither, run it against the code as it
stands, and see it pass:

```python
# test_report.py
import unittest
from datetime import date
from pathlib import Path

from report import LOANS, report

ON_TIME = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Vidas Secas", "book", date(2026, 3, 2), date(2026, 3, 16))]
MAGAZINE = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Piauí", "magazine", date(2026, 3, 20), date(2026, 3, 23))]


class ReportCharacterisation(unittest.TestCase):
    def test_the_march_report(self):
        approved = Path("approved.txt").read_text()
        self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)

    def test_a_month_with_nobody_late(self):
        self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "total: R$ 0,00")

    def test_a_kind_that_is_neither_book_nor_film(self):
        self.assertEqual(report(MAGAZINE, date(2026, 3, 31)),
                         "Eva Rocha <eva@example.org>: item 'Piauí', 3 days late, R$ 1,50\ntotal: R$ 1,50")


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py -v
test_a_kind_that_is_neither_book_nor_film (__main__.ReportCharacterisation.test_a_kind_that_is_neither_book_nor_film) ... ok
test_a_month_with_nobody_late (__main__.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (__main__.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

Read what the new test pins: **a magazine is due on the day it is lent**, so three days out costs
150 cents. That is almost certainly a bug, an `else` nobody thought about. It is recorded exactly as
it is, written on the list for the librarians, and left alone. Fixing it inside a refactoring would
mean the test suite could no longer tell the two changes apart.

## One class per kind

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\nfrom typing import Protocol\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]\n\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n\n    def __add__(self, other: \"Money\") -> \"Money\":\n        return Money(self.cents + other.cents)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n)\n\n    def __str__(self) -> str:\n        return f\"R$ {self.cents // 100},{self.cents % 100:02d}\"\n\n\nDAILY_FINE = Money(50)\n\n\n@dataclass(frozen=True)\nclass Member:\n    name: str\n    phone: str\n    email: str\n\n    def contact(self) -> str:\n        return f\"{self.name} <{self.email}>\"", "note": "Everything above the kinds is as the previous section left it."},
 {"code": "\n\nclass Kind(Protocol):\n    label: str\n\n    def due(self, lent_on: date) -> date: ...", "note": "What every kind must answer: its label, and its due date for a given day of lending. The two questions the two switches used to answer."},
 {"code": "\n\nclass Book:\n    label = \"book\"\n\n    def due(self, lent_on: date) -> date:\n        return lent_on + timedelta(days=14)\n\n\nclass Film:\n    label = \"film (DVD)\"\n\n    def due(self, lent_on: date) -> date:\n        return lent_on + timedelta(days=7)", "note": "Each branch of each chain went into the class it was about. Everything about a film is now in one place."},
 {"code": "\n\nclass OtherItem:\n    label = \"item\"\n\n    def due(self, lent_on: date) -> date:\n        return lent_on", "note": "The two `else` branches, kept faithfully, bug included: due on the day it was lent. The third test is what proves it was kept."},
 {"code": "\n\nKINDS: dict[str, Kind] = {\"book\": Book(), \"film\": Film()}", "note": "The strings still arrive from the callers, so one lookup from string to object remains. It is the only one, at the edge, instead of a switch in every function that cares."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    member: Member\n    title: str\n    kind: Kind\n    lent_on: date\n    returned_on: date | None\n\n    @classmethod\n    def from_row(cls, row: tuple) -> \"Loan\":\n        name, phone, email, title, kind, lent_on, returned_on = row\n        return cls(Member(name, phone, email), title, KINDS.get(kind, OtherItem()), lent_on, returned_on)\n\n    def days_late(self, today: date) -> int:\n        end = self.returned_on or today\n        return (end - self.kind.due(self.lent_on)).days", "note": "A loan holds a `Kind` object instead of a string, and asks it for the due date. `due_date()` and `label()` are gone."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = Money(0)\n    for loan in map(Loan.from_row, loans):\n        d = loan.days_late(today)\n        if d > 0:\n            fine = DAILY_FINE.times(d)\n            total = total + fine\n            out.append(f\"{loan.member.contact()}: {loan.kind.label} '{loan.title}', {d} days late, {fine}\")\n    out.append(f\"total: {total}\")\n    return \"\\n\".join(out)\n\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))", "note": "`label(loan.kind)` became `loan.kind.label`. Otherwise `report` did not change in this step."}
]}
```

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py -v
test_a_kind_that_is_neither_book_nor_film (__main__.ReportCharacterisation.test_a_kind_that_is_neither_book_nor_film) ... ok
test_a_month_with_nobody_late (__main__.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (__main__.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

And the comparison that started the lesson, made one last time by hand:

```
ana@laptop:~/patterns/refactoring$ python3 report.py | diff - approved.txt && echo identical
identical
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l14-kinds\" aria-label=\"Before and after replacing the conditional with polymorphism. On the left, before: two functions, due_date and label, each holding the same chain of tests on the kind string: book, film, anything else. On the right, after: Loan holds a Kind, drawn with a diamond at the Loan end. Kind is a protocol with a label and a due method. Book, Film and OtherItem each implement it. A dictionary, KINDS, turns the incoming string into a Kind once, when the loan is built.\"><defs><marker id=\"l14-kinds-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">before: one switch, written twice</text><rect x=\"30.0\" y=\"44.0\" width=\"220.0\" height=\"71.1\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"54.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">due_date(kind, lent_on)</text><path d=\"M30.0 65.8 L250.0 65.8\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"38.0\" y=\"76.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">if kind == &quot;book&quot;: +14</text><text x=\"38.0\" y=\"90.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">elif kind == &quot;film&quot;: +7</text><text x=\"38.0\" y=\"104.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">else: +0</text><rect x=\"30.0\" y=\"156.0\" width=\"220.0\" height=\"71.1\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"166.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">label(kind)</text><path d=\"M30.0 177.8 L250.0 177.8\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"38.0\" y=\"188.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">if kind == &quot;book&quot;: &quot;book&quot;</text><text x=\"38.0\" y=\"202.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">elif kind == &quot;film&quot;: ...</text><text x=\"38.0\" y=\"216.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">else: &quot;item&quot;</text><text x=\"140.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a new kind: find both chains</text><path d=\"M290.0 14.0 L290.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"505.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">after: each kind answers for itself</text><rect x=\"315.0\" y=\"44.0\" width=\"150.0\" height=\"92.9\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"54.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M315.0 65.8 L465.0 65.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"323.0\" y=\"76.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">member</text><text x=\"323.0\" y=\"90.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">title</text><text x=\"323.0\" y=\"104.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">kind: Kind</text><path d=\"M315.0 115.1 L465.0 115.1\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"323.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">days_late()</text><rect x=\"560.0\" y=\"52.0\" width=\"130.0\" height=\"79.1\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"62.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"625.0\" y=\"76.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">Kind</text><path d=\"M560.0 87.5 L690.0 87.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"98.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">label</text><path d=\"M560.0 109.3 L690.0 109.3\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"120.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">due(lent_on)</text><path d=\"M465.0 84.0 L560.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M465.0 84.0 L474.0 89.5 L483.0 84.0 L474.0 78.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><rect x=\"410.0\" y=\"200.0\" width=\"90.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M455.0 200.0 L455.0 178.0 L625.0 178.0 L625.0 131.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M625.0 131.1 L632.0 143.1 L618.0 143.1 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"510.0\" y=\"200.0\" width=\"90.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"555.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Film</text><path d=\"M555.0 200.0 L555.0 178.0 L625.0 178.0 L625.0 131.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M625.0 131.1 L632.0 143.1 L618.0 143.1 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"610.0\" y=\"200.0\" width=\"90.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">OtherItem</text><path d=\"M655.0 200.0 L655.0 178.0 L625.0 178.0 L625.0 131.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M625.0 131.1 L632.0 143.1 L618.0 143.1 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"315.0\" y=\"245.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">KINDS: str → Kind</text><path d=\"M390.0 245.0 L390.0 138.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-kinds-dp-ah-paper-dim)\"></path><text x=\"398.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">used once, in from_row</text><text x=\"560.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a new kind: one class, one entry</text></svg>", "caption": "The knowledge of what each kind does moves out of the switches and into the kinds."}
```

## What it bought, and when a table is enough

Adding a kind is now one class and one entry in `KINDS`, and nothing else in the file moves. A
renewal rule would be one method on `Kind`, and the type checker would point at every kind that
lacks it. That is the open/closed principle of lesson 3, reached by refactoring instead of designed
in.

Be honest about this case, though. `Book` and `Film` differ only in two values, a number of days
and a label, and a table would carry them with less code:
`{"book": (14, "book"), "film": (7, "film (DVD)")}`. **Polymorphism pays when the branches hold
different behaviour**, not different data: a reference book that refuses to be lent, a film whose
due date skips the days the library is closed. Until then, a dictionary of values is the simpler
design, and moving the branches into one is a refactoring as legitimate as this one. The
classes here are the version to reach for the day a branch grows real code.

The report prints what it printed at the start, byte for byte, and every step on the way there ran
green. The file is longer than the original, and each question a reader might bring to it now has
one place to look: how money prints, how a member is written, when each kind is due, which loans
appear.
