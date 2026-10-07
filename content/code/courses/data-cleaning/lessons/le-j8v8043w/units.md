---
title: Units: kilos, grams, tonnes and pounds
version: 1
---

**A quantity without its unit is the same problem as an amount without its currency**, with one
extra trap: units are often written in several spellings of the same thing. The order lines use
eight:

```
ana@lab:~/clean$ psql -c 'SELECT unit, count(*) FROM raw.order_items GROUP BY unit ORDER BY count(*) DESC'
 unit | count 
------+-------
 un   | 39872
 kg   | 34321
 KG   |  5093
 g    |  4759
 gr   |  4712
 UN   |  4580
 Kg   |  3548
 unid |  2276
(8 rows)
```

`kg`, `KG` and `Kg` are one unit; `g` and `gr` another; `un`, `UN` and `unid` a third. Three units in
eight spellings, and two of them — kilos and grams — measure the same thing at a factor of a thousand.
The quantities have their own convention problem:

```
ana@lab:~/clean$ psql -c "SELECT count(*) FILTER (WHERE quantity LIKE '%,%') AS comma, count(*) FILTER (WHERE quantity LIKE '%.%') AS point FROM raw.order_items"
 comma | point 
-------+-------
  2916 | 11490
(1 row)
```

2,916 quantities use a decimal comma, `1,5`, and 11,490 a decimal point. Both come from the website,
whose form accepted whatever the customer's keyboard produced.

The cleaning does three things in order — **map the spellings to a unit, read the decimal comma,
convert grams to kilos** — and then computes each line's value in cents:

```schooling-example
{
  "language": "python",
  "file": "lines.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nlines = pd.read_csv(\"raw/order_items.csv\", dtype=str)\n"
    },
    {
      "code": "UNIT = {\"kg\": \"kg\", \"KG\": \"kg\", \"Kg\": \"kg\", \"g\": \"g\", \"gr\": \"g\", \"un\": \"un\", \"UN\": \"un\",\n        \"unid\": \"un\"}\nlines[\"unit\"] = lines[\"unit\"].map(UNIT)\n",
      "note": "**Eight spellings, three units.** Grams stay grams for one more step."
    },
    {
      "code": "lines[\"quantity\"] = pd.to_numeric(lines[\"quantity\"].str.replace(\",\", \".\"))\n",
      "note": "A decimal comma becomes a point before the conversion to a number."
    },
    {
      "code": "grams = lines[\"unit\"] == \"g\"\nlines.loc[grams, \"quantity\"] = lines.loc[grams, \"quantity\"] / 1000\nlines.loc[grams, \"unit\"] = \"kg\"\n",
      "note": "**Grams to kilos**, so every weight is in the unit the price is per."
    },
    {
      "code": "lines[\"code\"] = lines[\"product_code\"].str.zfill(5)\n",
      "note": "The product code padded back to its five digits."
    },
    {
      "code": "lines[\"line_cents\"] = (lines[\"quantity\"] * pd.to_numeric(lines[\"unit_price\"]) * 100).round().astype(int)\n",
      "note": "Each line's value in cents: quantity times unit price, rounded to the centavo as the systems did."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from lines import lines as l; print(l['unit'].value_counts(dropna=False).to_string()); print(l[['product_code', 'code', 'quantity', 'unit', 'unit_price', 'line_cents']].head(4).to_string(index=False))"
unit
kg    52433
un    46728
product_code  code  quantity unit unit_price  line_cents
         438 00438       3.0   un      18.90        5670
         739 00739       2.0   un       5.90        1180
         689 00689       1.0   un      34.90        3490
       00833 00833       3.0   un       8.90        2670
```

Two units remain, `kg` and `un`. The supplier invoices needed the same treatment for weight, in the
previous section's code: tonnes multiplied by 1,000 and pounds by 0.45359237, the exact definition
of the pound.

## The check that proves it

A conversion can be checked against something it did not use. Every order's total should equal the
sum of its lines, less the discount, plus the delivery fee. That uses every conversion in this
lesson at once — units, decimal commas, grams, money in cents:

```
ana@lab:~/clean$ python -c "import pandas as pd; from lines import lines as l; o = pd.read_csv('raw/orders.csv', dtype=str).drop_duplicates(); o['cents'] = (pd.to_numeric(o['total']) * 100).round().astype(int); o['fee'] = (pd.to_numeric(o['delivery_fee']) * 100).round().astype(int); o['disc'] = (pd.to_numeric(o['discount'].fillna('0')) * 100).round().astype(int); s = l.groupby('order_id')['line_cents'].sum(); o['expected'] = o['order_id'].map(s) - o['disc'] + o['fee']; print((o['cents'] == o['expected']).sum(), (o['cents'] != o['expected']).sum())"
28519 7
```

**28,519 orders agree to the centavo, and 7 do not.** If any of the conversions were wrong, thousands
would disagree; seven is not a conversion problem. They are the totals typed by hand with a zero too
many, and lesson 9 finds them by exactly this check.
