---
title: Coerce, then count what was lost
version: 1
---

The obvious conversion fails at once:

```
ana@lab:~/clean$ python -c "from raw_customers import customers as c; c['birth_year'].astype(int)" 2>&1 | tail -1
ValueError: cannot convert float NaN to integer
```

**That failure is the honest one.** The column has blanks, a plain integer has no way to hold a
blank, and pandas refuses rather than inventing a number. The usual next step is the one the
documentation suggests: `pd.to_numeric` with `errors="coerce"`, which turns anything it cannot
read into `NaN` and carries on.

```
ana@lab:~/clean$ python -c "import pandas as pd; from raw_customers import customers as c; n = pd.to_numeric(c['birth_year'], errors='coerce'); print(c['birth_year'].isna().sum(), n.isna().sum()); print(n.head(3).to_string())"
332 332
0    1986.0
1    1982.0
2    1953.0
```

Here it did no harm. The column had 332 blanks before and 332 after, so every value that was
written down became a number. **The two counts are the whole check**, and they are only cheap
because the comparison was made. Watch the same call on four prices written the way this
company's files write them:

```
ana@lab:~/clean$ python -c "import pandas as pd; s = pd.Series(['12.90', '1.234,56', 'R$ 5,00', '7']); print(pd.to_numeric(s, errors='coerce').to_string())"
0    12.9
1     NaN
2     NaN
3     7.0
```

Two of four values are gone. `1.234,56` is a Brazilian thousand separator and decimal comma, and
`R$ 5,00` carries a currency sign; neither is a number to pandas, so both became `NaN`, and a
`NaN` looks exactly like a price nobody recorded. A sum over that column is wrong, an average is
wrong, and **nothing on the screen says so**. Lesson 7 showed how to read both; the danger is a column that
reaches this step without having been through that.

`errors="coerce"` is still the right tool. What it needs is the count beside it, every time,
written once so it cannot be forgotten:

```schooling-example
{
  "language": "python",
  "file": "convert.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n\n"
    },
    {
      "code": "def to_number(values, name):\n    \"\"\"Convert text to numbers and refuse to lose anything quietly.\"\"\"\n",
      "note": "A column of text, and its name for the error message."
    },
    {
      "code": "    numbers = pd.to_numeric(values, errors=\"coerce\")\n",
      "note": "Convert, turning whatever cannot be read into `NaN`."
    },
    {
      "code": "    lost = values.notna() & numbers.isna()\n",
      "note": "**Lost** means present before and blank after. A blank that was already blank is not counted."
    },
    {
      "code": "    if lost.any():\n        examples = sorted(values[lost].unique())[:5]\n        raise ValueError(f\"{name}: {lost.sum()} values are not numbers, e.g. {examples}\")\n",
      "note": "Any loss stops here, with how many and up to five of the values."
    },
    {
      "code": "    return numbers\n",
      "note": "Otherwise the numbers, with blanks only where there were blanks."
    }
  ]
}
```

The rule fits in one line: **a value that was there before and is blank after was lost**, and a
loss stops the conversion. It names how many and shows a few, because the first thing anyone does
with this error is look at the values:

```
ana@lab:~/clean$ python -c "import pandas as pd; from convert import to_number; to_number(pd.Series(['12.90', '1.234,56', None]), 'price')" 2>&1 | tail -1
ValueError: price: 1 values are not numbers, e.g. ['1.234,56']
ana@lab:~/clean$ python -c "import pandas as pd; from convert import to_number; print(to_number(pd.Series(['12.90', '7', None]), 'price').to_string())"
0    12.9
1     7.0
2     NaN
```

The second call passes because nothing was lost. The blank in the third position was blank before
the conversion too, so it stays blank and is not counted. That distinction is the point: missing
data is lesson 3's business and is kept, while a value destroyed by the conversion is this
lesson's, and is refused.
