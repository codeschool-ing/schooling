---
title: Two columns at a time
version: 1
---

Do orders with more items cost more? The obvious answer is yes, and a correlation should show it.
Two kinds of correlation, and the same one again without the companies:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(round(d['items'].corr(d['total']), 3), round(d['items'].rank().corr(d['total'].rank()), 3)); h = d[~d['corporate']]; print(round(h['items'].corr(h['total']), 3))"
0.224 0.644
0.427
```

**Pearson's correlation is 0.224**, which reads as a weak relationship. **Spearman's is 0.644**,
which reads as a strong one, and it is computed here the way it is defined: Pearson's formula
applied to the ranks instead of the values. The two disagree because they measure different things.
Pearson's measures how well a straight line fits the values, and sixteen corporate orders worth
thousands of reais each sit far from any line through the household baskets. Spearman's only asks
whether more items tends to come with a higher total, and for most orders it clearly does.

The third number confirms the diagnosis: **without the corporate orders, Pearson's rises to
0.427**. A handful of extreme rows had cut it almost in half. When the two coefficients disagree
this much, the gap itself is a finding: something in the data is far from the rest, and it is worth
finding before quoting either number.

Not every pair of columns is related, and that is a finding too:

```
ana@lab:~/clean$ python -c "import pandas as pd; from explore import delivered as d; print(pd.crosstab(d['channel'], d['payment'], normalize='index').round(3).to_string())"
payment  boleto   card    pix
channel                      
app       0.048  0.553  0.398
site      0.052  0.549  0.399
```

Each row adds up to 1. Card, Pix and boleto are used in almost exactly the same proportions in the
app and on the site, within one percentage point. **No relationship is a result**: it says that a
campaign promoting Pix in the app would be starting from the same place as one on the site.

Two cautions belong with every relationship found this way:

- **A correlation is not a cause.** Orders with more items cost more because each item costs
  something, which is a cause; but most correlations in a business data set have no such obvious
  mechanism, and a third column, the month or the customer, often drives both.
- **A relationship over all rows can hide groups** that behave differently, as the corporate orders
  did here. Lesson 9's rule holds: look at who is far from the rest before summarising everybody.
