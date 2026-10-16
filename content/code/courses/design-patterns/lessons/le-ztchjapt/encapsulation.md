---
title: Encapsulation: an object keeps its own promises
version: 1
---

**Encapsulation is often taught as "make the fields private", and that is the mechanism rather
than the idea.** The idea is that an object holds some state together with the rules that keep the
state sensible, and nothing outside can put it into a state the rules forbid. Private fields are
one way a language helps. The point is the promise.

Take a loan at the library this course uses as its running example. A loan has a due date, it can
be given back once, and a late return costs 50 cents a day. Those are three rules. If the due date
and the return date are loose variables that any part of the program can write, each of those
rules is a hope. **Every function that touches a loan has to remember all three, and the one that
forgets is where the bug lives.**

```schooling-example
{"language": "python", "file": "loan.py", "parts": [
 {"code": "# loan.py\nfrom datetime import date, timedelta", "note": "Dates come from the standard library, like everything in this course."},
 {"code": "\nclass Loan:\n    DAILY_FINE = 50  # cents", "note": "Money is a whole number of cents. A float would make 0.1 + 0.2 a problem the library's accounts have to explain."},
 {"code": "\n    def __init__(self, title: str, lent_on: date, days: int = 14):\n        self.title = title\n        self._lent_on = lent_on\n        self._due = lent_on + timedelta(days=days)\n        self._returned_on: date | None = None", "note": "The constructor is the one place the state is set up. The leading underscore is Python's way of saying *this is mine*: a convention, not a lock."},
 {"code": "\n    @property\n    def due(self) -> date:\n        return self._due", "note": "A property lets the outside read the due date with `loan.due` and gives it no way to write one."},
 {"code": "\n    def give_back(self, on: date) -> None:\n        if self._returned_on is not None:\n            raise ValueError(f\"{self.title!r} was already returned\")\n        if on < self._lent_on:\n            raise ValueError(\"a book cannot come back before it left\")\n        self._returned_on = on", "note": "The two rules about returning live here and nowhere else. A caller cannot get round them, because this method is the only door to `_returned_on`."},
 {"code": "\n    def fine(self, today: date) -> int:\n        end = self._returned_on or today\n        days_late = (end - self._due).days\n        return max(days_late, 0) * self.DAILY_FINE", "note": "The fine is computed, never stored. A stored fine is a second copy of the dates, and two copies disagree the day somebody updates one."},
 {"code": "\n\nif __name__ == \"__main__\":\n    loan = Loan(\"Dom Casmurro\", date(2026, 3, 2))\n    print(\"due:\", loan.due)\n    print(\"fine on 20 March:\", loan.fine(date(2026, 3, 20)))\n    loan.give_back(date(2026, 3, 18))\n    print(\"fine after return:\", loan.fine(date(2026, 4, 30)))\n    try:\n        loan.give_back(date(2026, 3, 19))\n    except ValueError as err:\n        print(\"refused:\", err)", "note": "The block under `if __name__ == \"__main__\"` runs when the file is run directly and not when another file imports it."}
]}
```

Save it as `loan.py` in a new directory, `~/patterns/oo`, and run it:

```
ana@laptop:~/patterns/oo$ python3 loan.py
due: 2026-03-16
fine on 20 March: 200
fine after return: 100
refused: 'Dom Casmurro' was already returned
```

Four days late on 20 March is 200 cents. Given back on 18 March, two days late, and the fine stops
moving: on 30 April it is still 100. The second return is refused with a sentence that says why.

## What the underscore does not do

Python does not enforce the underscore. Any code can write `loan._returned_on = None` and the
interpreter will let it. Java's `private`, C#'s `private` and TypeScript's `#field` make that a
compile error or a runtime one; Go makes a lower-case field invisible outside its package. **The
difference is real and smaller than it looks**: in every one of those languages a determined
caller gets in, through reflection or by editing the class. What all of them give you is a line
that a reader can see, and a code review can refuse to let anybody cross.

## The test of a good boundary

Ask what a caller has to know to use the object correctly. For `Loan` the answer is three
methods: `due`, `give_back` and `fine`. The caller does not know that the fine is 50 cents a day,
that the due date is computed from a loan length, or that "not returned" is stored as `None`. Each
of those can change without touching a single caller. **That is what encapsulation buys**, and it is
why lesson 3's single responsibility principle and lesson 12's aggregates are both, underneath,
arguments about where a boundary should go.

A boundary drawn badly looks like this: a class with a getter and a setter for every field. It has
the syntax of encapsulation and none of the promise, because every rule still has to be kept by
whoever calls the setters.
