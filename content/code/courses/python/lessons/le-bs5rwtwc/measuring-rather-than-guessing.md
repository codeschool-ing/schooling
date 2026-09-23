---
title: `timeit` for the expression, `cProfile` for the program
version: 2
---

```sh
python -m timeit -s "data = list(range(100_000))" "99_999 in data"
```

```sh
500 loops, best of 5: 866 usec per loop
```

`-s` is setup, run once and not timed. The statement is run many times and the **best** run is
reported, because the slow runs are other processes rather than your code.

```python
import timeit
timeit.timeit("99_999 in data", "data = list(range(100_000))", number=1000)
```

The same thing from inside a program, returning the total seconds for `number` runs.

## What `timeit` is not for

A function that touches the network, the disk or a database. The variance swamps the measurement,
and running it a thousand times is rude to whatever is on the other end. `timeit` is for a small,
pure expression you can repeat.

## `cProfile`, for a program

```sh
python -m cProfile -s tottime report.py
```

```sh
   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
    17145   13.879    0.001   13.879    0.001 report.py:15(find_customer)
    20000    0.490    0.000    0.490    0.000 report.py:12(allowed)
        1    0.054    0.054   14.423   14.423 report.py:31(<listcomp>)
```

- **`tottime`** — time in that function, **not** counting what it called. This is the column to
  sort by when looking for the slow thing.
- **`cumtime`** — time in that function and everything it called. Sorting by this puts `main` at
  the top, which is true and useless.
- **`ncalls`** — how often. A cheap function called two million times is a real finding.

## The profile is per function, and that is a limit

```sh
        1   18.307   18.307   18.317   18.317 report.py:12(report)
```

The first profile of that program said `report`, which is the whole thing. **A profiler cannot
see inside a function**, so a two-hundred-line function tells you nothing you did not know.

The fix is to split it — three functions instead of one — and run it again, which is what turned
the line above into the table above it. `line_profiler` is a third-party tool that does report
per line, and splitting the function is usually better anyway.

## The overhead

The profiled run above took 18 seconds where the plain run took 9. `cProfile` instruments every
call, so **absolute times under it are wrong** and a function that makes many small calls looks
worse than it is. Read the profile for the shape, then time the fix without it.

## The one rule

```sh
first fix, the obvious one:   9.0s → 8.4s     7%
second fix, the profiled one: 8.4s → 0.0166s  544×
```

**Profile before changing anything.** In the demonstration, the change that looked most wrong was
worth seven per cent, and the one the profiler named was worth five hundred times.
