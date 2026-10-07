---
title: Blocking: not comparing everything with everything
version: 1
---

**Comparing every record with every other grows with the square of the file.** 2,376 customers
make 2,821,500 pairs, and a million customers would make about five hundred billion. Scoring every
pair is wasteful at this size and impossible at the next.

**Blocking** compares only records that already share something cheap to check: a postcode, a
birth year, the first letters of a surname. Ana blocks on the last word of the plain name, the
surname:

```schooling-example
{
  "language": "python",
  "file": "match.py",
  "parts": [
    {
      "code": "import itertools\n\nimport pandas as pd\nfrom rapidfuzz import fuzz\n\nfrom keys import customers\n\n"
    },
    {
      "code": "customers[\"block\"] = customers[\"name_key\"].str.split().str[-1]\n",
      "note": "**The block is the surname**: the last word of the plain name."
    },
    {
      "code": "pairs = []\nfor _, group in customers.groupby(\"block\"):\n    for a, b in itertools.combinations(group.to_dict(\"records\"), 2):\n        pairs.append({\n",
      "note": "Every pair inside each block, and only inside it."
    },
    {
      "code": "            \"a\": a[\"customer_id\"], \"b\": b[\"customer_id\"],\n"
    },
    {
      "code": "            \"name\": fuzz.token_sort_ratio(a[\"name_key\"], b[\"name_key\"]),\n",
      "note": "How alike the two names are, words sorted first."
    },
    {
      "code": "            \"email\": pd.notna(a[\"email_key\"]) and a[\"email_key\"] == b[\"email_key\"],\n",
      "note": "Whether they share an e-mail address. Two blanks are not a match: `pd.notna` makes sure an address exists."
    },
    {
      "code": "            \"cep\": a[\"cep_key\"] == b[\"cep_key\"],\n",
      "note": "Whether they share a CEP, already in plain form."
    },
    {
      "code": "        })\npairs = pd.DataFrame(pairs)\n\n"
    },
    {
      "code": "if __name__ == \"__main__\":\n    n = len(customers)\n    print(f\"{n} customers: {n * (n - 1) // 2} possible pairs, {len(pairs)} compared\")\n",
      "note": "How many pairs were possible, and how many were compared."
    }
  ]
}
```

```
ana@lab:~/clean$ python match.py
2376 customers: 2821500 possible pairs, 46299 compared
```

46,299 comparisons instead of 2,821,500: under 2% of the work.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l05-blocking\" aria-label=\"Two squares drawn to scale by area. The large one is every possible pair of the 2376 customers, 2,821,500. The small one in its corner is the 46,299 pairs that share a surname, the only ones compared: 1.6% of the work.\"><rect x=\"60.0\" y=\"40.0\" width=\"260.0\" height=\"260.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60.0\" y=\"266.7\" width=\"33.3\" height=\"33.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">every pair: 2,821,500</text><text x=\"390.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">compared each with each</text><text x=\"390.0\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">same surname: 46,299</text><text x=\"390.0\" y=\"265.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">75 blocks, one per surname</text></svg>", "caption": "Blocking compares only records that already share something. The price is every real pair that does not share it."}
```

**The price is every real pair that does not share the block.** A person whose surname was mistyped
in one of their two records lands in a different block, and is never compared with themselves. The
score in the next section counts six real duplicates lost exactly that way: `Babrosa` for
`Barbosa`, `Ferreria` for `Ferreira`, and four more.

Two habits reduce that price:

- **block on something that is rarely wrong.** A surname is typed by a person; a postcode is often
  chosen from a list. The best key is the field the sources agree on most;
- **block more than once, on different keys, and combine the candidates.** A pair missed by the
  surname block will usually share a postcode or an e-mail address, and running a second pass on
  those catches it. Each pass is cheap; it is the comparison of everything that is not.
