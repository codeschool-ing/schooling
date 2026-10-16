---
title: "Pure functions: same arguments, same answer, nothing else"
version: 1
---

**Functional programming is often taken to mean a language: Haskell, Clojure, F#. The ideas that
pay their way in a back-end codebase are smaller and portable**, and the first of them fits in one
sentence. A pure function returns a value that depends only on its arguments, and does nothing else:
it changes no variable outside itself, writes no file, sends no message, reads no clock.

Each half of that definition rules out something specific. *Depends only on its arguments* rules
out reading a global that someone else can change, the current time, a random number or a database
row. *Does nothing else* rules out writing to any of those. What is left is a function you can call
twice with the same arguments and get the same answer, in any order, on any day, with nothing in
the world different afterwards.

Make `~/patterns/functional` and work there:

```sh
mkdir -p ~/patterns/functional
cd ~/patterns/functional
```

## Two ways to compute a fine

```schooling-example
{"language": "python", "file": "pure.py", "parts": [
 {"code": "# pure.py\nfrom datetime import date\n\ndaily_fine = 50\nfines_charged = []", "note": "Two module-level variables, the kind of shared state a codebase collects over the years."},
 {"code": "\n\ndef charge(due: date, returned: date) -> int:\n    cents = max((returned - due).days, 0) * daily_fine\n    fines_charged.append(cents)\n    return cents", "note": "Impure twice over. It reads `daily_fine`, which anybody can rebind, and it appends to `fines_charged`, which changes the world each time it is called."},
 {"code": "\n\ndef fine(due: date, returned: date, daily: int = 50) -> int:\n    return max((returned - due).days, 0) * daily", "note": "Pure. The daily rate is an argument with a default, so the function's whole input is in its signature."},
 {"code": "\n\nif __name__ == \"__main__\":\n    due, back = date(2026, 3, 16), date(2026, 3, 20)\n    print(\"charge:\", charge(due, back), charge(due, back), \"log:\", fines_charged)\n    daily_fine = 100\n    print(\"charge, same arguments:\", charge(due, back))\n    print(\"fine:\", fine(due, back), fine(due, back), fine(due, back, daily=100))", "note": "The line `daily_fine = 100` stands for some other module changing the setting. It runs at module level, so it rebinds the global that `charge` reads."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 pure.py
charge: 200 200 log: [200, 200]
charge, same arguments: 400
fine: 200 200 400
```

`charge` was called three times with the same two dates and answered 200, 200 and 400, and the log
grew by one entry per call. To know what `charge(due, back)` returns you need its arguments, the
current value of a global and the knowledge that calling it has consequences. `fine` answered 200
every time, and 400 only when it was asked for 400.

## What purity buys

**A pure function can be understood from its signature and its body, and nothing else.** That is the
whole benefit, and it shows up in four practical forms:

- testing: the test is a call and an assertion, with no setup and no clean-up. Lesson 13's
  `overdue` was pure for this reason;
- reasoning: `fine(due, back)` can be replaced by its value anywhere in the program without changing
  what the program does. The term for this is *referential transparency*;
- caching: if the answer depends only on the arguments, it can be remembered.
  `functools.cache` on an impure function returns stale answers; on a pure one it is always safe;
- concurrency: two threads calling `fine` at once cannot interfere, because it touches nothing
  shared. Lesson 18 shows what happens to code that does.

## Pure on the outside

Purity is a property of what a caller can observe, not of every line. A function that builds a
local list with `append` and returns it is pure: the list is created inside the call and nobody else
can see it change. The section on side effects at the edges uses exactly that shape. What breaks
purity is mutation that escapes: changing an argument the caller still holds, or anything at module
level.

Python does not check any of this. Neither do Java, Go or TypeScript. Haskell does, through its type
system. In the four languages of this course, purity is a discipline you keep and a reviewer can
see: a function that takes everything it needs as arguments and returns everything it produces is
pure by inspection.
