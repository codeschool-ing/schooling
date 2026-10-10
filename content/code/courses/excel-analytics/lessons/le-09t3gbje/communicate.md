---
title: What the colour says, and who can see it
version: 1
---

**A coloured cell is a sentence with the words missing, and the reader fills them in.** If the
reader fills in what you meant, the rule communicates. If not, it decorates, or it says something
false, like the 86 red arrows of the last section. Three questions decide which, and none of them
is about Excel.

## Does the reader know what it means?

A fill means "R$ 1,500 or more" only to the person who made the rule. Everybody else sees amber and
guesses: late, unpaid, important, wrong. So:

- **One meaning per colour, on the whole workbook.** If amber means "large sale" on `Sales`, it does
  not mean "below target" on another sheet.
- **Say it on the sheet.** A heading such as `Amber: sales of R$ 1,500 or more` above the table, or
  beside the `Threshold` cell, costs one line and removes the guess.
- **Choose the picture for the question.** Each kind of format answers one kind of question, and
  borrowing one for another question is how the red arrows happened:

| the question | the picture that answers it |
|---|---|
| which ones need attention? | a fill on those cells or rows, and nothing on the rest |
| how big is each one, compared with the others? | a data bar |
| where in a grid are the high and low values? | a colour scale |
| did it go up or down since last time? | arrows, on a column that holds a change |

## Can every reader see it?

**Around one man in twelve, and one woman in two hundred, has a colour vision deficiency**, most
often a difficulty telling red from green. A sheet where green means good and red means bad, with
nothing else to tell them apart, is a sheet where those readers see two shades of the same muddy
colour. In a team of twenty-five men, two of them, on average.

The fix is never to let colour carry the meaning alone:

- **add a second signal.** The three arrows differ in direction as well as colour, which is why an
  icon set survives where a red and green fill does not. A shape, a symbol or a word in the cell
  says the same thing to everybody;
- **differ in lightness, not only in hue.** A pale fill and a dark one stay distinct for every
  reader, and on a printer with only black ink;
- **keep the condition in a column.** A flag column, with the `IF` of lesson 3, says in words what
  the colour says in paint:

```localised
=IF([@Revenue]>=Threshold, "Large", "")
```

A flag column also does what a colour cannot: `COUNTIF` counts it, a filter selects it, and it is
still there when the sheet is pasted into an e-mail as values or read aloud by a screen reader,
which reads what a cell holds and not how it looks. The colour then becomes a second way of saying
something the sheet already says.

## Does it say something new?

The wholesale rows of section 03 are coloured because their `Channel` says `Wholesale`, which the
reader can already read in column G. That rule adds emphasis, not information, and it is worth
keeping only if wholesale is what this sheet is about. A sheet where five rules colour half the
cells says nothing at all, because the eye has nowhere to go. **Two or three rules a sheet, each
with a meaning written down, is a sensible ceiling**, and the next section is about finding and
removing the rest.
