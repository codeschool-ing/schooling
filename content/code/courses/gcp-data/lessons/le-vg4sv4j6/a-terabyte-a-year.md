---
title: A tebibyte for a year, in each class
version: 1
---

**The cheapest class to keep data in is the most expensive one to read it from**, and the only way to
choose is to put both numbers side by side for the data in question. A tebibyte is a good size to
reason with; say it is Quitanda's order exports for five years. The program below prices it for a
year in each class, adds what reading the whole of it back once would cost, and works out how many
full reads a year it takes for each class to cost as much as Standard. Save it as `~/gcp/year.py`
with the copy button.

```schooling-example
{"language": "python", "file": "year.py", "parts": [{"code": "\"\"\"A tebibyte for a year in each Cloud Storage class, and reading it back.\"\"\"\n\nTIB = 1024        # GiB in a TiB: the price list counts gibibytes\nMONTHS = 12\n\n", "note": "One tebibyte is 1,024 GiB, because Google's price list is per gibibyte, 2 to the 30th bytes. Change `TIB` to price another volume."}, {"code": "# class: (USD per GiB-month, USD per GiB read back), southamerica-east1,\n# from cloud.google.com/storage/pricing, read 2026-10-30.\nPRICES = {\n    'Standard': (0.035, 0.00),\n    'Nearline': (0.020, 0.01),\n    'Coldline': (0.007, 0.02),\n    'Archive':  (0.003, 0.05),\n}\nSTANDARD_YEAR = TIB * PRICES['Standard'][0] * MONTHS\n\n\n", "note": "**Every number here is a line of the pricing page**: the São Paulo storage prices and the retrieval fees, which are the same in every region. Standard charges nothing to read back. `STANDARD_YEAR` is the line every other class is compared against."}, {"code": "print(f'{\"class\":<10}{\"a year\":>9}{\"read once\":>11}{\"total\":>9}{\"reads to pass Standard\":>24}')\nfor name, (store, read) in PRICES.items():\n    year = TIB * store * MONTHS\n    once = TIB * read\n    passes = '-' if read == 0 else f'{(STANDARD_YEAR - year) / once:.1f}'\n    print(f'{name:<10}{year:>9.2f}{once:>11.2f}{year + once:>9.2f}{passes:>24}')\n", "note": "A year is the volume times the monthly price times twelve, and one full read is the volume times the retrieval fee. The last column is how many full reads a year it takes for the cheaper class to cost as much as Standard: the year saved, divided by what one read costs."}]}
```

```
ana@laptop:~/gcp$ python3 year.py
class        a year  read once    total  reads to pass Standard
Standard     430.08       0.00   430.08                       -
Nearline     245.76      10.24   256.00                    18.0
Coldline      86.02      20.48   106.50                    16.8
Archive       36.86      51.20    88.06                     7.7
ana@laptop:~/gcp$ python3 -c 'print(round((86.016 - 36.864) / (51.2 - 20.48), 1), round((245.76 - 86.016) / (20.48 - 10.24), 1))'
1.6 15.6
```

## Reading the table

**Standard costs 430.08 for the year and Archive 36.86**, and that gap is the reason the colder
classes exist. Reading the tebibyte back once does not change the order: 51.20 in retrieval fees,
for a total of 88.06, is still the cheapest line. A tebibyte read once a year belongs in Archive.

**The last column is where each class stops paying.** Archive passes Standard at 7.7 full reads a
year, because its fee of 0.05 a GiB is the highest. Coldline lasts until 16.8, and Nearline, whose
fee is the lowest, until 18.0. Those are the points at which each class costs as much as Standard;
they are not the points at which one cold class overtakes another, and the second command above
works those out.

Its two numbers are where the cheaper class of each pair stops being cheaper. Coldline and Archive
cost the same at 1.6 full reads a year, (86.02 − 36.86) / (51.20 − 20.48). Nearline and Coldline
cost the same at 15.6, (245.76 − 86.02) / (20.48 − 10.24). **So for a tebibyte kept a whole year in
São Paulo, Archive wins up to a read or so, Coldline from there to about fifteen, Nearline in the
narrow band up to eighteen, and Standard above that**, which is a read every three weeks. Coldline
is cheap here, at a fifth of Standard's price, and that is why it covers so much of the range.

## A shorter stay

The table assumes a year, and a stay shorter than a class's minimum changes the answer completely.
Say the tebibyte is a scratch copy kept for 60 days and never read. Each class bills the longer of
the 60 days and its minimum, counting a month as 30 days:

```
ana@laptop:~/gcp$ python3 -c 'for name, price, least in [("Standard", 0.035, 0), ("Nearline", 0.020, 30), ("Coldline", 0.007, 90), ("Archive", 0.003, 365)]: print(f"{name:<10}{1024 * price * max(60, least) / 30:>7.2f}")'
Standard    71.68
Nearline    40.96
Coldline    21.50
Archive     37.38
```

**Coldline is the cheapest at 21.50, and Archive, the cheapest of the year-long table, costs 37.38**,
because it bills 365 days for data that stayed 60. Nearline bills exactly what it kept, 40.96, and
Standard 71.68. A scratch copy kept 20 days would put Nearline's 30-day minimum against Coldline's 90
and Standard's nothing, and the answer would move again. Before the price per GiB-month, ask how long
the data stays.

## What the table leaves out

Two things, and each of them can turn the order around:

- **requests.** Each object written is a Class A operation and each one read a Class B, at the price
  of its class. A tebibyte of 1 GiB files is 1,024 of them, which costs nothing worth printing. A
  tebibyte of 10 KB files is about a hundred million, and in Archive that is 5,000 USD to write
  them, before a byte is kept. Lesson 5 prices what that does;
- **the network.** A read that leaves the region pays for the data that crosses, in every class,
  and that is lesson 5 as well.

What the table does not need is a column for waiting. Every class answered the first byte in
milliseconds, so the choice is made on money alone, which is what makes it a calculation.
