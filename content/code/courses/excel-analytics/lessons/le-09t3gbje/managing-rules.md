---
title: Finding, ordering and clearing rules
version: 1
---

**Rules are invisible until they fire, so a sheet collects them**: one added to try an idea,
another copied along with some cells, a third left from last year's report. The **Rules Manager**
is the only place that shows them all, and it is where the order between them is decided.

## The Rules Manager

**Home › Conditional Formatting › Manage Rules** opens it. The list at the top, **Show formatting
rules for**, starts on the current selection; switch it to **This Worksheet** to see every rule on
the sheet. Each line shows:

- the **rule**, such as `Formula: =$G2="Wholesale"` or `Cell Value >= 1500`;
- its **format**, as a small preview;
- **Applies to**, the range it covers, which you can edit in place;
- **Stop If True**, a box that some kinds of rule offer.

**New Rule**, **Edit Rule** and **Delete Rule** sit above the list, and the two arrows beside them
move the selected rule up or down.

## Order decides which colour wins

When two rules are true for the same cell and both set its fill, **the rule higher in the list
wins**. Formats that do not clash are combined: one rule can set the fill and another the bold.

Try it on `Sales[Revenue]`. Add one rule that fills cells of **1,500 or more** with a strong colour,
and another that fills cells of **1,000 or more** with a pale one. A formula counts each group:

```localised
=COUNTIF(Sales[Revenue], ">=1500")
=COUNTIF(Sales[Revenue], ">=1000")
```

**9** and **18**. With the 1,500 rule on top, the 9 largest sales are strong and the other 9 pale,
and the sheet shows two grades. Move the 1,000 rule to the top and all 18 are pale: the 1,500 rule
is still true for 9 of them, and loses every time. Nothing on the sheet says that a rule has been
outvoted, so **put the narrower condition above the wider one**.

**Stop If True** is an older way of saying the same thing. Ticked on a rule, it stops Excel
looking at the rules below it for any cell where that rule is true, even when they would set a
different property.

## How rules multiply

Copying and pasting formatted cells copies their rules, and inserting rows, moving cells or
pasting into the middle of a range can split one rule into several with odd, overlapping
**Applies to** ranges. The sheet still looks right, which is why nobody notices until the manager
lists twelve copies of the same rule. Two habits keep this down:

- **apply rules to whole columns of a table**, which the table extends as it grows, rather than to
  a range that somebody later extends by pasting;
- **open the manager on This Worksheet now and then**, merge duplicates by editing one rule's
  **Applies to** to cover the whole range, and delete the rest.

## Clearing

**Conditional Formatting › Clear Rules** removes rules from the selected cells, from the entire
sheet, or from the table the selection is in. It removes only conditional formats: fills and fonts
applied by hand stay.

Keep or clear what this lesson made as you like. Nothing in lessons 10 to 18 depends on these rules
or on the `By month` sheet: the pivot tables of lesson 10 read the values in `Sales`, never their
colours.
