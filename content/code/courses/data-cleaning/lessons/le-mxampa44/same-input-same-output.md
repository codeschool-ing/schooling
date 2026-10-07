---
title: Same input, same output
version: 1
---

**Reproducible** has a precise meaning: given the same inputs and the same code, the pipeline
produces the same outputs. Not similar outputs, the same bytes. That can be tested with the same
fingerprints that protect the raw files:

```
ana@lab:~/clean$ sha256sum out/*.csv > /tmp/first.sha256 && python run.py 2>/dev/null && sha256sum --check /tmp/first.sha256
out/changes.csv: OK
out/customers.csv: OK
out/orders.csv: OK
```

The fingerprints of the three outputs are taken, the whole pipeline runs again from raw, and every
file matches. If one did not, something in the pipeline would depend on more than its inputs and its
code, and the usual suspects are worth knowing:

- **The clock.** A column computed from "today", such as an age or a number of days since the last
  order, changes every day. Lesson 12 counted days from a fixed date, 1 January 2026, which is why
  its output will not change tomorrow.
- **Randomness without a seed.** A sample, a shuffle or a model that draws random numbers gives a
  different answer each run unless the seed is fixed and written down.
- **Order that nobody asked for.** A table written in whatever order a `groupby` or a hash returned
  it can change between versions of a library; sort before writing when the order matters.
- **The environment.** Lesson 1 installs every library at a pinned version, `pandas==3.0.6`
  and the rest, because a new version can change a default and, with it, an output.

A pipeline that passes this test turns a disagreement into something tractable. If two people get
different numbers, either their inputs differ, which the raw manifest shows, or their code differs,
which version control shows. **There is no third place for the difference to hide.**
