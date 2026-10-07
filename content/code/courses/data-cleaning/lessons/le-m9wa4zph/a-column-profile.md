---
title: A profile, column by column
version: 1
---

**A profile is a small, fixed set of measurements taken of every column.** The same set for every
column, so that the columns can be compared, and small enough to read in one screen, so that it
actually gets read. Ten rows of `head()` show you ten rows; a profile shows you all of them at
once, reduced to the numbers that give defects away.

Ana's profile takes eight measurements per column:

```schooling-example
{
  "language": "python",
  "file": "profile.py",
  "parts": [
    {
      "code": "import sys\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def profile(df):\n    rows = []\n    for column in df.columns:\n        values = df[column]\n        present = values.dropna()\n",
      "note": "One row of the result per column of the table. `present` is the column without its empty cells, so every measure after the first two describes only what is there."
    },
    {
      "code": "        rows.append({\n            \"column\": column,\n            \"filled\": present.size,\n            \"empty\": values.isna().sum(),\n",
      "note": "**Filled and empty** are completeness, counted rather than guessed."
    },
    {
      "code": "            \"distinct\": present.nunique(),\n",
      "note": "**Distinct** against filled is the uniqueness question: a key column where they differ has repeats."
    },
    {
      "code": "            \"shortest\": present.str.len().min(),\n            \"longest\": present.str.len().max(),\n",
      "note": "**Shortest and longest**, in characters. Every value is text here, so `.str.len()` works on every column, which is one reason to read everything as text first."
    },
    {
      "code": "            \"most_common\": present.value_counts().index[0],\n            \"times\": present.value_counts().iloc[0],\n        })\n",
      "note": "**The most common value, and how often.** A placeholder lives here: a value that is common because a form needed something, not because the world is like that."
    },
    {
      "code": "    return pd.DataFrame(rows)\n\n\n"
    },
    {
      "code": "path = sys.argv[1]\ndf = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[\"\"])\nprint(f\"{path}: {len(df)} rows\")\nprint(profile(df).to_string(index=False))\n",
      "note": "**Everything as text, and only a truly empty field as missing.** By default pandas turns `NA`, `null`, `n/a` and a dozen other strings into missing values on the way in; `keep_default_na=False` stops it, so the profile shows what the file says rather than what pandas decided."
    }
  ]
}
```

Run against the customer file:

```
ana@lab:~/clean$ python profile.py raw/customers.csv
raw/customers.csv: 2413 rows
          column  filled  empty  distinct  shortest  longest                       most_common  times
     customer_id    2413      0      2376         6        6                            C00107      2
            name    2413      0      2198         7       36                     Alice Pereira      5
           email    2131    282      2070        21       50 caio.barbosa.araujo70@example.org      2
             cep    2413      0      2360         7        9                         13015-441      2
            city    2413      0        28         2       15                         São Paulo    458
           state    2413      0        13         2       14                                SP   1053
       signed_up    2413      0      1417        10       10                        04/04/2025      8
      birth_year    2075    338       105         2        4                              1900    348
  signup_channel    2413      0         4         3       11                              site   1020
marketing_opt_in    2352     61        10         1        5                              true    579
```

Read it row by row and most of lesson 1 reappears, this time without anybody having to suspect it
first:

- **`customer_id`** has 2,413 values and 2,376 distinct ones. A key with 37 repeats, and the most
  common id appears twice: these are the exact duplicate rows lesson 5 removes.
- **`email`** is empty 282 times, the completeness gap from lesson 1. Its most common value appears
  twice, and an e-mail address shared by two accounts is either the same person twice or a
  family; lesson 5 decides which.
- **`cep`** runs from 7 to 9 characters. A Brazilian postal code has eight digits, written
  `99999-999` with the hyphen, so nine is right, eight is the hyphen dropped, and **seven is
  impossible** unless a digit was lost. The patterns two sections on say which.
- **`city`** has 28 distinct values and **`state`** has 13, for five cities in four states.
- **`signed_up`** is always 10 characters, which sounds tidy and hides three formats in two shapes.
- **`birth_year`** is 2 to 4 characters long and most often `1900`.
- **`marketing_opt_in`**, a yes-or-no question, has **10 distinct answers**.

That last line is the kind of finding a profile exists for. Nobody would think to look for ten
ways of saying yes and no, and nobody needs to: the number is on the screen. Lesson 10 counts
them.

## What a profile does not do

It does not judge. A `distinct` of 28 is a fact; whether it is wrong needs you to know that the
company serves five cities. **The profile tells you where to look and the domain tells you what
you are looking at.** That division of labour is the reason to profile every column rather than
the ones you already suspect: the suspicion comes after the number, not before.

It also does not show relationships between columns — that a two-digit year always comes from the
app, or that an empty courier always goes with a pickup. Those need a second step, splitting one
column by another, which the next sections and lesson 3 take.
