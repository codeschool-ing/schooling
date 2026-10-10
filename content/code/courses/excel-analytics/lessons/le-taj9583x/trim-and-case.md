---
title: Spaces and capitals
version: 1
---

**Extra spaces are the commonest fault in pasted text, and the one nobody sees.** A space at the
end of a word is invisible on screen, and to Excel it is a character like any other: `Wholesale`
and `Wholesale ` are as different as `Wholesale` and `Wholesalf`. Capitals are the opposite case.
Everybody sees them, and most of Excel ignores them.

## Measuring a space you cannot see

`LEN` counts the characters in a cell, spaces included, so it shows what the eye misses. In an
empty cell of `Old export`, such as **P2**:

```localised
=LEN(C3)
=LEN(TRIM(C3))
```

The first answers **12**, the second **10**. `café aroma` has ten characters, and C3 holds two
spaces in front of them.

## TRIM

`TRIM` removes every space at the start and the end of a text, and turns every run of spaces
between words into one. It is the first function to apply to any text column from outside. In
**I1** type `Customer`, and in **I2**:

```localised
=TRIM(C2)
```

Fill it down to I13. Row 3 becomes `café aroma`, and row 6, `Padaria  Central` with two spaces in
the middle, becomes `Padaria Central`.

`TRIM` knows one kind of space, the ordinary one typed with the space bar. Text copied from a web
page often carries a **non-breaking space** instead, which looks identical and survives `TRIM`
untouched. When `LEN` still counts one character too many after `TRIM`, that is the usual reason,
and `SUBSTITUTE`, in section 05, replaces it with an ordinary space first.

## Capitals: UPPER, LOWER and PROPER

Three functions set the case of a text: `UPPER` makes every letter a capital, `LOWER` makes none a
capital, and `PROPER` capitalises the first letter of each word. The channel column needs `TRIM`
for its stray spaces and `PROPER` for its capitals. In **J1** type `Channel`, and in **J2**:

```localised
=PROPER(TRIM(F2))
```

Filled down to J13, every row says `Wholesale`, `Online` or `Shop`, and the count from section 02
comes out right:

```localised
=COUNTIFS(J2:J13, "Wholesale")
```

answers **8**. The `PROPER` was not what fixed it, since conditions ignore case; the `TRIM` was. The
capitals are for the reader, who should see one spelling of each channel, and for the lessons
that group by this column, where a pivot table shows every spelling it finds.

`PROPER` is a blunt tool on names. On row 9, `café do largo ` with a space at the end,

```localised
=PROPER(TRIM(C9))
```

answers **Café Do Largo**: it capitalises *every* word, and the customer's name is `Café do Largo`.
Good for codes and channels, then, and not for people's or companies' names, which have their own
rules no function knows.

## Does it match the customer list?

The point of cleaning a name is usually to find it in another table, and lesson 4's lookups do
that. `MATCH` answers the position of a value in a list, and like every lookup it **ignores
case**:

```localised
=MATCH(TRIM(C3), Customers!B2:B12, 0)
=MATCH(TRIM(C7), Customers!B2:B12, 0)
```

The first answers **2**: `café aroma`, trimmed, matches `Café Aroma`, the second name on the list,
lower case and all. The second answers `#N/A`. Row 7 is `CAFE DO LARGO`, and the list says
`Café do Largo`. Case is not the difference; the **É** is. A letter with an accent and the same
letter without it are two different characters, and no function in Excel treats them as equal.

That last fault has no formula. Either the old system is fixed, or somebody decides, once and in
writing, that `CAFE DO LARGO` is customer `C04`, typically in a small table of known spellings
that a lookup reads. Lesson 4's `#N/A` is what tells you such a row exists, which is one more
reason never to hide it.

Use `EXACT` when case **does** matter: `EXACT(C2, C13)` is `TRUE` because both cells say
`Café Aroma`, while `EXACT(C2, C3)` is `FALSE`. An ordinary `=C2=C3` ignores case, and here says
`FALSE` only because of the two spaces.
