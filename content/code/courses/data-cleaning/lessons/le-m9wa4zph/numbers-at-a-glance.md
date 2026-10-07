---
title: Numbers at a glance: the ends and the middle
version: 1
---

**For a numeric column, the profile adds the summary `statistics` taught: the centre, the spread
and, above all, the two ends.** Most defects in a numeric column live at its ends, because a typo
or a placeholder is almost always much larger or much smaller than the honest values around it.

The order totals, read as numbers this time:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o['total'].describe())"
count    28551.000000
mean        94.112222
std        242.545325
min        -17.050000
25%         32.700000
50%         57.600000
75%        106.500000
max      26928.500000
Name: total, dtype: float64
```

Three things in eight lines.

**The minimum is negative.** An order total of −R$ 17.05 is not a refund — refunds have their own
status — and there is nothing in this business that pays a customer for buying vegetables. It is
the first thing to look at:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o.loc[o['total'] < 0, ['order_id', 'total', 'discount', 'delivery_fee', 'fulfilment']])"
       order_id  total  discount  delivery_fee fulfilment
144      100145  -2.20      20.0           9.9   delivery
328      100329  -1.85      15.0           9.9   delivery
351      100352  -0.20      10.0           0.0     pickup
800      100801  -4.20      20.0           9.9   delivery
838      100839  -4.20      20.0           9.9   delivery
...         ...    ...       ...           ...        ...
27060    127036  -2.15      20.0           0.0     pickup
27125    127101  -2.10      20.0           0.0     pickup
27914    127890  -6.20      20.0           9.9   delivery
27961    127937  -2.65      20.0           9.9   delivery
28096    128072 -12.10      20.0           0.0     pickup

[137 rows x 5 columns]
```

137 orders, all with a coupon worth more than the basket plus the delivery fee. The order of
R$ 7.90 with a R$ 20.00 coupon was recorded as −R$ 12.10. The website accepted a coupon larger than
the order and subtracted it anyway; what the customer was actually charged is a question for
whoever runs payments, and almost certainly zero. **A rule nobody wrote down — a total cannot be
negative — is the kind of validity check a profile suggests**, and lesson 9 decides what to do with
these rows.

**The standard deviation, 242.55, is more than two and a half times the mean, 94.11.** For order
values, which cannot go far below zero, that only happens when a few values sit very far above
the rest. `statistics` lesson 7 called this a long right tail.

**The maximum is R$ 26,928.50**, against a median of R$ 57.60. Percentiles show where the tail
begins:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o['total'].quantile([0.5, 0.9, 0.99, 0.999, 1]))"
0.500       57.6000
0.900      204.4000
0.990      481.2750
0.999      764.3925
1.000    26928.5000
Name: total, dtype: float64
```

Ninety-nine orders in a hundred are under R$ 481.28, and 999 in a thousand under R$ 764.39. The
largest is thirty-five times that. **The jump from the 99.9th percentile to the maximum is the
picture of an outlier in one line**, and it says nothing yet about whether the order is real.
Lesson 9 separates the corporate Christmas orders, which are real, from totals typed with a zero
too many, which are not.

## Why not just look at the mean?

Because the mean is pulled by exactly the values a profile is looking for. 137 negative totals and
a few totals in the tens of thousands move the mean in opposite directions, and a mean of R$ 94
looks like an ordinary number. **The minimum, the maximum and a handful of percentiles cost
nothing to print and are where the trouble shows.** The quartiles say what a normal order looks
like, from R$ 32.70 to R$ 106.50, and that is the yardstick for everything else.
