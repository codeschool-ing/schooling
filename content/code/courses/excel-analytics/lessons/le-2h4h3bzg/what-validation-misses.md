---
title: What validation does not see
version: 1
---

**Validation checks one thing: a value typed into a cell and confirmed with Enter.** Everything
else that changes a cell goes past it without a word, and a sheet full of rules can still hold
values that break every one of them. Knowing the gaps is what stops a rule from being mistaken for
a guarantee.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l08-paths\" aria-label=\"Four ways a value reaches a validated cell. Only the first, typing and pressing Enter, passes through the rule, which refuses it, warns or informs. Pasting replaces the value and the rule together. A formula's new answer and a value already there when the rule was made reach the cell unchecked. Circle Invalid Data, at the bottom, checks every cell against its rule when asked.\"><rect x=\"330.0\" y=\"32.0\" width=\"90.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"375.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">the rule</text><rect x=\"590.0\" y=\"30.0\" width=\"140.0\" height=\"200.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"660.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the cell</text><text x=\"30.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">typed, then Enter</text><path d=\"M250.0 55.0 L326.0 55.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M326.0 55.0 L318.0 51.0 L318.0 59.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M420.0 55.0 L586.0 55.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M586.0 55.0 L578.0 51.0 L578.0 59.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"375.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Stop · Warning</text><text x=\"375.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">· Information</text><text x=\"30.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pasted with Ctrl+V</text><path d=\"M250.0 105.0 L584.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M581.0 105.0 L586.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586.0 105.0 L578.0 101.0 L578.0 109.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"598.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">rule replaced</text><text x=\"30.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a formula's answer changes</text><path d=\"M250.0 155.0 L584.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M581.0 155.0 L586.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586.0 155.0 L578.0 151.0 L578.0 159.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"598.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">unchecked</text><text x=\"30.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">there before the rule existed</text><path d=\"M250.0 205.0 L584.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M581.0 205.0 L586.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586.0 205.0 L578.0 201.0 L578.0 209.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"598.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">unchecked</text><text x=\"598.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">checked</text><path d=\"M30.0 262.0 L730.0 262.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Circle Invalid Data checks every cell against its rule, but only when you ask,</text><text x=\"30.0\" y=\"303.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">and changes nothing: it draws a circle round each value that breaks it.</text></svg>", "caption": "Validation guards one door, typing. A paste, a recalculated formula and the data already in the sheet come in by the others, and Circle Invalid Data is how you find them."}
```

## Four ways past the rule

- **Pasting.** **Ctrl+V** into a validated cell replaces what the cell holds *and its rule*: the
  value arrives unchecked and the cell has no rule afterwards. **Paste Special › Values** keeps the
  rule, and still does not check the value it pastes. A column that is filled by pasting from
  somewhere else is not protected by its rules at all.
- **Values that were already there.** A rule applies to what is typed from now on. Putting a rule
  on a column that already holds data checks none of it.
- **Formulas.** A cell whose value comes from a formula is not checked when the formula's answer
  changes.
- **Removing the rule.** Anybody who can open the dialog can choose **Clear All**. Validation guides
  the people typing; it does not stop somebody who decides to get round it. Lesson 17 protects a
  sheet so that its rules stay put.

## Finding what got through: Circle Invalid Data

Excel can still show you which cells break their rules, whenever you ask. Try it on data that
existed before any rule. Suppose Café Serra decides that a sale above 15 bags needs a manager's
approval:

1. Select the `Bags` column of the `Sales` table, E2:E109.
2. **Data › Data Validation**, **Whole number**, **between** `1` and `15`, **OK**. Nothing on the
   sheet changes, because nothing was typed.
3. Click the small arrow beside **Data Validation** and choose **Circle Invalid Data**.

A red circle appears round every cell that breaks the rule. There are four. A formula confirms the
count and says the circles missed nothing:

```localised
=COUNTIF(Sales[Bags], ">15")
```

answers **4**: two sales of 16 bags, one of 17 and one of 20. The circles are a view, not a change:
**Clear Validation Circles**, from the same arrow, removes them, and editing a circled cell to a
valid value removes its circle.

Now take the rule off again, because `Sales` is the course's record of what happened and the sales
above 15 bags did happen: with E2:E109 still selected, **Data › Data Validation › Clear All**,
**OK**.

## Leaving the workbook as the next lessons expect it

Delete any test rows you typed into `NewSales`, so that the table has one empty row again, and keep
the sheet with its rules and the two names. Nothing in `New sales` reaches `Sales`: the lessons
after this one compute from `Sales`, and their numbers assume it still has its 108 rows.
