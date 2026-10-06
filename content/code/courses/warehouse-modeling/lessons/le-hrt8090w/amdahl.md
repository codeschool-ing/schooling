---
title: Amdahl's law, the limit on parallel work
version: 1
---

Gene Amdahl stated in 1967 the limit the previous section ran into. If a fraction *p* of a job can be
spread across processors and the rest cannot, then with *n* processors the best possible speed-up is:

```
speed-up(n) = 1 / ((1 - p) + p / n)
```

The part that cannot be split, `1 - p`, takes the same time whatever *n* is. As *n* grows, the parallel
part shrinks towards nothing and the serial part is all that is left, so the speed-up can never exceed
`1 / (1 - p)`.

Worked through for a job that is 90% parallel:

| processors | speed-up |
|---|---|
| 1 | 1.0 |
| 2 | 1.8 |
| 4 | 3.1 |
| 16 | 6.4 |
| as many as you like | at most 10 |

**Ten is the ceiling, and sixteen processors already reach two thirds of it.** Every processor beyond
that buys less than the one before. For a job that is 99% parallel the ceiling is 100; for one that is
50% parallel it is 2.

Two lessons for warehouses follow:

- **Scaling up has diminishing returns within one query**, which is why the four threads of section 03
  gave less than four times the speed.
- **Scaling out has the same law plus a new serial part**: moving data between machines and combining
  their answers. A distributed query whose machines spend half their time exchanging rows has *p* well
  below 1 however many machines it has. Sections 07 to 09 are about keeping that exchange small.

Amdahl's law is about one job. A warehouse also runs many queries at once, and twelve analysts running
twelve queries on twelve machines can each get a whole machine. That kind of scaling, more users rather
than faster single queries, is the one that scaling out does best, and section 11 comes back to it.
