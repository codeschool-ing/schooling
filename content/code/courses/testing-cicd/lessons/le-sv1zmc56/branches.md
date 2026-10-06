---
title: Lines and branches
version: 1
---

Line coverage asks whether each line ran. **Branch coverage** asks, at every decision, whether each
way out was taken. The difference shows up at an `if` with no `else`, and `shipquote`'s dispatch
rule has one:

```python
def dispatch_date(ordered_at: float) -> date:
    """The day an order placed at this Unix time leaves the warehouse."""
    local = datetime.fromtimestamp(ordered_at, WAREHOUSE)
    day = local.date()
    if local.time() >= CUTOFF:
        day += timedelta(days=1)
    while day.weekday() >= 5:     # Saturday and Sunday
        day += timedelta(days=1)
    return day
```

Line 13 decides whether the order is after the cut-off. If it is, line 14 adds a day. If it is not,
execution goes straight from line 13 to line 15. Here two of the three dispatch tests run on their
own, the after-two order on Monday and the Friday-afternoon order. **Both are after 14:00**, so the
"before the cut-off" path is never taken.

First with line coverage only, by telling `coverage` to ignore the project's configuration:

```
ana@laptop:~/shipquote$ coverage run --rcfile=/dev/null --source=shipquote -m pytest -q tests/test_dispatch.py -k "after_two or friday"
..                                                                       [100%]
2 passed, 1 deselected in 0.19s
ana@laptop:~/shipquote$ coverage report --rcfile=/dev/null -m --include=shipquote/dispatch.py
Name                    Stmts   Miss  Cover   Missing
-----------------------------------------------------
shipquote/dispatch.py      12      0   100%
-----------------------------------------------------
TOTAL                      12      0   100%
```

**100%.** Every line ran: line 14 ran for both orders, and the weekend loop on 15 and 16 ran for
the Friday one. Nothing in this report says the most common case of all, an order before two, was
never tried.

Then with the project's configuration, which turns branches on:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q tests/test_dispatch.py -k "after_two or friday"
..                                                                       [100%]
2 passed, 1 deselected in 0.19s
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/dispatch.py
Name                    Stmts   Miss Branch BrPart  Cover   Missing
-------------------------------------------------------------------
shipquote/dispatch.py      12      0      4      1    94%   13->15
-------------------------------------------------------------------
TOTAL                      12      0      4      1    94%
```

**94%**, and the missing entry is not a line but an arc: `13->15`, the jump from the decision
straight to the loop, which happens only when the order is before the cut-off. A bug in that path,
an order at 13:30 sent to the next day, would pass these two tests and the line report alike.

## Why branch coverage is the default to want

Line coverage is the number most tools show first, and it systematically overstates what was
tested: every `if` without an `else` is a place where only one of the two outcomes needs to happen
for the line to count. Branch coverage closes that gap at almost no cost, which is why `shipquote`
turns it on in `pyproject.toml` and why the team's report shows `Branch` and `BrPart` columns.

## What neither of them sees

Both measure jumps **between lines**. A decision that lives inside one line is invisible to both:

```python
    sign = "-" if cents < 0 else ""
```

That line in `brl` is covered by every test that formats a price, and no test in `shipquote` ever
formats a negative one. Line and branch coverage both report it as fully covered. Short-circuit
expressions like `a or b` hide the same way. Coverage is a floor: it can tell you something was
never run, and it can be fooled into saying something was.
