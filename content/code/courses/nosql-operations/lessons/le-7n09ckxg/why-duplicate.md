---
title: Why write the same fact twice
version: 1
---

Duplicated data has a bad name, and in a relational schema it earns it: two copies of a fact are two
places that can disagree, and normalisation exists to make that impossible. **In the stores of this
course duplication is a design tool**, used on purpose, and the question is never whether to copy
but which copies are worth what they cost.

## The cost moves, it does not disappear

Lesson 3 left the shop with questions that start from different keys. The order page starts from the
order number, "my orders" from the customer, the basket from the session. Without joins, each of
those answers is fastest when everything it shows is already under its key, and that means some
facts live under more than one key.

Count what that buys. The order page is read about 200 times a minute, which is 288,000 times a day.
If it shows each product's name, and the name lives only in `products`, every view pays a second
read per product, all day. If the order line carries a copy of the name, the view is one read, and
the cost of the copy is paid **when the name changes**, which for a product is a few times a year.

That is the trade in one sentence: **a copy moves cost from every read to the rare write that
changes the fact.** It pays when reads outnumber those writes by a wide margin, which for most of what
a shop shows is true by thousands to one. It does not pay for a fact that changes all the time and is
read rarely, like a stock count that moves with every sale.

## What the cost turns into

The write side of the trade is not only time. Three things move from the database to you:

- **the extra writes themselves**, every time a copied fact changes, to every place it was copied;
- **the knowledge of where the copies are**, which no store in this course keeps for you: nothing in
  MongoDB knows that `orders` carries a product's name;
- **the window in which copies disagree**, between the first write and the last, and the case where
  the last never happens because a process died in between.

The relational database paid all three for you by not having copies. Here they are a list somebody
has to keep, and the rest of this lesson is that list for the shop.

## Two kinds of copy

Not every copy is supposed to follow its source, and confusing the two is the commonest error in a
denormalised design:

| | a snapshot | a copy that follows |
|---|---|---|
| what it records | the fact **as it was** when something happened | the fact **as it is now**, kept nearby for speed |
| example in the shop | the price Ana paid for the mouse | the name the order page shows for Ana |
| when the source changes | **must not** change | must change, everywhere it was copied |

The next section puts both into one order document. After that, Cassandra writes one order into two
tables at once, and the last section checks a set of copies for the ones that did not follow.
