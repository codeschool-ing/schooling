---
title: Keys, and what a lookup does
version: 1
---

**A lookup takes a key from one row, finds the row of another table that has the same key, and
brings back a value from it.** That is all every function in this lesson does. They differ in how
you tell them where to look and what to bring back, and in what they do when the key is not there.

## The question a lookup answers

Sale S1001, on row 2 of `Sales`, sold `CER1K`. What does a bag of `CER1K` cost on today's list?
`Sales` does not say. It holds the code and nothing else about the product, which is the point of
lesson 1 section 06: the product's facts live once, in `Products`, and every sale points at them
by the key.

Answering by hand is three steps, and a lookup formula does the same three:

1. **The value to look for**: the key in this row, D2, which is `CER1K`.
2. **Where to look for it**: the key column of the other table, `Products!A2:A7`. It is found in the
   fourth row of that range.
3. **What to bring back**: the value in the same row of another column, here `List price`,
   `Products!F2:F7`. The fourth value of that column is **118**.

```schooling-figure
{"svg": "<svg data-fig=\"l04-lookup\"></svg>", "caption": ""}
```

## What a key has to be

A lookup trusts the key completely, so the key has to deserve it.

**Unique in the table being searched.** Each code appears once in `Products`. If `CER1K` appeared
twice, with two different prices, a lookup would return the first and never mention the second.
Nothing would look wrong.

**Spelled exactly the same on both sides.** `CER1K` in `Sales` must be the same characters as
`CER1K` in `Products`. Case does not matter, but a space at the end does, and so does a number
stored as text: section 07 shows each of these failing.

**Present.** A sale of a product that is not in `Products` has nothing to find, and the formula
says so with `#N/A`. That error is useful, and section 07 is about keeping it useful.

## Many rows, one answer each

The lookup runs from the many side to the one side. Twenty-eight sales in `Sales` sold `CER1K`,
and each of the 28 finds the same single row in `Products`. That is the direction that works: every
sale gets exactly one list price. Asked the other way, "which sale of `CER1K`?", there are 28
answers and a lookup returns only the first.

This lesson brings four things into `Sales` by lookup: the list price, the unit cost, the margin
that follows from them, and a size band. Lesson 15 does the same joining without a formula, by
telling Excel's data model that `Sales[Product]` points at `Products[Code]`. The idea is the same
one, and this lesson is where you see it work row by row.
