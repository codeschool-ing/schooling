---
title: Tests that give the same answer every time
version: 1
---

A test is useful only if it gives the same answer for the same code. A test that sometimes passes
and sometimes fails, with no change in between, is called **flaky**, and it is worse than no test:
it trains everybody to re-run failures until they go green, which is exactly how a real failure gets
ignored. Most flakiness comes from three sources a test did not control: **time, randomness and
order.** Section 03 covered order. This section covers the other two.

## Time

`shipquote`'s dispatch rule depends on the clock: an order before 14:00 leaves the same day. The
function could have read the clock itself:

```python
def dispatch_date():
    local = datetime.now(WAREHOUSE)
    ...
```

and every test of it would then depend on when it ran. A test asserting "same day" passes in the
morning and fails after two in the afternoon. Instead, `dispatch_date` takes the moment as an
argument, a seam exactly like lesson 2's carrier:

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

and the tests pass fixed Unix timestamps, with the date and time they stand for written beside them:

```python
# 2026-10-05 is a Monday, and São Paulo is three hours behind UTC.
MONDAY_1330_SP = 1791217800                    # 16:30 UTC
MONDAY_1430_SP = MONDAY_1330_SP + 3600
FRIDAY_1500_SP = MONDAY_1330_SP + 4 * 86400 + 5400
```

**The clock is an input.** Code that needs "now" should receive it, from a parameter or a clock
object, and only the outermost layer, the HTTP handler or the command-line entry point, asks the
real clock. Lesson 5 shows a draft of this function that took the moment as an argument and still
failed on some machines, for a reason that had nothing to do with the hour and everything to do with
where the machine thinks it is: notice the `WAREHOUSE` zone on line 11.

## Randomness

Random data in tests is sometimes the point: varied inputs find bugs that hand-picked ones miss,
which is the subject of the next section. But random data must be **reproducible**. A generator
started from a fixed seed produces the same sequence every time:

```
ana@laptop:~/shipquote$ python3 -c 'import random; random.seed(7); print(random.sample(range(100), 5))'
[41, 19, 50, 83, 6]
ana@laptop:~/shipquote$ python3 -c 'import random; random.seed(7); print(random.sample(range(100), 5))'
[41, 19, 50, 83, 6]
```

Same seed, same five numbers, on any machine running this Python. A test that uses randomness
should either fix the seed, or print the seed it used when it fails, so the failure can be replayed.
The tool in the next section does the second automatically.

## Spotting the rest

Other sources of non-determinism worth checking for in review: iteration over a `set`, whose
order is not guaranteed; dictionaries built from such iterations; floating-point sums whose order
changes; anything reading `os.environ` without the test setting it; and network calls, which lesson
2 replaced with doubles. Each is a place where the same code can give two answers.
