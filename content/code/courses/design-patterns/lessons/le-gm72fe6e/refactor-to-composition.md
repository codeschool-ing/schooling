---
title: Refactoring a hierarchy into parts
version: 1
---

**To turn a hierarchy into composition, find what varies between the subclasses and move each of
those things into a part the parent holds; then delete the subclasses.** Done in small steps with
a test run after each, the program behaves the same at every step.
Lesson 14 is about refactoring in general; this section is one refactoring, done once, end to end.

The tempting way is to write the composed version from scratch beside the old one and switch over.
That works for a file this size and fails for real code, because the old hierarchy holds decisions
nobody remembers making, and a rewrite drops them quietly. Steps that keep the tests green carry
every decision across.

## The hierarchy as it was found

Somebody built loans by subclassing, one axis at a time. Films came first, then the student rate,
then the student rate for films:

```python
# loans.py
from datetime import date, timedelta


class Loan:
    days = 14

    def __init__(self, title: str, lent_on: date):
        self.title = title
        self.due = lent_on + timedelta(days=self.days)

    def fine(self, returned_on: date) -> int:
        return max((returned_on - self.due).days, 0) * 50


class FilmLoan(Loan):
    days = 7


class StudentLoan(Loan):
    def fine(self, returned_on: date) -> int:
        return max((returned_on - self.due).days - 3, 0) * 50


class StudentFilmLoan(FilmLoan):
    def fine(self, returned_on: date) -> int:
        return max((returned_on - self.due).days - 3, 0) * 50


def open_loan(title: str, lent_on: date, film: bool = False, student: bool = False) -> Loan:
    if film and student:
        return StudentFilmLoan(title, lent_on)
    if film:
        return FilmLoan(title, lent_on)
    if student:
        return StudentLoan(title, lent_on)
    return Loan(title, lent_on)
```

Four classes for two axes, and `StudentFilmLoan.fine` is a copy of `StudentLoan.fine`, because it
needed the film's parent for `days` and the student's method for the fine, and single inheritance
offers one parent. That copy is the class explosion beginning.

## First, pin the behaviour

Before moving anything, write down what the code does now, through the one door every caller uses,
`open_loan`. These tests do not care which classes exist; that is what lets them survive the
refactoring.

```python
# test_loans.py
import unittest
from datetime import date

from loans import open_loan

LENT = date(2026, 3, 2)
BACK = date(2026, 3, 21)


class OpenLoanTest(unittest.TestCase):
    def test_book_for_an_adult(self):
        self.assertEqual(open_loan("Dom Casmurro", LENT).fine(BACK), 250)

    def test_film_for_an_adult(self):
        self.assertEqual(open_loan("Bacurau", LENT, film=True).fine(BACK), 600)

    def test_book_for_a_student(self):
        self.assertEqual(open_loan("Iracema", LENT, student=True).fine(BACK), 100)

    def test_film_for_a_student(self):
        loan = open_loan("Aquarius", LENT, film=True, student=True)
        self.assertEqual(loan.fine(BACK), 450)

    def test_back_early_costs_nothing(self):
        self.assertEqual(open_loan("Vidas Secas", LENT).fine(date(2026, 3, 10)), 0)
```

```
ana@laptop:~/patterns/composition$ python3 -m unittest -v test_loans.py
test_back_early_costs_nothing (test_loans.OpenLoanTest.test_back_early_costs_nothing) ... ok
test_book_for_a_student (test_loans.OpenLoanTest.test_book_for_a_student) ... ok
test_book_for_an_adult (test_loans.OpenLoanTest.test_book_for_an_adult) ... ok
test_film_for_a_student (test_loans.OpenLoanTest.test_film_for_a_student) ... ok
test_film_for_an_adult (test_loans.OpenLoanTest.test_film_for_an_adult) ... ok

----------------------------------------------------------------------
Ran 5 tests in 0.000s

OK
```

## The steps

