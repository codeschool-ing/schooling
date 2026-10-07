---
title: Moedas: converter pelo câmbio certo
version: 1
---

**Um valor sem moeda não é um valor.** A Quitanda Verde paga cinco fornecedores: três em reais, uma
empresa americana de sementes em dólares e um produtor espanhol de azeite em euros. Somar a coluna
`amount` de todas as notas soma reais com dólares com euros, e produz um número que não quer dizer
nada.

Converter exige três decisões, por escrito:

- **qual câmbio**: a empresa lança um câmbio por mês na própria contabilidade, em
  `fx_rates_2025.csv`. São os câmbios lançados pela Quitanda Verde, inventados para o curso; no
  trabalho real se usariam as taxas publicadas pelo Banco Central ou o que o financeiro lançou, e a
  escolha entre elas é do financeiro, não da analista;
- **qual data**: a data de emissão da nota decide o mês. Uma data de pagamento daria outro câmbio, e
  qualquer uma das duas pode estar certa, mas uma precisa ser escolhida e dita;
- **em que sentido**: um câmbio de 5,3961 BRL por USD multiplica um valor em dólares. Dividir por ele
  é o erro mais comum de conversão de moeda, e produz valores umas trinta vezes menores.

```
ana@lab:~/clean$ cat raw/fx_rates_2025.csv | head -4
month,usd_brl,eur_brl
2025-01,5.3961,5.8250
2025-02,5.4271,5.7725
2025-03,5.3595,5.8363
```

As notas, com os seus três formatos de data lidos por fornecedor e cada valor convertido pelo câmbio
do seu mês:

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
      "note": "A convenção de data de cada fornecedor, a partir das suas notas."
    },
    {
      "code": "invoices[\"issued\"] = [pd.to_datetime(d, format=FORMATS[s])\n                      for d, s in zip(invoices[\"issued\"], invoices[\"supplier\"])]\n",
      "note": "Toda data de emissão lida com o formato do fornecedor."
    },
    {
      "code": "invoices[\"month\"] = invoices[\"issued\"].dt.strftime(\"%Y-%m\")\n",
      "note": "O mês de emissão decide o câmbio."
    },
    {
      "code": "invoices = invoices.merge(rates, on=\"month\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**`validate=\"many_to_one\"`** faz o pandas recusar a junção se um mês aparecer duas vezes nos câmbios, o que duplicaria notas em silêncio."
    },
    {
      "code": "invoices[\"rate\"] = 1.0\nfor currency, column in {\"USD\": \"usd_brl\", \"EUR\": \"eur_brl\"}.items():\n    is_it = invoices[\"currency\"] == currency\n    invoices.loc[is_it, \"rate\"] = pd.to_numeric(invoices.loc[is_it, column])\n",
      "note": "Um real vale um real; dólares e euros levam o câmbio lançado do seu mês."
    },
    {
      "code": "invoices[\"amount_brl\"] = (pd.to_numeric(invoices[\"amount\"]) * invoices[\"rate\"]).round(2)\n",
      "note": "**Multiplicar**, nunca dividir: o câmbio é reais por unidade da moeda estrangeira."
    },
    {
      "code": "KG = {\"kg\": 1, \"t\": 1000, \"lb\": 0.45359237}\ninvoices[\"kg\"] = (pd.to_numeric(invoices[\"weight\"])\n                  * invoices[\"weight_unit\"].map(KG)).round(1)\n",
      "note": "Pesos em quilos: toneladas vezes mil, libras pela definição exata da libra."
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

A primeira nota, US$ 669,73 em junho, vira R$ 3.535,64. **O valor original e a moeda ficam na tabela
ao lado do convertido**: uma conversão é um cálculo com uma escolha dentro, e quem a conferir precisa
das entradas. Gasto por moeda, em reais: R$ 251.360,85 com fornecedores brasileiros, R$ 181.820,70 com
o americano e R$ 74.232,88 com o espanhol.

`validate="many_to_one"` na junção é uma checagem que vale a linha: levanta um erro se um mês aparece
duas vezes no arquivo de câmbios, o que de outro modo duplicaria toda nota daquele mês sem aviso. A
aula 11 é exatamente sobre esse tipo de junção.
