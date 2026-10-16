---
title: Test doubles inside the cycle
version: 1
---

**A test double is not a TDD invention, and TDD does not require mocks.** `testing-cicd` lesson 2
sorted the kinds, dummy, stub, spy, mock and fake, and that vocabulary is assumed here. What this
section adds is where doubles sit inside the red-green-refactor loop, because the two traditions of
TDD disagree about exactly that, and the disagreement shows up in how a suite behaves on the day you
refactor.

## Two schools

The **classicist** style, sometimes called Detroit or Chicago after where its early practitioners
worked, is Beck's own. Use real objects wherever they are cheap, and reach for a double only for
what is awkward: the clock, the network, the disk. Assert on results and on state. The `sent` list
of the previous section is this style: a lambda that records, checked afterwards.

The **mockist** style, or London school, comes from Steve Freeman and Nat Pryce's *Growing
Object-Oriented Software, Guided by Tests* (2009). Work from the outside in: start at the edge of the
system, and when the object under test needs a collaborator that does not exist yet, mock it. The
mock's expectations become the design of that collaborator's interface, which you then build in its
own cycle. Assert on the messages sent.

Both work, and both have produced large, well-tested systems. **The trade is between what each kind
of test notices**: a state-based test notices when the answer changes, an interaction-based test
notices when the conversation between objects changes, including when the answer has not.

## A mock that agrees with anything

Mockist tests carry a specific risk, and Python's `unittest.mock` shows it in one file. The
library's real notifier was given a better method name last week, `deliver` instead of `send`, and
`remind` was not updated:

```python
# notify.py
from datetime import date


class Notifier:
    def deliver(self, to: str, text: str) -> None:
        raise NotImplementedError("the real one talks to the mail server")


def remind(loans, today: date, notifier) -> int:
    late = [loan for loan in loans if loan.due < today]
    for loan in late:
        notifier.send(loan.email, f"'{loan.title}' was due on {loan.due}")
    return len(late)
```

Two tests of it, which differ in one argument. It reuses `Loan` from `reminders.py` in the same
directory:

```schooling-example
{"language": "python", "file": "test_notify.py", "parts": [
 {"code": "# test_notify.py\nimport unittest\nfrom datetime import date\nfrom unittest.mock import Mock\n\nfrom notify import Notifier, remind\nfrom reminders import Loan\n\nLOANS = [Loan(\"Dom Casmurro\", \"bia@example.org\", date(2026, 3, 16))]\nTEXT = \"'Dom Casmurro' was due on 2026-03-16\"", "note": "One overdue loan and the message it should produce."},
 {"code": "\n\nclass RemindTest(unittest.TestCase):\n    def test_with_a_bare_mock(self):\n        notifier = Mock()\n        remind(LOANS, date(2026, 3, 20), notifier)\n        notifier.send.assert_called_once_with(\"bia@example.org\", TEXT)", "note": "A bare `Mock()` invents any attribute it is asked for. `notifier.send` exists because `remind` called it, and the test was written to match the code."},
 {"code": "\n\n    def test_with_a_mock_that_knows_the_class(self):\n        notifier = Mock(spec=Notifier)\n        remind(LOANS, date(2026, 3, 20), notifier)\n        notifier.deliver.assert_called_once_with(\"bia@example.org\", TEXT)", "note": "`spec=Notifier` makes the mock refuse any attribute the real class does not have."},
 {"code": "\n\nif __name__ == \"__main__\":\n    unittest.main()"}
]}
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_notify.py
test_with_a_bare_mock (test_notify.RemindTest.test_with_a_bare_mock) ... ok
test_with_a_mock_that_knows_the_class (test_notify.RemindTest.test_with_a_mock_that_knows_the_class) ... ERROR

======================================================================
ERROR: test_with_a_mock_that_knows_the_class (test_notify.RemindTest.test_with_a_mock_that_knows_the_class)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_notify.py", line 22, in test_with_a_mock_that_knows_the_class
    remind(LOANS, date(2026, 3, 20), notifier)
  File "/home/ana/patterns/tdd/notify.py", line 13, in remind
    notifier.send(loan.email, f"'{loan.title}' was due on {loan.due}")
    ^^^^^^^^^^^^^
  File "/usr/lib/python3.12/unittest/mock.py", line 658, in __getattr__
    raise AttributeError("Mock object has no attribute %r" % name)
AttributeError: Mock object has no attribute 'send'

----------------------------------------------------------------------
Ran 2 tests in 0.002s

FAILED (errors=1)
```

The bare mock is green. In production, `remind` would raise `AttributeError` on the first overdue
loan, because the real `Notifier` has no `send`. The mock with a spec fails with that same error,
here, in the test run. Now fix the one word in `notify.py`:

```python
# notify.py
from datetime import date


class Notifier:
    def deliver(self, to: str, text: str) -> None:
        raise NotImplementedError("the real one talks to the mail server")


def remind(loans, today: date, notifier) -> int:
    late = [loan for loan in loans if loan.due < today]
    for loan in late:
        notifier.deliver(loan.email, f"'{loan.title}' was due on {loan.due}")
    return len(late)
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_notify.py
test_with_a_bare_mock (test_notify.RemindTest.test_with_a_bare_mock) ... FAIL
test_with_a_mock_that_knows_the_class (test_notify.RemindTest.test_with_a_mock_that_knows_the_class) ... ok

======================================================================
FAIL: test_with_a_bare_mock (test_notify.RemindTest.test_with_a_bare_mock)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_notify.py", line 17, in test_with_a_bare_mock
    notifier.send.assert_called_once_with("bia@example.org", TEXT)
  File "/usr/lib/python3.12/unittest/mock.py", line 955, in assert_called_once_with
    raise AssertionError(msg)
AssertionError: Expected 'send' to be called once. Called 0 times.

----------------------------------------------------------------------
Ran 2 tests in 0.002s

FAILED (failures=1)
```

**The bare mock was green while the code was broken and is red now that it works.** It never
tested `remind` against the notifier; it tested `remind` against a copy of `remind`'s own
assumptions. The spec version followed the truth both times.

## Rules that keep doubles honest in the cycle

- Double only what you own an interface for, or wrap what you do not. Mocking `smtplib` directly
  ties the tests to a library's call sequence; a `Notifier` of your own with one method is a seam
  you control.
- Give every mock a spec: `Mock(spec=Notifier)`, or `create_autospec(Notifier)`, which also checks
  the arguments of each call. Java's Mockito and Go's interfaces get this for free from the type
  system; Python and plain JavaScript mocks do not.
- Mock commands, stub queries. Asserting that `send` was called is checking an effect somebody
  cares about. Asserting that a lookup was called twice is checking how the code happens to work
  today, and it breaks on a harmless refactor.
- When the doubles outnumber the real objects in a test, the unit under test probably has too many
  collaborators, which is the previous section's pressure arriving by another route.
