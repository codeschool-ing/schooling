---
title: Years written with two digits
version: 1
---

The app stored a two-digit birth year for 105 customers, once the repeated rows are gone. `87` is
not a placeholder like `1900`; somebody born in 1987 wrote it down correctly, in a format
nobody should have allowed. Lesson 4 left these as unknown and promised a proper conversion. **A
two-digit year needs a century, and choosing one is a rule you write, not a fact you read.**

The rule here leans on one thing known about every customer: they are adults buying groceries.
Nobody in this file was born in 2087, and nobody born in 2087 is shopping. So a two-digit year
above `25` belongs to the 1900s, and `25` or below belongs to the 2000s:

```schooling-example
{
  "language": "python",
  "file": "years.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom raw_customers import customers\n\n",
      "note": "The customers as text, without the repeated rows."
    },
    {
      "code": "year = customers[\"birth_year\"].mask(customers[\"birth_year\"] == \"1900\")\n",
      "note": "**The placeholder** `1900` becomes a blank first, so it never reaches the century rule."
    },
    {
      "code": "two = year.str.len() == 2\n",
      "note": "Which values have two digits."
    },
    {
      "code": "# Customers are adults: a two-digit year above 25 is 19xx, at most 25 is 20xx.\nfull = year.mask(two & (year > \"25\"), \"19\" + year).mask(two & (year <= \"25\"), \"20\" + year)\n",
      "note": "**The century rule.** The comparison is between strings, which is safe here because both sides have exactly two digits."
    },
    {
      "code": "customers[\"birth\"] = pd.to_numeric(full).astype(\"Int64\")\n",
      "note": "Text to number, then to the nullable integer, so the blanks stay blanks."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from years import customers as c; t = c[c['birth_year'].str.len() == 2]; print(t[['birth_year', 'birth']].drop_duplicates().sort_values('birth').head(4).to_string(index=False)); print(c['birth'].min(), c['birth'].max(), c['birth'].isna().sum())"
birth_year  birth
        52   1952
        54   1954
        55   1955
        56   1956
1952 2006 670
```

The earliest two-digit customer was born in 1952, the latest in 2006, and the 670 blanks are the
332 nobody filled in plus the 338 shop placeholders, now openly unknown. **Every value either
became a plausible year or became a blank on purpose**, and the comment in the code says which
assumption decided the century, so the next reader can disagree with it.

The rule has an edge, and it is worth saying out loud. A customer born in 1925 who typed `25` is
now listed as born in 2025. Python's own `%y` draws the line elsewhere: `68` becomes 2068 and
`69` becomes 1969, so under it the customer born in 1952 would be born in 2052. A spreadsheet uses
yet another cut-off. **No cut-off is right for every file**; the one that fits is the one
that matches who the people in the file can be.

This lab has an answer key that real work never has, so the rule can be checked against it:

```
ana@lab:~/clean$ python -c "import pandas as pd; from years import customers as c; t = pd.read_csv('/var/lib/clean-data/truth/people.csv', dtype={'birth_year': 'Int64'}); m = c[c['birth_year'].str.len() == 2].merge(t[['customer_id', 'birth_year']], on='customer_id', suffixes=('', '_true')); print(len(m), (m['birth'] == m['birth_year_true']).sum())"
103 103
```

The truth file knows 103 of the two-digit customers, and the rule gives all 103 the right year.
Without a key, the check is the one in the last section of this lesson: a column of birth years
with a constraint that refuses anyone too old to be shopping or too young to have an account.
