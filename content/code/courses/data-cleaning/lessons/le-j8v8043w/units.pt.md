---
title: Unidades: quilos, gramas, toneladas e libras
version: 1
---

**Uma quantidade sem unidade é o mesmo problema de um valor sem moeda**, com uma armadilha a mais:
unidades costumam vir escritas de vários jeitos. Os itens dos pedidos usam oito:

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

`kg`, `KG` e `Kg` são uma unidade; `g` e `gr` outra; `un`, `UN` e `unid` uma terceira. Três unidades em
oito grafias, e duas delas — quilos e gramas — medem a mesma coisa com um fator de mil. As quantidades
têm o seu próprio problema de convenção:

```
ana@lab:~/clean$ psql -c "SELECT count(*) FILTER (WHERE quantity LIKE '%,%') AS comma, count(*) FILTER (WHERE quantity LIKE '%.%') AS point FROM raw.order_items"
 comma | point 
-------+-------
  2916 | 11490
(1 row)
```

2.916 quantidades usam vírgula decimal, `1,5`, e 11.490 usam ponto. As duas vêm do site, cujo
formulário aceitava o que o teclado do cliente produzisse.

A limpeza faz três coisas, nesta ordem — **mapear as grafias numa unidade, ler a vírgula decimal,
converter gramas em quilos** — e então calcula o valor de cada item em centavos:

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
      "note": "**Oito grafias, três unidades.** Gramas continuam gramas por mais um passo."
    },
    {
      "code": "lines[\"quantity\"] = pd.to_numeric(lines[\"quantity\"].str.replace(\",\", \".\"))\n",
      "note": "Uma vírgula decimal vira ponto antes da conversão em número."
    },
    {
      "code": "grams = lines[\"unit\"] == \"g\"\nlines.loc[grams, \"quantity\"] = lines.loc[grams, \"quantity\"] / 1000\nlines.loc[grams, \"unit\"] = \"kg\"\n",
      "note": "**Gramas em quilos**, para todo peso estar na unidade do preço."
    },
    {
      "code": "lines[\"code\"] = lines[\"product_code\"].str.zfill(5)\n",
      "note": "O código do produto completado de volta aos cinco dígitos."
    },
    {
      "code": "lines[\"line_cents\"] = (lines[\"quantity\"] * pd.to_numeric(lines[\"unit_price\"]) * 100).round().astype(int)\n",
      "note": "O valor de cada item em centavos: quantidade vezes preço unitário, arredondado ao centavo como os sistemas faziam."
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

Sobram duas unidades, `kg` e `un`. As notas dos fornecedores precisaram do mesmo tratamento para o
peso, no código da seção anterior: toneladas vezes 1.000 e libras vezes 0,45359237, a definição exata
da libra.

## A checagem que prova

Uma conversão se confere contra algo que ela não usou. O total de todo pedido deveria ser igual à soma
dos seus itens, menos o desconto, mais o frete. Isso usa toda conversão desta aula de uma vez —
unidades, vírgulas decimais, gramas, dinheiro em centavos:

```
ana@lab:~/clean$ python -c "import pandas as pd; from lines import lines as l; o = pd.read_csv('raw/orders.csv', dtype=str).drop_duplicates(); o['cents'] = (pd.to_numeric(o['total']) * 100).round().astype(int); o['fee'] = (pd.to_numeric(o['delivery_fee']) * 100).round().astype(int); o['disc'] = (pd.to_numeric(o['discount'].fillna('0')) * 100).round().astype(int); s = l.groupby('order_id')['line_cents'].sum(); o['expected'] = o['order_id'].map(s) - o['disc'] + o['fee']; print((o['cents'] == o['expected']).sum(), (o['cents'] != o['expected']).sum())"
28519 7
```

**28.519 pedidos batem ao centavo, e 7 não.** Se alguma conversão estivesse errada, milhares
discordariam; sete não é problema de conversão. São os totais digitados à mão com um zero a mais, e a
aula 9 os acha exatamente por esta checagem.
