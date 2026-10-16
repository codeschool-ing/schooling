---
title: Constructor injection: ask for what you need
version: 1
---

**Constructor injection means a class receives every object it depends on as an argument of its
constructor, and builds none of them itself.** That is the whole technique. It needs no library,
no decorator and no framework, which surprises people who met the term next to Spring or Angular
and assumed it was something those tools do. The tools automate it; the idea is one parameter list.

Start from the version most code begins as. The library sends a notice for every overdue loan, and
the first draft of that job reaches out and grabs whatever it needs:

```python
class OverdueNotices:
    def send_all(self) -> int:
        today = date.today()
        notifier = SmtpNotifier("smtp.example.org")
        loans = LoanTable(sqlite3.connect("library.db"))
        for loan in loans.open_loans():
            ...
```

Three decisions are buried in that method: which day it is, how members are reached, and where
loans are kept. None of them is the job's business, and each one makes the class harder to use.
You cannot run it against a test database, you cannot see what it would send on 20 March without
waiting for 20 March, and every run talks to a mail server. The class is tied to its collaborators
by the `new`, or in Python by the call to the class.

## The same job, handed its collaborators

```schooling-example
{"language": "python", "file": "overdue.py", "parts": [
 {"code": "# overdue.py\nfrom dataclasses import dataclass\nfrom datetime import date\nfrom typing import Protocol\n\n\n@dataclass(frozen=True)\nclass Loan:\n    member: str\n    title: str\n    due: date", "note": "A loan here carries only what this job reads. It is frozen, so nothing the job does can change it."},
 {"code": "\n\nclass LoanStore(Protocol):\n    def open_loans(self) -> list[Loan]: ...\n\n\nclass Notifier(Protocol):\n    def send(self, member: str, text: str) -> None: ...\n\n\nclass Clock(Protocol):\n    def today(self) -> date: ...", "note": "Three protocols, one per decision the first draft buried. The clock is one of them: \"what day is it\" is a dependency like any other, and the most often forgotten."},
 {"code": "\n\nclass OverdueNotices:\n    DAILY_FINE = 50  # cents\n\n    def __init__(self, loans: LoanStore, notifier: Notifier, clock: Clock):\n        self._loans = loans\n        self._notifier = notifier\n        self._clock = clock", "note": "The constructor is the injection. It stores what it was given and does nothing else: no connections opened, no files read."},
 {"code": "\n    def send_all(self) -> int:\n        today = self._clock.today()\n        sent = 0\n        for loan in self._loans.open_loans():\n            late = (today - loan.due).days\n            if late > 0:\n                fine = late * self.DAILY_FINE\n                self._notifier.send(\n                    loan.member, f\"'{loan.title}' is {late} days late, fine {fine} cents\")\n                sent += 1\n        return sent", "note": "The job itself now reads as the rule and nothing more: late loans get a notice with the fine in cents."},
 {"code": "\n\nclass ListedLoans:\n    def __init__(self, loans: list[Loan]):\n        self._loans = list(loans)\n\n    def open_loans(self) -> list[Loan]:\n        return list(self._loans)\n\n\nclass FixedClock:\n    def __init__(self, day: date):\n        self._day = day\n\n    def today(self) -> date:\n        return self._day\n\n\nclass PrintNotifier:\n    def send(self, member: str, text: str) -> None:\n        print(f\"to {member}: {text}\")", "note": "Three small implementations, one per protocol. None of them knows `OverdueNotices` exists."},
 {"code": "\n\nif __name__ == \"__main__\":\n    loans = ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16)),\n        Loan(\"Caio\", \"Vidas Secas\", date(2026, 3, 25)),\n        Loan(\"Duda\", \"Central do Brasil\", date(2026, 3, 11)),\n    ])\n    notices = OverdueNotices(loans, PrintNotifier(), FixedClock(date(2026, 3, 20)))\n    print(\"sent:\", notices.send_all())", "note": "Whoever builds the job chooses its collaborators. Here that is the block at the bottom of the file, and it picks a fixed day so the output is the same every time it runs."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 overdue.py
to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
to Duda: 'Central do Brasil' is 9 days late, fine 450 cents
sent: 2
```

Bia's book was due on 16 March, so on the 20th it is four days late and 200 cents. Caio's is not
due yet. Duda's film was due on the 11th, nine days and 450 cents. The job decided none of that
date: it was told.

## What the constructor buys

**The constructor's parameter list is now a complete, honest list of what the class needs.** A
reader sees three collaborators without opening the method. A caller cannot forget one, because
Python refuses to build `OverdueNotices` with two arguments. And the object is usable the moment it
exists: there is no half-built state in which it has a store but no notifier.

That last property is why constructor injection is the default form, and the forms in the next
section are for the cases it does not fit. It also gives a warning sign for free. A constructor that
takes seven collaborators is not an injection problem: it is a class doing seven things, and
lesson 3's single responsibility principle is the conversation to have about it.

## The same move in your language

| | how the job asks for its clock |
|---|---|
| Python | `clock: Clock`, a protocol; or a plain function, as the next section shows |
| Java | `java.time.Clock` in the constructor, with `Clock.fixed(...)` in tests |
| Go | a field `now func() time.Time` set by a `NewOverdueNotices(...)` function |
| TypeScript | `constructor(private readonly clock: Clock)` with an interface `Clock` |

Java's standard library ships the clock abstraction because this need is so common: every
`LocalDate.now()` has an overload `LocalDate.now(clock)`. Go has no constructors, so the
convention is a function named `New…` that takes the dependencies and returns the struct; the
idea is identical.
