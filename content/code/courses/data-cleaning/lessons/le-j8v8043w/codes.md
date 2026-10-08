---
title: Codes: text that looks like a number
version: 1
---

**A code is an identifier written with digits, and digits invite a reader to treat it as a number.**
A CEP, a product code, a tax number, a bank branch: none of them is ever added, averaged or
compared by size, and all of them can begin with zero. Read as numbers, they lose their leading
zeros; lesson 2 watched `00833` become `833`.

The repair is to pad back to the code's fixed width, which the previous section's code did with
`.str.zfill(5)`. Whether it worked is a question the catalogue can answer:

```
ana@lab:~/clean$ python -c "import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); print(l['product_code'].isin(p['product_code']).mean().round(3), l['code'].isin(p['product_code']).mean().round(4)); print(sorted(set(l['code']) - set(p['product_code'])))"
0.546 0.9883
['00123', '00584']
```

As they arrived, only 54.6% of the order lines' product codes exist in the catalogue: every app line
fails, for want of its zeros. Padded, 98.83% exist. **The remaining 1.2% are two codes that are not
in the catalogue at all**, `00123` and `00584`: products sold in 2025 and dropped from the catalogue
before the export. That is lesson 11's orphan problem, and the padding is what made it visible —
without it, 45% of lines would have looked orphaned and the real two would have been lost among
them.

The rules for any code column:

- **read it as text**, always — lesson 2's rule, here for its most important reason;
- **pad to the fixed width** when the width is known: eight digits for a CEP, five for a product
  code here;
- **write it in its canonical form for display**, `01310-100` with the hyphen, but **join on the
  bare digits**, so that two formats of one code never fail to meet;
- **validate against the list it comes from**, and count what fails. A code nobody can look up is a
  finding, not noise.
