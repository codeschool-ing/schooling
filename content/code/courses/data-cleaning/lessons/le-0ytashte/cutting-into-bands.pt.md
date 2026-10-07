---
title: Cortando um número em faixas
version: 1
---

**Discretizar** (*binning*) transforma um número numa categoria: idades em faixas, gastos em
níveis, tempos de entrega em no prazo e atrasado. Relatórios precisam disso, porque ninguém lê uma
tabela com uma linha por idade. É também a transformação com mais jeitos de errar em silêncio, e o
primeiro é a borda.

```
ana@lab:~/clean$ python -c "import pandas as pd; from per_customer import per; a = per['age']; print((a == 25).sum()); print(pd.cut(a[a == 25], [18, 25, 35]).value_counts().to_string())"
35
age
(18, 25]    35
(25, 35]     0
```

35 clientes nasceram em 2000 e completam 25 anos em 2025, e o `pd.cut` com bordas 18, 25 e 35 põe todos eles na
**primeira** faixa. Por padrão um intervalo é fechado à direita, `(18, 25]`: exclui o 18 e inclui
o 25. Rotule essa faixa como "18-24", como a maioria dos relatórios faria, e 35 pessoas ficam numa
faixa que não contém a idade delas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-bin-edges\" aria-label=\"Dois jeitos de cortar idades em 18, 25 e 35. Com o padrão do pandas, as faixas são (18, 25] e (25, 35], então uma idade de exatamente 25 cai na primeira faixa. Com right=False elas são [18, 25) e [25, 35), então o 25 abre a segunda faixa, o que combina com rótulos como 18-24 e 25-34.\"><path d=\"M314.1 30.0 L314.1 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"314.1\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">padrão</text><path d=\"M170.0 57.0 L314.1 57.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"57.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"314.1\" cy=\"57.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"242.1\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">(18, 25]</text><path d=\"M314.1 83.0 L520.0 83.0\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"314.1\" cy=\"83.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"520.0\" cy=\"83.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"417.1\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">(25, 35]</text><text x=\"545.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o 25 cai na primeira faixa</text><text x=\"20.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">right=False</text><path d=\"M170.0 147.0 L314.1 147.0\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"147.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"314.1\" cy=\"147.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"242.1\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">[18, 25)</text><path d=\"M314.1 173.0 L520.0 173.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"314.1\" cy=\"173.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"520.0\" cy=\"173.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"417.1\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">[25, 35)</text><text x=\"545.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o 25 abre a segunda faixa</text><path d=\"M128.8 222.0 L561.2 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M170.0 222.0 L170.0 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"170.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M314.1 222.0 L314.1 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"314.1\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M520.0 222.0 L520.0 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text></svg>", "caption": "Uma ponta cheia está incluída e uma vazia não. As bordas são as mesmas; um argumento decide de que lado do 25 caem os 35 clientes nascidos em 2000."}
```

A correção é decidir que lado é fechado e escrever rótulos que combinem com isso:

```schooling-example
{
  "language": "python",
  "file": "bands.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom per_customer import per\n\n"
    },
    {
      "code": "EDGES = [18, 25, 35, 45, 55, 65, 75]\nLABELS = [\"18-24\", \"25-34\", \"35-44\", \"45-54\", \"55-64\", \"65-74\"]\n",
      "note": "**Bordas e rótulos escritos juntos**, para serem lidos um contra o outro."
    },
    {
      "code": "per[\"age_band\"] = pd.cut(per[\"age\"], EDGES, right=False, labels=LABELS)\n",
      "note": "**`right=False`**: cada faixa inclui a borda de baixo, então o 25 abre a \"25-34\"."
    },
    {
      "code": "if per[\"age_band\"].isna().sum() != per[\"age\"].isna().sum():\n    raise ValueError(\"an age fell outside the edges\")\n",
      "note": "**A verificação**: toda faixa vazia tem de ser uma idade desconhecida, senão algo caiu de uma borda."
    },
    {
      "code": "per[\"spend_tier\"] = pd.qcut(per[\"revenue\"], 4, labels=[\"low\", \"mid-low\", \"mid-high\", \"high\"])\n\n",
      "note": "**Quartis**: quatro níveis com um quarto dos clientes cada, bordas tiradas dos dados."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(per[\"age_band\"].value_counts(sort=False, dropna=False).to_string())\n    print(per.groupby(\"spend_tier\", observed=True)[\"revenue\"].agg([\"size\", \"min\", \"max\"]).round(2).to_string())\n",
      "note": "Quantos em cada faixa, e onde cada nível começa e termina."
    }
  ]
}
```

```
ana@lab:~/clean$ python bands.py
age_band
18-24    207
25-34    301
35-44    282
45-54    277
55-64    268
65-74    267
NaN      671
            size      min       max
spend_tier                         
low          569     0.00    424.75
mid-low      568   426.35    892.10
mid-high     568   893.25   1568.80
high         568  1569.75  35522.50
```

Com `right=False` cada faixa é `[a, b)`, então o 25 abre a faixa "25-34", e todo rótulo é
verdadeiro. Mais duas coisas nessa saída são decisões, não acidentes:

- **Os 671 vazios ficam.** São clientes sem idade conhecida, e o `pd.cut` os deixa vazios em vez
  de inventar uma faixa. Qualquer valor fora das bordas também ficaria vazio, e é por isso que as
  bordas vão de 18 a 75: o cliente mais novo tem 19 e o mais velho 73, e **a verificação no
  código, de que os vazios são exatamente as idades desconhecidas,** prova que nada caiu por nenhuma
  das pontas.
- **Os níveis de gasto são quartis**, cortados pelo `pd.qcut` para que cada um tenha um quarto dos
  clientes. As bordas vêm dos dados: o "high" começa em R$ 1.569,75 este ano e vai começar em outro
  lugar no ano que vem. Isso serve para "o quarto de clientes que mais gasta" e não serve para
  "clientes que gastaram mais de R$ 1.500", que pede bordas fixas escritas à mão.

Uma faixa é um resumo, e resumos perdem detalhe: dois clientes de 25 e 34 anos ficam iguais depois
da faixa. **Mantenha a coluna original ao lado da faixa**, e derive a faixa de novo sempre que as
bordas mudarem, em vez de editar rótulos num relatório.
