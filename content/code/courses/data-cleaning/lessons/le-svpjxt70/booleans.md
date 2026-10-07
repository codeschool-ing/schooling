---
title: A yes written ten ways
version: 1
---

Marketing consent is the column with the most spellings in the file. Each system wrote its own:

```
ana@lab:~/clean$ python -c "from raw_customers import customers as c; print(c['marketing_opt_in'].value_counts(dropna=False).to_string())"
marketing_opt_in
true     568
false    459
1        391
0        344
sim      116
S        107
Sim      106
não       89
nao       76
N         63
NaN       57
```

Ten spellings and a blank. **Converting it with `astype(bool)` would be a disaster that runs
without an error**: in Python every non-empty string is true, so `"false"`, `"0"` and `"não"` would
all become consent, and 1,031 people who said no would start receiving offers. The blank is no
better, because `NaN` is truthy too. Counted on this file:

```
ana@lab:~/clean$ python -c "from raw_customers import customers as c; print(len(c), c['marketing_opt_in'].astype(bool).sum())"
2376 2376
```

Every one of the 2,376 customers would have consented.

The safe conversion names both sides and refuses everything else:

```schooling-example
{
  "language": "python",
  "file": "consent.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom raw_customers import customers\n\n"
    },
    {
      "code": "YES = {\"true\", \"1\", \"s\", \"sim\"}\nNO = {\"false\", \"0\", \"n\", \"não\", \"nao\"}\n",
      "note": "**Both sides written out**, in lower case."
    },
    {
      "code": "key = customers[\"marketing_opt_in\"].str.strip().str.lower()\n",
      "note": "Spaces and case removed before anything is compared."
    },
    {
      "code": "unknown = key.notna() & ~key.isin(YES | NO)\nif unknown.any():\n    raise ValueError(f\"unmapped consent values: {sorted(key[unknown].unique())}\")\n",
      "note": "A value that is present and in neither list stops the script, naming the spelling."
    },
    {
      "code": "customers[\"opt_in\"] = key.map(lambda v: True if v in YES else False if v in NO else pd.NA)\n",
      "note": "Each spelling to `True` or `False`; the blank stays `pd.NA`."
    },
    {
      "code": "customers[\"opt_in\"] = customers[\"opt_in\"].astype(\"boolean\")\n",
      "note": "The nullable boolean, which holds `<NA>` beside the two answers."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from consent import customers as c; print(c['opt_in'].value_counts(dropna=False).to_string()); print(c['opt_in'].dtype)"
opt_in
True     1288
False    1031
<NA>       57
boolean
```

Three things in it are deliberate.

- **Both lists are written out.** Mapping the yeses and calling everything else no would turn the
  next new spelling, perhaps `yes` from a form in English, into a refusal nobody chose.
- **An unknown spelling stops the script.** It names the values, so adding one to the right list is
  a one-line change somebody reviews, rather than a silent default.
- **The blank stays blank.** The 57 people with no recorded answer are neither a yes nor a no,
  and the `boolean` type, pandas' nullable boolean, holds `<NA>` beside `True` and `False`. For
  consent this matters legally as well as statistically: under the LGPD, no answer is not
  permission.

Case and spaces are removed before the comparison, so `Sim`, `sim` and ` SIM ` are one value.
Accents are not, on purpose: `não` and `nao` are both in the list, and a reader of the code sees
that both were seen.
