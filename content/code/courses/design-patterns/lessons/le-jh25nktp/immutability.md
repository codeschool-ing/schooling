---
title: "Immutability: values that cannot change behind your back"
version: 1
---

**The usual objection to immutable data is that it wastes memory by copying. The usual reason to
want it is a bug that copying would have prevented.** An object that can be changed can be changed
by anyone holding a reference to it, and in a program of any size more than one thing holds a
reference. Every place that keeps the object then sees the change, whether it wanted to or not.

## The bug, and the cure

A renewal adds 14 days to a loan. Written as a mutation, it edits the loan in place. Written as a
value, it returns a new loan and leaves the old one alone:

```schooling-example
{"language": "python", "file": "frozen.py", "parts": [
 {"code": "# frozen.py\nfrom dataclasses import FrozenInstanceError, dataclass, replace\nfrom datetime import date, timedelta", "note": "`replace` and `FrozenInstanceError` both come from `dataclasses`."},
 {"code": "\n\nclass MutableLoan:\n    def __init__(self, title: str, due: date):\n        self.title = title\n        self.due = due\n\n\ndef renew_in_place(loan: MutableLoan) -> None:\n    loan.due += timedelta(days=14)", "note": "An ordinary class and a function that edits it. Nothing about either looks wrong."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    due: date\n\n\ndef renewed(loan: Loan) -> Loan:\n    return replace(loan, due=loan.due + timedelta(days=14))", "note": "`frozen=True` makes assignment to a field an error. `replace` builds a new instance with the fields you name changed and the rest copied."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Member:\n    name: str\n    titles: list[str]", "note": "Frozen too, but holding a list. The demonstration below shows what that means."},
 {"code": "\n\nif __name__ == \"__main__\":\n    first = MutableLoan(\"Dom Casmurro\", date(2026, 3, 16))\n    history = [first]\n    renew_in_place(first)\n    print(\"history, mutable:\", history[0].due)", "note": "The history was meant to record the loan as it was. It holds a reference, not a copy, so the renewal rewrote history."},
 {"code": "\n    loan = Loan(\"Dom Casmurro\", date(2026, 3, 16))\n    history = [loan]\n    new = renewed(loan)\n    print(\"history, frozen:\", history[0].due, \"| renewed:\", new.due)\n    try:\n        loan.due = date(2026, 4, 30)\n    except FrozenInstanceError as err:\n        print(\"refused:\", err)", "note": "The same steps with a frozen loan. The history keeps the old due date, the renewal is a separate value, and an attempt to edit the old one is refused."},
 {"code": "\n    bia = Member(\"Bia\", [\"Iracema\"])\n    bia.titles.append(\"Dom Casmurro\")\n    print(\"frozen, but the list inside is not:\", bia.titles)", "note": "Freezing stops `bia.titles = ...`. It does not stop the list from being changed through `append`."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 frozen.py
history, mutable: 2026-03-30
history, frozen: 2026-03-16 | renewed: 2026-03-30
refused: cannot assign to field 'due'
frozen, but the list inside is not: ['Iracema', 'Dom Casmurro']
```

**With the mutable loan, the history says the book was due on 30 March, which was never true at the
time it was recorded.** Nothing raised an error; the program simply holds a false record. With the
frozen loan, the history keeps 16 March, the renewal is a new value with 30 March, and
`loan.due = ...` stops with `cannot assign to field 'due'`.

## Shallow, not deep

The last line of output is the trap. `frozen=True` protects the fields of the object, so `bia.titles`
cannot be pointed at a different list. The list itself is an ordinary mutable list and `append`
changes it. A frozen object is only as immutable as the values it holds.

The fix is to hold immutable values all the way down: a `tuple` instead of a `list`, a `frozenset`
instead of a `set`, and other frozen dataclasses instead of plain objects. `titles: tuple[str, ...]`
would make `bia.titles.append` an `AttributeError`, and adding a title would be
`replace(bia, titles=bia.titles + ("Dom Casmurro",))`, another new value.

## Is the copying a cost?

`replace` copies the fields, not the objects they refer to: the new loan shares its `title` string
with the old one. For records of a dozen fields this is negligible next to a database call. Where it
is not, for large collections changed often, functional languages use **persistent data
structures** that share most of their structure between versions, so a new version of a
million-element map costs a handful of new nodes. Python's standard library has none; `tuple` and
`frozenset` are copied whole. That is a reason to keep immutability for the domain values,
the loans, members and money of lessons 12 and 14, rather than for every buffer in the program.

What immutability buys in exchange is the guarantee that no other part of the program can change a
value you are holding. Aliasing bugs like the history above cannot happen, a value can be shared
between threads without a lock, and a value can be a dictionary key or a set member because its hash
never changes. A frozen dataclass gets a `__hash__` for this reason, and a regular one does not.
