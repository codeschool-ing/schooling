---
title: A join that reports on itself
version: 1
---

The catalogue's job in this join is to give each line a name and a category. **The price a line
was charged is already on the line**, so the catalogue's two prices do not have to be resolved
for this join at all, only kept out of it:

```schooling-example
{
  "language": "python",
  "file": "catalogue.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "products = pd.read_csv(\"raw/products.csv\", dtype=str)\n",
      "note": "The catalogue as text, 72 rows."
    },
    {
      "code": "# Three codes are listed twice, at two prices and with no date. What a line was\n# charged is on the line; the catalogue is used for names and categories only.\n",
      "note": "Why the prices are left behind, written where the next reader will look."
    },
    {
      "code": "names = products.groupby(\"product_code\")[\"name\"].nunique()\nif (names > 1).any():\n    raise ValueError(f\"codes with two names: {list(names[names > 1].index)}\")\n",
      "note": "**The check that makes keeping one row safe**: no code may carry two names."
    },
    {
      "code": "catalogue = (products.drop_duplicates(\"product_code\")\n             .rename(columns={\"product_code\": \"code\"})[[\"code\", \"name\", \"category\"]])\n",
      "note": "One row per code, renamed to match the lines, with only the columns this join needs."
    }
  ]
}
```

The check before `drop_duplicates` is the important line. Keeping the first row of each code is
only safe if the rows agree on what is being kept, and here they do, apart from the category's
spelling, which lesson 8's map handles. If a code ever arrived with two different names, the
script would stop and say which.

Then the join itself, written once so that every later join reports the same three numbers:

```schooling-example
{
  "language": "python",
  "file": "joins.py",
  "parts": [
    {
      "code": "def join(left, right, on, how=\"left\", validate=\"many_to_one\"):\n    \"\"\"Join, and say how many rows went in, came out and found nothing.\"\"\"\n",
      "note": "A left join by default, and **`many_to_one` by default**: the common case, checked unless you say otherwise."
    },
    {
      "code": "    out = left.merge(right, on=on, how=how, validate=validate, indicator=True)\n",
      "note": "`indicator=True` adds a column saying whether each row found a partner."
    },
    {
      "code": "    alone = (out[\"_merge\"] == \"left_only\").sum()\n",
      "note": "The rows that found none."
    },
    {
      "code": "    print(f\"join on {on}: {len(left)} rows in, {len(out)} out, {alone} with no match\")\n",
      "note": "**The three numbers**, printed every time."
    },
    {
      "code": "    return out.drop(columns=\"_merge\")\n",
      "note": "The indicator column goes, so the result looks like any other join."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from lines import lines; from catalogue import catalogue; from joins import join; j = join(lines, catalogue, 'code'); print(j[j['name'].isna()].groupby('code').agg(lines=('order_id', 'size'), price=('unit_price', 'first')).to_string())"
join on code: 99161 rows in, 99161 out, 1161 with no match
       lines  price
code               
00123    614   18.9
00584    547   26.9
```

**Rows in equals rows out**, which `validate` guarantees and the count shows. And 1,161 lines
found no product: the two codes lesson 7 found, `00123` and `00584`, missing from the catalogue
while sold all year. The lines still know what they were charged, so they stay, with a blank name
and category, and a question goes to whoever owns the catalogue.

Compare the join most people write first, an inner join with no checks:

```
ana@lab:~/clean$ python -c "from lines import lines as l; from catalogue import catalogue as c; i = l.merge(c, on='code'); print(len(l), len(i)); print(l['line_cents'].sum() / 100, i['line_cents'].sum() / 100)"
99161 98000
2516503.95 2476458.4
```

It ran without complaint and returned 98,000 rows. **R$ 40,045.55 of real sales left the
analysis**, and every figure built on it, revenue by category, by month, by customer, is low by
that amount, with nothing on the screen to say so. An inner join is the right tool when an
unmatched row truly does not belong; it is the wrong default, because it answers the question
"which rows have no partner?" by deleting them.
