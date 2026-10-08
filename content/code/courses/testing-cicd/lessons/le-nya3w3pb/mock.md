---
title: Mock
version: 2
---

A **mock** is a double that carries expectations about how it will be called, and checks them. In
Python the word also names the library, `unittest.mock`, whose `Mock` object is a stub, a spy and a
mock at once: it answers any call, records every call, and offers assertion methods.

Two tests in `shipquote` use one. The first asserts that something did **not** happen:

```python
def test_a_free_order_never_asks_the_carrier():
    carrier = mock.Mock()
    assert price(carrier, "01310-100", 1200, 19900) == 0
    carrier.rate.assert_not_called()
```

An order of R$ 199,00 ships free, so `price` should not spend a paid API call asking the carrier.
The return value alone cannot tell you that: 0 comes back either way. Only a double that records
calls can, and `assert_not_called` is the check.

The second asserts that something happened exactly once, with exactly these arguments. It needs
the real mailer, which the project has not had until now: since lesson 1, `place` has sent its
e-mail through whatever `mailer` it was handed. The real one speaks SMTP. Save it as
`shipquote/mailer.py`:

```python
"""E-mail through an SMTP server."""
import smtplib
from email.message import EmailMessage


class SmtpMailer:
    def __init__(self, host, port=25):
        self.host = host
        self.port = port

    def send(self, to, subject, body):
        msg = EmailMessage()
        msg["From"] = "pedidos@livraria.example"
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        with smtplib.SMTP(self.host, self.port, timeout=5) as smtp:
            smtp.send_message(msg)
```

and commit it, `git add shipquote/mailer.py && git commit -m "Send e-mail over SMTP"`, because the
experiment below changes it and git is what puts it back. The test:

```python
def test_placing_an_order_sends_exactly_one_confirmation():
    mailer = mock.create_autospec(SmtpMailer, instance=True)
    order_id = place(FakeOrders(), mailer, "bia@example.org", 8990)
    mailer.send.assert_called_once_with(
        to="bia@example.org", subject=f"Order {order_id} confirmed",
        body="Total: R$ 89,90")
```

One confirmation e-mail, to the right address, with the right subject and total. **The call is the
behaviour here**: `place` returns an id, and the e-mail is a side effect nobody would see in the
return value.

## A Mock agrees with anything

The same freedom that makes `Mock` convenient makes it dangerous. A plain `Mock` accepts any method
name, misspelt or invented:

```
ana@laptop:~/shipquote$ python3 -c '
from unittest import mock
mailer = mock.Mock()
mailer.sned(to="bia@example.org")
print(mailer.sned.call_args)
print(mailer.anything.at.all())
'
call(to='bia@example.org')
<Mock name='mock.anything.at.all()' id='139716095751376'>
```

`mailer.sned(...)` succeeded and was recorded, and `mailer.anything.at.all()` returned another
mock. A typo in production code calling a plain `Mock` raises nothing in the test.

`create_autospec` builds the mock from the real class instead, and refuses what the class does not
have:

```
ana@laptop:~/shipquote$ python3 -c '
from unittest import mock
from shipquote.mailer import SmtpMailer
mailer = mock.create_autospec(SmtpMailer, instance=True)
mailer.sned(to="bia@example.org")
'
Traceback (most recent call last):
  File "<string>", line 5, in <module>
    mailer.sned(to="bia@example.org")
    ^^^^^^^^^^^
  File "/usr/lib/python3.13/unittest/mock.py", line 690, in __getattr__
    raise AttributeError("Mock object has no attribute %r" % name)
AttributeError: Mock object has no attribute 'sned'
```

## What happens when the real class changes

This is where it stops being about typos. Suppose somebody renames `SmtpMailer.send` to `deliver`
and forgets `orders.place`, which still calls `send`. Production now fails on every order. Make
that rename yourself, `def send` to `def deliver` in `shipquote/mailer.py`. Then run
`tests/test_orders.py` twice: first as lesson 1 wrote it, with a plain `mock.Mock()`, and then with
the two lines this section changes, so that the file reads, whole, as below. Save it as
`tests/test_orders.py`:

```python
from unittest import mock

import pytest

from shipquote.mailer import SmtpMailer
from shipquote.orders import place
from tests.fakes import FakeOrders


def test_placing_an_order_sends_exactly_one_confirmation():
    mailer = mock.create_autospec(SmtpMailer, instance=True)
    order_id = place(FakeOrders(), mailer, "bia@example.org", 8990)
    mailer.send.assert_called_once_with(
        to="bia@example.org", subject=f"Order {order_id} confirmed",
        body="Total: R$ 89,90")


def test_an_order_of_nothing_is_refused_before_anything_is_written():
    orders = FakeOrders()
    with pytest.raises(ValueError, match="must cost something"):
        place(orders, mailer=None, email="bia@example.org", cents=0)
    assert orders.rows == []
```

The rename, the old test, and the new one:

```
ana@laptop:~/shipquote$ git diff --stat
 shipquote/mailer.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/shipquote$ python -m pytest tests/test_orders.py -q
..                                                                       [100%]
2 passed in 0.15s
ana@laptop:~/shipquote$ python -m pytest tests/test_orders.py -q --tb=line
F.                                                                       [100%]
=================================== FAILURES ===================================
E   AttributeError: Mock object has no attribute 'send'
/usr/lib/python3.13/unittest/mock.py:690: AttributeError: Mock object has no attribute 'send'
=========================== short test summary info ============================
FAILED tests/test_orders.py::test_placing_an_order_sends_exactly_one_confirmation
1 failed, 1 passed in 0.16s
```

**The plain mock passed. The autospec mock failed**, with `Mock object has no attribute 'send'`,
which is the same error production would raise. That is why the project keeps the second version.
A mock that does not know the shape of what it replaces checks the code against an imaginary
collaborator, and the imaginary one never changes. Put `send` back with
`git checkout shipquote/mailer.py`, and commit the new test.

The rule of thumb: **mock by spec, from the real class**, and use a mock only where the call is the
thing you need to check. For everything else, a stub or a fake keeps the test about results.
