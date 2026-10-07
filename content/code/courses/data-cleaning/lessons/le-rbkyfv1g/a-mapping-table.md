---
title: A mapping table, kept as a file
version: 1
---

**The decision about what each label means belongs in a table, not in code.** A chain of
`if category in ('fruta', 'fruits')` lines works, and buries each decision inside a program where
nobody who knows the products will ever read it. A table is a list the buyers can review:

```
category_key,category,department
frutas,Frutas,Hortifruti
fruta,Frutas,Hortifruti
fruits,Frutas,Hortifruti
verduras,Verduras,Hortifruti
folhas,Verduras,Hortifruti
legumes,Legumes,Hortifruti
legume,Legumes,Hortifruti
ovos e laticinios,Ovos e laticínios,Frios
laticinios,Ovos e laticínios,Frios
graos e cereais,Grãos e cereais,Mercearia
graos,Grãos e cereais,Mercearia
mercearia,Mercearia,Mercearia
emporio,Mercearia,Mercearia
cestas,Cestas,Cestas
cesta,Cestas,Cestas
```

Every key the cleaned column can contain has one line, with the category it means and the
department above it. The cleaning code then does exactly one thing with it — join — and checks two
things on the way:

```schooling-example
{
  "language": "python",
  "file": "categorise.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom keyed import products\n\n"
    },
    {
      "code": "mapping = pd.read_csv(\"category_map.csv\", dtype=str)\n",
      "note": "The mapping table, read as text."
    },
    {
      "code": "if mapping[\"category_key\"].duplicated().any():\n    raise SystemExit(\"category_map.csv lists a spelling twice\")\n",
      "note": "**A spelling listed twice is refused**: two lines for one key would duplicate every product that uses it."
    },
    {
      "code": "products = products.merge(mapping, on=\"category_key\", how=\"left\",\n                          suffixes=(\"_raw\", \"\"), validate=\"many_to_one\")\n",
      "note": "A **left** join, so a product with an unknown label stays in the table to be counted; `validate` refuses a map that is not one line per key."
    },
    {
      "code": "unmapped = products[products[\"category\"].isna()]\nif len(unmapped):\n    raise SystemExit(f\"{len(unmapped)} products have a category the map does not know: \"\n                     f\"{sorted(unmapped['category_raw'].unique())}\")\n",
      "note": "**Unknown labels stop the run**, with their count and their names."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from categorise import products as p; print(p.groupby(['department', 'category']).size().to_string())"
department  category         
Cestas      Cestas                4
Frios       Ovos e laticínios     7
Hortifruti  Frutas               16
            Legumes              15
            Verduras             13
Mercearia   Grãos e cereais       8
            Mercearia             9
```

Seven categories in four departments, with every product placed. Because the lab knows each
product's real category, the mapping can be scored too:

```
ana@lab:~/clean$ python -c "import pandas as pd; from categorise import products as p; t = pd.read_csv('~/clean-data/truth/categories.csv', dtype=str); m = p.merge(t, on='product_code', suffixes=('', '_true')); print(len(m), (m['category'] == m['category_true']).sum())"
72 72
```

**72 of 72 products land in the category they really belong to.** Real work has no truth file, and
there the check is a person from the buying team reading the seven groups and the products in each.
The table makes that review possible; a chain of `if`s would not.

The table has three properties worth keeping in any mapping:

- **one row per input value**, which `validate="many_to_one"` enforces from the data side and the
  duplicate check enforces from the table side. A spelling listed twice with two meanings would
  silently duplicate products;
- **the canonical output written in full**, `Ovos e laticínios` with its accent and capital,
  because the table is also where the display form comes from;
- **every value the data contains**, and no more. The map has `fruits`, which this year's file does
  not use: a spelling the buyers know they have used, kept so next year's file does not stop on it.
