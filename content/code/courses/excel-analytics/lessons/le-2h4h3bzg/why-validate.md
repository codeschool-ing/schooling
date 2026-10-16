---
title: Why check what is typed
version: 1
---

**A cell accepts whatever is typed into it, and a wrong value shows its cost somewhere else, later,
in a total that nobody connects with the typing.** Excel has no idea that `Channel` holds one of
three words, that a sale is a few bags rather than a few hundred, or that Café Serra did not sell
anything in 2205. You know all three. Data validation is how you tell the cell.

## One space, and the totals stop adding up

Try it on your own workbook. In an empty cell to the right of the `Sales` table, type the three
channel totals and the grand total:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Online")
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")+SUMIFS(Sales[Revenue], Sales[Channel], "Online")+SUMIFS(Sales[Revenue], Sales[Channel], "Shop")
=SUM(Sales[Revenue])
```

The first answers **11,143**, and the other two agree on **51,494**, as they should: every sale
belongs to exactly one channel. Now click G4, the channel of sale `S1003`, and type `Online` with a
space after it. The cell looks the same. But `Online` with a space is a different word from
`Online`, so `SUMIFS` no longer finds the sale. The Online total drops to **11,028**, the three
channels add up to **51,379**, and the grand total still says **51,494**. The gap is **115**, the
revenue of `S1003`, and nothing on the sheet says where it went.

Press **Ctrl+Z** to put the cell back before going on.

`SUMIFS` does not care about capitals, so `online` would have been found. A trailing space, a
transposed letter (`Onlnie`) or a different word for the same thing (`Web`) each create a channel
that no formula asks about.

## The four ways a typed value goes wrong

| what was typed | where it hurts |
|---|---|
| a category spelled another way: `Online ` | a total by that category, which silently leaves it out |
| a number out of range: `140` bags for `14` | every sum and average that includes it |
| an impossible date: `2205-03-11` | a total by year or month, and every filter on dates |
| a code that does not exist: `CER1KG` | every lookup on it, which answers `#N/A` (lesson 4) |

None of them is an error Excel can see. Each one is a valid value of its type, in a cell that had
no rule.

## Checking at the moment of typing

**Validation moves the check to the one moment the right value is known**: when somebody is typing
it, with the order or the receipt in front of them. Found a month later in a report, the same
mistake means somebody hunting through 108 rows for the one that is wrong. Found at the moment of
typing, it costs a second.

It is a tool for data that people type. Data that arrives as a file from another system is a
different job, and lessons 13 and 14 do it with Power Query. The next section builds the place
where Café Serra's people would type the next sale.
