---
title: Where the money is
version: 1
---

Breaking a total down by a category is the most common question a business asks of its data. It
needs lesson 8's categories, lesson 11's checked join and the line amounts lesson 7 converted, which
is why it comes this late:

```
ana@lab:~/clean$ python -c "from explore import sold; r = sold.groupby('category', dropna=False)['line_cents'].sum() / 100; print(r.sort_values(ascending=False).to_string()); print(round(r.sum(), 2))"
category
Cestas               861595.30
Mercearia            421614.40
Frutas               290519.50
Legumes              219490.20
Verduras             188922.10
Ovos e laticínios    186290.80
Grãos e cereais      137732.50
NaN                   37761.35
2343926.15
```

The lines of delivered orders add up to R$ 2,343,926.15. That is less than the orders' totals,
because a line has no delivery fee and no discount, and **a breakdown has to say which of the two
it adds up**. A share of "revenue" computed on lines and compared with a total computed on orders
would never add up to 100%.

The ranking says baskets, the ready-made boxes, bring in more than a third of everything, R$
861,595.30, and Mercearia comes second. Both deserve a second look before anyone acts on them:

- **Mercearia includes the sugar.** From July every bag was charged R$ 134.90 instead of R$ 12.90,
  and lesson 9 put the overcharge at R$ 115,412.00 across all orders. A category ranking built on
  that would credit the grocery shelf with money the customers should not have paid.
- **The last row has no category**, R$ 37,761.35. Those are the lines of the two codes the catalogue
  does not have, found in lessons 7 and 11. They stay as a row of their own rather than being
  dropped or spread across the others, because **a breakdown that silently loses 1.6% of the money
  no longer adds up to the total it claims to break down**.

Both cautions are the same idea: a breakdown is only as good as the cleaning behind each of its
rows, and the rows that look most impressive are the ones to check first.
