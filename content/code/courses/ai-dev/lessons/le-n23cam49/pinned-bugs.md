---
title: Generated tests pin what the code does
version: 2
---

"Write tests for this function" is one of the most common requests made to an assistant, and the
result looks like exactly what was asked for: a file of tests, named well. **What decides whether
they help is where their expected values came from.** A test written by reading the code describes
the code, and the code includes its bugs.

## Asking for tests

ana asks for tests for `apply_coupon`, with the buggy version of lesson 4 section 02 still in place,
and asks for the imports, because a test file that cannot import what it tests is the most common
failure of a generated one. `--write` puts the block of code from the reply straight into
`tests/test_generated.py`. Then she lists what it tests, and every line that mentions the coupon's
last day, before running it:

```
ana@dev:~/shop$ python scratch/assist.py ask "Write pytest tests for apply_coupon, including its end dates. Start the file with every import it needs." --open shop/coupons.py --write tests/test_generated.py > /dev/null
context sent (187 of 3000 tokens):
    187  shop/coupons.py
---
ana@dev:~/shop$ grep -n "^def test_\|10, 31" tests/test_generated.py
7:def test_apply_coupon_known_code():
12:def test_apply_coupon_unknown_code():
17:def test_apply_coupon_expired_code():
23:def test_apply_coupon_code_with_end_date():
25:    today = date(2026, 10, 31)
29:def test_apply_coupon_code_with_end_date_expired():
31:    today = date(2026, 10, 31)
35:def test_apply_coupon_code_with_end_date_not_set():
37:    today = date(2026, 10, 31)
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py | tail -n 15
        if code not in COUPONS:
            raise UnknownCoupon(code)
        percent, until = COUPONS[code]
        if until is not None and today >= until:
>           raise ExpiredCoupon(code)
E           shop.coupons.ExpiredCoupon: FRIENDS15

shop/coupons.py:25: ExpiredCoupon
=========================== short test summary info ============================
FAILED tests/test_generated.py::test_apply_coupon_unknown_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_expired_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date - shop.c...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_expired
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_not_set
5 failed, 1 passed in 0.71s
```

Six tests, and five fail. Look at what each fails with before deciding what it says.
`test_apply_coupon_code_with_end_date` fails with `ExpiredCoupon: FRIENDS15` (shortened to
`shop.c...` in the summary): it uses 31 October, line 25, and expects the coupon to work, so **it
found the bug**. `test_apply_coupon_code_with_end_date_not_set`, the last in the file, also uses 31
October, and the traceback above the summary is its failure: the same refusal, from the same line.
The other three are `NameError`s, names the file uses and never imported, although the request
asked for every import. And one of those three, `test_apply_coupon_code_with_end_date_expired`,
also uses 31 October, line 31, and you will see in lesson 4 section 05 what it expects of that day.

```
ana@dev:~/shop$ sed -i "1i from datetime import date" tests/test_generated.py && python -m pytest -q tests/test_generated.py | tail -n 15
        if code not in COUPONS:
            raise UnknownCoupon(code)
        percent, until = COUPONS[code]
        if until is not None and today >= until:
>           raise ExpiredCoupon(code)
E           shop.coupons.ExpiredCoupon: FRIENDS15

shop/coupons.py:25: ExpiredCoupon
=========================== short test summary info ============================
FAILED tests/test_generated.py::test_apply_coupon_unknown_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_expired_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date - shop.c...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_expired
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_not_set
5 failed, 1 passed in 0.70s
```

ana adds the import of `date`, the repair a generated test file needs most often. This file had it
already, and nothing changes: its five failures are of the two other kinds. **So the file
disagrees with itself about 31 October**, and nothing in it says which of its tests is right. That
is the honest description of a generated test file: a list of guesses about what the code should
do, some of them read off the code, to be checked against something that is not the code.

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
