---
title: What missing looks like
version: 1
---

**A missing value is whatever a system writes when it has nothing to write, and systems disagree
about what that is.** An empty field is the honest version. The others are values that stand in
for absence — a zero, a placeholder year, a dash, the word `null` — and they are harder to find
precisely because they look like data.

Start with the honest ones. Every empty field in every file, read as lesson 2 taught, with only a
true blank counted as missing:

```schooling-example
{
  "language": "python",
  "file": "blanks.py",
  "parts": [
    {
      "code": "import glob\n\nimport pandas as pd\n\n"
    },
    {
      "code": "for path in sorted(glob.glob(\"raw/*.csv\")):\n",
      "note": "Every file in `raw/`, in a fixed order so the output can be compared between runs."
    },
    {
      "code": "    latin = \"store_sales\" in path\n    df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[\"\"],\n                     encoding=\"latin-1\" if latin else \"utf-8\", sep=\";\" if latin else \",\")\n",
      "note": "The shops' file is read as lesson 2 found it was written. Everything is text, and only a truly empty field is missing."
    },
    {
      "code": "    empty = df.isna().sum()\n",
      "note": "`isna().sum()` counts the blanks of every column at once."
    },
    {
      "code": "    for column, n in empty[empty > 0].items():\n        print(f\"{path:22} {column:18} {n:6} of {len(df)}\")\n",
      "note": "Only the columns with at least one blank are printed, each beside the size of its file."
    }
  ]
}
```

```
ana@lab:~/clean$ python blanks.py
raw/customers.csv      email                 282 of 2413
raw/customers.csv      birth_year            338 of 2413
raw/customers.csv      marketing_opt_in       61 of 2413
raw/orders.csv         discount            13883 of 28551
raw/orders.csv         courier              5717 of 28551
raw/orders.csv         delivery_minutes    13679 of 28551
raw/store_sales.csv    cliente             15406 of 23594
raw/survey.csv         answered_on         16838 of 26494
raw/survey.csv         nps                 16838 of 26494
```

Nine columns in four files have blanks. That list is where this lesson begins, and it is
deliberately not where it ends, because **a count of blanks says nothing about why they are
there**: 13,679 empty delivery times and 16,838 empty survey scores are both "missing" and have
nothing else in common.

## One fact, two spellings

Some columns record the same fact as a blank in one system and as a value in another. The app's
discount:

```
ana@lab:~/clean$ psql -c "SELECT discount, count(*) FROM raw.orders WHERE channel = 'app' GROUP BY discount ORDER BY count(*) DESC"
 discount | count 
----------+-------
 0        | 11233
 5.00     |   411
 10.00    |   392
 15.00    |   382
 20.00    |   378
(5 rows)
```

No blanks at all, and 11,233 zeros. Lesson 2 showed that the website writes the same fact, no
coupon, as an empty field. **Here a blank means zero**, and a rule that counted blanks would call
the app complete and the website 88% empty, for a difference that exists only in how two programs
were written.

The shops' marketing consent mixes both kinds in one column:

```
ana@lab:~/clean$ psql -c "SELECT marketing_opt_in, count(*) FROM raw.customers WHERE signup_channel = 'store' GROUP BY marketing_opt_in ORDER BY count(*) DESC"
 marketing_opt_in | count 
------------------+-------
 sim              |   115
 S                |   108
 Sim              |   107
 não              |    88
 nao              |    79
 N                |    61
                  |    60
(7 rows)
```

Six spellings of yes and no, and 60 blanks. The blank here is a customer at a counter who was never
asked, or who did not answer, and the file cannot say which. That distinction is the subject of
the rest of this lesson.

The cases this course has met so far, by what they look like in the file:

| looks like | example here | means |
|---|---|---|
| an empty field | `delivery_minutes` on a pickup | no value could exist |
| an empty field | `nps` on the survey | the customer did not answer |
| an empty field | `discount` on the website | zero: no coupon |
| a placeholder year | `birth_year` of 1900 | nobody asked, or nobody knew |
| a value nobody typed | lesson 2's `NA` in a default pandas read | whatever the reader decided |

**Before any of these can be treated, each one has to be recognised as missing**, which means the
first step of handling missing values is reading them out of their disguises. Lesson 4 turns the
1900s into honest blanks, and the website's blank discounts into the zeros they mean, before
deciding anything else.
