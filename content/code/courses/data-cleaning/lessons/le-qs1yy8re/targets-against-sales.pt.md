---
title: Metas contra vendas
version: 1
---

A pergunta que a equipe comercial fez nunca foi "quais são as metas". Foi "como cada loja se saiu
contra a sua meta". Com as duas tabelas no formato longo, isso é uma junção por duas colunas:

```schooling-example
{
  "language": "python",
  "file": "actuals.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom money import reais\nfrom ready import orders\n\n",
      "note": "O `reais` da aula 7 e os pedidos da aula 12 com os totais decididos."
    },
    {
      "code": "shops = pd.read_csv(\"raw/store_sales.csv\", sep=\";\", encoding=\"latin-1\", dtype=str)\n",
      "note": "O arquivo do caixa das lojas, Latin-1 e ponto e vírgula, como a aula 2 o encontrou."
    },
    {
      "code": "shops[\"month\"] = pd.to_datetime(shops[\"data\"], format=\"%d/%m/%Y\").dt.to_period(\"M\")\n",
      "note": "O mês de cada venda, pela data `dd/mm/aaaa`."
    },
    {
      "code": "shops[\"amount\"] = shops[\"total\"].map(reais).astype(float)\n\n",
      "note": "Cada valor em reais, pela função que recusa o que não consegue ler."
    },
    {
      "code": "online = orders[orders[\"status\"] == \"delivered\"].copy()\n",
      "note": "**Só pedidos entregues**: um pedido cancelado ou reembolsado não é venda."
    },
    {
      "code": "online[\"loja\"] = \"Online\"\nonline[\"month\"] = online[\"placed\"].dt.to_period(\"M\")\nonline[\"amount\"] = online[\"total\"]\n\n",
      "note": "O canal online ganha nome de loja, mês e valor, as mesmas três colunas das lojas."
    },
    {
      "code": "sales = pd.concat([shops[[\"loja\", \"month\", \"amount\"]], online[[\"loja\", \"month\", \"amount\"]]])\n",
      "note": "**Uma tabela longa de vendas**, as duas origens empilhadas."
    },
    {
      "code": "actuals = sales.groupby([\"loja\", \"month\"], as_index=False)[\"amount\"].sum()\n",
      "note": "**Uma linha por loja e mês**: o grão das metas."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "attainment.py",
  "parts": [
    {
      "code": "from actuals import actuals\nfrom targets import targets\n\n",
      "note": "As duas tabelas longas."
    },
    {
      "code": "both = targets.merge(actuals, on=[\"loja\", \"month\"], how=\"left\", validate=\"one_to_one\",\n                     indicator=True)\n",
      "note": "**A junção por duas colunas**, cada meta mantendo a sua linha, conferida um para um, com indicador."
    },
    {
      "code": "missing = both[both[\"_merge\"] == \"left_only\"]\nif len(missing):\n    raise ValueError(f\"targets with no sales: {missing[['loja', 'month']].values.tolist()}\")\n",
      "note": "**Uma meta sem vendas para o script**, dizendo a loja e o mês."
    },
    {
      "code": "both[\"attainment\"] = both[\"amount\"] / both[\"target\"]\n\n",
      "note": "Atingimento por loja e mês: vendas sobre meta."
    },
    {
      "code": "if __name__ == \"__main__\":\n    year = both.groupby(\"loja\")[[\"target\", \"amount\"]].sum()\n    year[\"attainment\"] = (year[\"amount\"] / year[\"target\"]).round(3)\n    print(year.round(2).sort_values(\"attainment\").to_string())\n",
      "note": "**O ano pelas somas**, não pela média das razões mensais."
    }
  ]
}
```

```
ana@lab:~/clean$ python attainment.py
            target      amount  attainment
loja                                      
Pinheiros   660000   631457.60        0.96
Savassi     204000   210877.70        1.03
Botafogo    294000   311434.20        1.06
Online     2286000  2493548.15        1.09
Cambuí      180000   199280.80        1.11
Batel       177000   195875.40        1.11
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l13-attainment\" aria-label=\"Barras horizontais das vendas de cada loja em 2025 como fração da sua meta, contra uma linha em 100%: Pinheiros 96%, Savassi 103%, Botafogo 106%, Online 109%, Batel 111%, Cambuí 111%. Só Pinheiros fica antes da linha.\"><text x=\"120.0\" y=\"51.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pinheiros</text><rect x=\"130.0\" y=\"40.0\" width=\"414.6\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.6\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">96%</text><text x=\"120.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Savassi</text><rect x=\"130.0\" y=\"71.0\" width=\"447.9\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"583.9\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">103%</text><text x=\"120.0\" y=\"113.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Botafogo</text><rect x=\"130.0\" y=\"102.0\" width=\"459.0\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">106%</text><text x=\"120.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Online</text><rect x=\"130.0\" y=\"133.0\" width=\"472.7\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"608.7\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">109%</text><text x=\"120.0\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Batel</text><rect x=\"130.0\" y=\"164.0\" width=\"479.5\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.5\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">111%</text><text x=\"120.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Cambuí</text><rect x=\"130.0\" y=\"195.0\" width=\"479.8\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.8\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">111%</text><path d=\"M563.3 30.0 L563.3 39.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 63.0 L563.3 70.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 94.0 L563.3 101.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 125.0 L563.3 132.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 156.0 L563.3 163.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 187.0 L563.3 194.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 218.0 L563.3 240.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"563.3\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meta</text></svg>", "caption": "Vendas sobre meta no ano, pelas somas e não pela média dos meses. A maior loja é a única abaixo.", "same": ["Batel", "Botafogo", "Cambuí", "Online", "Pinheiros", "Savassi"]}
```

Cinco das seis bateram a meta. Pinheiros, a maior loja, ficou abaixo, com 96%; Cambuí e
Batel terminaram 11% acima, e o canal online, que movimenta mais dinheiro, 9% acima.

Quatro coisas nesses dois arquivos são as aulas anteriores trabalhando:

- **As vendas são contadas do mesmo jeito que no resto do curso.** Os valores das lojas passam pelo
  `reais` da aula 7, os totais online pelo `ready.py` da aula 12, e só pedidos entregues contam,
  porque um pedido cancelado ou reembolsado não é venda.
- **A chave da junção são duas colunas**, loja e mês, e as duas têm o mesmo tipo dos dois lados: o
  nome da loja como texto, o mês como `period[M]`.
- **`validate="one_to_one"`** confere que nenhum lado tem duas linhas para uma loja e um mês.
  Tabelas longas feitas por `melt` e por `groupby` devem passar as duas, e se alguma um dia não
  passar, a junção para antes de abrir um leque.
- **Uma meta sem vendas para o script.** Um left join mantém toda meta, e o indicador diz se ela
  achou o seu mês. Uma loja sem vendas num mês é possível, mas é uma descoberta para olhar, não um
  vazio para dividir.

O atingimento é uma coluna derivada no sentido da aula 12, calculada no grão de loja e mês. A
tabela do ano é calculada de novo a partir das somas, em vez da média das doze razões mensais,
porque **uma média de razões dá a um mês fraco o mesmo peso de um mês cheio**.
