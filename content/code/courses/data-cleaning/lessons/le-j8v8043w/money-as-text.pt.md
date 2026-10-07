---
title: Dinheiro escrito como texto
version: 1
---

**O caixa das lojas escreve dinheiro para pessoas: `R$ 1.234,56`, com símbolo da moeda, ponto entre os
milhares e vírgula antes dos centavos.** Cada parte disso é uma convenção, e a conversão precisa
desfazer cada uma de propósito.

O atalho tentador falha, ao menos com barulho:

```
ana@lab:~/clean$ python -c "print(float('1.234,56'.replace(',', '.')))" 2>&1 | tail -1
ValueError: could not convert string to float: '1.234.56'
```

Trocar a vírgula por ponto deixa `1.234.56`, que não é número. Tirar primeiro o ponto de milhar e
depois trocar a vírgula é a ordem certa, e a função que faz isso recusa tudo o que não entende:

```schooling-example
{
  "language": "python",
  "file": "money.py",
  "parts": [
    {
      "code": "from decimal import Decimal\n\n\n",
      "note": "`Decimal` guarda valores decimais com exatidão, o que um float não consegue."
    },
    {
      "code": "def reais(text):\n    \"\"\"'R$ 1.234,56' -> Decimal('1234.56'). Refuses anything else.\"\"\"\n"
    },
    {
      "code": "    digits = text.removeprefix(\"R$\").strip().replace(\".\", \"\").replace(\",\", \".\")\n",
      "note": "**A ordem importa**: tirar o símbolo da moeda, tirar o ponto de milhar, e então trocar a vírgula decimal por ponto."
    },
    {
      "code": "    value = Decimal(digits)\n",
      "note": "`Decimal` recusa qualquer texto que não seja número, em vez de chutar."
    },
    {
      "code": "    if value != value.quantize(Decimal(\"0.01\")):\n        raise ValueError(f\"more than two decimals: {text!r}\")\n    return value\n",
      "note": "E um valor com mais de duas casas decimais também é recusado: nenhuma quantia em reais tem fração de centavo."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from money import reais; print(reais('R$ 94,50'), reais('R$ 1.234,56'), int(reais('R$ 1.234,56') * 100))"
94.50 1234.56 123456
```

`R$ 94,50` e `R$ 1.234,56` convertem, e o segundo vira 123456 centavos. O perfil de padrões da aula 2
mostrou que nenhuma venda de 2025 chegou a mil reais, então o ponto de milhar nunca aparece no arquivo
deste ano — **e a função o trata mesmo assim**, porque a primeira venda grande do ano que vem não vai
pedir licença.

## Por que `Decimal` e não `float`

```
ana@lab:~/clean$ python -c "print(0.1 + 0.2, sum([0.1] * 10))"
0.30000000000000004 1.0
```

`0.1 + 0.2` não é `0.3` em ponto flutuante binário, e dez moedas de dez centavos não dão exatamente
um. Os erros são minúsculos e se acumulam: somados num ano de vendas, chegam a centavos inteiros, e um
total errado por um centavo é um total que um contador não assina. **Dinheiro vira `Decimal` ou vai
direto para centavos inteiros**, e nunca passa por um float no caminho.

A coluna inteira, em centavos:

```
ana@lab:~/clean$ python -c "import pandas as pd; from money import reais; s = pd.read_csv('raw/store_sales.csv', sep=';', encoding='latin-1', dtype=str); c = s['total'].map(reais).map(lambda v: int(v * 100)); print(len(c), c.sum(), c.min(), c.max())"
23594 154892570 390 19050
```

23.594 vendas, R$ 1.548.925,70 ao todo, de R$ 3,90 a R$ 190,50. Em SQL, os mesmos passos são funções
de texto e uma conversão para `numeric`, que é exato:

```
ana@lab:~/clean$ psql -c "SELECT total, replace(replace(substr(total, 4), '.', ''), ',', '.')::numeric(12, 2) AS reais FROM raw.store_sales LIMIT 3"
  total   | reais 
----------+-------
 R$ 94,50 | 94.50
 R$ 44,00 | 44.00
 R$ 10,60 | 10.60
(3 rows)
```
