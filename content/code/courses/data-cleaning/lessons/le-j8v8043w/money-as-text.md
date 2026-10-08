---
title: Money written as text
version: 1
---

**The shops' till writes money for people: `R$ 1.234,56`, with a currency sign, a point between the
thousands and a comma before the cents.** Every part of that is a convention, and the conversion has
to undo each one deliberately.

The tempting shortcut fails, loudly at least:

```
ana@lab:~/clean$ python -c "print(float('1.234,56'.replace(',', '.')))" 2>&1 | tail -1
ValueError: could not convert string to float: '1.234.56'
```

Swapping the comma for a point leaves `1.234.56`, which is not a number. Removing the thousands
point first and then swapping the comma is the right order, and the function that does it refuses
anything it does not understand:

```schooling-example
{
  "language": "python",
  "file": "money.py",
  "parts": [
    {
      "code": "from decimal import Decimal\n\n\n",
      "note": "`Decimal` holds decimal amounts exactly, where a float cannot."
    },
    {
      "code": "def reais(text):\n    \"\"\"'R$ 1.234,56' -> Decimal('1234.56'). Refuses anything else.\"\"\"\n"
    },
    {
      "code": "    digits = text.removeprefix(\"R$\").strip().replace(\".\", \"\").replace(\",\", \".\")\n",
      "note": "**The order matters**: drop the currency sign, drop the thousands point, then turn the decimal comma into a point."
    },
    {
      "code": "    value = Decimal(digits)\n",
      "note": "`Decimal` refuses any text that is not a number, instead of guessing."
    },
    {
      "code": "    if value != value.quantize(Decimal(\"0.01\")):\n        raise ValueError(f\"more than two decimals: {text!r}\")\n    return value\n",
      "note": "And a value with more than two decimal places is refused too: no amount of reais has fractions of a centavo."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from money import reais; print(reais('R$ 94,50'), reais('R$ 1.234,56'), int(reais('R$ 1.234,56') * 100))"
94.50 1234.56 123456
```

`R$ 94,50` and `R$ 1.234,56` both convert, and the second becomes 123456 cents. Lesson 2's pattern
profile found that no sale in 2025 reached a thousand reais, so the thousands point never appears in
this year's file — **and the function handles it anyway**, because next year's first large sale
will not ask first.

## Why `Decimal` and not `float`

```
ana@lab:~/clean$ python -c "print(0.1 + 0.2, sum([0.1] * 10))"
0.30000000000000004 1.0
```

`0.1 + 0.2` is not `0.3` in binary floating point, and ten dimes do not make exactly one. The errors
are tiny and they accumulate: added over a year of sales they reach whole centavos, and a total that
is wrong by a centavo is a total an accountant will not sign. **Money is converted to `Decimal` or
straight to integer cents**, and never passes through a float on the way.

The whole column, in cents:

```
ana@lab:~/clean$ python -c "import pandas as pd; from money import reais; s = pd.read_csv('raw/store_sales.csv', sep=';', encoding='latin-1', dtype=str); c = s['total'].map(reais).map(lambda v: int(v * 100)); print(len(c), c.sum(), c.min(), c.max())"
23594 154892570 390 19050
```

23,594 sales, R$ 1,548,925.70 in all, from R$ 3.90 to R$ 190.50. In SQL the same steps are string
functions and a cast to `numeric`, which is exact:

```
ana@lab:~/clean$ psql -c "SELECT total, replace(replace(substr(total, 4), '.', ''), ',', '.')::numeric(12, 2) AS reais FROM raw.store_sales LIMIT 3"
  total   | reais 
----------+-------
 R$ 94,50 | 94.50
 R$ 44,00 | 44.00
 R$ 10,60 | 10.60
(3 rows)
```
