---
title: A header is data in disguise
version: 1
---

After melting, the old headers are values in a column, `jan/25`, `fev/25` and so on, and they are
still text. A month that is text sorts alphabetically, `abr` before `fev`, and cannot be joined to
a month computed from a date. It has to become a real month.

The tempting shortcut is to let a date parser read the abbreviation:

```
ana@lab:~/clean$ python -c "import pandas as pd; print(pd.to_datetime('fev/25', format='%b/%y'))" 2>&1 | grep ^ValueError
ValueError: time data "fev/25" doesn't match format "%b/%y". You might want to try:
```

`%b` means "abbreviated month name", and **whose abbreviations depends on the machine's locale**.
Python reads month names in a neutral locale unless a program asks for another, so it knows `Feb`
and not `fev`. A machine set to Portuguese might parse it, and then the same script would work on
one laptop and fail on the server that runs it every night.

So `targets.py`, in the previous section, spells the twelve months out in a dictionary. That is
twelve lines of nothing clever, and it has two virtues a parser lacks: it reads the same on every
machine, and **an unknown header stops the script** instead of becoming a blank month. If the team
one day writes `Fev/25` or `fevereiro/25`, the error names it.

The result has the type `period[M]`, a month as a value: it sorts in time order, it knows that
2025-12 is followed by 2026-01, and it is exactly what `.dt.to_period("M")` produces from a date.
That last property is what the join in two sections' time depends on. **A join key must have the
same type on both sides**, and a month written two ways is two keys that never meet.
