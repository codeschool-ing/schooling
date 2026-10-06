---
title: Dummy
version: 1
---

A **dummy** is the simplest double: a value passed only because a signature demands one, which the
code under test never uses. It does nothing, and if the code ever did use it, the test would
rightly blow up.

`orders.place` refuses an order of zero cents before it writes anything or sends anything. The
test of that refusal still has to pass a mailer, because `place` takes one:

```python
def test_an_order_of_nothing_is_refused_before_anything_is_written():
    orders = FakeOrders()
    with pytest.raises(ValueError, match="must cost something"):
        place(orders, mailer=None, email="bia@example.org", cents=0)
    assert orders.rows == []
```

`mailer=None` is the dummy. The test is about the refusal, and the refusal happens before the
mailer could be touched. Passing `None` says so: **if this line ever reaches the mailer, something
is wrong**, and `None.send(...)` would fail loudly with an `AttributeError`.

The orders store in the same test is not a dummy: the last line asserts that `orders.rows` is still
empty, so the test reads it. That is a fake, which section 07 describes.

## Why bother naming it

Because the alternative is common and costly. A test that needs a mailer it does not use often
builds a real one, `SmtpMailer("smtp.example", 25)`, "just to have something". That object is
harmless until the day the refusal check moves below the e-mail line. Then the test sends real
mail, or hangs for five seconds waiting for a server that is not there, and nobody knows why the
suite got slow.

A dummy makes the test's claim visible: *this collaborator is irrelevant here*. A reader sees
`None` and knows not to look for its behaviour.

## When `None` is not enough

Some code checks the type of what it receives, or calls a method on it as part of setup. Then
the dummy has to be an object of the right shape that still does nothing useful, and
`unittest.mock.Mock()` is one: it accepts any call. That convenience has a cost, which section 06
shows, so reach for `None` first and for a `Mock` only when the shape is needed.
