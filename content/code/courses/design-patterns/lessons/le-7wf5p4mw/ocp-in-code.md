---
title: A new fine rule, with nothing edited
version: 1
---

**Closing a module against a kind of change takes three pieces: a protocol naming what the module
needs, implementations of it in their own code, and one place that decides which implementation
goes where.** A new case is then a new implementation and one line in that place. The module that
does the work is never opened.

People sometimes expect the open/closed principle to mean that *no* file changes when a case is
added. Something always changes, because something has to say that the new case exists. The point
is which file: a short list of wiring that has no logic in it, instead of the function every
caller relies on.

## The protocol and two rules

The rules are the ones lesson 2 built, rewritten here so this lesson's directory is complete:

```python
# policies.py
from typing import Protocol


class FinePolicy(Protocol):
    def fine(self, days_late: int) -> int: ...


class PerDay:
    def __init__(self, cents: int):
        self.cents = cents

    def fine(self, days_late: int) -> int:
        return max(days_late, 0) * self.cents


class GraceDays:
    def __init__(self, free: int, then: FinePolicy):
        self.free = free
        self.then = then

    def fine(self, days_late: int) -> int:
        return self.then.fine(days_late - self.free)
```

## The closed module

This is the function that replaced the `if` chain. It prints the charge sheet the desk hands out,
and it asks a table of rules for each kind of member instead of asking which kind it has:

```schooling-example
{"language": "python", "file": "charges.py", "parts": [
 {"code": "# charges.py\nfrom policies import FinePolicy", "note": "The only thing it imports is the protocol. No rule class is named anywhere in this file."},
 {"code": "\n\ndef charge_sheet(loans: list[tuple[str, str, int]], rules: dict[str, FinePolicy]) -> None:\n    total = 0\n    for title, kind, days_late in loans:\n        cents = rules[kind].fine(days_late)", "note": "One lookup replaces the whole chain. A kind with no rule raises `KeyError` here, loudly, instead of falling off the end and printing `None`."},
 {"code": "        total += cents\n        print(f\"{title:<20}{kind:<9}{days_late:>3} days late {cents:>6}\")\n    print(f\"{'total':<44}{total:>6}\")", "note": "Layout and totals, which do not care what the rule was."}
]}
```

## The wiring

One short file says which rule each kind of member gets, and runs the sheet:

```python
# main.py
from charges import charge_sheet
from policies import GraceDays, PerDay

standard = PerDay(50)
rules = {
    "adult": standard,
    "student": GraceDays(3, standard),
}
charge_sheet([
    ("Dom Casmurro", "adult", 5),
    ("Iracema", "student", 5),
    ("O Cortiço", "adult", 40),
], rules)
```

```
ana@laptop:~/patterns/solid-1$ python3 main.py
Dom Casmurro        adult      5 days late    250
Iracema             student    5 days late    100
O Cortiço           adult     40 days late   2000
total                                         2350
```

## Children's fines are capped

The library introduces the child membership, with a rule that no child's fine goes above 1000
cents however late the book is. That rule is a new class in a new file, built the way `GraceDays`
was, around another rule:

```python
# capped.py
from policies import FinePolicy


class Capped:
    def __init__(self, most: int, then: FinePolicy):
        self.most = most
        self.then = then

    def fine(self, days_late: int) -> int:
        return min(self.then.fine(days_late), self.most)
```

And the wiring learns about it. This is the whole of `main.py` again, with one import, one entry in
the table and one loan added:

```python
# main.py
from capped import Capped
from charges import charge_sheet
from policies import GraceDays, PerDay

standard = PerDay(50)
rules = {
    "adult": standard,
    "student": GraceDays(3, standard),
    "child": Capped(1000, standard),
}
charge_sheet([
    ("Dom Casmurro", "adult", 5),
    ("Iracema", "student", 5),
    ("O Cortiço", "adult", 40),
    ("O Menino Maluquinho", "child", 40),
], rules)
```

```
ana@laptop:~/patterns/solid-1$ python3 main.py
Dom Casmurro        adult      5 days late    250
Iracema             student    5 days late    100
O Cortiço           adult     40 days late   2000
O Menino Maluquinho child     40 days late   1000
total                                         3350
```

Forty days late costs an adult 2000 cents and a child 1000, the cap. **`charges.py` and
`policies.py` were not opened, so every test that passed against them still describes them
exactly.** The new behaviour lives in `capped.py`, which can be tested on its own with nothing but
integers, and in three lines of wiring.

## The same shape in the other languages

The protocol is the part that varies most between languages. In Java, `FinePolicy` is an
`interface` and `Capped` says `implements FinePolicy`; in Go and TypeScript, `Capped` satisfies the
interface by having the method, as it does here. Because `FinePolicy` has a single method, all
four languages could also use a plain function: a `func(int) int` in Go, a lambda in Java, an arrow
function in TypeScript. The table of rules would then hold functions, and `charges.py` would call
`rules[kind](days_late)`. The principle does not care which: the closed code depends on a shape,
and new cases arrive as new things of that shape.

`main.py` is the one file that knows every rule by name. Lesson 5 gives that file a name, the
composition root, and makes it the deliberate home for exactly this kind of change.
