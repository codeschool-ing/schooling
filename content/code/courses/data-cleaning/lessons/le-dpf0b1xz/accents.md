---
title: Accents: removed for the key, kept for the name
version: 1
---

**People type the same name with and without its accents**, especially on keyboards that make
accents slow. `Sao Paulo` is the second most common spelling of São Paulo in this file. For a key,
the accents should go.

Removing them uses the decomposition from the previous section: decompose to NFKD, so every accent
becomes a separate combining character, then drop the combining characters:

```schooling-example
{
  "language": "python",
  "file": "cascade.py",
  "parts": [
    {
      "code": "import unicodedata\n\nfrom cities import city\n\n\n"
    },
    {
      "code": "def fix_mojibake(text):\n    if \"Ã\" in text:\n        return text.encode(\"latin-1\").decode(\"utf-8\")\n    return text\n\n\n",
      "note": "**Repair mojibake**, only where its signature `Ã` appears; the section on mojibake explains why the test matters."
    },
    {
      "code": "def without_accents(text):\n    text = unicodedata.normalize(\"NFKD\", text)\n    return \"\".join(ch for ch in text if not unicodedata.combining(ch))\n\n\n",
      "note": "**Remove accents**: decompose, then drop every combining character."
    },
    {
      "code": "steps = [\n    (\"as exported\", lambda s: s),\n",
      "note": "The steps in order, each a function from a column to a column."
    },
    {
      "code": "    (\"spaces trimmed\", lambda s: s.str.strip().str.replace(r\"\\s+\", \" \", regex=True)),\n",
      "note": "Trim the ends and collapse every run of whitespace to one space."
    },
    {
      "code": "    (\"Unicode to NFC\", lambda s: s.str.normalize(\"NFC\")),\n",
      "note": "Every letter in its composed form."
    },
    {
      "code": "    (\"mojibake repaired\", lambda s: s.map(fix_mojibake)),\n"
    },
    {
      "code": "    (\"lower case\", lambda s: s.str.lower()),\n"
    },
    {
      "code": "    (\"accents removed\", lambda s: s.map(without_accents)),\n"
    },
    {
      "code": "]\n"
    },
    {
      "code": "values = city\nfor label, step in steps:\n    values = step(values)\n    if __name__ == \"__main__\":\n        print(f\"{label:18} {values.nunique():3} distinct\")\nif __name__ == \"__main__\":\n    print(sorted(values.unique()))\n",
      "note": "Apply the steps one after another, and print how many distinct values are left after each."
    }
  ]
}
```

`without_accents` is that function. In PostgreSQL the `unaccent` extension does the same, with a
table of replacements; the last section of this lesson uses it.

## What removing accents costs

Accents are not decoration in Portuguese. `país` is a country and `pais` is parents; `avó` is a
grandmother and `avô` a grandfather; `Simões` and `Simoes` are the same surname spelt by two
generations of the same family. **A key without accents merges all of these**, and for a city or a
surname in a matching key that is what you want: the cost of merging two spellings of one name is
lower than the cost of splitting one person in two.

For the stored value it is the wrong trade. A customer whose name is `João` should not receive a
letter to `Joao`. This is the same rule as case, and the reason it keeps coming back: **the key is
for the machine, the name is for the person**, and the cleaning keeps both.
