---
title: Unmask first: make every absence a blank
version: 1
---

**Every strategy in this lesson works on blanks, so the first step is to make every absence a
blank and every blank that is not an absence a value.** Lesson 3 found both kinds: the 1900s, which
are missing values wearing a year, and the website's empty discounts, which are zeros wearing a
blank. Leave either in place and every choice after it is made on the wrong numbers.

SQL has a function for each direction:

```
ana@lab:~/clean$ psql -c "SELECT count(*) FILTER (WHERE birth_year = '1900') AS was_1900, count(*) FILTER (WHERE NULLIF(birth_year, '1900') IS NULL) AS now_blank FROM raw.customers"
 was_1900 | now_blank 
----------+-----------
      348 |       686
(1 row)
```

`NULLIF(birth_year, '1900')` returns NULL when the value is `1900` and the value otherwise. The
348 placeholders join the 338 real blanks, and the column now has 686 missing years — **the honest
count, twice what the file showed**. Nothing has been lost; something has stopped pretending.

`COALESCE(discount, '0')` goes the other way. It returns the first argument that is not NULL, so a
blank becomes `0`:

```
ana@lab:~/clean$ psql -c "SELECT channel, count(*) FILTER (WHERE discount IS NULL) AS blank, count(*) FILTER (WHERE COALESCE(discount, '0') = '0') AS no_coupon FROM raw.orders GROUP BY channel"
 channel | blank | no_coupon 
---------+-------+-----------
 site    | 13883 |     13883
 app     |     0 |     11233
(2 rows)
```

On the website, the 13,883 blanks become 13,883 orders without a coupon, the same thing the app's
11,233 zeros say. This is safe for one reason only: lesson 2 established that the blank means zero.
**`COALESCE` with a constant is a statement about meaning**, and written without that evidence it
is a guess dressed as a fix.

In pandas the same two moves look like this, as the file every later section of this lesson
imports:

```schooling-example
{
  "language": "python",
  "file": "customers.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "customers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n",
      "note": "The customer file as text, and without the exact duplicate rows lesson 2 found: a repeated customer would count twice in every average."
    },
    {
      "code": "unusable = customers[\"birth_year\"].eq(\"1900\") | customers[\"birth_year\"].str.len().eq(2)\n",
      "note": "**The rows whose year cannot be used**: the placeholder and the two-digit years."
    },
    {
      "code": "customers[\"birth_year\"] = pd.to_numeric(customers[\"birth_year\"].mask(unusable))\n",
      "note": "`mask` blanks those rows and leaves the rest; only then is the column converted to numbers, so no placeholder ever becomes the number 1900."
    }
  ]
}
```

The two-digit years from the app are set aside here too. They are not placeholders — `87` almost
certainly meant 1987 — but deciding that is a conversion with its own risks, and lesson 10 makes it
properly. Until then they count as unknown rather than as a guess.
