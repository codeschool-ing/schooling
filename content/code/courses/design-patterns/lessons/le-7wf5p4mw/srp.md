---
title: "Single responsibility: one reason to change"
version: 1
---

**The single responsibility principle says that a module should have one reason to change, and a
reason to change is a person or a group who asks for changes.** Martin's later wording makes the
people explicit: a module should be responsible to one actor. Code that answers to two actors will
one day be changed for the first and break for the second.

The usual reading is "a class should do one thing", and it sounds the same and leads somewhere
else. *Do one thing* is good advice for a function, and applied to classes it produces dozens of
one-method classes split by verb. The principle is about who asks. A class with six methods that
all change when the fines office changes its rules has one responsibility. A class with two methods,
one the fines office owns and one the statistics team owns, has two.

## Two actors, one helper

Make `~/patterns/solid-1` and work there for this lesson:

```sh
mkdir -p ~/patterns/solid-1
cd ~/patterns/solid-1
```

The loan desk computes fines for the fines office, and the average number of days a loan is out for
the statistics team, which uses it to decide how many copies of a title to buy. Both need to know
how long a loan lasted, so both use one helper:

```schooling-example
{"language": "python", "file": "desk.py", "parts": [
 {"code": "# desk.py\nfrom datetime import date\n\n\ndef days_counted(lent_on: date, back_on: date) -> int:\n    return (back_on - lent_on).days", "note": "The shared helper: calendar days between lending and return."},
 {"code": "\n\nclass LoanDesk:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def __init__(self, loans: dict[str, tuple[date, date]]):\n        self.loans = loans", "note": "Each loan is a title with the day it went out and the day it came back."},
 {"code": "\n    def fine(self, title: str) -> int:\n        lent_on, back_on = self.loans[title]\n        late = days_counted(lent_on, back_on) - self.LOAN_DAYS\n        return max(late, 0) * self.DAILY_FINE", "note": "The fines office's method. Fourteen days are free; each day after costs 50 cents."},
 {"code": "\n    def average_days_out(self) -> float:\n        days = [days_counted(lent_on, back_on) for lent_on, back_on in self.loans.values()]\n        return round(sum(days) / len(days), 1)", "note": "The statistics team's method, built on the same helper because it looked like the same question."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = LoanDesk({\n        \"Dom Casmurro\": (date(2026, 3, 2), date(2026, 3, 21)),\n        \"Iracema\": (date(2026, 3, 4), date(2026, 3, 12)),\n        \"Vidas Secas\": (date(2026, 3, 9), date(2026, 3, 30)),\n    })\n    print(\"fine for Dom Casmurro:\", desk.fine(\"Dom Casmurro\"))\n    print(\"average days out:     \", desk.average_days_out())"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 desk.py
fine for Dom Casmurro: 250
average days out:      16.0
```

Dom Casmurro was out 19 days, five of them late, so 250 cents. The three loans average 16 days.

## The change one actor asked for

The fines office decides that a Sunday, when the library is shut, should not count against a
borrower: nobody could have brought the book back. A developer makes the change where the counting
happens, which is the obvious place:

```schooling-example
{"language": "python", "file": "desk.py", "parts": [
 {"code": "# desk.py\nfrom datetime import date, timedelta\n\n\ndef days_counted(lent_on: date, back_on: date) -> int:\n    days, day = 0, lent_on\n    while day < back_on:\n        day += timedelta(days=1)\n        if day.weekday() != 6:  # the library is shut on Sundays\n            days += 1\n    return days", "note": "The only change: count each day after lending, skipping Sundays. `weekday()` is 6 for a Sunday."},
 {"code": "\n\nclass LoanDesk:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def __init__(self, loans: dict[str, tuple[date, date]]):\n        self.loans = loans\n\n    def fine(self, title: str) -> int:\n        lent_on, back_on = self.loans[title]\n        late = days_counted(lent_on, back_on) - self.LOAN_DAYS\n        return max(late, 0) * self.DAILY_FINE\n\n    def average_days_out(self) -> float:\n        days = [days_counted(lent_on, back_on) for lent_on, back_on in self.loans.values()]\n        return round(sum(days) / len(days), 1)\n\n\nif __name__ == \"__main__\":\n    desk = LoanDesk({\n        \"Dom Casmurro\": (date(2026, 3, 2), date(2026, 3, 21)),\n        \"Iracema\": (date(2026, 3, 4), date(2026, 3, 12)),\n        \"Vidas Secas\": (date(2026, 3, 9), date(2026, 3, 30)),\n    })\n    print(\"fine for Dom Casmurro:\", desk.fine(\"Dom Casmurro\"))\n    print(\"average days out:     \", desk.average_days_out())", "note": "Everything else is as it was."}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 desk.py
fine for Dom Casmurro: 150
average days out:      14.0
```

The fine dropped to 150, two Sundays fewer, which is what the fines office asked for. The average
dropped from 16.0 to 14.0, which nobody asked for. **The statistics team's number changed because
of a decision made in another department, and no test of theirs ran, because nothing of theirs was
edited.** Next quarter they buy fewer copies of the popular titles than they would have.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l03-actors\" aria-label=\"Two actors and one class. The fines office asks for changes to LoanDesk.fine; the statistics team asks for changes to LoanDesk.average_days_out. Both methods call the same helper, days_counted. The helper is edited for the fines office to skip Sundays, and the change travels through the shared helper into the statistics team's method, whose average drops from 16.0 to 14.0 without anybody on that team asking.\"><defs><marker id=\"l03-actors-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"53.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fines office</text><rect x=\"20.0\" y=\"173.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">statistics team</text><rect x=\"225.0\" y=\"30.0\" width=\"230.0\" height=\"210.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"340.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LoanDesk</text><rect x=\"245.0\" y=\"75.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fine()</text><rect x=\"245.0\" y=\"175.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">average_days_out()</text><path d=\"M160.0 70.0 L160.0 90.0 L241.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><path d=\"M160.0 190.0 L241.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><text x=\"200.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">asks for changes</text><rect x=\"520.0\" y=\"123.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">days_counted()</text><path d=\"M435.0 90.0 L600.0 90.0 L600.0 119.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><path d=\"M435.0 190.0 L600.0 190.0 L600.0 161.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><text x=\"600.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">edited to skip Sundays,</text><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">for the fines office</text><text x=\"340.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">16.0 becomes 14.0, unasked</text></svg>", "caption": "One helper serving two actors. A change one of them asked for reaches the other through the code they share."}
```

## Same code is not the same reason

The helper was shared because two computations looked alike: days between two dates. They were
alike by accident. One is a question about what is fair to charge, owned by the fines office; the
other is a question about how long books are physically away, owned by the statistics team. The day
their answers diverged, the shared code became a channel through which one team's change leaked
into the other's.

The repair is to let each actor own its own code: a `fine_days` for the fines office and a
`calendar_days` for the statistics team, even though they start identical. That looks like
duplication, and it is the right kind. **Two pieces of code that change for different reasons are
not duplicates, however similar they look today.** The next section splits a larger class along
the same line.
