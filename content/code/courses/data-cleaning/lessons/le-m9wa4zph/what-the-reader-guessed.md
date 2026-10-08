---
title: What the reader guessed
version: 1
---

**Every reader of a CSV file converts as it reads, and every conversion is a guess.** pandas looks
at a column, decides it holds numbers, dates or text, and hands you the result as though the file
had said so. Most of the time the guess is right. A profile is where you find the times it was
not, so a profile has to look at the file before the guess.

Reading the customer file with no options at all:

```
ana@lab:~/clean$ python -c "import pandas as pd; c = pd.read_csv('raw/customers.csv'); print(c.dtypes); print(c['birth_year'].head(3))"
customer_id             str
name                    str
email                   str
cep                     str
city                    str
state                   str
signed_up               str
birth_year          float64
signup_channel          str
marketing_opt_in        str
dtype: object
0    1986.0
1    1982.0
2    1953.0
Name: birth_year, dtype: float64
```

Nine columns came back as text, `str`. One came back as `float64`, a floating-point number:
`birth_year`. A year is a whole number, so why a float? Because 338 rows have no birth year, and a
plain NumPy integer column cannot hold a missing value, so pandas chose the one numeric type that
can. **Every year is now printed with `.0` after it**, and the 106 two-digit years from the app
are now the numbers 87.0, 92.0 and so on, indistinguishable from a real value except by being
impossible.

The order lines show a worse guess:

```
ana@lab:~/clean$ python -c "import pandas as pd; i = pd.read_csv('raw/order_items.csv'); print(i['product_code'].head(4))"
0    438
1    739
2    689
3    833
Name: product_code, dtype: int64
ana@lab:~/clean$ python -c "import pandas as pd; i = pd.read_csv('raw/order_items.csv', dtype=str); print(i['product_code'].head(4))"
0      438
1      739
2      689
3    00833
Name: product_code, dtype: str
```

The product codes are five-digit strings in the catalogue, `00833`, and the website writes them
that way. **Read without options, `00833` becomes the number 833** and the leading zeros are gone
for good; nothing in the result says they were ever there. Read as text, the column shows the
real situation: some rows say `00833` and others `438`, because the app writes its codes without
zeros. That is a finding — two systems, two formats — and the default reading erased it before
anybody saw it.

## Read everything as text first

The rule this course follows from here on is **read as text, look, then convert on purpose**:

- `dtype=str` keeps every value exactly as it is in the file;
- `keep_default_na=False, na_values=[""]` makes only a truly empty field missing. By default
  pandas also turns `NA`, `null`, `None`, `n/a` and other strings into missing values, which in a
  column of country codes erases Namibia, whose code is `NA`;
- conversion happens later, one column at a time, with a check that counts what failed to
  convert. Lesson 10 is about that step.

In SQL the same rule is why lesson 1 loaded the schema `raw` with every column as `text`. A
`COPY` into a typed table is the database version of a guess, except that it usually fails loudly
instead of quietly — which is the better of the two ways to be wrong.
