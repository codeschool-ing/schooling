---
title: Splitting a class along its actors
version: 1
---

**To apply the single responsibility principle, list who asks for changes to a class, then give
each of them a piece of code of their own and a small function that puts the pieces together.** The
behaviour stays exactly the same. What changes is where the next request lands.

The mistake to avoid is splitting by size. A long class is not necessarily doing two jobs, and a
short one can be doing three. The class in this section is under twenty lines long and answers to three
different people.

## A report with three owners

Every morning the library mails the fines office a list of overdue loans. One class does it:

```python
# report_service.py
from datetime import date, timedelta


class ReportService:
    def __init__(self, loans: list[tuple[str, str, date]]):
        self.loans = loans

    def run(self, today: date) -> None:
        lines, total = [], 0
        for title, member, lent_on in self.loans:
            late = (today - (lent_on + timedelta(days=14))).days
            if late > 0:
                total += late * 50
                lines.append(f"{title:<16}{member:<20}{late * 50:>6}")
        lines.append(f"{'total':<36}{total:>6}")
        print("To: fines@example.org")
        print("Subject: overdue loans on", today.isoformat())
        print()
        print("\n".join(lines))


if __name__ == "__main__":
    ReportService([
        ("Dom Casmurro", "bia@example.org", date(2026, 3, 2)),
        ("Iracema", "caio@example.org", date(2026, 3, 20)),
        ("Vidas Secas", "duda@example.org", date(2026, 3, 9)),
    ]).run(date(2026, 4, 1))
```

```
ana@laptop:~/patterns/solid-1$ python3 report_service.py
To: fines@example.org
Subject: overdue loans on 2026-04-01

Dom Casmurro    bia@example.org        800
Vidas Secas     duda@example.org       450
total                                 1250
```

Read `run` and ask who would ask for each line to change. The 14 and the 50 belong to the **fines
office**. The column widths and the total line belong to whoever **reads** the report, the desk
coordinator, who has already asked for a spreadsheet instead. The `To:` and `Subject:` belong to
**IT**, who will one day replace printing with a real mail server. Three actors, one method, and a
change for any of them means editing the code the other two depend on.

## The same report, in three pieces

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Dom Casmurro\", \"bia@example.org\", date(2026, 3, 2)),\n    (\"Iracema\", \"caio@example.org\", date(2026, 3, 20)),\n    (\"Vidas Secas\", \"duda@example.org\", date(2026, 3, 9)),\n]", "note": "The same three loans, kept in the module so the next program can reuse them."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Overdue:\n    title: str\n    member: str\n    cents: int", "note": "What the pieces hand each other: one overdue loan and its fine. A small value is the boundary between them."},
 {"code": "\n\nclass FineCalculator:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def overdue(self, loans: list[tuple[str, str, date]], today: date) -> list[Overdue]:\n        rows = []\n        for title, member, lent_on in loans:\n            late = (today - (lent_on + timedelta(days=self.LOAN_DAYS))).days\n            if late > 0:\n                rows.append(Overdue(title, member, late * self.DAILY_FINE))\n        return rows", "note": "The fines office's piece. It knows the rules and nothing about columns or mail."},
 {"code": "\n\nclass TextReport:\n    def render(self, rows: list[Overdue]) -> str:\n        lines = [f\"{r.title:<16}{r.member:<20}{r.cents:>6}\" for r in rows]\n        lines.append(f\"{'total':<36}{sum(r.cents for r in rows):>6}\")\n        return \"\\n\".join(lines)", "note": "The reader's piece. It turns rows into text and does not know how a fine is computed."},
 {"code": "\n\nclass ConsoleMailer:\n    def send(self, to: str, subject: str, body: str) -> None:\n        print(\"To:\", to)\n        print(\"Subject:\", subject)\n        print()\n        print(body)", "note": "IT's piece. Printing stands in for a mail server, and replacing it touches nothing above."},
 {"code": "\n\ndef send_overdue_report(today: date, calculator: FineCalculator, report, mailer) -> None:\n    rows = calculator.overdue(LOANS, today)\n    mailer.send(\"fines@example.org\", f\"overdue loans on {today.isoformat()}\", report.render(rows))", "note": "Two lines that put the pieces together. This function owns the order of the steps and none of their details."},
 {"code": "\n\nif __name__ == \"__main__\":\n    send_overdue_report(date(2026, 4, 1), FineCalculator(), TextReport(), ConsoleMailer())"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 report.py
To: fines@example.org
Subject: overdue loans on 2026-04-01

Dom Casmurro    bia@example.org        800
Vidas Secas     duda@example.org       450
total                                 1250
```

Byte for byte the same output. Splitting along actors is a refactoring: nothing a user sees changes.

## The coordinator's spreadsheet

Now the request arrives: the coordinator wants rows they can paste into a spreadsheet. With the
pieces apart, it is a new piece and nothing else:

```python
# csv_report.py
from datetime import date

from report import ConsoleMailer, FineCalculator, Overdue, send_overdue_report


class CsvReport:
    def render(self, rows: list[Overdue]) -> str:
        lines = ["title,member,cents"]
        lines += [f"{r.title},{r.member},{r.cents}" for r in rows]
        return "\n".join(lines)


if __name__ == "__main__":
    send_overdue_report(date(2026, 4, 1), FineCalculator(), CsvReport(), ConsoleMailer())
```

```
ana@laptop:~/patterns/solid-1$ python3 csv_report.py
To: fines@example.org
Subject: overdue loans on 2026-04-01

title,member,cents
Dom Casmurro,bia@example.org,800
Vidas Secas,duda@example.org,450
```

`report.py` was not edited, so the fines rules and the mail code cannot have been broken by this
change. **That is what the principle buys: a request from one actor reaches only that actor's
code.** A test of `FineCalculator` can now check fines by comparing lists of `Overdue` values, with
no output to parse and no mail to intercept.

Notice also that the CSV report was added without editing anything. That is the next principle,
arriving early because the split made room for it.

## How far to split

Three actors gave three pieces. A fourth class for the total line, or one per column, would answer
to the same coordinator as `TextReport` and buy nothing. In Java or Go these three would usually be
three files, or three types in one package; in Python a module with three small classes is normal.
The principle cares about which code changes together, not about how many files it sits in.
