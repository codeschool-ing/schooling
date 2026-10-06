---
title: Four decisions, in this order
version: 1
---

The commonest way to start a warehouse is to copy the operational tables across and start writing
reports. It feels like progress, and it rebuilds lesson 1's problem one database further along:
the same six joins, the same ragged category tree, the same customer in the wrong state.

**Dimensional modelling starts from the questions instead of from the tables.** Ralph Kimball,
whose books in the 1990s made it the standard way to design a warehouse, reduced it to four
decisions taken in a fixed order:

1. **Choose the business process.** Not a department and not a report: something the business
   *does*, that leaves a record each time. Selling a book. Counting the stock. Shipping a parcel.
2. **Declare the grain.** Say, in one sentence, what one row of the table will be. "One row per
   line of an order that was not cancelled."
3. **Identify the dimensions.** Everything a person will want to filter or group a row by: the
   date, the shop, the book, the promotion.
4. **Identify the facts.** The numbers measured at that grain: the quantity, the gross amount,
   the discount, the net amount.

**The order is the method.** The grain comes before the dimensions because a dimension only fits
if it has one value per row. A sale line has one book, so the book is a dimension of the sales
table; it has no single author, because some books have three, and lesson 4 is about what to do
with that. The facts come last because a number is only a fact *at* a grain: the shipping fee is
charged once per order, and at the grain of a line it does not exist.

Ana's first business process is the one the manager asked about in lesson 1: **selling books**.
The rest of this lesson follows the four steps for it, then for three other processes the shop
has, each of which turns out to need a different kind of table.

Lesson 4 spends a whole lesson on step 2, because it is the one most often skipped and the one
whose mistakes are hardest to see.
