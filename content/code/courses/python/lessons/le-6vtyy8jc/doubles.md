---
title: `monkeypatch`, `mock`, and the test that proves the mock
version: 1
---

```python
def test_total(monkeypatch):
    monkeypatch.setattr("app.rates.fetch", lambda code: 5.0)
    assert total(2, "USD") == 10.0
```

**Replace the edge, never the subject.** `fetch` reaches the network; `total` is what is being
tested. `monkeypatch` puts the replacement in place, and undoes it when the test ends whatever
happened — which is the part a hand-rolled `setattr` forgets.

It also handles the rest of the ambient world: `monkeypatch.setenv`, `delenv`, `setitem`,
`chdir`. Each one is undone the same way.

## `unittest.mock`, for when you need to ask what was called

```python
from unittest.mock import patch

def test_notify_sends():
    with patch("app.mailer.send") as send:
        mailer.notify({"email": "a@b.c"})
        send.assert_called_once_with("a@b.c", "Welcome")
```

A `Mock` records every call. `patch` takes the target **where it is used**, not where it is
defined — `app.mailer.send`, because that is the name `notify` looks up.

## Three ways this goes wrong

```python
with patch("app.mailer.notify") as m:      # patching the subject
    m.return_value = True
    assert mailer.notify({"email": "a@b.c"}) is True
```

Green, forever, proving that a `Mock` returns what you told it to. If the function under test is
the one being replaced, the test has nothing left in it.

```python
send.called_once_with("nothing", "like it")     # passes silently
```

A `Mock` answers any attribute with another `Mock`, so a name that is not an assertion is a call
that records itself and asserts nothing. Modern Python catches the near-misses —
`assert_called_once_wth` raises `'assert_called_once_wth' is not a valid assertion` — but only
for names that start like an assertion. `called_once_with` starts with `c`, and passes.

```python
with patch("app.mailer.send") as send:
    send("only one argument")               # accepted
```

A bare `Mock` accepts any signature, so a test keeps passing after the real function grows a
required argument. `patch(..., autospec=True)` builds the double from the real signature and
raises `TypeError: missing a required argument: 'subject'` instead.

## When not to use one at all

A pure function needs no double. A class you can construct in three lines needs no double. Reach
for one at a genuine boundary — the network, the clock, the filesystem, the payment gateway — and
prefer passing a simple object you wrote over patching a name, because a real object has a real
signature and does not answer attributes it has never heard of.
