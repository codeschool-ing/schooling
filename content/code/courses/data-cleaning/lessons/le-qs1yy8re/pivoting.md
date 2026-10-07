---
title: Pivoting, and two rows in one cell
version: 1
---

The opposite move, long to wide, is **pivoting**: one column's values become the new headers, and
another column fills the cells. The sales are long by nature, one row per sale. To read them next
to the targets, they need a row per shop and a column per month.

`actuals.py`, shown in full in the next section, stacks the shops' till sales and the delivered
online orders into one long table called `sales`, with three columns: `loja`, `month`, `amount`.
Pivoting it directly:

```
ana@lab:~/clean$ python -c "from actuals import sales; sales.pivot(index='loja', columns='month', values='amount')" 2>&1 | tail -1
ValueError: Index contains duplicate entries, cannot reshape
ana@lab:~/clean$ python -c "from actuals import sales; print(len(sales), len(sales[['loja', 'month']].drop_duplicates()))"
50104 72
```

`pivot` refuses, and it is right to. It places exactly one value in each cell, and **there are
50,104 sales for only 72 shop-and-month cells**. It does not know what to do with the hundreds of
sales that share a cell, so it stops instead of choosing.

`pivot_table` is the version that is told what to do: an `aggfunc` that turns the many values in a
cell into one.

```
ana@lab:~/clean$ python -c "from actuals import sales; w = sales.pivot_table(index='loja', columns='month', values='amount', aggfunc='sum'); print(w.shape); print(w.iloc[:, :3].round(2).to_string())"
(6, 12)
month        2025-01   2025-02   2025-03
loja                                    
Batel       14475.70   16645.9   19089.5
Botafogo    24815.80   24449.8   31686.7
Cambuí      15126.90   16271.5   19287.9
Online     124345.55  125994.1  164724.0
Pinheiros   49952.80   52629.7   62632.7
Savassi     15635.20   16955.1   20411.6
```

Six shops, twelve months, and each cell the month's sales summed. This is the useful default for
money. It is also the place where a pivot can lie without an error, because **the aggregation runs
on whatever arrives in the cell**:

- **Duplicate rows are added, not refused.** If the 25 repeated orders of lesson 5 were still in
  the data, `pivot_table` would add them in silently, where `pivot` would at least have stopped.
- **The function must fit the measure.** `sum` is right for money and wrong for a price or a
  rating, where a mean or a median is the honest summary; `pivot_table`'s default is the mean, so
  forgetting `aggfunc` gives average sales per sale in every cell, under a heading that looks like
  totals.
- **An empty cell is a blank, not a zero.** If a shop had no sales in a month, the cell would be
  `NaN`. Whether that should be 0 is lesson 3's question: a shop that sold nothing and a shop whose
  file is missing are not the same.

**Reach for `pivot` first, and use `pivot_table` when the refusal tells you the data has more than
one row per cell.** The error is information about the grain, and the choice of `aggfunc` is a
decision you then make on purpose.
