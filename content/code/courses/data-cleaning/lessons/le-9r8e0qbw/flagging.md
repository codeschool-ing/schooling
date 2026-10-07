---
title: Flagging: keep the blank and say why
version: 1
---

**The fourth move does not guess at all. It keeps the blank and adds a column that says what the
blank means.** For MNAR data it is often the only honest option, and it frequently answers the
question better than any fill.

The own fleet's delivery times, flagged:

```python
from minutes import own, report

own["timing"] = own["minutes"].notna().map({True: "recorded", False: "over 120"})
print(own["timing"].value_counts().to_string())
floor = own["minutes"].fillna(120)
report("blanks as 120, a floor", floor)
```

```
ana@lab:~/clean$ python flag.py
timing
recorded    14858
over 120      456
blanks as 120, a floor mean  61.2  sd 23.2  late 13.2%
```

The new column, `timing`, says `recorded` for 14,858 deliveries and `over 120` for 456. Nothing has
been invented. But what lesson 3 learnt from operations is now in the data: **a blank here means at
least 120 minutes.** That turns a missing value into a bound, and a bound can be used.

- **The late share is exact.** Every flagged delivery took 120 minutes or more, so every one is
  late by the 90-minute rule. Counting them gives 13.2%.
- **The mean has a floor.** Treating each flagged delivery as exactly 120 gives 61.2 minutes, the
  lowest the real mean can be, and the report says "at least 61.2".

Against the truth file:

```
ana@lab:~/clean$ python -c "import pandas as pd; t = pd.read_csv('~/clean-data/truth/orders.csv'); m = t.loc[t['what'] == 'minutes', 'value']; print(f'real: mean {m.mean():.1f}, late {(m >= 90).mean() * 100:.1f}%')"
real: mean 61.9, late 13.2%
```

The late share is exactly right, 13.2%, where every fill earlier in this lesson said 10.2% or
10.5%. The mean is 61.9, inside the bound. **The humblest move gave the best answer**, because it
carried the one thing that was known about the blanks instead of replacing it with something that
was not.

A flag also serves the next person. A column filled with medians looks complete and gives no hint
that 456 of its values are guesses; a flag says which rows to trust for which question, and lets
somebody with a better method use it without undoing anything.
