---
title: Fine notices behind a Notifier
version: 1
---

**The inverted design has three files with three jobs: the rules and the protocol they own, the
adapters that fit the protocol, and a short file that connects one to the other.** The rules import
nothing of the library's own. The adapters import the rules' protocol. Only the connecting file
knows both.

You may expect the inverted version to be longer and more abstract than the obvious one. It is a
few lines longer. It is not more abstract: every name in it is a word the library uses, and the one
protocol has one method.

## The rules, with the protocol they need

```schooling-example
{"language": "python", "file": "notices.py", "parts": [
 {"code": "# notices.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\nfrom typing import Protocol", "note": "Standard library only. Nothing here mentions e-mail, SMS or paper."},
 {"code": "\n\nclass Notifier(Protocol):\n    def notify(self, member: str, text: str) -> None: ...", "note": "The port. It lives in this module because the rules own it: its name and its one method are what the rules want, not what any gateway offers."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    member: str\n    lent_on: date", "note": "A loan as the rules see it."},
 {"code": "\n\nclass OverdueNotices:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def __init__(self, notifier: Notifier):\n        self.notifier = notifier", "note": "The rules are handed a notifier. They do not build one, so they cannot depend on which."},
 {"code": "\n    def send(self, loans: list[Loan], today: date) -> int:\n        sent = 0\n        for loan in loans:\n            late = (today - loan.lent_on - timedelta(days=self.LOAN_DAYS)).days\n            if late > 0:\n                cents = late * self.DAILY_FINE\n                self.notifier.notify(loan.member, f\"'{loan.title}' is {late} days late, {cents} cents so far\")\n                sent += 1\n        return sent", "note": "The whole policy: who is late, by how much, what it costs, and that they are told. It returns how many notices went out, which is what a caller or a test wants to know."}
]}
```

## The adapters

```python
# adapters.py
from notices import Notifier


class EmailNotifier(Notifier):
    def __init__(self, addresses: dict[str, str]):
        self.addresses = addresses

    def notify(self, member: str, text: str) -> None:
        print(f"e-mail to {self.addresses[member]}: {text}")


class SmsNotifier(Notifier):
    def __init__(self, phones: dict[str, str]):
        self.phones = phones

    def notify(self, member: str, text: str) -> None:
        print(f"SMS to {self.phones[member]}: {text}")
```

Printing stands in for the real gateways, as `ConsoleMailer` did in lesson 3. Each adapter names
`Notifier` as its parent. A Python protocol does not require that, and the classes would fit by
shape alone; naming it makes the direction visible in the code, the way Java's `implements` would.

## The wiring

```python
# main.py
from datetime import date

from adapters import EmailNotifier
from notices import Loan, OverdueNotices

LOANS = [
    Loan("Dom Casmurro", "Bia", date(2026, 3, 2)),
    Loan("Iracema", "Caio", date(2026, 3, 20)),
    Loan("Vidas Secas", "Duda", date(2026, 3, 9)),
]

if __name__ == "__main__":
    notifier = EmailNotifier({
        "Bia": "bia@example.org",
        "Caio": "caio@example.org",
        "Duda": "duda@example.org",
    })
    sent = OverdueNotices(notifier).send(LOANS, date(2026, 4, 1))
    print(sent, "notices sent")
```

```
ana@laptop:~/patterns/solid-2$ python3 main.py
e-mail to bia@example.org: 'Dom Casmurro' is 16 days late, 800 cents so far
e-mail to duda@example.org: 'Vidas Secas' is 9 days late, 450 cents so far
2 notices sent
```

Iracema was lent on 20 March and is not due until 3 April, so two of the three loans get a notice.

## The arrows, read off the files

The direction of a dependency is a fact you can check without a diagram. List the imports:

```
ana@laptop:~/patterns/solid-2$ grep -n import notices.py adapters.py main.py
notices.py:2:from dataclasses import dataclass
notices.py:3:from datetime import date, timedelta
notices.py:4:from typing import Protocol
adapters.py:2:from notices import Notifier
main.py:2:from datetime import date
main.py:4:from adapters import EmailNotifier
main.py:5:from notices import Loan, OverdueNotices
```

`notices.py` imports three standard modules and nothing from this directory. `adapters.py` imports
from `notices.py`: **the detail depends on the policy, which is the inversion.** `main.py` imports
both, because deciding which adapter the rules get is its job. Switching every notice to SMS is a
change to `main.py` alone.

## The rules, tested with nothing behind them

Because the rules own the port, a test can hand them anything with a `notify` method:

```python
# test_notices.py
import unittest
from datetime import date

from notices import Loan, OverdueNotices


class Recording:
    def __init__(self):
        self.sent: list[tuple[str, str]] = []

    def notify(self, member: str, text: str) -> None:
        self.sent.append((member, text))


class OverdueNoticesTest(unittest.TestCase):
    def test_only_late_loans_get_a_notice(self):
        notifier = Recording()
        loans = [Loan("Iracema", "Caio", date(2026, 3, 20)),
                 Loan("Vidas Secas", "Duda", date(2026, 3, 9))]
        sent = OverdueNotices(notifier).send(loans, date(2026, 4, 1))
        self.assertEqual(sent, 1)
        self.assertEqual(notifier.sent, [("Duda", "'Vidas Secas' is 9 days late, 450 cents so far")])
```

```
ana@laptop:~/patterns/solid-2$ python3 -m unittest -v test_notices.py
test_only_late_loans_get_a_notice (test_notices.OverdueNoticesTest.test_only_late_loans_get_a_notice) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

The test imports only `notices.py`; `adapters.py` could be deleted and it would still pass. Your
timing on the `Ran` line will differ from this one. In Java the same test would implement the
`Notifier` interface in a small class, in Go it would be a struct with a `Notify` method, and in
TypeScript an object literal; in all four, the test needs nothing that sends anything.
