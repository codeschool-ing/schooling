---
title: Testing with fakes: the payoff
version: 1
---

**The test is where injection pays for itself: a class that receives its collaborators can be
handed small, predictable ones, and the test needs no patching, no network and no calendar.**
Everything in this lesson so far has been an argument about design. This section is the evidence,
because a test is the second caller every class has, and a class that is awkward to test is awkward
for the same reason it will be awkward to change.

`testing-cicd` lesson 2 named the kinds of test double: dummies, stubs, spies, mocks and fakes. That
vocabulary is assumed here. What this section adds is how the design decides which doubles are
possible at all.

## A test that hands the job its world

```schooling-example
{"language": "python", "file": "test_overdue.py", "parts": [
 {"code": "# test_overdue.py\nimport unittest\nfrom datetime import date\n\nfrom overdue import FixedClock, ListedLoans, Loan, OverdueNotices", "note": "The test imports the job and the two simple implementations from `overdue.py`. It needs nothing from `main.py`: the composition root is not part of what is tested."},
 {"code": "\n\nclass RecordingNotifier:\n    def __init__(self):\n        self.sent = []\n\n    def send(self, member: str, text: str) -> None:\n        self.sent.append((member, text))", "note": "A spy, in `testing-cicd`'s terms: a notifier that records what it was asked to send instead of sending it. It is six lines and needs no library."},
 {"code": "\n\nclass OverdueNoticesTest(unittest.TestCase):\n    def setUp(self):\n        self.notifier = RecordingNotifier()\n        loans = ListedLoans([\n            Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16)),\n            Loan(\"Caio\", \"Vidas Secas\", date(2026, 3, 20)),\n        ])\n        self.notices = OverdueNotices(loans, self.notifier, FixedClock(date(2026, 3, 20)))", "note": "Every test starts from the same world: two loans, a fixed day, a fresh notifier. The job cannot tell this from production."},
 {"code": "\n    def test_only_late_loans_get_a_notice(self):\n        self.assertEqual(self.notices.send_all(), 1)\n        self.assertEqual([member for member, _ in self.notifier.sent], [\"Bia\"])\n\n    def test_the_fine_is_fifty_cents_a_day(self):\n        self.notices.send_all()\n        self.assertIn(\"fine 200 cents\", self.notifier.sent[0][1])\n\n    def test_due_today_is_not_late(self):\n        self.notices.send_all()\n        self.assertNotIn(\"Caio\", [member for member, _ in self.notifier.sent])\n\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "Each test states one rule of the job. Caio's loan is due on the day itself, which is the boundary somebody gets wrong."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 -m unittest -v test_overdue.py
test_due_today_is_not_late (test_overdue.OverdueNoticesTest.test_due_today_is_not_late) ... ok
test_only_late_loans_get_a_notice (test_overdue.OverdueNoticesTest.test_only_late_loans_get_a_notice) ... ok
test_the_fine_is_fifty_cents_a_day (test_overdue.OverdueNoticesTest.test_the_fine_is_fifty_cents_a_day) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

The time on the `Ran` line changes from run to run; the three `ok`s do not. Nothing in the test
mentions a date of today, a mail server or a database, so it gives the same answer on any machine,
on any day, with the network unplugged.

## The same test without injection

Go back to the first draft from the constructor section, the one that called `date.today()` and
built its own `SmtpNotifier`. It can still be tested in Python, with `unittest.mock.patch`:

```python
with patch("overdue_draft.date") as fake_date, \
     patch("overdue_draft.SmtpNotifier") as fake_smtp:
    fake_date.today.return_value = date(2026, 3, 20)
    OverdueNotices().send_all()
    fake_smtp.return_value.send.assert_called_once()
```

It works, and it is worth seeing what it depends on. The strings `"overdue_draft.date"` and
`"overdue_draft.SmtpNotifier"` are the module's import names: rename an import, or move the job to
another file, and the patch quietly replaces nothing while the real mail server is called. **A patch
couples the test to how the code is written; an injected fake couples it only to what the code
needs.** Java has the same split between Mockito's `@InjectMocks` on a class with a constructor and
PowerMock reaching into static calls, and Go, with no patching at all, leaves injection as the only
road.

`patch` remains a good tool for code you do not own and cannot change. For your own classes, the
need to patch is a message about the design: something inside is building a collaborator that
should have been handed in.

## What to fake, and what to leave real

Fake the things that are slow, non-deterministic or outside the process: the clock, the network,
the mail server, a payment gateway. Leave real the things that are fast and yours: `Loan` and
`ListedLoans` are real in the test above, because faking a frozen dataclass would test nothing. A
test that fakes every collaborator checks only that the class calls methods in a certain order, and
breaks on every refactor that keeps the behaviour. Lesson 13 turns the order round and writes the
test before the class, and there the doubles arrive because a test asked for them.
