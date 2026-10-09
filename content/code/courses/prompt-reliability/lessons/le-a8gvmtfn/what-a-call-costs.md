---
title: What a call costs
version: 2
---

On your own machine a call costs time and electricity, and the time is what the last section
measured. A hosted model charges by the token instead, with one price for tokens read and a higher
one for tokens written. To do that arithmetic you need a price list, and this course writes its own
rather than copy a provider's, because real price lists change often enough that any number copied
into a lesson would be wrong within a year. Save it as `prices.json`:

```json
{
  "note": "cents per million tokens, written by the course for its arithmetic, not any provider's prices",
  "input": 300,
  "output": 1500
}
```

**These prices were written by the course**, as the file says, and they are in whole cents per
million tokens: 300 cents for a million input tokens, 1500 for a million output tokens. Real price
lists have the same shape, a price per million tokens with output dearer than input. To use the
program below with a provider, put that provider's prices in the file.

## The arithmetic

This program adds up the tokens of a run and multiplies. Save it as `cost.py`:

```python
"""cost: what a run would cost at the prices in prices.json, which are whole
cents per million tokens. Every product is a whole number; the one division
happens at the end, and so does the one rounding."""
import json
import sys
from decimal import ROUND_HALF_UP, Decimal

from pl import read_jsonl

prices = json.load(open("prices.json", encoding="utf-8"))


def cents(units):
    """units are cents times tokens; a million of them is one cent."""
    return (Decimal(units) / 1_000_000).quantize(Decimal("0.0001"), ROUND_HALF_UP)


for path in sys.argv[1:]:
    rows = read_jsonl(path)
    tin = sum(r["tokens_in"] for r in rows)
    tout = sum(r["tokens_out"] for r in rows)
    units = tin * prices["input"] + tout * prices["output"]
    print("%s, %d calls" % (path, len(rows)))
    print("  input    %7d tokens   %8.1f a call" % (tin, tin / len(rows)))
    print("  output   %7d tokens   %8.1f a call" % (tout, tout / len(rows)))
    print("  these calls      %s cents" % cents(units))
    print("  a million calls  %s cents" % cents(Decimal(units) * 1_000_000 / len(rows)))
```

```
ana@lab:~/triage$ python3 cost.py runs/v3.jsonl
runs/v3.jsonl, 40 calls
  input       9926 tokens      248.2 a call
  output      1226 tokens       30.6 a call
  these calls      4.8168 cents
  a million calls  120420.0000 cents
```

The forty calls read 9926 tokens and wrote 1226. At 300 and 1500 cents a million, that is
9926 × 300 + 1226 × 1500 = 2,977,800 + 1,839,000 = 4,816,800 cent-tokens, which `cents()` divides by
a million once to give the 4.8168 cents on the line below. Divide by forty for one call, 0.12042
cents, and multiply by a million for the last line. **Output was 11% of the tokens and 38% of the
cost**, because each output token costs five times as much. That is the same lesson as the last
section, in money.

The last line is the one to put in front of somebody deciding whether to ship: 120,420 cents for a
million calls like these. A cost per call sounds like nothing; a cost per million is a budget.

## Why money is never a float

The program never touches a fractional number on the way to that total, and its opening comment
says so. Tokens are whole and prices are whole cents per million, so their product is a whole
number, exact. **Nothing is rounded until the very end**, once, half up, at the fourth decimal
place, by Python's `decimal` module, which does arithmetic in decimal digits the way a person with a
pencil does. The alternative looks harmless and is not:

```
ana@lab:~/triage$ python3 -c 'print(0.1 + 0.2)'
0.30000000000000004
```

A binary floating-point number cannot hold most decimal fractions exactly, so `0.1` is stored as
the nearest value it can hold, and sums of such values drift. One drift is invisible; the same
computation over every call of a month, compared with an invoice computed another way, produces a
difference somebody has to explain. **Keep money as an integer count of the smallest unit you
charge in**, multiply integers, and round once, with a rule you wrote down.
