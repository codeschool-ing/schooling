---
title: "Primitive obsession: give the concept a type"
version: 1
---

**Primitive obsession is using the language's built-in types for ideas the domain has a name for.**
An `int` that holds money, a `str` that holds a kind of item, a tuple whose fifth position happens
to be the kind. Each works, and each leaves the rules about that idea scattered across whoever
handles the value. `report.py` has two clear cases.

The first is money. `total` and `f` are plain integers of cents, and nothing stops a caller from
adding a fine to a number of days, or printing one without `money()`. The rules of the concept, *it
is cents, it adds to other money, it prints as reais*, live in the heads of the people using it.

The second is the row. `row[4]` is the kind and `row[6]` is the return date, and the only
documentation is the order of the values in `LOANS`. Insert a field at the front and every index
in the file is silently wrong by one.

## Replace primitive with object

Fowler's move is to make a small class for the concept, move the rules into it, and change the
callers to use it. For money that class is a value object of the kind lesson 12 built: frozen,
compared by value, with the arithmetic it needs and nothing else. For the row, a `NamedTuple` gives
each position a name while staying a tuple, so the callers who pass plain tuples are untouched:

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\nfrom typing import NamedTuple\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]", "note": "Two imports more, both from the standard library."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n\n    def __add__(self, other: \"Money\") -> \"Money\":\n        return Money(self.cents + other.cents)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n)\n\n    def __str__(self) -> str:\n        return f\"R$ {self.cents // 100},{self.cents % 100:02d}\"\n\n\nDAILY_FINE = Money(50)", "note": "`money()` became `Money.__str__`: the formatting moved into the type it formats. Money adds to money and multiplies by a count; there is no `Money + int`, so adding days to reais is now an error instead of a wrong number."},
 {"code": "\n\nclass Row(NamedTuple):\n    name: str\n    phone: str\n    email: str\n    title: str\n    kind: str\n    lent_on: date\n    returned_on: date | None", "note": "The positions get names. A `NamedTuple` is still a tuple, so `Row._make(t)` wraps any tuple from `LOANS` without copying the values around."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on\n\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"", "note": "Untouched. The kind is still a string, a third primitive left for the section on switches."},
 {"code": "\n\ndef days_late(row, today):\n    end = row.returned_on or today\n    return (end - due_date(row.kind, row.lent_on)).days", "note": "`row[6]` and `row[4]` became `row.returned_on` and `row.kind`. A typo in a name is an `AttributeError` on the first run; a wrong index was a wrong answer."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = Money(0)\n    for row in map(Row._make, loans):\n        d = days_late(row, today)\n        if d > 0:\n            fine = DAILY_FINE.times(d)\n            total = total + fine\n            out.append(f\"{row.name} <{row.email}>: {label(row.kind)} '{row.title}', {d} days late, {fine}\")\n    out.append(f\"total: {total}\")\n    return \"\\n\".join(out)", "note": "The interface is kept: callers still pass tuples. Each is wrapped on the way in, and `{fine}` in the f-string calls `Money.__str__`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

With no file named, `unittest` looks for every `test*.py` in the directory, which here is the one:

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest -v
test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (test_report.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## Why a two-line class is worth it

The `Money` class is short and the file is longer than before, which looks like a loss. Count the
other way. **Every rule about money now has one home**, and a reader who wants to know how amounts
are printed or added opens one class. The next rule the library adds, refusing negative amounts or
splitting a fine into instalments, has an obvious place to go. And mistakes that were silent become
loud: `Money(50) + 3` stops with `AttributeError: 'int' object has no attribute 'cents'`
instead of quietly producing a number that means nothing.

The same reasoning applies to the identifiers, e-mail addresses and phone numbers in the row, which
are still plain strings. Whether they deserve types depends on whether they carry rules. A phone
number the library only prints can stay a string; one it validates, normalises and dials has
earned a class. **Wrap a primitive when it has behaviour to hold, not as a ritual.**

## The same move in your language

| language | a small value type | a named record for the row |
|---|---|---|
| Python | `@dataclass(frozen=True) class Money` | `class Row(NamedTuple)` or a frozen dataclass |
| Java | `record Money(long cents)` with methods | `record Row(String name, ...)` |
| Go | `type Money struct{ cents int64 }` with methods, or `type Money int64` | a `struct` with named fields |
| TypeScript | a `class Money` with a private field, or a branded `number` type | an `interface` or `type` with named properties |

Go's `type Money int64` is worth a note: it is a new type the compiler will not mix with a plain
`int64` without a conversion, and it can carry methods, so it gives most of the protection for
almost no code. TypeScript's structural typing would let any `number` stand in for a plain alias,
which is why the branded type exists.