1. Name what varies. Comparing the four classes, two things differ: the loan length (`days`)
   and the fine rule (with or without three days' grace). Everything else is shared.
2. Give the parent a field for each. `Loan.__init__` takes `days` and a `policy`, and `fine`
   asks the policy. The rules already exist as parts: `PerDay` and `GraceDays` in `fines.py`, from
   two sections back. Run the tests.
3. Make the factory pass parts instead of picking a class. `open_loan` works out the length and
   the rule and builds a plain `Loan`. Run the tests.
4. Delete the subclasses, which nothing constructs any more. Run the tests.

Here is the file at the end of step 4, with `fines.py` beside it in the same directory:

```python
# loans.py
from datetime import date, timedelta

from fines import FinePolicy, GraceDays, PerDay

STANDARD = PerDay(50)


class Loan:
    def __init__(self, title: str, lent_on: date, days: int, policy: FinePolicy):
        self.title = title
        self.due = lent_on + timedelta(days=days)
        self.policy = policy

    def fine(self, returned_on: date) -> int:
        return self.policy.fine((returned_on - self.due).days)


def open_loan(title: str, lent_on: date, film: bool = False, student: bool = False) -> Loan:
    days = 7 if film else 14
    policy = GraceDays(3, STANDARD) if student else STANDARD
    return Loan(title, lent_on, days, policy)
```

```
ana@laptop:~/patterns/composition$ python3 -m unittest -v test_loans.py
test_back_early_costs_nothing (test_loans.OpenLoanTest.test_back_early_costs_nothing) ... ok
test_book_for_a_student (test_loans.OpenLoanTest.test_book_for_a_student) ... ok
test_book_for_an_adult (test_loans.OpenLoanTest.test_book_for_an_adult) ... ok
test_film_for_a_student (test_loans.OpenLoanTest.test_film_for_a_student) ... ok
test_film_for_an_adult (test_loans.OpenLoanTest.test_film_for_an_adult) ... ok

----------------------------------------------------------------------
Ran 5 tests in 0.000s

OK
```

The same five tests, unchanged, pass against both files. **The test file never mentioned a
subclass, which is the only reason it could prove that deleting four of them changed nothing.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 330\" role=\"img\" data-fig=\"l02-refactor\" aria-label=\"Two class diagrams of loans.py. On the left, before: Loan with days = 14 and fine; FilmLoan sets days to 7 and StudentLoan overrides fine, both pointing up to Loan; StudentFilmLoan points up to FilmLoan and overrides fine with a copy of StudentLoan's method. Four classes, one method written twice. On the right, after: one Loan class with title, due and policy, holding a FinePolicy protocol drawn with a filled diamond; PerDay and GraceDays implement FinePolicy, and GraceDays itself holds another FinePolicy, the rule it hands the remaining days to.\"><text x=\"190.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">before: a class per combination</text><rect x=\"125.0\" y=\"40.0\" width=\"130.0\" height=\"67.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M125.0 62.5 L255.0 62.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"133.0\" y=\"73.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">days = 14</text><path d=\"M125.0 85.0 L255.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"133.0\" y=\"96.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"20.0\" y=\"160.0\" width=\"110.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FilmLoan</text><path d=\"M20.0 182.5 L130.0 182.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"28.0\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">days = 7</text><rect x=\"220.0\" y=\"160.0\" width=\"120.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">StudentLoan</text><path d=\"M220.0 182.5 L340.0 182.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"228.0\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"20.0\" y=\"245.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"256.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">StudentFilmLoan</text><path d=\"M20.0 267.5 L160.0 267.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"28.0\" y=\"278.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><path d=\"M75.0 160.0 L75.0 135.0 L190.0 135.0 L190.0 107.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M190.0 107.5 L197.0 119.5 L183.0 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><path d=\"M280.0 160.0 L280.0 135.0 L190.0 135.0 L190.0 107.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M190.0 107.5 L197.0 119.5 L183.0 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><path d=\"M75.0 245.0 L75.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M75.0 205.0 L82.0 217.0 L68.0 217.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"172.0\" y=\"261.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">fine() copied</text><text x=\"172.0\" y=\"274.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">from StudentLoan</text><path d=\"M390.0 20.0 L390.0 315.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"585.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">after: a loan holds its rule</text><rect x=\"410.0\" y=\"50.0\" width=\"130.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M410.0 72.5 L540.0 72.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"418.0\" y=\"83.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title</text><text x=\"418.0\" y=\"98.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">due</text><text x=\"418.0\" y=\"112.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">policy</text><path d=\"M410.0 124.0 L540.0 124.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"418.0\" y=\"135.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"600.0\" y=\"60.0\" width=\"140.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"71.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"670.0\" y=\"85.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FinePolicy</text><path d=\"M600.0 97.0 L740.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"608.0\" y=\"108.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine(days_late)</text><path d=\"M540.0 85.0 L600.0 85.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M540.0 85.0 L549.0 90.5 L558.0 85.0 L549.0 79.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><rect x=\"560.0\" y=\"220.0\" width=\"90.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"231.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PerDay</text><path d=\"M560.0 242.5 L650.0 242.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"253.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cents</text><rect x=\"670.0\" y=\"220.0\" width=\"90.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"715.0\" y=\"231.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">GraceDays</text><path d=\"M670.0 242.5 L760.0 242.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"678.0\" y=\"253.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">free</text><text x=\"678.0\" y=\"268.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">then</text><path d=\"M605.0 220.0 L605.0 185.0 L670.0 185.0 L670.0 119.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M670.0 119.5 L677.0 131.5 L663.0 131.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M715.0 220.0 L715.0 185.0 L670.0 185.0 L670.0 119.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M670.0 119.5 L677.0 131.5 L663.0 131.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M760.0 262.0 L772.0 262.0 L772.0 90.0 L740.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M760.0 262.0 L769.0 267.5 L778.0 262.0 L769.0 256.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><text x=\"475.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">open_loan()</text><text x=\"475.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">picks the parts</text><text x=\"585.0\" y=\"305.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a new option is a new part, not a new class</text></svg>", "caption": "The same loans before and after the refactoring. The axes that multiplied classes on the left are fields holding parts on the right."}
```

## What the new shape buys

The duplicated student rule is gone: there is one `GraceDays`, and both a student's book and a
student's film hold it. The axes have stopped multiplying. A third kind of item with a 21-day
loan is a new number in `open_loan`; a fine increase is `PerDay(75)`; the amnesty week from two
sections back works on these loans unchanged, because they hold their rule in the same field.

One choice moved, and it is worth noticing where. The `if` chain that picked a class became two
small expressions that pick parts, still in `open_loan`. Deciding which parts an object gets has to
happen somewhere, and gathering it in one function is the start of what lesson 5 calls a
composition root.

`isinstance(loan, StudentLoan)` no longer answers anything, so any code that asked it has to ask a
part instead. Search for such checks before step 4; in this file there were none, and the tests
would not have found one in another file.
