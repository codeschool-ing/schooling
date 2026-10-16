---
title: As notas RFM
version: 1
---

O RFM descreve cada cliente com três números que, juntos, preveem uma parte surpreendente do que ele
vai fazer:

- **Recência**: quantos dias desde o último pedido. O melhor previsor isolado de se o cliente vai
  pedir de novo.
- **Frequência**: quantos pedidos num período, aqui o último ano.
- **Valor monetário**: quanto ele gastou no mesmo período.

```schooling-example
{"language": "python", "file": "rfm.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\ntoday = pd.Timestamp(\"2025-12-31\")\nyear = orders[orders[\"date\"] > today - pd.Timedelta(days=365)]", "note": "Tudo é medido no último dia do dado, nos últimos 365 dias."}, {"code": "rfm = pd.DataFrame({\n    \"recency\": (today - orders.groupby(\"customer\")[\"date\"].max()).dt.days,\n    \"frequency\": year.groupby(\"customer\").size(),\n    \"monetary\": year.groupby(\"customer\")[\"value\"].sum(),\n}).dropna()\nprint(f\"{len(rfm):,} customers with an order in the last 365 days\")\nprint(rfm.describe().loc[[\"min\", \"25%\", \"50%\", \"75%\", \"max\"]].round(0).to_string())", "note": "Recência são os dias desde o último pedido; frequência e valor são os pedidos e os reais do último ano. O `dropna` mantém só os clientes que pediram nesse ano."}, {"code": "rfm[\"R\"] = pd.qcut(rfm[\"recency\"].rank(method=\"first\"), 5, labels=[5, 4, 3, 2, 1]).astype(int)\nrfm[\"F\"] = pd.qcut(rfm[\"frequency\"].rank(method=\"first\"), 5, labels=[1, 2, 3, 4, 5]).astype(int)\nrfm[\"M\"] = pd.qcut(rfm[\"monetary\"].rank(method=\"first\"), 5, labels=[1, 2, 3, 4, 5]).astype(int)\nprint(\"\\nthe first three customers and their scores\")\nprint(rfm.head(3).to_string())\nrfm.to_csv(\"rfm.csv\")", "note": "Cada número é cortado em cinco grupos de mesmo tamanho, quintis, com notas de 1 a 5. A recência é invertida: um pedido recente é uma nota alta. A tabela é salva para os dois programas seguintes."}], "output": "4,679 customers with an order in the last 365 days\n     recency  frequency  monetary\nmin      0.0        1.0     160.0\n25%      6.0        5.0     983.0\n50%     33.0       11.0    2239.0\n75%    196.0       21.0    4237.0\nmax    364.0       52.0   15059.0\n\nthe first three customers and their scores\n          recency  frequency  monetary  R  F  M\ncustomer                                       \nc00005         79       27.0   7725.24  3  5  5\nc00006          2       29.0   4828.98  5  5  4\nc00010          8       37.0  10636.20  4  5  5"}
```

A distribuição mostra por que se usam notas e não os números crus. A recência vai de 0 a 364 dias, a
frequência de 1 a 52 pedidos, o gasto de 160 a 15.059 reais: três escalas que ninguém compara a olho.
**Notas por quintil põem as três na mesma escala de 1 a 5**, cada nota com um quinto dos clientes,
então "R5 F5" quer dizer "no quinto mais recente e no quinto mais frequente", sejam quais forem as
unidades.

Dois detalhes do programa valem saber.

- **A recência é invertida.** Poucos dias desde o último pedido é bom, então as menores recências
  ganham um 5.
- **O `rank(method="first")` desempata.** Um quarto destes clientes pediu nos últimos 6 dias, então
  muitos têm a mesma recência; cortar valores empatados em cinco grupos iguais é impossível sem antes
  dar a cada cliente uma posição própria. O custo é que dois clientes com a mesma recência podem cair
  em notas vizinhas. Com poucos valores distintos, notas em menos grupos, como três, são a alternativa
  honesta.
