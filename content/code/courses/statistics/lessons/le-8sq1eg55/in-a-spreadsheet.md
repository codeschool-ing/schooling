---
title: The three in a spreadsheet
version: 1
---

Every spreadsheet computes all three. With Horta's delivery times in cells A2 to A13, the baskets in B2 to B13 and the items in C2 to C13:

```localised
=AVERAGE(A2:A13)      38.9583333333333
=MEDIAN(A2:A13)       37.25
=MEDIAN(B2:B13)       68.2
=MODE.SNGL(C2:C13)    3
```

The values on the right are what LibreOffice Calc returned for those formulas on the course's data. Excel and Google Sheets have the same functions under the same names.

## The mode functions hide things

Two behaviours of the mode function are worth knowing before they surprise you.

**With no repeated value, it returns an error.** `MODE.SNGL` over the twelve delivery times gives an error instead of a number, because every time occurs once. The error is the correct answer, but a chart or a report that expected a number will break on it.

**With a tie, it returns one of the tied values without saying so.** Over the star ratings, in the order the table lists them, `MODE.SNGL` returns **5**: the first of the two tied values it meets. The 4s, which occur just as often, vanish. `MODE.MULT` returns every mode, here 5 and 4, as a list that fills several cells.

So `MODE.SNGL` reporting 5 for the ratings is a true statement that hides half of the truth. Look at the counts before trusting a single mode.

## Writing the formula is not the same as choosing the summary

A spreadsheet will compute `AVERAGE` over a column of postcodes or payment codes without complaint, as lesson 2 warned. The formula is the last step. The first is deciding which centre the variable's scale allows, and the next two sections help with the second step: deciding which one the question needs.
