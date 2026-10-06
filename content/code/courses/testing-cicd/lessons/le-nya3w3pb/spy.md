---
title: Spy
version: 1
---

A **spy** records how it was used, so the test can check afterwards. Where a stub answers, a spy
watches: which calls arrived, in what order, with which arguments.

The simplest spy in Python is a list. `price` writes a line when it falls back to the table, and it
writes it through `log`, which defaults to `print`. The test passes `lines.append` instead:

```python
def test_the_fallback_is_logged_with_the_reason():
    lines = []
    stub = StubCarrier(error=CarrierError("timed out"))
    price(stub, "01310-100", 1200, 5000, log=lines.append)
    assert lines == ["carrier unavailable, using the table: timed out"]
```

The stub makes the carrier fail; the spy, `lines`, collects whatever `price` logged; the assertion
compares the whole list. That last detail matters: **comparing the whole list catches a second,
unexpected line**, where `"timed out" in lines[0]` would not.

## Why the log deserves a test

A fallback that works silently is a fallback nobody knows is happening. If the carrier's API breaks
on a Friday evening, the shop keeps quoting from its own table all weekend, customers pay prices
the carrier does not honour, and the only trace is that line. The project's rule is that **silent
failure is forbidden**: a path that can fail must say so, and this test is what keeps it saying so.
Delete the `log(...)` call in `price` and this test goes red; the other three in the file stay
green.

## Spies in libraries

`unittest.mock.Mock` records every call made to it, so any mock can act as a spy:

```python
mailer = mock.Mock()
place(FakeOrders(), mailer, "bia@example.org", 8990)
print(mailer.send.call_args)       # the arguments of the last call
print(mailer.send.call_count)      # how many calls
```

The difference between a spy and a mock, in the vocabulary this lesson uses, is **who checks**. With
a spy the test reads the record and asserts on it, in its own words. With a mock the double comes
with assertion methods of its own. The line is blurry in practice and the libraries mix both; what
matters is that recording calls is a tool for when the call is the behaviour, as with a log line or
an e-mail, and not for every collaborator in sight.
