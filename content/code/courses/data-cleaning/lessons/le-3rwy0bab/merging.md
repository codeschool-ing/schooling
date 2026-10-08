---
title: Merging: who survives, and what follows them
version: 1
---

**A match is a decision about identity; a merge is a decision about data.** Once two records are
the same person, three questions remain: which id survives, which value of each field it keeps,
and what happens to everything that pointed at the other id.

Ana's rules are short:

- **the earliest id survives.** Ids here are given in signup order, so the smaller one is the first
  account, and its history is the longer one;
- **values are not merged yet.** Choosing the newer e-mail, the longer name or the more complete
  address is **survivorship**, and each choice is a rule to write down, by field. For now the
  survivor keeps its own values;
- **nothing is deleted.** The decision is written to a file mapping each merged id to the one that
  survives, and applied wherever the ids appear.

```schooling-example
{
  "language": "python",
  "file": "merge.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom keys import customers\nfrom match import pairs\n\n"
    },
    {
      "code": "same = pairs[(pairs[\"name\"] >= 85) & (pairs[\"email\"] | pairs[\"cep\"])]\n",
      "note": "The rule chosen in the previous section: a similar name and one shared identifier."
    },
    {
      "code": "keep = {}\nfor a, b in zip(same[\"a\"], same[\"b\"]):\n    keep[max(a, b)] = min(a, b)\n",
      "note": "**The earliest id survives.** Ids are in signup order, so the smaller is the first account."
    },
    {
      "code": "survivor = pd.Series(keep, name=\"kept_id\").rename_axis(\"customer_id\").reset_index()\nsurvivor.to_csv(\"survivors.csv\", index=False)\n",
      "note": "**The decision, as a file**: one line per merged id and the id it now means."
    },
    {
      "code": "print(f\"{len(survivor)} records point at an earlier one; first lines of survivors.csv:\")\nprint(survivor.head(3).to_string(index=False))\n\n"
    },
    {
      "code": "orders = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates()\n",
      "note": "The orders, read as text and without their repeats."
    },
    {
      "code": "moved = orders[\"customer_id\"].isin(survivor[\"customer_id\"])\nprint(f\"orders that change owner: {moved.sum()}\")\n",
      "note": "How many orders belonged to an id that is merged away."
    },
    {
      "code": "before = orders[\"customer_id\"].nunique()\norders[\"customer_id\"] = orders[\"customer_id\"].replace(dict(zip(survivor[\"customer_id\"],\n                                                                survivor[\"kept_id\"])))\nprint(f\"customers with orders: {before} before, {orders['customer_id'].nunique()} after\")\n",
      "note": "The mapping applied: every merged id replaced by its survivor, and the number of distinct customers before and after."
    }
  ]
}
```

```
ana@lab:~/clean$ python merge.py
49 records point at an earlier one; first lines of survivors.csv:
customer_id kept_id
     C02450  C00519
     C02414  C00409
     C02436  C00388
orders that change owner: 2
customers with orders: 2273 before, 2272 after
```

49 records now point at an earlier one: the 48 real duplicates and the one pair the data cannot
separate. Only 2 orders change owner. Most second accounts were opened and never used, which is
itself typical — somebody signs up again because they forgot the first account, then finds it.

**`survivors.csv` is the most important output of this lesson.** It is small, it is readable, and it
is the whole decision in one file: anybody can check a line, reverse a wrong merge by deleting it,
or apply the same mapping to next month's orders. A merge done by overwriting ids in place would
have the same effect today and leave no way to answer, next year, why two customers became one.

## In SQL

The same mapping, loaded as a table, is applied with a join and `COALESCE`: each order takes the
survivor's id when there is one and keeps its own otherwise. Lesson 11 builds the joins this needs,
and lesson 17 puts the mapping file beside the rest of the cleaning so it runs every time.
