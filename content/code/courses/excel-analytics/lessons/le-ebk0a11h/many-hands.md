---
title: Many hands on one file
version: 1
---

**A workbook is built for one person at a time, and most of its trouble starts with the second
person.** Everything in this course so far assumed one analyst with one file. A business is rarely
that. The owner of Café Serra enters wholesale orders, an employee at the counter records shop
sales, an accountant wants the month's revenue, and each of them reasonably wants the same file.

## Copies by e-mail

The usual answer is to send it. On Monday the owner e-mails `cafe-serra.xlsx` to the employee. On
Tuesday she adds two wholesale sales to her copy. On Wednesday he corrects the price of sale
`S1105`, from 106 to 96, because the customer had a discount, in his. On Friday there are two files
with the same name, each holding something the other does not, and neither is the truth.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l18-copies\" aria-label=\"Two copies of one workbook over a week. On Monday the owner e-mails cafe-serra.xlsx to an employee. On Tuesday the owner's copy gains two wholesale sales. On Wednesday the employee's copy changes the price of sale S1105 from 106 to 96. On Friday there are two files with the same name, each holding a change the other lacks.\"><text x=\"110.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Monday</text><text x=\"290.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Tuesday</text><text x=\"470.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Wednesday</text><text x=\"650.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Friday</text><text x=\"36.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">owner</text><text x=\"36.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">employee</text><rect x=\"40.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"48.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 sales</text><path d=\"M110.0 112.0 L110.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M110.0 170.0 L114.0 162.0 L106.0 162.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"118.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e-mail</text><rect x=\"40.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"48.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 sales</text><rect x=\"220.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"228.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 sales</text><text x=\"228.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">+ 2 wholesale sales</text><rect x=\"220.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"228.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 sales</text><rect x=\"400.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"408.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"408.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 sales</text><text x=\"408.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">+ 2 wholesale sales</text><rect x=\"400.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"408.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"408.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 sales</text><text x=\"408.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">S1105: price 106 → 96</text><rect x=\"580.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"588.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"588.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">+ 2 wholesale sales</text><text x=\"588.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">S1105 still 106</text><rect x=\"580.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"588.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"588.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">S1105: price 106 → 96</text><text x=\"588.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no new sales</text><path d=\"M182.0 81.0 L218.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M218.0 81.0 L210.0 77.0 L210.0 85.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M362.0 81.0 L398.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M398.0 81.0 L390.0 77.0 L390.0 85.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M362.0 201.0 L398.0 201.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M398.0 201.0 L390.0 197.0 L390.0 205.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M542.0 81.0 L578.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M578.0 81.0 L570.0 77.0 L570.0 85.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M542.0 201.0 L578.0 201.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M578.0 201.0 L570.0 197.0 L570.0 205.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"580.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">two files, one name,</text><text x=\"580.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">neither is the truth</text></svg>", "caption": "The week of a workbook sent by e-mail. Each copy gains a correct change the other never sees, and on Friday somebody has to merge them by eye."}
```

Somebody now merges them by eye, row by row, and whichever copy they start from decides which
changes they will notice. The file names grow suffixes, `cafe-serra-final.xlsx`,
`cafe-serra-final-v2.xlsx`, and the version that ends up in next month's report is whichever one
was open when the report was made.

## A cell keeps its value and not its history

**Nothing in a sheet records who typed a value, when, or why.** Sale `S1105` shows 96. Whether that
is the price the customer paid, a discount somebody agreed on the phone, or a typing slip for 106,
the cell is the same cell. If the revenue for June looks wrong in three months, there is no trail
to follow back to the change that made it wrong.

And nothing stops the wrong change. Lesson 8's validation checks what is typed into a cell, and a
paste goes round it, as that lesson showed. The rules a business needs, such as *a price is a whole
number above zero* or *every sale names a product that exists*, live in the workbook as advice, not
as walls.

## What co-authoring fixes, and what it does not

Microsoft 365 removes the copies. Keep the workbook on OneDrive or SharePoint and several people can
open the same file at once, each seeing the others' edits as they arrive. **File › Info › Version
History** keeps earlier versions of the whole file and can restore one, and **Review › Show Changes**
lists recent edits cell by cell, with who made them.

That solves the Friday problem: there is one file. It does not make the data any safer. The rules
are still advice that a paste can ignore. Nothing records why a value changed. A version is a whole
workbook at a moment, so undoing one bad edit means restoring everything around it as well, or
copying the old value back by hand. And another program, the web shop's order system for instance,
still cannot write a sale into the file in a way anybody would trust.

## What a database does instead

A database is built for exactly the case Excel was not. **It refuses a row that breaks a rule,
whoever sends it**: a price that is not a number, a sale naming a product that does not exist, a
second row with the same key. Many people and programs can write to it at once, and each change
either happens completely or not at all. Who changed what can be recorded by the database itself,
not by everyone remembering to.

It is a different job from the workbook's, and section 06 of this lesson says which course of the
track teaches it.
