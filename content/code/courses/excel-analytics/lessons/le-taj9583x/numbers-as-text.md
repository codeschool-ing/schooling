---
title: Numbers stored as text, and text that must stay text
version: 1
---

**A column is either quantities or identifiers, and Excel has to be told which.** Quantities are
numbers: they are added, averaged and compared. Identifiers only look like numbers: an order number,
a postcode, a phone number, a code with a leading zero. The `Old export` sheet has one of each gone
wrong. Four quantities arrived as text, and every order number lost its zeros by being read as a
number.

## Text that should be a number

Lesson 1 section 08 showed the symptom: a number stored as text is skipped by `SUM` and not counted
by `COUNT`, without an error. Here the cause is visible, `6 un`, and the cure is two steps. Take the
unit out with `SUBSTITUTE`, which replaces one piece of text with another, here with nothing; then
turn what is left into a number with `VALUE`. In **L1** type `Bags`, and in **L2**:

```localised
=VALUE(SUBSTITUTE(E2, " un", ""))
```

Fill it down to L13. Row 3, `6 un`, becomes **6**, a number that sits on the right of its cell. Row 2,
which was already the number 12, passes through unharmed: `SUBSTITUTE` finds nothing to replace and
returns the text `12`, and `VALUE` turns it back into 12. One formula handles both kinds of row,
which is what lets it fill down a whole column.

Then the check, which is the reason for the column:

```localised
=COUNT(L2:L13)
=SUM(L2:L13)
```

**12** and **86**. Twelve rows went in and twelve numbers came out, and the total is the 86 that
section 02 promised, not the 48 that `SUM` found when four values were text.

Some people convert with arithmetic instead: `=--E2`, two minus signs, or `=E2*1`, both force a
number out of text that looks like one. They do the same as `VALUE` on a cell like `12` and fail on
`6 un` just as it does, since no arithmetic can read the letters. `VALUE` says what it is for, which
is the better reason to use it.

When the column is clean apart from its type, with no unit in it, there are two quicker ways that
leave numbers rather than formulas: the warning triangle on the cell, whose menu offers **Convert to
Number** for a whole selection; and **Data › Text to Columns** with **Finish** straight away, which
re-reads every cell of the column as if it had just been typed.

## Text that must not become a number

The order numbers went wrong the other way. The old system wrote `00841`, and when it was pasted
Excel saw digits and stored the number 841. For a quantity that would be right. For an identifier
it is a different value: an order called `00841` and one called `841` are not the same to whoever
searches the old system for it.

`TEXT` turns a number into text, laid out by a pattern, and a pattern of five zeros means *at least
five digits, padded with zeros on the left*. In **M1** type `Order`, and in **M2**:

```localised
=TEXT(A2, "00000")
```

answers **00841**, as text, sitting on the left of the cell. Filled down, every order has its five
digits back.

This repairs the column after the damage, and only because the length is known, five digits for
every order. The better fix is to stop the damage at the door. When a file is imported rather than
pasted, the import lets each column be declared as text before any value is read, and lesson 13
does exactly that with Power Query. A code whose length varies,
like a product code that may or may not start with zero, cannot be repaired afterwards at all,
because nothing left in the cell says how many zeros there were.

## The rule underneath

Ask of every column the question from lesson 1: what will be done with it? If it will be added or
compared as a quantity, it is a number, and anything that turned it into text has to be undone. If
it is only ever matched, looked up or read, it is text, even when it is all digits, and the cell
should be told so before Excel guesses. `Sale`, `Customer` and `Product` in `Sales` are text for
exactly this reason, and so are postcodes and phone numbers everywhere.
