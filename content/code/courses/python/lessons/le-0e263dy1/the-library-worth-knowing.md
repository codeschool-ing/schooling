---
title: Ten modules, one line each
version: 1
---

You are not meant to memorise these. You are meant to remember that they exist, so that the next
time the problem shows up you look before you write.

| module | for |
| --- | --- |
| `pathlib` | paths as objects — join, test, read, walk a directory |
| `datetime` | dates, times, and the arithmetic between them |
| `collections` | `Counter`, `defaultdict`, `deque`, `namedtuple` |
| `itertools` | building blocks for loops that would otherwise nest |
| `json` | read and write JSON — lesson 9 |
| `re` | regular expressions — lesson 10 |
| `math` | square roots, logarithms, `inf`, `isclose` |
| `random` | a choice, a shuffle, a number in a range |
| `os` | the environment, and the things `pathlib` does not cover |
| `sys` | arguments, exit codes, the path, standard streams |

## Four more that come up constantly

`csv` for anything a spreadsheet produced, `statistics` for a mean or a median, `textwrap` for
wrapping and dedenting, `subprocess` for running another program.

## And the shape of the question

Most of what a beginner writes by hand is in here. A few examples, each of which is a section of
somebody's first program:

- counting occurrences → `collections.Counter`
- "today plus thirty days" → `datetime.timedelta`
- building a file path → `pathlib.Path`
- every combination of two lists → `itertools.product`
- "is this number close enough" → `math.isclose`

**The test is not whether you know the function. It is whether you think to look**, and the habit
is worth more than any one of the modules above.

## What is NOT in here

HTTP requests (`requests`, lesson 21 — `urllib` exists and is unpleasant), data frames
(`pandas`), arrays (`numpy`), and anything to do with the web. Those are dependencies, and
lesson 18 is where installing one properly happens.
