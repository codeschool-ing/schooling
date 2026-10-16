---
title: A list from the old system
version: 1
---

**Data from another system arrives with every value present and half of them unusable.** Until
the end of 2024, Café Serra kept its orders in a different program, and the twelve orders of
December 2024 exist only in its export. They are not in `Sales`, which starts in January 2025, and
this lesson's job is to make them look as if they were: one clean value per cell, of the right
type, spelled the same way every time.

## Pasting it

1. Add a sheet called `Old export`.
2. Click **A1**, copy the block below with the button in its corner, and paste.

```
Order	Date	Customer	Item	Qty	Channel	Price
00841	20241202	Café Aroma	SUL1K - Sul de Minas 1 kg	12	Wholesale	113
00842	20241203	  café aroma	DEC250 - Decaf 250 g	6 un	wholesale	35
00843	20241205	EMPÓRIO SERRA	cer1k - Cerrado 1 kg	10 un	WHOLESALE 	101
00844	20241209	Walk-in and web	MOG250 - Mogiana Reserve 250 g	2	 Online	49
00845	20241210	Padaria  Central	SUL250 - Sul de Minas 250 g	8	Wholesale	32
00846	20241212	CAFE DO LARGO	SUL1K - Sul de Minas 1 kg	15 un	Wholesale	113
00847	20241216	Walk-in and web	CER250 - Cerrado 250 g	3	Shop	31
00848	20241217	café do largo 	CER1K - Cerrado 1 kg	9	wholesale	101
00849	20241218	Walk-in and web	DEC250 - Decaf 250 g	1	online	39
00850	20241219	Empório Serra	MOG250 - Mogiana Reserve 250 g	7 un	Wholesale	44
00851	20241220	Walk-in and web	SUL1K - Sul de Minas 1 kg	2	Shop	126
00852	20241223	Café Aroma	CER1K - Cerrado 1 kg	11	Wholesale	101
```

Look at it before doing anything. On screen, most of it reads correctly, and that is the problem:
a person reads `  café aroma` as Café Aroma and `6 un` as six, and no formula does either.

## Counting what is wrong

The same habit as lesson 1: before trusting a column, count it. In an empty cell of `Old export`
to the right of the data, such as **P1**:

```localised
=COUNT(E2:E13)
=SUM(E2:E13)
=COUNTIFS(F2:F13, "Wholesale")
```

`COUNT` answers **8**. Twelve orders and eight numbers: four quantities are text, the ones typed
with `un` after them, so `SUM` adds the other eight and answers **48**. The real total, once the
column is repaired in section 04, is **86**. The `COUNTIFS` answers **7**, and counting by eye
gives eight wholesale orders: `WHOLESALE ` has a space after it, and to a condition that makes it a
different word. Capitals are not the problem, since conditions ignore case; the space is.

Two more faults hide in plain sight. **A2** shows `841`, because the order number arrived as
`00841` and Excel read it as a number and dropped the zeros. **B2** shows `20241202`, which is a
date to a person and twenty million to Excel, which stores 2 December 2024 as **45628**.

## The plan

Each column has its own fault, and each fault has a function. The rest of the lesson goes through
them in this order:

| column | what is wrong | what fixes it | section |
|---|---|---|---|
| `Customer` | spaces before, after and between words; capitals all over | `TRIM`, and `PROPER` for display | 03 |
| `Channel` | the same three words in mixed capitals, with stray spaces | `TRIM` and `PROPER` | 03 |
| `Item` | a code and a name in one cell, some codes in lower case | `FIND`, `LEFT`, `UPPER` | 04 |
| `Qty` | some numbers carry `un` and are text | `SUBSTITUTE` and `VALUE` | 05 |
| `Order` | the leading zeros were lost | `TEXT` | 05 |
| `Date` | eight digits, not a date | `LEFT`, `MID`, `RIGHT` and `DATE` | 06 |

**Every fix goes in a new column, from I onward, and the original stays untouched.** A cleaned
column beside the one it came from can be compared row by row, and a mistake in the formula shows
up as a row where the two disagree in a way they should not. Retyping the values by hand leaves
nothing to compare, and the next export of the same system arrives with the same faults.
