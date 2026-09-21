---
title: The branch nobody can see
version: 1
---

```python
@admin_only
def delete_everything():
    ...
```

Read the body. Nothing in it says that a permission is checked, what happens when the check
fails, or which permission it is. **The most important line of this function is not in this
function**, and it is above the `def` where somebody reading the body will not look.

## The rule

**A decorator is right when it wraps the CALL and wrong when it decides the ANSWER.**

Around the call: timing, retrying, caching, logging, opening a transaction, registering the
function somewhere. Those are things that happen and do not change what the function means.

Deciding the answer: returning early, choosing a different implementation, swallowing an
exception, changing the result. Those are branches, and a branch belongs where a reader will find
it.

## The argument that would have been clearer

```python
@retry(times=3)
def fetch(url): ...

def fetch(url, times=3): ...    # the same behaviour, visible in the signature
```

When the wrapping is small and the function is yours, a parameter says it where it can be read.
The decorator wins when the same wrapping is on nine functions — and loses when it is on one.

## The debugging cost

A traceback through a decorated function has extra frames in it, and a stack of three has three.
`functools.wraps` keeps the names honest, and nothing keeps the stack short.

**Every decorator is a layer between what somebody reads and what actually runs.** That is worth
it for the nine-function case and is not worth it for cleverness.

## And the test

If you cannot say what the decorator does in one short sentence, without "and", it is doing two
things — and the second one is the one that will surprise somebody.
