---
title: Categories stored as numbers
version: 1
---

Systems love to store categories as numbers. A survey tool records payment as 1, 2 or 3. A form
records sex as 1 or 2, satisfaction as 1 to 5, and the region as 11 to 53. The numbers save space and
typing, and they set a trap.

**A coded column looks numerical to every tool that reads it.** The spreadsheet will offer a sum. A
dashboard will happily draw the average region. Lesson 1 averaged Horta's payment codes — 1 for pix,
2 for card, 3 for cash — and got 1.67, a number with no meaning.

## How the trap springs

Nobody types "average of the payment codes" on purpose. It happens in three quiet ways.

- **A summary over every column.** A tool that describes a whole table prints the mean of each
  numerical column, and coded categories are numerical to it. The mean of *payment* sits in the
  report beside the mean of *basket*, looking equally serious.
- **A model fed the codes.** Give a regression the region as 11, 21, 31 and it will assume region 31
  is to region 21 as region 21 is to region 11, and fit a slope through them. Lesson 19 shows
  how categories should enter a model instead.
- **A recode nobody records.** Somebody swaps the codes for card and cash. Every count is still
  right, every "average payment" changes, and nothing anywhere says why.

## What to do instead

Keep the label beside the code, or instead of it. A column that says `pix` cannot be averaged by
accident. Where the codes must stay, keep a **codebook**: a document that says what each code means
and which scale the variable is on.

Before summarising any column whose values are small whole numbers, ask whether they are amounts or
codes. **1, 2 and 3 might be items in a bag or the names of three payment methods**, and only the
codebook knows which.

## The ordinal case

Ratings are the hard middle. The codes 1 to 5 do carry an order, so a median of them is meaningful,
and the last section allowed a mean with care. What the codes never carry is the size of each step.
When a report averages a coded ordinal scale, it should say so, and it should show the distribution
beside the average.
