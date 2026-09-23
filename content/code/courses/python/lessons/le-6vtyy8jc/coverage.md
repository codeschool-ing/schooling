---
title: The number says what ran, not what was checked
version: 2
---

```sh
pytest --cov=app --cov-report=term-missing
```

```sh
Name              Stmts   Miss  Cover   Missing
-----------------------------------------------
app/__init__.py       0      0   100%
app/rates.py          6      2    67%   4-5
-----------------------------------------------
TOTAL                 6      2    67%
```

**`Missing` is the useful column.** The percentage is a headline; lines 4 and 5 are a place to
look. Here they are the body of `fetch`, which a `monkeypatch` replaced — so the number is
telling the truth and the truth is that nothing exercised the real one.

## A hundred per cent, with a bug

```python
def tax(amount, rate):
    return amount * rate * 2        # doubled

def test_total_runs():
    result = total([(2, 10.0)], 0.1)
    assert result is not None
```

```sh
app/invoice.py        7      0   100%
1 passed
```

Every line ran. Nothing about the answer was asserted. **Coverage measures execution and has no
way to see an assertion**, so it cannot distinguish a proven line from a line that merely
happened — and this is not a hypothetical, it is the module the demonstration finds a doubled tax
in.

## What it is good for

The other direction. A line at 0% is a line no test has ever run, and that list is reliable,
specific and worth reading. Coverage is a **finder of gaps**, not a measure of quality — and the
gap it finds is usually an error path somebody wrote and never exercised.

## Branch coverage

```sh
pytest --cov=app --cov-branch --cov-report=term-missing
```

```sh
Name              Stmts   Miss Branch BrPart  Cover   Missing
-------------------------------------------------------------
app/guard.py          4      1      2      1    67%   4
```

Without `--cov-branch`, an `if` whose body always ran counts as covered even though the other way
through it never did. With it, a partly-taken branch is reported as `BrPart`. It is closer to the
question you meant to ask.

## The target in CI

```toml
[tool.coverage.report]
fail_under = 80
```

A floor that stops the number falling is defensible. A target somebody has to reach is where
tests get written to touch lines rather than to check behaviour, and `assert result is not None`
is what that produces.

**Coverage is not a target.** Write the test that would have caught the failure you just found,
and the one for the failure mode you can name.
