---
title: Mock
version: 1
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

The second asserts that something happened exactly once, with exactly these arguments:

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
and forgets `orders.place`, which still calls `send`. Production now fails on every order. Here is
the rename, then the test as it was at step 5 of the project, with a plain `mock.Mock()`, then the
test as it is now, with `create_autospec`:

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
which is the same error production would raise. That is why step 6 of the project changed the test
from one to the other. A mock that does not know the shape of what it replaces checks the code
against an imaginary collaborator, and the imaginary one never changes.

The rule of thumb: **mock by spec, from the real class**, and use a mock only where the call is the
thing you need to check. For everything else, a stub or a fake keeps the test about results.
