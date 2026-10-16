---
title: When apply is the right tool
version: 1
---

**`apply` is right when the calculation genuinely needs Python, and the number of calls is small.**
Both halves matter. A loop over twelve months costs nothing; a loop over a million rows costs
minutes, whatever it computes.

The longest run of dry days in each month is a calculation of the first kind. Each day depends on the
days before it, so there is no single column expression for it, and a plain loop says it clearly:

```python
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")

def longest_dry(rain):
    best = run = 0
    for r in rain:
        run = run + 1 if r == 0 else 0
        best = max(best, run)
    return best

dry = weather.groupby(weather["date"].dt.month)["rain_mm"].agg(longest_dry)
dry.tolist()
```

```
[8, 10, 7, 2, 2, 1, 3, 5, 9, 9, 7, 12]
```

December had a run of 12 dry days, June only 1. Twelve calls, one per month, each over about
thirty values:

```python
t_dry = %timeit -o -q weather.groupby(weather["date"].dt.month)["rain_mm"].agg(longest_dry)
round(t_dry.average * 1000, 1)
```

```
1.2
```

About a millisecond. Nobody should rewrite that to save time. **Measure before you optimise**: a slow
path that runs twelve times is not slow.

The function also makes a decision visible, which is worth as much as its speed. `r == 0` is
`False` for a missing reading, so a day with no reading **breaks** a dry run instead of extending it.
That is one honest choice; counting unknown days as dry is another. On `weather.csv` the two give the
same twelve numbers, because none of the six unread days sits where it would lengthen a month's
longest run, and on other data they need not agree. In a function the choice is one line you can read
and change; hidden in a clever vectorised expression it would be much harder to see.

## Formatting is the other case

`DataFrame.map` applies a function to every cell, which suits presentation more than calculation,
on a table already small enough to read:

```python
summary = trips.groupby("plan")[["minutes"]].median()
summary.map(lambda v: f"{v:.1f} min")
```

```
         minutes
plan            
annual  12.4 min
day     19.9 min
```

The result is text, ready to print or paste, and no longer numbers. Keep the numeric table for
anything that computes, and format at the end.

**The rule this lesson leaves**: write the column expression when one exists, which is most of the
time; use `map` with a dictionary for lookups; and keep `apply` for logic that needs Python, applied
to few enough pieces that the loop does not matter.
