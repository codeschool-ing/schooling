---
title: Links, frozen headers and a sheet that cannot be broken by accident
version: 1
---

**A workbook that somebody else opens needs a way round that does not depend on them knowing the
tabs.** `cafe-serra.xlsx` now has six sheets, and one of them is hidden. The person who built it
knows where everything is. The owner, opening it once a month, sees a row of tabs at the bottom of
the window, possibly cut off, and has to guess.

## A contents sheet

Add a sheet called `Contents` and drag its tab to the front, so it is the first sheet. Give it one
line per sheet the reader may want: a link, and one sentence saying what is there.

```localised
=HYPERLINK("#Dashboard!A1", "Dashboard")
=HYPERLINK("#Sales!A1", "Sales")
```

The `#` means *a place in this workbook*, and what follows is an ordinary address. Clicking the
cell jumps to it. The second argument is the text the cell shows. **Insert › Link**, with **Place
in This Document**, makes the same jump without a formula, if you prefer a dialog.

Then give every sheet the way back: a link to `#Contents!A1` in the same corner of each one, so the
reader never needs the tabs at all.

One thing these links do not do is follow a renamed sheet. The address is text inside quotes, and
Excel does not rewrite text when a sheet is renamed, so `#Sales!A1` keeps pointing at a sheet that
no longer exists and the link stops working. **Rename sheets before you write the links**, or check
every link after a rename.

## Headers that stay put

On the data sheets, the column headers scroll away after a screenful of rows, and somebody reading
row 80 of `Sales` has to remember which column is `Bags` and which is `Price`. **View › Freeze
Panes › Freeze Top Row** keeps row 1 in place while the rest scrolls. On `Customers`, where the
first column names the row, **Freeze Panes** with **B2** selected keeps both the header row and
column A.

The dashboard does not need it, because it fits one screen, which is the rule of the previous
section.

## Hiding the machinery

Right-click the `Calc` tab and choose **Hide**. The reader does not need four pivot tables, and a
sheet nobody sees is a sheet nobody edits by mistake. Hidden is not protected, though: **Unhide** on
the same menu brings it back, and the next step is about that.

## Protecting the dashboard from a stray click

A dashboard with a live cell under the mouse breaks easily. One click and a typed digit overwrite a
`GETPIVOTDATA` formula with a number, and from then on the card shows that number whatever the
slicer says. Sheet protection stops it, but done in the obvious order it also stops the slicer.

Before protecting, right-click the slicer, choose **Size and Properties**, and in **Properties**
untick **Locked**. Do the same for the timeline. Then **Review › Protect Sheet**, and in its list
tick **Use PivotTable & PivotChart** as well as the two kinds of cell selection. Click the slicer
afterwards to see that it still filters, because a protected dashboard whose controls do not move
looks exactly like one with no data.

**Protection keeps accidents out, not people.** A sheet password is easy to remove and stops
nobody who wants to change the sheet. Worse, every row of `Sales` and `Customers` is in the file,
hidden or not, readable by anyone who has the file. If the workbook must be unreadable without a
password, that is **File › Info › Protect Workbook › Encrypt with Password**, and it is a different
thing. The next section is about who should have the file at all.
