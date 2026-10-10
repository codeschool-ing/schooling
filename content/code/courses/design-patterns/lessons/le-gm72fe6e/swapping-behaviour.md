---
title: Swapping behaviour while the program runs
version: 1
---

**A class is fixed when an object is made; a part held in a field can be replaced at any moment.**
That is the property of composition no amount of careful inheritance can give you. An object built
from parts can change what it does without changing what it is.

The common belief here is that subclassing is how you vary behaviour, and that a different fine
rule therefore means a different kind of loan: `StudentLoan(Loan)` overriding `fine`. It works
until the rule has to change for a loan that already exists. The library declares an amnesty week,
and every open loan's fine has to become zero, today, for the loans already out on the shelves. An
object cannot become an instance of another class (Python will let you assign `__class__`, and
nobody should), so the subclass design has to rebuild every loan. With the rule in a field, the
amnesty is an assignment.

## A loan that holds its fine rule

```schooling-example
{"language": "python", "file": "fines.py", "parts": [
 {"code": "# fines.py\nfrom datetime import date, timedelta\nfrom typing import Protocol\n\n\nclass FinePolicy(Protocol):\n    def fine(self, days_late: int) -> int: ...", "note": "What a fine rule must offer: given the days late, a number of cents. Days late can be negative, for a loan back early."},
 {"code": "\n\nclass PerDay:\n    def __init__(self, cents: int):\n        self.cents = cents\n\n    def fine(self, days_late: int) -> int:\n        return max(days_late, 0) * self.cents", "note": "The library's standard rule, with the price per day as a value rather than a constant baked into the class."},
 {"code": "\n\nclass GraceDays:\n    def __init__(self, free: int, then: FinePolicy):\n        self.free = free\n        self.then = then\n\n    def fine(self, days_late: int) -> int:\n        return self.then.fine(days_late - self.free)", "note": "Students get three days' grace. This rule does not compute a fine at all: it subtracts the free days and hands the rest to another rule. Parts can hold parts."},
 {"code": "\n\nclass Amnesty:\n    def fine(self, days_late: int) -> int:\n        return 0", "note": "The amnesty week, as a rule like any other."},
 {"code": "\n\nclass Loan:\n    def __init__(self, title: str, lent_on: date, days: int, policy: FinePolicy):\n        self.title = title\n        self.due = lent_on + timedelta(days=days)\n        self.policy = policy\n\n    def fine(self, returned_on: date) -> int:\n        return self.policy.fine((returned_on - self.due).days)", "note": "The loan works out how late it is, because that is a fact about the loan. What lateness costs is the policy's business."},
 {"code": "\n\nif __name__ == \"__main__\":\n    standard = PerDay(50)\n    loans = [\n        Loan(\"Dom Casmurro\", date(2026, 3, 2), 14, standard),\n        Loan(\"Vidas Secas\", date(2026, 3, 2), 14, GraceDays(3, standard)),\n        Loan(\"Central do Brasil\", date(2026, 3, 10), 7, standard),\n    ]\n    back = date(2026, 3, 21)\n    for loan in loans:\n        print(f\"{loan.title:<18} due {loan.due}  fine {loan.fine(back):>3}\")", "note": "An adult's book, a student's book and a film, all back on 21 March."},
 {"code": "    for loan in loans:\n        loan.policy = Amnesty()\n    print(\"amnesty week:\", [loan.fine(back) for loan in loans])", "note": "The same three objects, each given a new rule. Nothing is rebuilt."}
]}
```

```
ana@laptop:~/patterns/composition$ python3 fines.py
Dom Casmurro       due 2026-03-16  fine 250
Vidas Secas        due 2026-03-16  fine 100
Central do Brasil  due 2026-03-17  fine 200
amnesty week: [0, 0, 0]
```

The adult is five days late at 50 cents, 250. The student is also five days late, minus three days'
grace, 100. The film is due a day later and costs 200. Then the amnesty: the same three loans, the
same titles and due dates, and every fine zero.

Look at what `GraceDays` did. It is a rule built out of another rule, so a student rate during a
fine increase is `GraceDays(3, PerDay(75))`, written where the loan is made, without a class called
`StudentIncreasedFineLoan`. **This is how composition answers the class explosion: options combine
when objects are built, instead of when classes are written.**

## The same seam makes the loan testable

A part handed in from outside can be replaced by a test as easily as by the amnesty week. To check
that a loan works out its lateness correctly, a test hands it a rule that records what it was asked
and answers something no real rule would:

```python
# test_fines.py
import unittest
from datetime import date

from fines import Loan


class Recording:
    def __init__(self):
        self.asked: list[int] = []

    def fine(self, days_late: int) -> int:
        self.asked.append(days_late)
        return 999


class LoanTest(unittest.TestCase):
    def test_passes_the_days_late_to_its_policy(self):
        policy = Recording()
        loan = Loan("Iracema", date(2026, 3, 2), 14, policy)
        self.assertEqual(loan.fine(date(2026, 3, 20)), 999)
        self.assertEqual(policy.asked, [4])
```

```
ana@laptop:~/patterns/composition$ python3 -m unittest -v test_fines.py
test_passes_the_days_late_to_its_policy (test_fines.LoanTest.test_passes_the_days_late_to_its_policy) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

The time on the `Ran` line depends on your machine and will differ from this one. `Recording` is a
test double, the spy of `testing-cicd` lesson 2, and it needed no mocking library: the loan accepts
anything with a `fine` method. With `fine` written into a subclass, the test would have to compute a
real fine and work backwards from it.

## Functions are parts too

`Amnesty` is a class with one method that ignores its argument. In Python a plain function could
play the same role, if `Loan` called `self.policy(days)` instead of `self.policy.fine(days)`; Go
and TypeScript pass functions just as easily, and Java has lambdas for single-method interfaces.
Lesson 6 shows several patterns shrinking to a function this way. The design is the same either
way: the loan holds the behaviour that varies, and the behaviour can be swapped.
