---
title: The same person, twice
version: 1
---

**The duplicates that cost the most are the ones with different keys**: one person with two
accounts. Nothing repeats exactly. The name is spelt differently, the e-mail moved domains, the
postcode lost its hyphen. A customer count is inflated by one, the person's purchases are split
across two histories, and a "new customer" campaign targets somebody who has bought for two years.

The first step is to bring every field that could identify a person to one plain form, so that
differences that do not matter stop hiding the ones that do:

```schooling-example
{
  "language": "python",
  "file": "keys.py",
  "parts": [
    {
      "code": "import unicodedata\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def plain(text):\n",
      "note": "**One plain form for any text.**"
    },
    {
      "code": "    text = unicodedata.normalize(\"NFKD\", text)\n",
      "note": "`NFKD` splits every accented letter into the letter and its accent, so `ú` becomes `u` followed by a combining acute accent. Lesson 6 explains the forms."
    },
    {
      "code": "    text = \"\".join(ch for ch in text if not unicodedata.combining(ch))\n",
      "note": "The accents, now separate characters, are dropped."
    },
    {
      "code": "    return \" \".join(text.lower().split())\n\n\n",
      "note": "Lower case, and every run of spaces collapsed to one, with none at either end."
    },
    {
      "code": "customers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n",
      "note": "The customer file without its exact duplicate rows."
    },
    {
      "code": "customers[\"name_key\"] = customers[\"name\"].map(plain)\n",
      "note": "The name in plain form."
    },
    {
      "code": "customers[\"email_key\"] = customers[\"email\"].str.strip().str.lower()\n",
      "note": "The e-mail address trimmed and lower-cased. Accents are not removed here: an address is compared exactly or not at all."
    },
    {
      "code": "customers[\"cep_key\"] = customers[\"cep\"].str.replace(\"-\", \"\").str.zfill(8)\n",
      "note": "The CEP as eight digits, with the hyphen gone and lost leading zeros restored, as lesson 2's patterns asked."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from keys import plain; print(repr(plain('  MARIANA  Souza')), repr(plain('Mariana Souza')), repr(plain('Júlia Simões')))"
'mariana souza' 'mariana souza' 'julia simoes'
```

Case, extra spaces and accents all collapse. Lesson 6 takes text standardisation further; this is
the minimum for matching.

With plain keys, the obvious test is whether two records share one:

```
ana@lab:~/clean$ python -c "from keys import customers as c; print(c['name_key'].duplicated().sum(), c['email_key'].dropna().duplicated().sum())"
262 35
```

262 records share a plain name with an earlier one, and 35 share an e-mail address. **The first
number is not 262 duplicates.** The most common name shows why:

```
ana@lab:~/clean$ python -c "from keys import customers as c; d = c[c['name_key'] == c['name_key'].value_counts().index[0]]; print(d[['customer_id', 'name', 'city', 'email']].apply(lambda col: col.str.normalize('NFC')).to_string(index=False))"
customer_id          name      city                       email
     C01000 Alice Pereira  Curitiba                         NaN
     C01380 Alice Pereira São Paulo alice.pereira33@example.net
     C01392 Alice Pereira São Paulo alice.pereira31@example.org
     C01760 Alice Pereira São Paulo alice.pereira89@example.com
     C01778 Alice Pereira São Paulo alice.pereira61@example.net
```

Five customers called Alice Pereira, four in São Paulo and one in Curitiba, with four different
e-mail addresses. Names are not unique, least of all in a country where a few surnames cover a
large share of the population. **A match on name alone merges different people**, and every one of
those merges joins two strangers' purchase histories.

The e-mail address is stronger but incomplete: shop customers often have none, and a person who
signs up again sometimes uses another address. Matching needs both, and a way of saying how alike
two names are when they are not identical.
