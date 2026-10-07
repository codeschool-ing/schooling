---
title: Whitespace: the defect nobody can see
version: 1
---

**A space at the end of a value is invisible on every screen and different to every comparison.**
`'São Paulo'` and `'São Paulo '` print the same, sort next to each other and group apart. It is the
cheapest defect in the course to fix and the most common one to miss, because nobody looks for
what they cannot see.

Counting is the only way to find it:

```schooling-example
{
  "language": "python",
  "file": "cities.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "customers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n",
      "note": "The customer file as text, without its exact duplicates, so that each customer counts once."
    },
    {
      "code": "city = customers[\"city\"]\n",
      "note": "The column this lesson works on, imported by every later command."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from cities import city; print(city.nunique(), (city != city.str.strip()).sum(), city.str.strip().nunique())"
28 60 25
```

28 distinct cities; 60 values differ from themselves with their ends trimmed; 25 distinct once they
are. **Three of the 28 spellings existed only because of a trailing space.** Lesson 1 met one of
them, the row of 25 customers in São Paulo with eleven bytes.

Printing the values with Python's `ascii()`, which writes every invisible or non-ASCII character as
an escape, shows what each São Paulo really is:

```
ana@lab:~/clean$ python -c "from cities import city; print(sorted({ascii(v) for v in city if 'Paulo' in v and 'Ã' not in v}))"
["'S. Paulo'", "'S\\xe3o Paulo '", "'S\\xe3o Paulo'", "'Sa\\u0303o Paulo '", "'Sa\\u0303o Paulo'", "'Sao Paulo'"]
```

`'S\xe3o Paulo '` has its space in plain view at last. The `̃` in two of them is the next
section's subject.

## Trim, then collapse

Whitespace goes wrong in three places, and a standard step fixes all three:

- **at the ends**, from a form field that kept what the cursor left: `strip()`, `trim()` in SQL;
- **in the middle**, as two spaces where one was meant, which lesson 5 found in names like
  `Mariana  Souza`: replace every run of whitespace with a single space;
- **as characters that are not the ordinary space**: a tab, a line break, or the non-breaking
  space that text copied from a web page brings with it. A regular expression's `\s` matches all of
  them, which is why the collapse uses it rather than a literal space.

In pandas: `.str.strip().str.replace(r"\s+", " ", regex=True)`. **This step is safe on any text
column** — no city, name or address is supposed to begin or end with a space — and it belongs at the
start of every cleaning of text, before anything compares values.
