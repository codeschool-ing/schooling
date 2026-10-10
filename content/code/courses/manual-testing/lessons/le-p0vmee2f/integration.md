---
title: An integration test through HTTP
version: 1
---

An integration test checks that pieces which each work on their own also work together. The usual
mistake is to think of it as a bigger unit test, the same thing with more code inside. **What
changes is what the test depends on**: a unit test needs nothing but the function, and an
integration test needs the pieces it crosses to be there and running. That difference shapes how
it is written, how it fails and what its failures mean.

For boxoffice the natural integration test goes in by the same door you use with curl. It posts
the booking form over HTTP to the running application, exactly as a browser would, and reads the
total on the order page that comes back. On the way it crosses the server, the code that reads the
form, the quantity check, `discount`, the arithmetic of the total and the page itself.

## The test file

Save it as `test_booking.py`, in `~/boxoffice` beside the other two files:

```schooling-example
{"language": "python", "file": "test_booking.py", "parts": [
 {"code": "import re\nimport unittest\nfrom urllib.parse import urlencode\nfrom urllib.request import urlopen\n", "note": "Everything here is in Python's standard library. `urlopen` sends a request the way curl does."},
 {"code": "BOXOFFICE = \"http://127.0.0.1:8000\"\n\n", "note": "The address of the running application. The test does not start it: somebody has to, in another terminal, and that is the first difference from a unit test."},
 {"code": "def total_of_booking(**fields):\n    \"\"\"Book through the running application and return the total on the order page.\"\"\"\n    with urlopen(BOXOFFICE + \"/book\", urlencode(fields).encode()) as answer:\n        page = answer.read().decode()\n    return re.search(r\"<strong>(R\\$ [^<]+)</strong>\", page).group(1)\n\n", "note": "Posts the booking form with the fields a browser would send, reads the order page that comes back, and picks out the total, the first bold amount in reais."},
 {"code": "class BookingTest(unittest.TestCase):\n\n    def test_member(self):\n        total = total_of_booking(email=\"member@example.org\", show=\"S2\", quantity=\"2\")\n        self.assertEqual(total, \"R$ 144,00\")\n", "note": "Two tickets for Hamlet at R$ 80,00, booked by the seeded member, who gets 10% off. The expected value is money, as the customer sees it, and no longer a percentage."},
 {"code": "    def test_student(self):\n        total = total_of_booking(email=\"member@example.org\", show=\"S2\", quantity=\"2\",\n                                 student=\"on\")\n        self.assertEqual(total, \"R$ 80,00\")", "note": "The same order with the student box ticked, which the browser sends as `student=on`. Half of R$ 160,00 is R$ 80,00, because the largest discount applies."}
]}
```

Two tests, each one booking: the seeded member buying two tickets for Hamlet, once as herself and
once with the student box ticked. The expected values are written as the customer would read them,
in reais with a comma, because that is what this layer can see and the unit test could not.

## When the application is not running

An integration test has a precondition a unit test never has. Run it with boxoffice stopped and
both tests stop at the first request:

```
ana@laptop:~/boxoffice$ python3 -m unittest test_booking 2>&1 | grep -E 'ERROR|URLError|FAILED'
ERROR: test_member (test_booking.BookingTest.test_member)
    raise URLError(err)
urllib.error.URLError: <urlopen error [Errno 111] Connection refused>
ERROR: test_student (test_booking.BookingTest.test_student)
    raise URLError(err)
urllib.error.URLError: <urlopen error [Errno 111] Connection refused>
FAILED (errors=2)
```

The full output is long, because each test prints the chain of calls that led to the refused
connection; `grep` keeps the lines that matter. Two words are worth separating here, because
`unittest` separates them. **A `FAIL` is a test that ran and got the wrong answer. An `ERROR` is a
test that could not get an answer at all**: here, nothing was listening on port 8000. Reporting
these two errors as a defect in boxoffice would be wrong. They are a fault in the setup, the same
kind lesson 1 section 05 dealt with when the server would not start.

## When it is running

Start boxoffice in its own terminal, as always, and run the test again from the second one:

```
ana@laptop:~/boxoffice$ python3 -m unittest -v test_booking
test_member (test_booking.BookingTest.test_member) ... ok
test_student (test_booking.BookingTest.test_student) ... FAIL

======================================================================
FAIL: test_student (test_booking.BookingTest.test_student)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/boxoffice/test_booking.py", line 25, in test_student
    self.assertEqual(total, "R$ 80,00")
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^
AssertionError: 'R$ 144,00' != 'R$ 80,00'
- R$ 144,00
+ R$ 80,00


----------------------------------------------------------------------
Ran 2 tests in 0.054s

FAILED (failures=1)
```

One `ok` and one `FAIL`. The member's two tickets cost R$ 144,00, which is R$ 160,00 less 10%, so
everything between the form and the page works for a member. The student's order came back at
R$ 144,00 as well, where R5 says R$ 80,00: the student box reached the application and changed
nothing.

**It is the same regression for the third time.** Lesson 10 saw it in a browser, section 03 of this
lesson saw it in `discount`, and this test sees it in between. The three views are not redundant:
the unit test says where the cause is, this one says what it costs a customer, and only a browser
shows what the customer sees. If the developer fixes `discount`, both this file and
`test_discount.py` go green; if somebody later renames the student box in the form, only this file
notices.

## What integration tests cost

Two things you will meet in any team that has them.

**They leave state behind.** Every run of this file books four tickets for Hamlet and creates two
orders, so the seats left go down and the order numbers go up each time. Here that is harmless,
because a restart resets boxoffice. Against a shared test environment with a real database it is
the reason integration suites spend so much code creating their own data and cleaning up after
themselves, a subject lesson 20 comes back to.

**They are slower and noisier.** These two ran quickly, on one machine. A real suite talks to a
database, a payment service and a mail server, and a test can fail because one of them was slow or
down. That is an `ERROR` like the one above, it says nothing about the code under test, and a team
that gets many of them stops trusting the suite. Section 05 of this lesson is about the usual
answer: replace the parts the test is not about with stand-ins.
