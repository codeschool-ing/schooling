---
title: Patterns: the shape of every value
version: 1
---

**A pattern profile replaces every digit with `9` and every letter with `a`, and counts what is
left.** `01310-100` becomes `99999-999`, `2025-03-14` becomes `9999-99-99`, `Pix` becomes `aaa`.
Thousands of distinct values collapse into a handful of shapes, and a column that should have one
shape and has four says so in four lines. It is the single most productive technique in this
lesson, and it takes one function:

```schooling-example
{
  "language": "python",
  "file": "patterns.py",
  "parts": [
    {
      "code": "import sys\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def pattern(values):\n    return (values.str.replace(r\"[0-9]\", \"9\", regex=True)\n                  .str.replace(r\"[^\\W\\d_]\", \"a\", regex=True))\n\n\n",
      "note": "**Every digit becomes `9` and every letter becomes `a`**, accented letters included: `[^\\W\\d_]` is a letter in any alphabet. Punctuation and spaces stay as they are, because they are what tells formats apart."
    },
    {
      "code": "path, column = sys.argv[1], sys.argv[2]\ndf = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[\"\"])\n",
      "note": "The same reading as `profile.py`: text, and only a blank as missing."
    },
    {
      "code": "if len(sys.argv) > 3:\n    print(pd.crosstab(pattern(df[column]), df[sys.argv[3]]))\n",
      "note": "With a third argument, a table of pattern against another column, which is how a format is traced to the system that wrote it."
    },
    {
      "code": "else:\n    print(pattern(df[column]).value_counts(dropna=False).to_string())\n",
      "note": "Without it, each pattern and how many values have it."
    }
  ]
}
```

The postal code, the sign-up date and the birth year:

```
ana@lab:~/clean$ python patterns.py raw/customers.csv cep
cep
99999-999    1322
99999999      803
9999999       288
ana@lab:~/clean$ python patterns.py raw/customers.csv signed_up
signed_up
99/99/9999    1369
9999-99-99    1044
ana@lab:~/clean$ python patterns.py raw/customers.csv birth_year
birth_year
9999    1969
NaN      338
99       106
```

**`cep` has three shapes.** The post office writes a CEP as five digits, a hyphen and three digits.
803 values dropped the hyphen and 288 have only seven digits, which no CEP has: a digit is
missing, and it can only be a leading zero, because CEPs in the São Paulo region start with `0`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l02-cep-profile\" aria-label=\"A profile card for the cep column of customers.csv: 2413 filled, none empty, 2360 distinct, 7 to 9 characters long. Beside it, the three patterns: 1322 values written as the post office writes them, 803 without the hyphen, and 288 without the hyphen and with a leading zero lost.\"><rect x=\"20.0\" y=\"30.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">cep, profiled</text><text x=\"36.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">filled</text><text x=\"204.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2413</text><text x=\"36.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">empty</text><text x=\"204.0\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"36.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">distinct</text><text x=\"204.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2360</text><text x=\"36.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">length</text><text x=\"204.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7–9</text><text x=\"250.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pattern</text><text x=\"250.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">99999-999</text><rect x=\"345.0\" y=\"70.0\" width=\"200.0\" height=\"20.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"551.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1322</text><text x=\"345.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as the post office writes it</text><text x=\"250.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">99999999</text><rect x=\"345.0\" y=\"114.0\" width=\"121.5\" height=\"20.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"472.5\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">803</text><text x=\"345.0\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hyphen dropped</text><text x=\"250.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">9999999</text><rect x=\"345.0\" y=\"158.0\" width=\"43.6\" height=\"20.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"394.6\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">288</text><text x=\"345.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hyphen dropped and a leading zero lost</text></svg>", "caption": "The profile says the lengths disagree; the patterns say how. Only the first bar is a postal code a lookup table would match as it stands."}
```

**`signed_up` has two shapes, and that is the trap.** `9999-99-99` is the ISO format and can only
mean one thing. `99/99/9999` covers both `14/03/2025` and `03/14/2025`, so the pattern profile
reports two formats where lesson 1 found three. A pattern sees shape and not meaning; for the
meaning, split the shapes by where the values came from:

```
ana@lab:~/clean$ python patterns.py raw/customers.csv signed_up signup_channel
signup_channel  app  import-2023  site  store
signed_up                                    
99/99/9999      730           21     0    618
9999-99-99        0           24  1020      0
ana@lab:~/clean$ python patterns.py raw/customers.csv cep signup_channel
signup_channel  app  import-2023  site  store
cep                                          
99999-999         0           28  1020    274
9999999         285            3     0      0
99999999        445           14     0    344
```

Now the sources show. The website writes ISO dates and CEPs with the hyphen. The shops write
`99/99/9999` — day first, as lesson 1 found — and CEPs with and without the hyphen, as the person
at the counter typed them. **The app writes `99/99/9999` too, month first, and produced 285 of the 288
seven-digit CEPs**: it stores the CEP as a number, so `01310100` became `1310100`. The 2023
migration contributes a few of everything, because it was a copy of all three systems' records at
the time.

**`birth_year` has `9999`, `99` and empty**, with nothing else hiding: the two-digit years lesson 1
found and the 338 blanks. The 1900s do not show here at all, because `1900` has exactly the shape of
a good year. **A pattern profile finds invalid values, never inaccurate ones**, which is lesson 1's
distinction measured.

## What patterns are for

Each shape is a rule waiting to be written. `99999-999` is the valid CEP, so the cleaning rule
for the column is: remove the hyphen, pad to eight digits on the left with zeros, put the hyphen
back. Lesson 7 writes it. Without the profile, the obvious rule — remove the hyphen — would have
left 288 seven-digit codes that match nothing in any address table, and a join to one would lose
them without a word.
