---
title: When the spreadsheet disagrees with you
version: 1
---

Most of the trouble a sheet like the last one gives comes from five mistakes. Two of them announce
themselves with an error and one happens before any formula runs. **The other two give a number that
looks fine and is wrong**, and those are the ones that reach a meeting. Each value below is what LibreOffice Calc returned when
the mistake was made on purpose, in a three-row copy of the sheet:

| | A | B |
|---|---|---|
| 1 | Store | Sales |
| 2 | Savassi | 11880 |
| 3 | Pampulha | 10560 |
| 4 | Contagem | 12480 |

Typed correctly, the total is:

```localised
=SUM(B2:B4)      34920
```

## A number that is really text

Copy a number out of an email or a web page and it can arrive as text that happens to contain digits.
Make B3 text and the total does not complain:

```localised
=SUM(B2:B4)      24360
```

**`SUM` skips text without a word**, so Pampulha's R$ 10.56 million simply vanished from the total.
Adding the cells one by one gives LibreOffice no way to skip it, and it refuses instead:

```localised
=B2+B3+B4      #VALUE!
```

Other spreadsheets treat that second formula differently, so do not rely on the error to warn you.
The giveaway that works everywhere is alignment: a number sits on the right of its cell and text on
the left. To be certain, ask the spreadsheet:

```localised
=IF(ISTEXT(B3),"text","number")      text
```

The cure is to retype the number, and then to look at where it came from: a column pasted from one
place usually has more than one of them.

## A thousands separator the sheet reads as a decimal point

In Brazil, twelve thousand four hundred and eighty is written `12.480`. Type that into a spreadsheet
set to English and it reads the full stop as a decimal point:

```localised
B4      12.48
=SUM(B2:B4)      22452.48
```

No error, a plausible-looking total, and Contagem's sales are a thousand times too small. **This is
why the numbers in the last section were typed bare.** The opposite happens too: an English `12,480`
typed into a Portuguese spreadsheet becomes twelve point four eight.

## A function from the other language

A spreadsheet answers `#NAME?` when it does not know a function's name. The usual cause is a formula
copied from somewhere written for another language:

```localised
=SOMA(B2:B4)      #NAME?
```

`SOMA` is the Portuguese name of `SUM`, typed into a LibreOffice running in English. Excel and the
installed LibreOffice use their own language's names; Google Sheets has a setting to always use the
English ones. This course shows each formula in the spelling of the language you are reading it in.

## A division by an empty cell

A share, a rate and an average are all divisions, and a division by an empty cell or a zero answers:

```localised
=B2/0      #DIV/0!
```

In this course it nearly always means a reference pointing at the wrong cell — the missing `$` from
the last section is the usual culprit. Fix the reference rather than hiding the error.

## A pasted table that lands in one column

The last mistake has no value to show, because it is about the paste. Copy a table out of a text file
or an email and the whole of each row can land in column A, commas and all. Select the column and
split it: **Data → Text to Columns** in LibreOffice and in Excel, **Data → Split text to columns** in
Google Sheets. Then check one row by hand against the original before trusting the rest, which is the
habit that catches all five of these.
