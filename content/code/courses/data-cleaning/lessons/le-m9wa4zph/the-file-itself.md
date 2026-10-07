---
title: The file itself: encoding, separator and lines
version: 1
---

**A CSV file does not say how it was written.** There is no header that names its character
encoding, its separator, its decimal mark or how it quotes a field, and every tool that opens one
guesses all four. Profiling starts by checking the guesses before any of them reaches a column.

`file` reads the first bytes of each file and says what they look like:

```
ana@lab:~/clean$ file raw/*.csv
raw/customers.csv:     CSV Unicode text, UTF-8 text
raw/fx_rates_2025.csv: CSV ASCII text
raw/invoices.csv:      CSV Unicode text, UTF-8 text
raw/order_items.csv:   CSV ASCII text
raw/orders.csv:        CSV ASCII text
raw/products.csv:      CSV Unicode text, UTF-8 text
raw/store_sales.csv:   ISO-8859 text
raw/survey.csv:        CSV ASCII text
raw/targets_2025.csv:  CSV Unicode text, UTF-8 text
```

Eight files look like UTF-8 or plain ASCII, which is a subset of it. **`store_sales.csv` is
different**: ISO-8859, the family Latin-1 belongs to, and `file` does not even recognise it as
CSV, because its fields are separated by semicolons. Both facts come from the shops' till, an
old program set up for Portuguese, where the comma is the decimal mark and therefore
cannot also separate fields.

pandas assumes UTF-8 and commas, and says so in the only way it can:

```
ana@lab:~/clean$ python -c "import pandas as pd; pd.read_csv('raw/store_sales.csv')" 2>&1 | tail -1
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xe3 in position 106: invalid continuation byte
```

Byte `0xe3` at position 106 is in the first data row. Looking at the bytes of that row shows
which character it is:

```
ana@lab:~/clean$ sed -n 2p raw/store_sales.csv | od -An -c
   V   0   0   0   0   0   1   ;   P   i   n   h   e   i   r   o
   s   ;   0   2   /   0   1   /   2   0   2   5   ;   0   8   :
   3   3   ;   C   0   0   5   9   6   ;   R   $       9   4   ,
   5   0   ;   C   a   r   t 343   o   ;   5  \n
```

`od` prints `343`, which is octal for `0xe3`, where the word `Cartão` needs its `ã`. In Latin-1 that
one byte is `ã`. In UTF-8 the same letter takes two bytes, and a lone `0xe3` is the start of a
character that never finishes — hence *invalid continuation byte*. **The error is the good
outcome.** A tool that decoded this file as Latin-1 when it was UTF-8, or the other way round,
would not fail at all: it would produce `CartÃ£o`, which is exactly the mangled text the 2023
migration left in the customer file.

Telling pandas what the file is fixes both problems at once:

```
ana@lab:~/clean$ python -c "import pandas as pd; print(pd.read_csv('raw/store_sales.csv', sep=';', encoding='latin-1').head(3))"
     venda       loja        data   hora cliente     total pagamento  itens
0  V000001  Pinheiros  02/01/2025  08:33  C00596  R$ 94,50    Cartão      5
1  V000002  Pinheiros  02/01/2025  15:07  C00121  R$ 44,00    Cartão      3
2  V000003  Pinheiros  02/01/2025  12:50  C00089  R$ 10,60    Cartão      2
```

## Lines and rows

Lesson 1 counted lines with `wc -l` and promised to check that lines and records agree. A CSV field
may contain a line break if it is quoted, and then one record spans two lines. Counting both ways
settles it:

```schooling-example
{
  "language": "python",
  "file": "lines_and_rows.py",
  "parts": [
    {
      "code": "import csv\nimport glob\n\n",
      "note": "Only the standard library: this check should not depend on the tool whose parsing it is checking."
    },
    {
      "code": "for path in sorted(glob.glob(\"raw/*.csv\")):\n    encoding = \"latin-1\" if \"store_sales\" in path else \"utf-8\"\n    delimiter = \";\" if \"store_sales\" in path else \",\"\n",
      "note": "Each file is opened the way the previous section found it was written. Guessing here would repeat the mistake being measured."
    },
    {
      "code": "    with open(path, encoding=encoding, newline=\"\") as f:\n        lines = sum(1 for _ in f)\n",
      "note": "Counting what iterating the file yields counts physical lines, header included."
    },
    {
      "code": "    with open(path, encoding=encoding, newline=\"\") as f:\n        rows = sum(1 for _ in csv.reader(f, delimiter=delimiter)) - 1\n",
      "note": "`csv.reader` follows the quoting rules, so a quoted field with a line break inside it stays one record. Less one for the header."
    },
    {
      "code": "    print(f\"{path:24} {lines:7} lines {rows:7} rows\")\n",
      "note": "One line per file, the two counts side by side."
    }
  ]
}
```

```
ana@lab:~/clean$ python lines_and_rows.py
raw/customers.csv           2414 lines    2413 rows
raw/fx_rates_2025.csv         13 lines      12 rows
raw/invoices.csv              61 lines      60 rows
raw/order_items.csv        99162 lines   99161 rows
raw/orders.csv             28552 lines   28551 rows
raw/products.csv              73 lines      72 rows
raw/store_sales.csv        23595 lines   23594 rows
raw/survey.csv             26495 lines   26494 rows
raw/targets_2025.csv           7 lines       6 rows
```

Every file has exactly one line more than it has records, which is the header. **When the two
numbers differ by more than one, a field contains a line break**, typically a free-text comment
or an address someone typed with Enter, and any tool that splits on lines rather than parsing CSV
will cut that record in half.

What to write down from this section, before looking at a single value:

| file | encoding | separator |
|---|---|---|
| `store_sales.csv` | Latin-1 | `;` |
| everything else | UTF-8 | `,` |

The decimal mark is not on the list because it is not a property of the file. It is a property of
each value, and lesson 7 finds a column that uses both.
