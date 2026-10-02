---
title: Generated tests pin what the code does
version: 1
---

"Write tests for this function" is one of the most common requests made to an assistant, and the
result looks like exactly what was asked for: a file of tests, named well, that pass. **That they
pass is the problem.** A test written by reading the code describes the code, and the code
includes its bugs.

## Asking for tests

ana asks for tests for `apply_coupon`, with the buggy version of lesson 4 section 02 still in place.
The reply, written by the course to look like a typical generated test file, goes straight into
`tests/test_generated.py`:

```
ana@dev:~/shop$ assist ask "Write pytest tests for apply_coupon." --open shop/coupons.py > tests/test_generated.py
context sent (187 of 3000 tokens):
    187  shop/coupons.py
---
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py
....                                                                     [100%]
4 passed in 0.54s
```

All four pass, on code with a known bug. Here is the one that should not:

```
ana@dev:~/shop$ grep -n -A2 "def test_friends15" tests/test_generated.py
21:def test_friends15_expires_on_2026_10_31():
22-    with pytest.raises(ExpiredCoupon):
23-        apply_coupon(Cart(), "FRIENDS15", today=date(2026, 10, 31))
```

`test_friends15_expires_on_2026_10_31` asserts that the coupon is refused on its last valid day.
**The test is the bug, written down as a requirement.** It was derived from `today >= until`, so
it agrees with `today >= until`, and it will fail the day somebody fixes the code. Lesson 4 section
05 shows exactly that happening.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two places a test&#x27;s expected value can come from. From the specification, the coupon terms, a test says the 31st is valid; against the buggy code it fails, which is the bug found. From the code itself, today &gt;= until, a generated test says the 31st is refused; against the buggy code it passes, which is the bug written down.\"><defs><marker id=\"sr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"210\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the specification</text><text x=\"125.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">valid until 31 October, inclusive</text><rect x=\"20\" y=\"140\" width=\"210\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the code</text><text x=\"125.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">today &gt;= until</text><rect x=\"280\" y=\"38\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">test: the 31st is valid</text><rect x=\"280\" y=\"148\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">test: the 31st is refused</text><path d=\"M232 58 L276 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><path d=\"M232 168 L276 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><path d=\"M472 58 L516 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><path d=\"M472 168 L516 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><text x=\"522\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">fails: the bug is found</text><text x=\"522\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">passes: the bug is pinned</text></svg>", "caption": "Where the expected value comes from decides what a green test means. Both tests run against the same buggy line."}
```

## Why this happens

A model asked to test a function has two things it could test against: what the function is
supposed to do, and what the function does. It only has the second, because the code is in the
context and the intent usually is not. So it does the reasonable thing with what it has, and
writes down what the code does, edge cases included, bugs included. A person who writes tests by
reading the implementation produces the same file.

Generated tests are not useless. Two things they are good for:

- **Characterisation before a refactoring**, the job of lesson 3 section 06: when the goal is
  "nothing changes", a test of what the code does now is exactly the right test, bugs and all.
- **A starting list of cases to think about.** Reading a generated test file is a quick way to see
  which inputs the function has branches for. Each case is then checked against the specification,
  and the expected values come from there.

What they are not is evidence that the code is right. A green generated test suite tells you the
code does what it does.
