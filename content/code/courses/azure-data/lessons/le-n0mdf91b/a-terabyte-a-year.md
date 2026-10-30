---
title: A terabyte for a year, in each tier
version: 1
---

**The cheapest tier to keep data in is the most expensive one to read it from**, and the only way to
choose is to put both numbers side by side for the data in question. A terabyte is a good size to
reason with; say it is five years of Quitanda's order exports. The program below prices it for a
year in each tier, adds what reading it all back once would cost, and prices the mistake of the
previous section: keeping it ten days and deleting it.

**The prices in it are illustrative.** Lesson 1 explains why this course quotes none of Azure's: the
machine its transcripts were recorded on could not reach the price list. The numbers below are round,
in the documented order, and meant to be replaced. Run lesson 1's `prices.py` for each tier, put the
real prices in, and the same program does the same sums with them.

```schooling-example
{"language": "python", "file": "year.py", "parts": [{"code": "\"\"\"A terabyte for a year in each access tier, at ILLUSTRATIVE prices.\"\"\"\n\nTB = 1024        # GB in a terabyte, as the price sheet counts them\nMONTHS = 12\n", "note": "One terabyte is 1,024 GB, because the price sheet's gigabyte is 2 to the 30th bytes. Change `TB` to price another volume."}, {"code": "\n# tier: (USD per GB-month kept, USD per GB read back, minimum days billed)\n# The prices are ROUND NUMBERS FOR THE ARITHMETIC, not Azure's: replace them\n# with what `python prices.py Storage <tier> LRS` prints. The days are documented.\nTIERS = {\n    \"Hot\":     (0.020, 0.00, 0),\n    \"Cool\":    (0.010, 0.01, 30),\n    \"Cold\":    (0.004, 0.03, 90),\n    \"Archive\": (0.002, 0.02, 180),\n}\n", "note": "**Every price here is illustrative**, chosen so that the sums are easy to follow and the tiers keep their documented order. The minimum days are Microsoft's. Archive's read price is for the standard rehydration priority."}, {"code": "\nprint(f\"{'tier':<9}{'a year':>9}{'read once':>11}{'total':>9}{'kept 10 days':>14}\")\nfor tier, (keep, read, minimum) in TIERS.items():\n    year = TB * keep * MONTHS\n    once = TB * read\n    ten_days = TB * keep * max(10, minimum) / 30\n    print(f\"{tier:<9}{year:>9.2f}{once:>11.2f}{year + once:>9.2f}{ten_days:>14.2f}\")\n", "note": "A year is the volume times the monthly price times twelve, and reading it back once is the volume times the read price. The last column keeps the terabyte for ten days and deletes it, billed for the minimum when the minimum is longer, a month counted as 30 days."}], "output": "tier        a year  read once    total  kept 10 days\nHot         245.76       0.00   245.76          6.83\nCool        122.88      10.24   133.12         10.24\nCold         49.15      30.72    79.87         12.29\nArchive      24.58      20.48    45.06         12.29\n"}
```

Run it with `python year.py`; the output is under the program.

## Reading the table

**Hot costs 245.76 for the year and archive 24.58**, ten times less, and that gap is the reason
archive exists. Reading the terabyte back once adds 20.48 to archive and it is still the cheapest
line by far. Data read once a year, or less, belongs in archive, as long as hours of waiting are
acceptable when it is read.

**Cold is the tier whose reads matter most.** Its year is 49.15 and one full read is 30.72, more
than half the year again. Read the whole terabyte four times and cold costs 49.15 + 4 × 30.72 =
172.03; at seven full reads it is 264.19, past hot's 245.76. Cold is for data read almost never,
and needed at once when it is.

**Cool sits between them**: 122.88 for the year and 10.24 for a full read. Its break-even with hot
is (245.76 − 122.88) / 10.24 = 12 full reads a year. At these prices, data read every week is cheaper
in hot and data read every quarter is cheaper in cool. With Azure's real prices the break-even moves,
and the program finds it the same way.

**The last column is the early deletion charge at work.** Ten days in hot cost 6.83, a third of a
month. Ten days in cool cost 10.24, because they are billed as thirty; in cold 12.29, billed as
ninety; and in archive 12.29 as well, billed as a hundred and eighty. For data that stays ten days,
hot is the cheapest tier and archive is not, which is the opposite of the first column.

## What the table leaves out

Three things, and the first can turn the order around on its own:

- **operations.** Every read is a request, and each tier prices requests differently, higher the
  colder it is. A terabyte of 1 GB files is 1,024 reads; a terabyte of 10 KB files is about a hundred
  million, and lesson 7 prices what that does;
- **high-priority rehydration**, which costs more per gigabyte than the standard price used here;
- **the time.** Archive's 20.48 comes with up to fifteen hours of waiting at standard priority, which
  is a price paid in something other than money.
