---
title: The plant's data: three records and three clocks
version: 1
---

Every number in this lesson came from somewhere, and in a factory the somewhere matters more than in
retail or in a hospital. **A plant keeps three records of the same event**, made by three different
things for three different purposes, and they disagree in ways that are predictable once you know
who wrote each one.

| record | who writes it | when | what it is for |
|---|---|---|---|
| the machine's counters and sensors | the machine's controller, automatically | every cycle, to the second | running the machine |
| the ERP | the warehouse and the planners | when an order is released, when boxes are counted in | stock, invoices and the customer |
| the shift sheet | the operator, by hand | at the end of the shift | the scrap, the stops and their reasons |

## One shift, three answers

IM-07's second shift, the one taken apart for OEE. The machine's counter recorded 1,350 cycles. The
warehouse counted 1,296 good caps into the ERP. The operator's shift sheet said 40 caps were
scrapped. Type the three:

| | A | B |
|---|---|---|
| 1 | Machine counter | 1350 |
| 2 | Operator's scrap | 40 |
| 3 | Boxed into the warehouse | 1296 |

If the operator's scrap were complete, the good parts would be the counter minus the scrap:

```localised
=B1-B2      1310
=B1-B2-B3      14
```

**Fourteen caps were made, were not good and were not written down.** The usual explanation, and the
one Rafael found when he asked, is start-up scrap: after the mould change, the first shots are
thrown into a bin while the machine comes up to temperature, and the operator, busy restarting,
writes down the scrap from the run and not the scrap from the restart.

The two quality figures that follow are both computed correctly:

```localised
=ROUND((B1-B2)/B1*100,1)      97
=ROUND(B3/B1*100,1)      96
```

97.0% from the shift sheet, 96.0% from the counter and the boxes. The OEE section used the second,
and that was a choice: **between a number a machine counted and a number a person typed at the end
of a tiring shift, trust the counter**, and use the hand-written one for what only a person can
supply, which is the reason. A report that took scrap from the shift sheet would show IM-07 one
point better than it is, every shift, and the missing caps would add up to thousands a month that
nobody can find.

## Three clocks

The records also disagree about time. The machine's controller has its own clock, set when it was
installed and not always since. The ERP uses the server's clock. The shift sheet uses whatever the
operator wrote, which is usually the end of the shift. When Rafael first joined the controller's
stop log to the maintenance log, a breakdown seemed to be repaired seven minutes before it started;
IM-11's controller clock was seven minutes fast.

**Shifts cross midnight**, and reports by calendar day do not. The third shift runs from 22:00 to
06:00, so a report of "Tuesday's production" either splits it between two days or assigns it whole
to the day it started, and two reports that chose differently will never agree. Serra Azul's rule,
written at the top of every production report, is that a shift belongs to the date on which it
started.

## The trap, and what to do about it

The industry's trap is the one in the table at the start of this lesson: **a typed number sits in
the same table as a counted one and looks just as solid**. Nothing in a dashboard shows that the
scrap column was written by hand at 21:55 and the parts column by a controller at every cycle.

The fixes are dull and they work. Reconcile the three records every shift, as the sheet above does,
and put the gap on the supervisor's screen, so that 14 unexplained caps are noticed on the night
they happen instead of at the month's stocktake. Take counts from the machine wherever the machine
can count them. Ask people for what only people know, the reason for a stop or for scrap, and make it
quick to give: a short list on a screen beside the machine beats a blank line on a sheet. And write
the rules, the shift's date and which clock wins, where every report can point to them.
`data-governance` lesson 9 covers data quality and lineage for any industry; a factory is simply the
place where a person's handwriting and a machine's counter meet in one column.
