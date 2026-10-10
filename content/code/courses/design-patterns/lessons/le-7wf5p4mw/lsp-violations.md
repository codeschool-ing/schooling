---
title: Three ways a child breaks a promise
version: 1
---

**A substitution failure has one of three shapes: the child refuses something the parent accepted,
returns something the parent ruled out, or lets the object get into a state the parent never
allowed.** The last section showed the first. This one shows the other two, then the test that
catches all three before a caller does.

The violations worth learning are the quiet ones. `ReferenceBook` raised an exception, which at
least stops the program at the line that is wrong. The two below run to completion and print a
wrong answer, which is the shape a production bug usually takes.

## A due date that is not later

The library starts lending laptops for use inside the building, due back the same day. It is an
item, it is lent, so it looks like an `Item` with a loan of zero days:

```python
# laptop.py
from items import Item


class Laptop(Item):
    loan_days = 0
```

Nothing is overridden and nothing raises. But `lend` promised a due date *later* than the day of
lending, and `Laptop` returns the same day. That is a **weakened postcondition**. The callers
that break are the ones written trusting it: the reminder job that sends "due in two days"
by subtracting two days from the due date, or a report of loans that are out, which counts an item
as out while `today < due`. Lesson 1's `ReferenceBook` had `loan_days = 0` too. It was this
violation, waiting for a caller.

## The square that is a rectangle

The most quoted example is geometry, because it shows that an *is a* true in mathematics can be
false in code. Every square is a rectangle. But a mutable `Rectangle` promises something extra:
setting its width leaves its height alone.

```schooling-example
{"language": "python", "file": "shapes.py", "parts": [
 {"code": "# shapes.py\nclass Rectangle:\n    def __init__(self, width: int, height: int):\n        self._width = width\n        self._height = height\n\n    @property\n    def width(self) -> int:\n        return self._width\n\n    @width.setter\n    def width(self, value: int) -> None:\n        self._width = value\n\n    @property\n    def height(self) -> int:\n        return self._height\n\n    @height.setter\n    def height(self, value: int) -> None:\n        self._height = value\n\n    def area(self) -> int:\n        return self._width * self._height", "note": "Two sides that can be set independently. That independence is part of what a `Rectangle` is to the code that uses it."},
 {"code": "\n\nclass Square(Rectangle):\n    def __init__(self, side: int):\n        super().__init__(side, side)\n\n    def _set_side(self, value: int) -> None:\n        self._width = self._height = value\n\n    width = property(Rectangle.width.fget, _set_side)\n    height = property(Rectangle.height.fget, _set_side)", "note": "To stay square, setting either side sets both. Inside the class this is correct; it is the only way to keep the square's own invariant."},
 {"code": "\n\ndef widen(board: Rectangle) -> None:\n    height = board.height\n    board.width = 10\n    print(f\"{type(board).__name__:<9} height before {height}, after {board.height}, area {board.area()}\")", "note": "A caller that widens a notice board and expects its height to stay put, as any `Rectangle` promised."},
 {"code": "\n\nif __name__ == \"__main__\":\n    widen(Rectangle(4, 3))\n    widen(Square(3))"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 shapes.py
Rectangle height before 3, after 3, area 30
Square    height before 3, after 10, area 100
```

The rectangle comes out 10 by 3, area 30. The square, handed to the same function, comes out 10 by
10, area 100: the caller changed one side and the other moved. Neither class is wrong on its own
terms. **The square cannot keep both its own invariant and its parent's promise, so it is not a
substitute for a mutable rectangle.** An immutable one would be different: if `Rectangle` had no
setters, a square would break nothing, which is one reason lesson 15 prefers values that do not
change.

## A test written for the parent, run for every child

The tool that catches all three shapes is a **contract test**: the parent's promises written as
assertions once, and run against every class that claims to be the parent. It needs no knowledge
of the children beyond their names.

```python
# test_contract.py
import unittest
from datetime import date

from items import Book, Film, ReferenceBook
from laptop import Laptop


class ItemContract(unittest.TestCase):
    def test_lend_returns_a_later_due_date(self):
        lent_on = date(2026, 3, 2)
        for cls in (Book, Film, ReferenceBook, Laptop):
            with self.subTest(cls.__name__):
                self.assertGreater(cls("any title").lend(lent_on), lent_on)
```

`subTest` runs the body once per class and reports each failure separately, instead of stopping at
the first:

```
ana@laptop:~/patterns/solid-1$ python3 -m unittest test_contract.py
EF
======================================================================
ERROR: test_lend_returns_a_later_due_date (test_contract.ItemContract.test_lend_returns_a_later_due_date) [ReferenceBook]
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/test_contract.py", line 14, in test_lend_returns_a_later_due_date
    self.assertGreater(cls("any title").lend(lent_on), lent_on)
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/patterns/solid-1/items.py", line 26, in lend
    raise ValueError(f"{self.title!r} is for the reading room only")
ValueError: 'any title' is for the reading room only

======================================================================
FAIL: test_lend_returns_a_later_due_date (test_contract.ItemContract.test_lend_returns_a_later_due_date) [Laptop]
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/test_contract.py", line 14, in test_lend_returns_a_later_due_date
    self.assertGreater(cls("any title").lend(lent_on), lent_on)
AssertionError: datetime.date(2026, 3, 2) not greater than datetime.date(2026, 3, 2)

----------------------------------------------------------------------
Ran 1 test in 0.001s

FAILED (failures=1, errors=1)
```

Two children pass and two do not, and the report says which and how. `ReferenceBook` is an
**error**, the exception from the last section. `Laptop` is a **failure**: the due date came back
equal to the day of lending, the weakened postcondition. The time on the `Ran` line depends on your
machine and will differ.

A contract test is cheap to keep: a new child is one more name in the tuple, and a child that
breaks a promise fails the day it is written. In larger codebases the same idea appears as a base
test class that each child's tests inherit, one of the cases where inheritance fits as lesson 2
described it.

## Fixing the hierarchy, not the callers

Each of the three repairs is a change of what is claimed, never a check in a caller:

| child | the broken promise | the repair |
|---|---|---|
| `ReferenceBook` | precondition: refuses to lend | it is not lendable; do not make it claim to be |
| `Laptop` | postcondition: due the same day | change the parent's promise to "not earlier", if same-day loans are real, and check the callers |
| `Square` | invariant: sides move together | no inheritance between the two, or no setters on either |

The second repair shows that the parent's contract is a decision too. If same-day loans are part of
the library, the promise was wrong and gets weakened on purpose, with every caller read again. What
the principle forbids is a child weakening it quietly.
