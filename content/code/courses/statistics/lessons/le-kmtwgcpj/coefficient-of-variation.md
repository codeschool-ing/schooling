---
title: Comparing spreads across scales
version: 1
---

Is a standard deviation of 9.77 minutes large? Is one of R$ 59.42? The numbers cannot be compared directly, because they are in different units. Even within one unit, a spread of R$ 10 is large on a coffee and small on a car.

The **coefficient of variation** solves both problems by dividing the standard deviation by the mean:

```localised
CV = s ÷ mean
```

It has no units, because the units cancel, and it says how large the spread is **relative to the typical size**.

## Horta's columns compared

| column | mean | standard deviation | CV |
|---|---|---|---|
| minutes | 38.96 | 9.77 | 0.25 |
| items | 6.25 | 4.20 | 0.67 |
| basket (R$) | 79.17 | 59.42 | 0.75 |

Delivery times vary by about a quarter of their mean. Baskets vary by three quarters of theirs. That fits the shop: the time to cross Campinas does not change much from order to order, while one household buys a pint of milk and the next does the month's shopping.

## Where it is used

The CV turns up wherever spreads on different scales must be compared.

- **Quality control**: a filling machine whose CV on 1 kg bags is 0.5% is steadier than one whose CV on 5 kg bags is 2%, although the second has the larger bags.
- **Laboratories** report the CV of repeated measurements as the precision of a method.
- **Finance** compares the risk of investments of different sizes by spread per unit of return.

## Its limits

The CV needs a **ratio scale**, with a true zero, which lesson 2 made a precondition for ratios. On temperatures in Celsius it is meaningless: the mean depends on where the zero was put, so the CV would change with the scale.

It also misbehaves when the mean is close to zero. A mean of 0.1 and a standard deviation of 1 give a CV of 10, which says more about the small mean than about the spread. For variables that can be negative, such as profit, it is not used at all.
