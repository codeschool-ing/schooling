---
title: Two decorators, and two different orders
version: 1
---

```python
@timed
@retry(times=3)
def fetch(url):
    ...
```

is

```python
fetch = timed(retry(times=3)(fetch))
```

**They APPLY from the bottom up**: the one nearest the `def` wraps first, and the one above wraps
that.

**They RUN from the top down**: a call goes into `timed`'s wrapper, which calls `retry`'s
wrapper, which calls `fetch`.

Those are two different orders, and they are both correct at the same time — the outermost
wrapper is the last one applied and the first one entered.

## Which is why the order matters

```python
@timed
@retry(times=3)      # timing measures all three attempts

@retry(times=3)
@timed               # timing measures each attempt separately
```

Same two decorators, different meaning. Neither is wrong; they answer different questions, and
the stack is where the answer is decided.

## The one that is always wrong

```python
@app.route("/rows")
@login_required
def rows(): ...
```

against

```python
@login_required
@app.route("/rows")     # the framework registered the UNPROTECTED function
def rows(): ...
```

A decorator that REGISTERS the function must be outermost, because it registers whatever it is
given — and what it is given is whatever is below it. The second version protects a function
nobody calls and serves one that is not protected.

**This is a real bug shape in web code**, and it is silent.

## And the advice

Two is a stack somebody can read. Three is a stack somebody will get wrong. If the order matters
and is not obvious, a comment beside it costs one line — and a single decorator that does both
things is often the honest answer.
