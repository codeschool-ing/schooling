---
title: Data clumps and feature envy
version: 1
---

**Two smells that point at the same missing thing: a class that ought to exist and does not.** A
data clump is a group of values that always travel together. Feature envy is a function that spends
its time on another object's data instead of its own. Both say that some data and the behaviour
that uses it have ended up in different places, and both are fixed by bringing them together.

## The clump

`name`, `phone` and `email` sit side by side in every row, and any function that needed to contact
a member would take all three. Fowler's test for a clump is to delete one of the values in your
head and ask whether the others still make sense on their own. A phone number without the person it
belongs to is useless, so the three are one thing: a member. **When values only make sense
together, they are an object that has not been named yet.**

The same is true, one level up, of the rest of the row. A title, a kind and two dates are a loan,
and `Row` from the previous section is a loan with no behaviour.

## The envy

`days_late(row, today)` reads `row.returned_on`, `row.kind` and `row.lent_on`, and nothing else
except `today`. It is a question about a loan, asked from outside the loan. The f-string in `report`
does the same to the member: it pulls out `name` and `email` and glues them into
`Bia Souza <bia@example.org>`, a format that is a fact about how the library writes a member's
contact, wherever it appears.

The move for envy is **move function**: put the function on the object whose data it uses. Then the
caller stops asking for the fields and asks the object instead, which is what the old advice *tell,
don't ask* means.

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]\n\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n\n    def __add__(self, other: \"Money\") -> \"Money\":\n        return Money(self.cents + other.cents)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n)\n\n    def __str__(self) -> str:\n        return f\"R$ {self.cents // 100},{self.cents % 100:02d}\"\n\n\nDAILY_FINE = Money(50)", "note": "The data and `Money` are as the previous section left them. `NamedTuple` is no longer imported: `Row` is gone."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Member:\n    name: str\n    phone: str\n    email: str\n\n    def contact(self) -> str:\n        return f\"{self.name} <{self.email}>\"", "note": "The clump, named. The way a member's contact is written moved in with the fields it uses, so the next screen that needs it calls `contact()` instead of copying the f-string."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on\n\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"", "note": "Still the two switches on a string. They are the last smell, and the next section's."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    member: Member\n    title: str\n    kind: str\n    lent_on: date\n    returned_on: date | None", "note": "`Row` became `Loan`, and a loan has a member rather than three loose strings: composition, as in lesson 1."},
 {"code": "\n    @classmethod\n    def from_row(cls, row: tuple) -> \"Loan\":\n        name, phone, email, title, kind, lent_on, returned_on = row\n        return cls(Member(name, phone, email), title, kind, lent_on, returned_on)", "note": "The one place that knows the order of the old tuple. If the callers ever switch to passing loans, this method is all that goes."},
 {"code": "\n    def days_late(self, today: date) -> int:\n        end = self.returned_on or today\n        return (end - due_date(self.kind, self.lent_on)).days", "note": "The envious function, moved home. Its body is the same with `row.` replaced by `self.`, which is how you can tell it was always about a loan."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = Money(0)\n    for loan in map(Loan.from_row, loans):\n        d = loan.days_late(today)\n        if d > 0:\n            fine = DAILY_FINE.times(d)\n            total = total + fine\n            out.append(f\"{loan.member.contact()}: {label(loan.kind)} '{loan.title}', {d} days late, {fine}\")\n    out.append(f\"total: {total}\")\n    return \"\\n\".join(out)", "note": "`report` now asks the loan how late it is and the member how to write their contact. What it still does itself is the report's own job: deciding which loans appear and adding up the total."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest
..
----------------------------------------------------------------------
Ran 2 tests in 0.001s

OK
```

Same two tests, same output. The order of moves matters here, and it is worth spelling out
because a refactoring of this size is exactly where people take one big step. Introduce `Member`
and build it in `report`, run. Introduce `Loan` with `from_row`, still holding the kind as a
string, run. Move `days_late` onto `Loan` and change the one caller, run. Add `contact()` and
change the f-string, run. Four green runs, any of which could have been a commit.

## When it is not envy

A function that reads another object's fields is not always misplaced. `report` reads the member,
the loan and the fine, and that is its purpose: a report exists to combine things that belong to
other objects. The smell is a function that is *mostly* about one other object and would read more
naturally as a method on it. Two patterns separate data from behaviour on purpose: a strategy
(lesson 6) keeps an algorithm apart so it can be swapped, and a visitor walks a structure without
living in it. **Envy is a mismatch between where a behaviour lives and what it is about**, not a rule
that every function must use only its own fields.
