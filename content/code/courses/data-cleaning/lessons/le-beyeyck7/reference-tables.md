---
title: Joining a reference table
version: 1
---

The two IBGE files are small and plain:

```
ana@lab:~/clean$ head -4 ref/ibge_states.csv; wc -l ref/ibge_states.csv
code,uf,name,region
11,RO,Rondônia,Norte
12,AC,Acre,Norte
13,AM,Amazonas,Norte
28 ref/ibge_states.csv
ana@lab:~/clean$ cat ref/ibge_cities.csv
code,name,uf
3550308,São Paulo,SP
3509502,Campinas,SP
3304557,Rio de Janeiro,RJ
3106200,Belo Horizonte,MG
4106902,Curitiba,PR
```

27 rows of states, each with its numeric code, its two letters, its name and its region; five
cities with their seven-digit municipal codes. The first two digits of a city's code are its
state's: São Paulo city is 3550308 and São Paulo state is 35. That is the kind of structure an
official code carries and a name never does.

The customer file's `state` column is what the reference has to meet:

```
ana@lab:~/clean$ python -c "from cities import customers; print(customers['state'].value_counts(dropna=False).to_string())"
state
SP                1036
RJ                 422
MG                 305
PR                 282
sp                  98
São Paulo           54
S.P.                46
rj                  40
Rio de Janeiro      25
mg                  22
pr                  21
Paraná              15
Minas Gerais        10
```

Thirteen spellings: the two letters in both cases, the letters with dots, and the full names. **The
reference table defines what the right answers are**, so the matching only has to cover the ways
of writing them, not invent the targets:

```schooling-example
{
  "language": "python",
  "file": "places.py",
  "parts": [
    {
      "code": "import unicodedata\n\nimport pandas as pd\n\n"
    },
    {
      "code": "from cascade import values  # lesson 6: each city trimmed, repaired, lower case, unaccented\nfrom cities import customers\n\n\n",
      "note": "Lesson 6's work on the city column, and the customers it came from."
    },
    {
      "code": "def plain(text):\n    text = unicodedata.normalize(\"NFKD\", text)\n    return \"\".join(ch for ch in text if not unicodedata.combining(ch)).lower().strip()\n\n\n",
      "note": "Lower case with the accents removed, for comparing names."
    },
    {
      "code": "states = pd.read_csv(\"ref/ibge_states.csv\", dtype=str)\ncities = pd.read_csv(\"ref/ibge_cities.csv\", dtype=str)\nspellings = pd.read_csv(\"abbreviations.csv\", dtype=str)\n\n",
      "note": "**The three references**: IBGE's states and cities, and lesson 6's list of city spellings."
    },
    {
      "code": "# A state is written as its two letters, with or without dots, or as its name.\nby_name = dict(zip(states[\"name\"].map(plain), states[\"uf\"]))\n",
      "note": "State names in comparable form, each pointing at its two letters."
    },
    {
      "code": "letters = customers[\"state\"].str.replace(\".\", \"\", regex=False).str.strip().str.upper()\ncustomers[\"uf\"] = letters.where(letters.isin(states[\"uf\"]), customers[\"state\"].map(plain).map(by_name))\n",
      "note": "**Two letters where the letters are valid**, otherwise the name looked up; dots and case removed first."
    },
    {
      "code": "customers[\"city_name\"] = values.map(dict(zip(spellings[\"spelling\"], spellings[\"city\"])))\n\n",
      "note": "Each city's spelling to its name as IBGE writes it."
    },
    {
      "code": "for found, written in [(\"uf\", \"state\"), (\"city_name\", \"city\")]:\n    lost = customers[found].isna() & customers[written].notna()\n    if lost.any():\n        raise ValueError(f\"{written}: {sorted(customers.loc[lost, written].unique())} match no reference\")\n\n",
      "note": "**Every written value must have matched**, or the script names the ones that did not."
    },
    {
      "code": "customers = customers.merge(cities.rename(columns={\"code\": \"city_code\", \"name\": \"city_name\",\n                                                   \"uf\": \"city_uf\"}),\n                            on=\"city_name\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**The city's code and its own state**, joined many to one so the reference cannot multiply customers."
    },
    {
      "code": "customers = customers.merge(states[[\"uf\", \"region\"]], on=\"uf\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**The region**, from the state."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from places import customers as c; print(c[['customer_id', 'state', 'uf', 'city', 'city_name', 'city_code', 'region']].head(4).to_string(index=False))"
customer_id state uf           city      city_name city_code  region
     C00001    sp SP      Sao Paulo      São Paulo   3550308 Sudeste
     C00002    RJ RJ Rio de Janeiro Rio de Janeiro   3304557 Sudeste
     C00004    MG MG Belo Horizonte Belo Horizonte   3106200 Sudeste
     C00005    PR PR       Curitiba       Curitiba   4106902     Sul
ana@lab:~/clean$ python -c "from places import customers as c; print(c['region'].value_counts(dropna=False).to_string()); print((c['uf'] != c['city_uf']).sum())"
region
Sudeste    2058
Sul         318
0
```

Every customer now has a two-letter `uf`, a city name as IBGE writes it, the city's code and the
region. Three checks went with it, two in the code, where they would stop the script, and one in
the command after it:

- **Every written state and city must match.** A spelling that matches nothing is named in the
  error. Enrichment that quietly leaves a blank is the same failure as a conversion that does.
- **Both joins are `many_to_one`**, so a reference table with a repeated key cannot multiply the
  customers.
- **The state and the city must agree.** The city's own `uf`, from IBGE, is kept as `city_uf`, and
  the last number above, 0, counts the customers whose written state disagrees with their city's.
  Two columns that should say the same thing, checked against an outside authority, is
  lesson 9's consistency check with a better referee.

All 2,376 customers land in two regions, 2,058 in the Sudeste and 318 in the Sul, which matches
where the five cities are.
