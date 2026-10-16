---
title: Higher-order functions and composition
version: 1
---

**A higher-order function takes a function as an argument or returns one.** Python, Java, Go and
TypeScript all treat functions as values, so this is less exotic than its name: `sorted(loans,
key=...)` is a higher-order function, and so is every callback you have ever passed. What the
functional style adds is the habit of building behaviour by combining small functions, rather than
by writing a class for each variation.

## Three uses in one file

```schooling-example
{"language": "python", "file": "hof.py", "parts": [
 {"code": "# hof.py\nfrom functools import reduce\nfrom typing import Callable\n\nLOANS = [(\"Dom Casmurro\", 4), (\"Central do Brasil\", 15), (\"Iracema\", 0), (\"Cidade de Deus\", 4)]", "note": "Four loans as title and days late, the numbers of lesson 14's report."},
 {"code": "\n\ndef per_day(cents: int) -> Callable[[int], int]:\n    def fine(days_late: int) -> int:\n        return days_late * cents\n    return fine", "note": "A function that returns a function. The inner `fine` remembers `cents` after `per_day` has returned; that remembered variable is a *closure*."},
 {"code": "\n\ndef capped(limit: int) -> Callable[[int], int]:\n    return lambda cents: min(cents, limit)", "note": "The same idea written as a `lambda`: a function that takes an amount and never lets it pass `limit`."},
 {"code": "\n\ndef pipeline(*steps: Callable) -> Callable:\n    return lambda value: reduce(lambda acc, step: step(acc), steps, value)", "note": "Composition: given functions, build the one that applies them in turn, left to right. `reduce` feeds each step's output to the next."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(\"most late first:\", [title for title, _ in sorted(LOANS, key=lambda loan: loan[1], reverse=True)])\n    standard = per_day(50)\n    print(\"50 a day:\", [standard(days) for _, days in LOANS])\n    gentle = pipeline(per_day(50), capped(500))\n    print(\"capped at 500:\", [gentle(days) for _, days in LOANS])", "note": "Passing a function (`key=`), getting one back (`per_day(50)`) and composing two (`pipeline`). The cap is an invented policy, here to have something to compose."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 hof.py
most late first: ['Central do Brasil', 'Dom Casmurro', 'Cidade de Deus', 'Iracema']
50 a day: [200, 750, 0, 200]
capped at 500: [200, 500, 0, 200]
```

The sort put *Dom Casmurro* before *Cidade de Deus*, both four days late, because Python's sort is
**stable**: items that compare equal keep their original order. Fifteen days at 50 cents is 750,
and the capped policy turns it into 500 without either function knowing about the other.

## Strategy without the classes

Look at `per_day(50)` and `capped(500)` again. In lesson 6, a strategy was an interface with one
method and a class per variation. **When the interface has a single method, a function is the
strategy**, and the class around it is ceremony. Peter Norvig made this point in 1996 about
dynamic languages: several of the classic patterns become invisible, or a line long, once functions
are values. A fine policy is a `Callable[[int], int]`; a new policy is a new function; the code that
applies it does not change.

The class version still earns its place when the strategy carries several related methods, or state
that a reader should see named, or needs to be found by a dependency-injection container. One
method and no state is a function.

## Composition, and its order

Mathematics writes composition right to left: *(f ∘ g)(x)* is *f(g(x))*, so *g* runs first. The
`pipeline` above runs left to right, in reading order, which is what Unix pipes, method chains and
most data-processing libraries do. Neither is wrong; know which one a library means before you
trust it. `pipeline(per_day(50), capped(500))` and `pipeline(capped(500), per_day(50))` are
different policies: the second caps the *days* at 500 before multiplying, and caps nothing in
practice.

Where composition helps is in keeping each step small enough to test alone and to reuse. Where it
hurts is in debugging: a stack trace through four lambdas built by `reduce` says less than a loop
with named variables. **Name the steps that mean something in the domain**, as `per_day` and
`capped` do, and the composed result stays readable.
