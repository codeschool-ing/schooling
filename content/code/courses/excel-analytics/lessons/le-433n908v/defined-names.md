---
title: Names for ranges and constants
version: 1
---

**A defined name is an absolute reference with a word where the address was.** `=H2/$L$2` is
correct and says nothing to the person who opens the file next month; `=H2/TotalRevenue` is the
same formula, and it says what it divides by. A name is also absolute by nature: it points at the
same cells from every row, so a formula that uses one can be filled anywhere without a dollar sign.

## Three ways to make one

**From the Name Box**, the box at the left end of the formula bar that normally shows the address
of the selected cell. Click L2 on `Sales`, click in the Name Box, type `TotalRevenue` and press
Enter. L2 now has a name, and clicking it in the Name Box's list selects it from anywhere in the
workbook.

**From Formulas › Define Name**, which opens a dialog with a **Name** and a **Refers to** box.
Select H2:H109 first and the box is filled in for you; name it `Revenue`. **Refers to** reads
`=Sales!$H$2:$H$109`: the sheet, then the range, with both dollars.

**For a value that lives in no cell.** In the same dialog, name `Discount` and in **Refers to**
type `=0.1`. No cell holds it; the workbook does.

Then use them. Replace J2 with this and fill it down; the shares are the same as before:

```localised
=H2/TotalRevenue
```

Anywhere on `Sales`, this answers **51494**, the same total as `=SUM(H2:H109)`:

```localised
=SUM(Revenue)
```

And on `Products`, in an empty cell of row 2, the 10% price of `SUL250`, **37**, with no rate typed
anywhere in the formula:

```localised
=ROUND(F2*(1-Discount),0)
```

## The Name Manager

**Formulas › Name Manager** (Ctrl+F3 on Windows) lists every name in the workbook with its value,
what it refers to and its **scope**. It is where you edit a name that points at the wrong range,
and delete one nobody uses. A name's scope is the **workbook** unless you choose a sheet when you
create it; a sheet-scoped name is known only on that sheet, which lets two sheets each have their
own `Rate`. Leave it at workbook until you have a reason.

Excel refuses some names, and the rules are short:

- the first character is a letter, an underscore or a backslash, and there are **no spaces**:
  `TotalRevenue` or `Total_Revenue`, never `Total Revenue`;
- a name cannot look like a cell address. `Q1` for the first quarter is refused, because Q1 is a
  cell, and so is `TAX2025`, because column TAX exists in a sheet of 16,384 columns;
- `C` and `R` alone are refused too, because Excel uses them for the current column and row in
  another way of writing references;
- case does not count: `revenue` and `Revenue` are the same name.

## What a name costs

A name hides where it points, and that is both its use and its price. Two habits keep the price low.

**A constant in a cell is visible; a constant in a name is not.** `Discount` sits in the Name
Manager, where nobody looks, and a colleague who wants to know why the grid uses 10% has to know to
open it. A labelled cell, `Discount` in one cell and `10%` in the next, is seen and changed by
anyone. Use a name for a value that should not change casually, and a cell for one that should be
seen.

**A name is a fixed range.** `Revenue` means H2:H109. The day Café Serra's 109th sale is added in
row 110, `=SUM(Revenue)` leaves it out, without an error. Inserting a row inside the range widens
the name; adding one below it does not. Lesson 7 turns `Sales` into an Excel table, which names
every column and grows with the data, and that is the better tool for a range that grows. Names
remain the right tool for a single cell and for a constant.
