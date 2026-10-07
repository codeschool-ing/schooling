---
title: Finding the variants
version: 1
---

**A category column is a promise that a few labels repeat across many rows**, and that promise is
broken by every hand that typed a label slightly differently. The catalogue is the clearest case in
Quitanda Verde's files: seventy-two rows, one category each, kept by the buyers in a spreadsheet.

Listing the values sorted by their lower-case form puts the variants next to each other:

```
ana@lab:~/clean$ psql -c 'SELECT category, count(*) FROM raw.products GROUP BY category ORDER BY lower(category), count(*) DESC'
     category      | count 
-------------------+-------
 Cesta             |     2
 Cestas            |     2
 Empório           |     3
 Folhas            |     1
 Fruta             |     2
 Frutas            |     9
 frutas            |     3
 FRUTAS            |     1
 Frutas            |     1
 Graos e cereais   |     3
 Grãos             |     5
 Laticínios        |     1
 Legume            |     1
 Legumes           |     9
 legumes           |     5
 Mercearia         |     6
 ovos e laticinios |     1
 Ovos e laticínios |     5
 Verduras          |    10
 VERDURAS          |     2
(20 rows)
```

Twenty labels. Some groups are obviously one category written several ways — `Frutas`, `frutas`,
`FRUTAS`, and a `Frutas` that sorts separately because of a trailing space. Others are less obvious:
`Fruta` in the singular, `Grãos` beside `Graos e cereais`, `Folhas` beside `Verduras`, `Empório`
beside `Mercearia`.

**The first step is the one lesson 6 built**: a plain key that removes case, spaces and accents.

```schooling-example
{
  "language": "python",
  "file": "keyed.py",
  "parts": [
    {
      "code": "import unicodedata\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def plain(text):\n    text = unicodedata.normalize(\"NFKD\", text)\n    text = \"\".join(ch for ch in text if not unicodedata.combining(ch))\n    return \" \".join(text.lower().split())\n\n\n",
      "note": "**Lesson 6's plain form**: accents, capitals and extra spaces removed."
    },
    {
      "code": "products = pd.read_csv(\"raw/products.csv\", dtype=str)\nproducts[\"category_key\"] = products[\"category\"].map(plain)\n",
      "note": "The catalogue, with a plain key beside the label as the buyers typed it."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from keyed import products as p; print(p['category'].nunique(), p['category_key'].nunique()); print(sorted(p['category_key'].unique()))"
20 14
['cesta', 'cestas', 'emporio', 'folhas', 'fruta', 'frutas', 'graos', 'graos e cereais', 'laticinios', 'legume', 'legumes', 'mercearia', 'ovos e laticinios', 'verduras']
```

Twenty labels become fourteen keys. Every difference of capitals, spacing and accent is gone, and
what remains is a list a person can read in ten seconds — and must, because the remaining
differences are not typography. `fruta` and `frutas` differ by a plural, `graos` and
`graos e cereais` by a word, `folhas` and `verduras` by everything. No rule folds those safely.
**From here on the work is deciding, not cleaning.**

Two habits make variants easier to see in any column: sort by the plain key rather than the raw
value, so neighbours are candidates; and print the count beside each, because a label used once is
far more likely a variant than one used nine times.
