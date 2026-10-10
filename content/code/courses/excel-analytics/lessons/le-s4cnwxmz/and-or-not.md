---
title: AND, OR and NOT
version: 1
---

**`AND`, `OR` and `NOT` combine comparisons into one answer, and they are how a condition with
several parts is written.** `AND` is `TRUE` when every comparison inside it is; `OR` when at least
one is; `NOT` turns one answer into the other. Each returns `TRUE` or `FALSE`, so each can stand
alone in a cell or sit in the first argument of `IF`.

## AND: every part must hold

Which wholesale sales were small, under ten bags? Two conditions, both required:

```localised
=AND(G2="Wholesale",E2<10)
```

Row 2 is `FALSE`: S1001 is wholesale, but 14 bags. Filled down, 16 rows say `TRUE`. The same pair
of comparisons, written as a range, is the repair for the chain of the first section. Between 4
and 9 bags is:

```localised
=AND(E2>=4,E2<10)
```

and that one is `TRUE` on 41 rows, the 41 `Medium` sales of the previous section.

## OR: one part is enough

Which sales were of the two speciality bags, the decaf or the Mogiana Reserve?

```localised
=OR(D2="DEC250",D2="MOG250")
```

Each argument has to be a whole comparison, and forgetting it is the commonest mistake with `OR`.
Written the way it is said aloud, `=OR(G2="Wholesale","Shop")`, the second argument is only the word
`"Shop"`: it asks nothing about G2. Excel does not read your intention into it, and whatever the
cell shows, it is not the answer to "is this wholesale or shop". Repeat the cell in every part:
`=OR(G2="Wholesale",G2="Shop")`.

Filled down, the decaf-or-Mogiana formula is `TRUE` on 35 rows.

## NOT: the other answer

`=NOT(G2="Online")` is `TRUE` for every sale that was not made online. For one comparison, `<>`
says the same thing more plainly, `=G2<>"Online"`, and is the better choice. `NOT` earns its place
around something longer, such as `=NOT(OR(D2="DEC250",D2="MOG250"))`, every sale that was neither.

## Inside IF

The three are most often the test of an `IF`. A label for the small wholesale orders, and nothing
on every other row:

```localised
=IF(AND(G2="Wholesale",E2<10),"Small trade order","")
```

Read a long condition the way the earlier sections read a nested `IF`: from the outside in, one
function at a time, and with one row of the data in front of you to check each part against.

A last thing these formulas show about the data. `=AND(G2="Wholesale",E2>=10)` is `TRUE` on 22
rows, and so is `=E2>=10` on its own: on this sheet, every sale of ten bags or more is a wholesale
sale. The second condition adds nothing here, and noticing that is itself a finding about Café
Serra's customers.
