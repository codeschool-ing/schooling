---
title: One behaviour, a name that says it, and the assert that proves nothing
version: 2
---

```python
def test_slugify_works():                       # what broke?
def test_punctuation_is_removed_from_a_slug():  # this one
```

**The name is what you read at half past five when CI is red.** A good one is a sentence about
the system, so the suite's output becomes a list of facts and a failure names one of them without
anybody opening a file.

## One behaviour per test

```python
def test_slugify():                             # six facts
    assert slugify("Hello World") == "hello-world"
    assert slugify("ALL CAPS") == "all-caps"
    assert slugify("Hello, World") == "hello-world"
    assert slugify("") == ""
    ...
```

The first failing line hides the five below it, so you fix one, run again, find the next, and
learn the state of the function one round trip at a time. Parametrisation, two sections along, is
how this table becomes six tests with one function.

## The assertion that proves nothing

```python
def test_total_runs():
    result = total([(2, 10.0)], 0.1)
    assert result is not None
```

Every line of the module runs. Coverage reports a hundred per cent. And `is not None` is true of
almost every value there is, so the test passes whatever the arithmetic did — which is the module
this lesson's demonstration finds a doubled tax in.

**Assert the answer, not the fact that there was one.**

## Behaviour, not implementation

```python
def test_notify(mocker):
    ...
    assert mailer.send.called          # that a helper was called
```

```python
def test_notify():
    ...
    assert sent == [("a@b.c", "Welcome")]   # what the system did
```

The first goes red when you rename the helper and green when the message is wrong. **A test
coupled to the implementation makes refactoring expensive and finds nothing**, which is the worst
of both halves.

## What a good test asserts

The value that comes back. The state that changed. The exception raised for a bad input. The
boundary — an empty list, a zero, a single element, the last day of the month. Those are the
inputs where the code was written from a picture of the ordinary case.
