---
title: Currencies: converting at the right rate
version: 1
---

**An amount without its currency is not an amount.** Quitanda Verde pays five suppliers: three in
reais, an American seed company in dollars and a Spanish olive oil producer in euros. Adding the
`amount` column across all invoices adds reais to dollars to euros, and produces a number that means
nothing at all.

Converting needs three decisions, written down:

- **which rate**: the company books one rate per month for its own accounts, in `fx_rates_2025.csv`.
  These are Quitanda Verde's booked rates, invented for the course; real work would use the central
  bank's published rates or whatever the finance team booked, and the choice between them is
  finance's, not the analyst's;
- **which date**: the invoice's date of issue decides the month. A payment date would give a
  different rate, and either can be right, but one has to be chosen and stated;
- **which way round**: a rate of 5.3961 BRL per USD multiplies a dollar amount. Dividing by it is the
  commonest error in currency conversion, and it produces amounts roughly thirty times too small.

```
ana@lab:~/clean$ cat raw/fx_rates_2025.csv | head -4
month,usd_brl,eur_brl
2025-01,5.3961,5.8250
2025-02,5.4271,5.7725
2025-03,5.3595,5.8363
```

The invoices, with their three date formats parsed per supplier and each amount converted at its
month's rate:

```schooling-example
{
  "language": "python",
  "file": "invoices.py",
  "parts": [
    {
      "code": "import pandas as pd\n\ninvoices = pd.read_csv(\"raw/invoices.csv\", dtype=str)\nrates = pd.read_csv(\"raw/fx_rates_2025.csv\", dtype=str)\n"
    },
    {
      "code": "FORMATS = {\"Sítio Boa Terra\": \"%d/%m/%Y\", \"Cooperativa Vale Verde\": \"%d/%m/%Y\",\n           \"Fazenda Santa Clara\": \"%Y-%m-%d\", \"Green Valley Seeds Inc.\": \"%m/%d/%Y\",\n           \"Oliveira Hermanos SL\": \"%d.%m.%Y\"}\n",
      "note": "Each supplier's date convention, from its invoices."
    },
    {
      "code": "invoices[\"issued\"] = [pd.to_datetime(d, format=FORMATS[s])\n                      for d, s in zip(invoices[\"issued\"], invoices[\"supplier\"])]\n",
      "note": "Every issue date parsed with its supplier's format."
    },
    {
      "code": "invoices[\"month\"] = invoices[\"issued\"].dt.strftime(\"%Y-%m\")\n",
      "note": "The month of issue decides the rate."
    },
    {
      "code": "invoices = invoices.merge(rates, on=\"month\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**`validate=\"many_to_one\"`** makes pandas refuse the merge if a month appears twice in the rates, which would duplicate invoices silently."
    },
    {
      "code": "invoices[\"rate\"] = 1.0\nfor currency, column in {\"USD\": \"usd_brl\", \"EUR\": \"eur_brl\"}.items():\n    is_it = invoices[\"currency\"] == currency\n    invoices.loc[is_it, \"rate\"] = pd.to_numeric(invoices.loc[is_it, column])\n",
      "note": "A real is worth one real; dollars and euros take their month's booked rate."
    },
    {
      "code": "invoices[\"amount_brl\"] = (pd.to_numeric(invoices[\"amount\"]) * invoices[\"rate\"]).round(2)\n",
      "note": "**Multiply**, never divide: the rate is reais per unit of the foreign currency."
    },
    {
      "code": "KG = {\"kg\": 1, \"t\": 1000, \"lb\": 0.45359237}\ninvoices[\"kg\"] = (pd.to_numeric(invoices[\"weight\"])\n                  * invoices[\"weight_unit\"].map(KG)).round(1)\n",
      "note": "Weights to kilos: tonnes by a thousand, pounds by the pound's exact definition."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from invoices import invoices as i; print(i[['invoice', 'currency', 'amount', 'amount_brl', 'weight', 'weight_unit', 'kg']].head(4).to_string(index=False)); print(i.groupby('currency')['amount_brl'].sum().round(2).to_string())"
invoice currency   amount  amount_brl weight weight_unit     kg
NF-0001      USD   669.73     3535.64   1012          lb  459.0
NF-0002      BRL  3109.76     3109.76    351          kg  351.0
NF-0003      BRL 11448.93    11448.93  2.397           t 2397.0
NF-0004      EUR  1445.59     8792.80    750          kg  750.0
currency
BRL    251360.85
EUR     74232.88
USD    181820.70
```

The first invoice, US$ 669.73 in June, becomes R$ 3,535.64. **The original amount and currency stay
in the table beside the converted one**: a conversion is a calculation with a choice inside it, and
anybody checking it needs the inputs. Spending by currency, in reais: R$ 251,360.85 to Brazilian
suppliers, R$ 181,820.70 to the American and R$ 74,232.88 to the Spanish one.

`validate="many_to_one"` in the merge is a check worth its line: it raises an error if a month
appears twice in the rates file, which would otherwise duplicate every invoice of that month without
a word. Lesson 11 is about exactly that kind of join.
