---
title: The catalogue typo that reached the customers
version: 1
---

**Lesson 5 found sugar listed twice in the catalogue, at R$ 12.90 and R$ 134.90**, and suspected a
typo. The order lines say what happened next. Every line of that product, by month and price:

```
ana@lab:~/clean$ python -c "from lines import lines as l; s = l[l['code'] == '00343'].copy(); s['month'] = s['order_id'].astype(int); import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str).drop_duplicates(); s = s.merge(o[['order_id', 'ordered_at']], on='order_id'); s['month'] = s['ordered_at'].str[:7]; print(s.groupby(['month', 'unit_price']).size().to_string())"
month    unit_price
2025-01  12.9           49
2025-02  12.9           43
2025-03  12.9           60
2025-04  12.9           75
2025-05  12.9           84
2025-06  12.9           86
2025-07  12.9            1
         134.9          83
2025-08  134.9          91
2025-09  134.9          81
2025-10  134.9          75
2025-11  134.9          75
2025-12  134.9         105
```

Until June, R$ 12.90. From July, R$ 134.90 on every line but one. **The new price was charged.**
The orders are internally consistent — lesson 7's check passes them, because the lines and the
totals agree — and that is exactly why no consistency check found it: the error is upstream of
both.

Its size:

```
ana@lab:~/clean$ python -c "from lines import lines as l; s = l[(l['code'] == '00343') & (l['unit_price'] > 100)]; print(len(s), s['order_id'].nunique(), round(s['line_cents'].sum() / 100, 2), round((s['quantity'] * (134.90 - 12.90)).sum(), 2))"
510 510 127615.4 115412.0
```

510 order lines in 510 orders, R$ 127,615.40 of sugar sold at the wrong price, and R$ 115,412.00 more
than the old price would have charged.

**This is not a cleaning decision.** Correcting the price in the analysis would make the revenue
figure describe money the company did not receive; leaving it would make it describe money it should
not have taken. What the analyst does is the same as with the refunds: report it, with the numbers,
to the people who decide — here the buyers, who own the catalogue, and finance, who will want to
refund 510 customers. The analysis then states plainly which figure it uses.

The general lesson is about where to look. A typo inside one record is caught by the record's other
fields; **a typo in a reference table is copied into every record that uses it**, consistently, and
only a comparison over time or against an outside price shows it. A price that rises tenfold
overnight is the kind of change a monthly price chart makes obvious, and lesson 15 draws one.
