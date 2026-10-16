---
title: When references break
version: 1
---

**A reference can break in three ways, and only one of them shows you an error.** A cell it pointed
at is deleted, and it says `#REF!`. A formula points at itself, and Excel complains once and then
shows a number that means nothing. Or a number is typed where a reference should be, and nothing
says anything at all. The third is the one that costs money.

## `#REF!`: the cell is gone

With J2:J109 holding `=H2/$L$2` and its copies, right-click the column letter **L** and choose
**Delete**. Every share in column J becomes `#REF!`, and J2's formula now reads `=H2/#REF!`. Excel
did not lose the address by accident: the cell it named no longer exists, and there is nothing it
could put there that would be true. A name follows its cells the same way, so if `TotalRevenue`
from the previous section pointed at L2, the Name Manager now shows it referring to a `#REF!` too.

Press **Ctrl+Z** at once and everything comes back. After the file is saved and closed, undo is
gone, and the only repair is to write the reference again.

Deleting rows inside a range is a different event, and a quieter one. Delete row 50 of `Sales`, sale
S1049, and the total in L2 changes from `=SUM(H2:H109)` to `=SUM(H2:H108)`: the range shrank to fit
the rows that remain, and the total drops to **50450**. No error, because nothing is broken. A sale
has gone, and that may be what you meant, or not. Undo this one too.

## A circular reference: the formula counts itself

Put a total at the foot of the column it adds, in H110:

```localised
=SUM(H2:H110)
```

The range includes H110, so the cell's value depends on its own value. Excel warns you with a
message the first time, the cell shows 0, and the status bar at the bottom of the window shows
**Circular References** with the address of the cell. **Formulas › Error Checking › Circular
References** lists every cell caught in one. The same thing happens with `=SUM(H:H)` written
anywhere in column H, which is the usual way it arrives.

The cure is the rule from lesson 1 section 06: **totals live outside the data.** In a cell beside
it, as L2 was, or under a gap, or on another sheet. Delete H110.

Excel has a setting that lets circular formulas recalculate in a loop, **Enable iterative
calculation**, for the rare model that needs one. A formula that counts its own total is not that
model, and the setting would hide the warning that just helped you.

## A number where a formula belongs

This one has no symptom, which is why it is worth staging on purpose. Click H50, sale S1049, which
shows 1044: 9 bags of `SUL1K` at R$ 116. Type `1044` over it and press Enter. Nothing changes on
the screen, and the total is still 51,494. The cell now holds a number instead of a formula, and
that difference is invisible.

Now suppose the order is corrected: it was 10 bags, not 9. Type `10` in E50. With the formula, H50
would become 1160 and the total **51610**. With the typed number, H50 stays 1044 and the total stays
**51494**, short by R$ 116, and every report built on it inherits the gap.

Hard-coded numbers arrive two ways. **A value pasted over a formula**, as above, usually by somebody
who copied a column and used **Paste Values** in the wrong place. And **a constant buried inside a
formula**, like `=ROUND(F2*0.9,0)` written in six cells instead of a reference to one cell holding
the discount: when the discount changes, somebody has to find all six, and the one they miss gives
an old price with no error.

Two commands find them:

- **Formulas › Show Formulas** shows every formula instead of its result. In a
  column of `=E2*F2` copies, a bare `1044` stands out at a glance. Click it again to go back.
- **Home › Find & Select › Go To Special**, then **Constants**, selects every cell in the
  selection that holds a typed value rather than a formula. Select H2:H109 first; in a healthy
  Revenue column it finds nothing at all.

Put H50 back with `=E50*F50` and E50 back to 9, and check that the total is 51,494 again.

## Before lesson 3

Keep column H, `Revenue`; the rest of the course uses it. The other things this lesson made are
not needed again: clear J1:J109 and L1:L2 on `Sales`, clear I1:K7 on `Products`, and delete
`TotalRevenue`, `Revenue` and `Discount` in the Name Manager. Lesson 3 starts its own helper columns
in J. Then save.
