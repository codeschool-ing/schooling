---
title: Deciding a match, and counting the mistakes
version: 1
---

**Every matching rule makes two kinds of mistake**: it merges records that are different people,
and it misses records that are the same person. Tightening a rule trades the first for the second.
In real work you estimate both by checking a sample of pairs by hand. Here the lab's truth file
lists the 58 people who really signed up twice, so every rule gets an exact score:

```schooling-example
{
  "language": "python",
  "file": "score.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom match import pairs\n\n"
    },
    {
      "code": "truth = pd.read_csv(\"/var/lib/clean-data/truth/duplicates.csv\")\nreal = {frozenset(p) for p in zip(truth[\"customer_id\"], truth[\"same_as\"])}\n",
      "note": "**The lab's answer**: the 58 pairs it planted, each as an unordered pair so `a, b` and `b, a` are the same."
    },
    {
      "code": "pairs[\"real\"] = [frozenset(p) in real for p in zip(pairs[\"a\"], pairs[\"b\"])]\n",
      "note": "Each compared pair, marked real or not."
    },
    {
      "code": "rules = [\n    (\"name 100\", pairs[\"name\"] == 100),\n    (\"name >= 85\", pairs[\"name\"] >= 85),\n    (\"name >= 85 and email or cep\", (pairs[\"name\"] >= 85) & (pairs[\"email\"] | pairs[\"cep\"])),\n    (\"email or cep, any name\", pairs[\"email\"] | pairs[\"cep\"]),\n]\n\n",
      "note": "Four rules, from the strictest name rule to an identifier alone."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(f\"real duplicates: {len(real)}, of which in a compared block: {pairs['real'].sum()}\")\n    for rule, chosen in rules:\n        found = pairs[chosen]\n        print(f\"{rule:30} matched {len(found):4}  right {found['real'].sum():3}  \"\n              f\"wrong {(~found['real']).sum():4}\")\n",
      "note": "For each rule, how many pairs it matched, and how many of those are real."
    }
  ]
}
```

```
ana@lab:~/clean$ python score.py
real duplicates: 58, of which in a compared block: 52
name 100                       matched  300  right  41  wrong  259
name >= 85                     matched  539  right  48  wrong  491
name >= 85 and email or cep    matched   49  right  48  wrong    1
email or cep, any name         matched   53  right  52  wrong    1
```

Read the rows from the top:

- **Identical names** finds 41 real duplicates and merges 259 pairs of different people. Six times
  more wrong than right.
- **Names at least 85 alike** finds 48 and merges 491 wrongly. Loosening the threshold found seven
  more duplicates and added 232 more strangers.
- **A similar name plus one shared identifier**, the same e-mail or the same postcode: 48 right and
  1 wrong. The name narrows the field and the identifier confirms.
- **The identifier alone**, whatever the name: 52 right and 1 wrong. Within a surname block, a
  shared e-mail or postcode is evidence enough, and it catches the duplicates whose names drifted
  furthest.

One of the 259 wrong merges, to see what a homonym looks like:

```
ana@lab:~/clean$ python -c "from score import pairs; from keys import customers as c; w = pairs[(pairs['name'] == 100) & ~pairs['real']].iloc[0]; print(c[c['customer_id'].isin([w['a'], w['b']])][['customer_id', 'name', 'city', 'cep', 'signed_up']].to_string(index=False))"
customer_id           name         city       cep  signed_up
     C00007 Daniel Almeida   SÃ£o Paulo 08399-108 2023-02-24
     C01610 Daniel Almeida B. Horizonte 30010-991 2025-06-06
```

Same name, different city, different postcode, two and a half years apart. Nobody reading the two
rows would call them one person, and a rule on names alone did.

**The one wrong match that survives every rule** is a pair with the same name and the same e-mail
address whom the truth file lists as two people. Nothing in the data could separate them; a couple
sharing an address would look exactly like this. Every matching system has a residue like that, and
the honest response is to keep it small, measure it, and make merges reversible — which is the
next section.
