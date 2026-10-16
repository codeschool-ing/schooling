---
title: Saying what a cell wants, and what a refusal does
version: 1
---

**A rule with no message refuses a value without saying why, and the person typing learns nothing
except that Excel said no.** The two other tabs of the **Data Validation** dialog fix that: one
speaks before anything is typed, the other decides what a broken rule does.

## The input message: before typing

On the **Input Message** tab, a **title** and a **message** typed here appear in a small note
beside the cell whenever it is selected. For `Bags` (E2) it could be:

- **Title**: `Bags`
- **Input message**: `Whole bags, from 1 to 50.`

The note costs nothing and prevents the mistake rather than catching it. Keep it to one line about
what the cell wants; the person reading it is in the middle of typing a sale.

## The error alert: after a value breaks the rule

The **Error Alert** tab has a **Style**, and the style decides what the person can do next:

| style | the person can | use it when the value is |
|---|---|---|
| **Stop** | retype it, or cancel; the value cannot stay | impossible: a product that does not exist, 0 bags |
| **Warning** | keep it with **Yes**, go back and edit it with **No**, or cancel | possible but unusual, worth a second look |
| **Information** | keep it with **OK**, or cancel | fine, with something the person should know |

**Stop is the only style that enforces anything.** Warning and Information ask the person, and a
person in a hurry presses the button that makes the box go away. That is the right behaviour for a
value that is sometimes legitimate, and the wrong one for a value that is never legitimate.

Excel's own message, when the tab is left empty, names neither the rule nor what to type instead.
Write one that does both: `Bags is a whole number from 1 to 50. For a larger order, split it into
two sales.` tells the person exactly what to do next.

## Price: a warning, not a refusal

The price of a sale is the case for **Warning**. Wholesale customers pay below the list price, so
a price under the list is normal; a price far under it is usually a slip, such as `18` typed for
`118`. Select the `Price` cell of `NewSales` (F2), choose **Allow: Custom**, and type:

```localised
=F2>=0.8*XLOOKUP(D2, Products!A:A, Products!F:F)
```

The rule looks the product up in `Products`, as lesson 4 did, and accepts any price that is at
least 80% of its list price. For `CER1K`, whose list price is 118, the bound is 94.4: the 106 that
wholesale customers paid in 2026 passes, and `18` breaks the rule. On the **Error Alert** tab
choose **Warning**, with a message such as `This is less than 80% of the list price. Yes keeps it;
No lets you correct it.`

The rule reads `D2`, so it depends on the product being chosen first. With `D2` empty the lookup
answers `#N/A`, a rule whose formula answers an error counts as broken, and the warning appears.
Typing the columns from left to right, as the sheet is laid out, avoids that.

## One rule per cell

A cell holds one validation rule, with one style. The rule above warns, so a price of `-5` is
warned about too rather than refused, and a hurried **Yes** keeps it. Choosing the style is
choosing which mistake matters more: on `Price` a dropped digit is the common slip, and a warning
lets the legitimate low prices through. On `Product`, where a wrong value is never legitimate, the
list rule of section 04 stays a **Stop**.
