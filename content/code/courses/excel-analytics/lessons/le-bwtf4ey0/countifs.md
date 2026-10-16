---
title: COUNTIFS, how many rows pass
version: 1
---

**`COUNTIFS` counts rows, never what is in them.** It is `SUMIFS` with nothing to add: the same
pairs of range and condition, and the answer is how many rows passed all of them. The trap is
reading that count as a quantity. Ask how many online sales there were and how many bags they
sold, and you need two different functions:

```localised
=COUNTIFS(G2:G109, "Online")
=SUMIFS(E2:E109, G2:G109, "Online")
```

The first answers **47**, the second **149**. Forty-seven sales, 149 bags. A report that put 47
under a heading saying *bags* would be wrong by a factor of three, and nothing about the number
would look strange.

Because every sale has one channel, the counts split the rows like the totals did:
`Wholesale` gives **38** and `Shop` **23**, and 47 + 38 + 23 is the 108 sales you checked in
lesson 1.

## Counting with two conditions

How many wholesale sales were of ten bags or more?

```localised
=COUNTIFS(G2:G109, "Wholesale", E2:E109, ">=10")
```

**22** of the 38. The condition `">=10"` is a comparison written as text, in quotes, which section
05 explains with the rest of the condition language. Change it to `"<10"` and the answer is **16**,
and 22 + 16 is 38 again: one condition and its opposite split a group exactly, which gives you a
check on the condition itself.

## A count that says something about the business

```localised
=COUNTIFS(C2:C109, "C00")
```

answers **70**. Seventy of the 108 sales went to `C00`, the walk-in and web customer with no
account, so most sales are small and anonymous, while 38 wholesale sales bring in three quarters
of the revenue. Counting rows is how you find out what a typical row looks like, and here it is
nothing like the rows that carry the money.

## Counting the empty cells

A condition of `""` matches an empty cell, and `"<>"` matches any cell that is not empty. On the
`Customers` sheet, in an empty cell such as **J2**,

```localised
=COUNTIFS(D2:D12, "")
=COUNTIFS(D2:D12, "<>")
```

answer **1** and **10**: one customer has no city, `C00`, and ten do. The two add up to the 11
customers, so no cell in the column was left out of both. It is the same question
`COUNTBLANK` answered in lesson 1, asked in a form that accepts more conditions.

## What COUNTIFS cannot count

It counts rows, so it cannot tell you how many **different** customers bought online: a customer
with six sales is six rows that pass. Counting distinct values needs another tool, and lesson 16
has one. `COUNTIF`, without the S, also exists, and unlike `SUMIF` it keeps the same argument
order as its plural, so it is harmless; this course still writes `COUNTIFS` throughout.
