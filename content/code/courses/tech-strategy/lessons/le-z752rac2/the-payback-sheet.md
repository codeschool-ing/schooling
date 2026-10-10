---
title: The payback sheet
version: 1
---

With a principal and an interest for each debt, one division answers what a list of debts never
does: **how many sprints until paying the debt off has paid for itself**. That is the payback,
principal divided by interest. This is the first sheet in the course where you compute, so open the
spreadsheet you set up in lesson 1 and add a new sheet to it.

## The sheet

Type the header and the four debts. Columns D and E stay empty for now.

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Debt | Principal (h) | Interest (h/sprint) | Payback (sprints) | Interest a year (R$) |
| 2 | Seat-hold locking | 320 | 31 | | |
| 3 | PDF ticket generator | 120 | 6 | | |
| 4 | Flaky end-to-end suite | 80 | 14 | | |
| 5 | Old reporting replica | 200 | 4 | | |

In D2, the payback of the seat-hold debt, rounded to one decimal place:

```localised
D2      =ROUND(B2/C2,1)      10.3
```

Now copy D2 down to D5. In LibreOffice, select D2 and drag the small square at its bottom-right
corner down to row 5; the references move with each row:

```localised
D3      =ROUND(B3/C3,1)      20
D4      =ROUND(B4/C4,1)      5.7
D5      =ROUND(B5/C5,1)      50
```

The spreadsheet shows 20 and 50 with no decimal, because rounding to one place left nothing after the
point. In E2, what the seat-hold interest costs in a year — hours a sprint, times 26 sprints, times
R$ 150:

```localised
E2      =C2*26*150      120900
```

Copy E2 down to E5 the same way. The other three come out at 23400, 54600 and 15600.

## Three questions the sheet answers

**Which debt pays back first?** Ask the spreadsheet instead of reading down the column:

```localised
=INDEX(A2:A5,MATCH(MIN(D2:D5),D2:D5,0))      Flaky end-to-end suite
```

`MIN` finds the shortest payback, `MATCH` finds which row holds it, and `INDEX` returns the name in
that row. The suite costs 80 hours and gives back 14 a sprint, so it has paid for itself in 5.7
sprints — under twelve weeks.

What do the four cost together, every sprint?

```localised
=SUM(C2:C5)*150      8250
```

That is R$ 8,250 a sprint, or 55 engineer-hours. And over a year:

```localised
=SUM(E2:E5)      214500
```

**R$ 214,500 a year, for four debts that nobody has decided to pay.** In hours it is 1,430 (55 × 26),
about four-fifths of an engineer-year of 1,760 hours, spent without appearing on any budget line.

## Reading the payback column

| debt | principal (h) | payback (sprints) |
|---|---|---|
| Flaky end-to-end suite | 80 | 5.7 |
| Seat-hold locking | 320 | 10.3 |
| PDF ticket generator | 120 | 20 |
| Old reporting replica | 200 | 50 |

Sorted by principal, the list started with the suite and ended with the seat-hold locking. Sorted by
payback, the seat-hold debt moves up to second and the replica drops to the bottom. Fifty sprints is
nearly two years (50 ÷ 26 = 1.9), and **a debt that takes two years to pay for itself is one to leave
alone** unless something outside the sheet forces the work. Lesson 6 describes what that something
looks like.

## What the sheet does not decide

The payback puts the suite first, and Coreto's strategy puts the seat-hold debt first. Both can be
right, because they answer different questions. The payback counts hours. The seat-hold debt also
carries the risk of a failed big on-sale, which costs venues, and which lesson 1's diagnosis named as
the challenge the whole strategy is built around.

**So the sheet informs the strategy and does not overrule it.** It says the suite is cheap and quick to
pay back, so whoever owns the tests can fix it alongside the seat-hold work. It says the PDF
generator is worth paying only when a team is working in that code anyway. And it says the replica
can wait, which is worth having in writing the next time somebody proposes rebuilding it because it
looks old.

Two assumptions sit under every payback in the sheet, and both are worth checking before quoting
one:

- that paying the principal removes the interest entirely — a half-finished fix often removes only
  part of it, and the sheet then overstates the return;
- that the interest stays where it is while you wait. The next section is about the debt whose
  interest does not.
