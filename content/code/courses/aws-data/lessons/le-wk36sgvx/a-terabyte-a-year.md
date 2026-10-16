---
title: A terabyte for a year, in each class
version: 1
---

**The cheapest class to keep data in is the most expensive one to read it from**, and the only way
to choose is to put both numbers side by side for the data in question. A terabyte is a good size to
reason with; say it is Quitanda's order exports for five years. The program below prices
it, for a year, in each class, and adds what reading the whole terabyte back once would cost. Save it
as `~/aws/year.py` with the copy button, as lesson 1 did with the price sheet.

```schooling-example
{"language": "python", "file": "year.py", "parts": [{"code": "\"\"\"A terabyte for a year in each S3 class, and reading it back once.\"\"\"\n\nTB = 1024        # GB in a terabyte, as the price list counts them\nMONTHS = 12\n\n", "note": "One terabyte is 1,024 GB, because the price list's gigabyte is 2 to the 30th bytes. Change `TB` to price another volume."}, {"code": "# class: (USD per GB-month, USD per GB read back), from `python3 prices.py s3`.\n# None is a price the sheet does not print.\nPRICES = {\n    'Standard':                    (0.04050, 0.0),\n    'Standard-IA':                 (0.02210, 0.01000),\n    'One Zone-IA':                 (0.01770, None),\n    'Glacier Instant Retrieval':   (0.00830, 0.03000),\n    'Glacier Flexible, standard':  (0.00765, 0.01400),\n    'Deep Archive, standard':      (0.00320, 0.02800),\n    'Deep Archive, bulk':          (0.00320, 0.00800),\n}\n\n\n", "note": "**Every number here is a line of the S3 block**, copied by hand. Standard charges nothing to read back. One Zone-IA's retrieval fee is not in the sheet, so it is `None` rather than a guess, and the program prints a dash for it. Deep Archive appears twice, once per restore tier."}, {"code": "def money(x):\n    return '-' if x is None else f'{x:,.2f}'\n\n\n", "note": "A price that is not known prints as a dash, never as zero."}, {"code": "print(f'{\"class\":<30}{\"a year\":>10}{\"read once\":>11}{\"total\":>10}')\nfor name, (store, read) in PRICES.items():\n    year = TB * store * MONTHS\n    once = None if read is None else TB * read\n    total = None if once is None else year + once\n    print(f'{name:<30}{money(year):>10}{money(once):>11}{money(total):>10}')\n", "note": "A year is the volume times the monthly price times twelve. Reading it back once is the volume times the retrieval price, and only the storage for the year is certain; how often the data is read is the part a design guesses."}]}
```

```
ana@laptop:~/aws$ python3 year.py
class                             a year  read once     total
Standard                          497.66       0.00    497.66
Standard-IA                       271.56      10.24    281.80
One Zone-IA                       217.50          -         -
Glacier Instant Retrieval         101.99      30.72    132.71
Glacier Flexible, standard         94.00      14.34    108.34
Deep Archive, standard             39.32      28.67     67.99
Deep Archive, bulk                 39.32       8.19     47.51
```

## Reading the table

**Standard costs 497.66 for the year and Deep Archive 39.32**, and that gap is the reason archive
classes exist. Reading the terabyte back once does not change the order: 8.19 at Deep Archive's bulk
speed, 28.67 at its standard speed, and it is still the cheapest line. A terabyte read once a year belongs in an archive.

**Glacier Instant Retrieval is the class whose reads matter most.** Its year is 101.99 and one full
read is 30.72, nearly a third of the year again. Read the whole terabyte four times and the reads,
122.88, cost more than the storage. At about eleven full reads a year, 101.99 + 11 × 30.72 = 439.91,
it is closing on Standard's 497.66, and at fourteen it has passed it: 101.99 + 14 × 30.72 = 532.07.
Instant Retrieval is for data read rarely and needed at once when it is, such as the images of an
order a customer disputes months later.

**Standard-IA sits between them**: 271.56 for the year, 10.24 for a full read. The same arithmetic
puts its break-even with Standard at about 22 full reads a year, (497.66 − 271.56) / 10.24 = 22.08.
Data read every week is cheaper in Standard; data read every quarter is cheaper in Standard-IA.

## What the table leaves out

Three things, and the first two can each turn the order around:

- **requests.** Each object read is a `GET`, and in the archive classes a restore request as well.
  A terabyte of 1 GB files is 1,024 of them, which costs nothing worth printing. A terabyte of 10 KB
  files is about a hundred million, and lesson 5 prices what that does;
- **the minimum durations and sizes** of the section on what a class trades. The table assumes every
  object stays a full year and is larger than 128 KB;
- **the time.** Deep Archive's 8.19 comes with up to 48 hours of waiting, which is a price paid in
  something other than money.
