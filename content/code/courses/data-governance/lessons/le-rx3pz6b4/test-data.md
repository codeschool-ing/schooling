---
title: Test data that cannot be anybody
version: 1
---

Lesson 5 built a masked copy for developers and said that, for most work, generated data is better
than any copy. Ipê's own data is generated — by lesson 1's `generate.py`, with fixed seeds — and it was built
so that it **cannot be real**, which is a property worth checking rather than trusting.

The CPF is the clearest case. A CPF has eleven digits, and the last two are check digits computed from
the first nine. A number whose check digits are right *might* belong to somebody; one whose check
digits are wrong belongs to nobody. The generator makes the first check digit right and the second
deliberately wrong. The plaintext CPFs left the database in lesson 5, so the check reads the file the
lab loaded them from:

```python
"""How many CPFs in the file pass their own check digits."""
import csv, sys

def digit_ok(cpf, n):
    """Is the n-th digit (9 or 10, from zero) the check digit it should be?"""
    d = [int(c) for c in cpf if c.isdigit()]
    s = sum(v * w for v, w in zip(d[:n], range(n + 1, 1, -1)))
    return (s * 10 % 11) % 10 == d[n]

rows = list(csv.DictReader(open(sys.argv[1])))
first = sum(digit_ok(r["cpf"], 9) for r in rows)
both = sum(digit_ok(r["cpf"], 9) and digit_ok(r["cpf"], 10) for r in rows)
print(len(rows), "CPFs:", first, "pass the first check digit,", both, "pass both")
```

```
ana@lab:~/gov$ python3 cpf_check.py /var/lib/ipe-data/customers.csv
6012 CPFs: 6012 pass the first check digit, 0 pass both
```

All 6,012 pass the first check digit — the validator works — and **none passes both.** No customer in
this course has a CPF that could be a real person's.

The rest of the generator follows the same rule, and its header says so:

- every e-mail address is under `example.com`, `example.net` or `example.org`, domains reserved for
  documentation, so no message sent by a test can reach anybody;
- no telephone number is generated at all, because Brazil reserves no range of numbers for fiction;
- names are a first name and two surnames drawn from lists of common ones, and the combination is
  chance;
- card numbers are never generated — payments carry a token and four digits, as lesson 5 described.

## Why this matters beyond the lab

Test data escapes. It goes into screenshots, demos, bug reports, training material and, now and then,
an e-mail campaign pointed at the wrong database. **Generated data that cannot be real makes every one
of those accidents harmless**, which a masked copy of production never fully does. It is also the
only kind of data a company can put in a public repository — this course's included — without a
second thought.
