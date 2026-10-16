---
title: What writing the test first does to the design
version: 1
---

**A test written first is the first caller of the code, and code shaped by its first caller comes
out easier to call.** That is why some people expand the second D as *design*. The tests are a
safety net, and they are also a steady pressure on the design: towards small units, towards inputs
passed in rather than fetched, towards decisions kept apart from effects. The pressure comes from
something mundane. Code that is awkward to test is awkward to write a test for first, and you notice
while the design is still cheap to change.

## The code that is written when nobody asks first

The library wants a morning job that e-mails every member whose loan is overdue. Written straight
off, it tends to look like this:

```python
def send_overdue_reminders(loans):
    for loan in loans:
        if loan.due < date.today():
            smtp = smtplib.SMTP("mail.example.org")
            smtp.sendmail("desk@example.org", loan.email, f"{loan.title} is overdue")
```

Now try to write a test for it. Which loans are overdue depends on the day the test runs, so a test
that passes on 20 March fails on 1 April. Running it sends real e-mail, or fails with no mail server.
And the one thing worth checking, *which* loans count as overdue, is wound into a loop that also
opens network connections. Testing it afterwards means patching `date.today` and `smtplib` from the
outside, which works and leaves the design as it was.

## The code the tests asked for

Writing the test first, you would start from the call you want to make in the test, and two facts
fall out immediately. The test has to choose the day, so `today` is an argument. And the test wants
to see what would be sent without sending it, so the sending is something passed in. Four cycles
later, the file looks like this:

```schooling-example
{"language": "python", "file": "reminders.py", "parts": [
 {"code": "# reminders.py\nfrom dataclasses import dataclass\nfrom datetime import date\nfrom typing import Callable", "note": "Standard library only, as everywhere in this course."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    email: str\n    due: date", "note": "Only the fields this job needs. A test can build one in a line, which is a design property, not luck."},
 {"code": "\n\ndef overdue(loans: list[Loan], today: date) -> list[Loan]:\n    return [loan for loan in loans if loan.due < today]", "note": "The decision on its own: no clock, no network, nothing to set up. The first test drove this function into existence."},
 {"code": "\n\ndef remind(loans: list[Loan], today: date, send: Callable[[str, str], None]) -> int:\n    late = overdue(loans, today)\n    for loan in late:\n        send(loan.email, f\"'{loan.title}' was due on {loan.due}\")\n    return len(late)", "note": "The effect, kept thin. `send` is any function taking an address and a text; in production it talks to the mail server, in the test it appends to a list."}
]}
```

And the tests that drove it:

```schooling-example
{"language": "python", "file": "test_reminders.py", "parts": [
 {"code": "# test_reminders.py\nimport unittest\nfrom datetime import date\n\nfrom reminders import Loan, overdue, remind\n\nLOANS = [Loan(\"Dom Casmurro\", \"bia@example.org\", date(2026, 3, 16)),\n         Loan(\"Iracema\", \"caio@example.org\", date(2026, 3, 30))]", "note": "Two loans, one due before 20 March and one after. Fixed dates, so the test means the same thing every day it runs."},
 {"code": "\n\nclass OverdueTest(unittest.TestCase):\n    def test_only_loans_past_their_due_date(self):\n        late = overdue(LOANS, today=date(2026, 3, 20))\n        self.assertEqual([loan.title for loan in late], [\"Dom Casmurro\"])\n\n    def test_due_today_is_not_overdue(self):\n        self.assertEqual(overdue(LOANS, today=date(2026, 3, 16)), [])", "note": "The second test pins the boundary: a loan due today is not yet late. Change the `<` in `overdue` to `<=` and this is the test that goes red."},
 {"code": "\n\nclass RemindTest(unittest.TestCase):\n    def test_sends_one_message_per_overdue_loan(self):\n        sent = []\n        count = remind(LOANS, date(2026, 3, 20), lambda to, text: sent.append((to, text)))\n        self.assertEqual(count, 1)\n        self.assertEqual(sent, [(\"bia@example.org\", \"'Dom Casmurro' was due on 2026-03-16\")])", "note": "The sender is a lambda that records what it was given. No mail server, and the assertion reads the exact message."},
 {"code": "\n\nif __name__ == \"__main__\":\n    unittest.main()"}
]}
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_reminders.py
test_due_today_is_not_overdue (test_reminders.OverdueTest.test_due_today_is_not_overdue) ... ok
test_only_loans_past_their_due_date (test_reminders.OverdueTest.test_only_loans_past_their_due_date) ... ok
test_sends_one_message_per_overdue_loan (test_reminders.RemindTest.test_sends_one_message_per_overdue_loan) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

## Three pressures, named

Look at what the test did to the shape, because it does the same thing in every codebase:

| what the test needed | what the design got |
|---|---|
| to choose the day | the clock became an argument, `today` |
| to check the decision alone | `overdue` split from `remind`, a pure function beside a thin effect |
| to see the message without sending it | the sender passed in, `send` |

The third row is dependency injection, arrived at from the test side. Lesson 5 is about the same
move from the design side, and about the one place, the composition root, where the real
`date.today()` and the real mail sender get plugged in. The second row is the functional core and
imperative shell that lesson 15 builds on purpose.

## When the pressure points the wrong way

**A test that is painful to write is information about the design**, usually that the unit has too
many collaborators or does too many things. Ten lines of setup before one assertion is the test
telling you so. The fix is in the code, not in a cleverer test helper.

The opposite complaint is real too. David Heinemeier Hansson called it *test-induced design damage*
in 2014: indirection added only so that a test could reach in, layers and interfaces with one
implementation each, which make the production code harder to read for the sake of the tests. The
counterweight is to inject what is genuinely awkward, the clock, the network, randomness, and to let
everything else be called directly. `overdue` takes a list and a date and calls nothing; it needed
no injection at all.
