---
title: STL, a decomposição que chega às pontas
version: 1
---

A decomposição clássica tem três fraquezas que você já viu: perde meio período em cada ponta,
insiste que a sazonalidade é idêntica todo ano, e uma semana estranha puxa todas as médias de que
faz parte. O **STL**, Seasonal and Trend decomposition using Loess, foi criado em 1990 para resolver
as três, e é o que a maioria dos profissionais usa hoje.

Ele troca as médias móveis por **loess**, um suavizador que ajusta uma pequena regressão ponderada
em volta de cada ponto. Uma regressão pode ser ajustada na borda do dado, então a tendência chega às
duas pontas. A sazonalidade é suavizada entre os anos em vez de virar uma média, então pode mudar
devagar. E com `robust=True` ele ajusta, vê quais semanas explicou pior, e ajusta de novo dando
menos peso a elas.

```schooling-example
{"language": "python", "file": "stl.py", "parts": [{"code": "import numpy as np\nimport pandas as pd\nfrom statsmodels.tsa.seasonal import STL\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-08-31\"]", "note": "As semanas até o fim de agosto de 2025, antes do aumento de preço. A aula 6 roda a mesma coisa na série inteira e mostra o que o aumento faz com ela."}, {"code": "parts = STL(np.log(weekly), period=52, robust=True).fit()\ntrend = np.exp(parts.trend)", "note": "O STL soma, então recebe o logaritmo de uma série que multiplica, e a tendência volta com `exp`. O `robust=True` deixa que ele dê pouco peso a semanas que parecem pontos fora da curva."}, {"code": "print(f\"trend runs from {trend.index[0].date()} to {trend.index[-1].date()}\")\nfor week in [\"2023-01-08\", \"2024-01-07\", \"2025-01-05\", \"2025-08-31\"]:\n    print(f\"  {week}  {trend[week]:8.0f}\")", "note": "A tendência na primeira semana de cada ano e na última semana do dado."}], "output": "trend runs from 2023-01-08 to 2025-08-31\n  2023-01-08      5935\n  2024-01-07      7556\n  2025-01-05      9353\n  2025-08-31     10645"}
```

**Agora a tendência cobre todas as semanas**, da primeira à última semana de agosto de 2025, onde a
clássica parava 26 semanas antes de cada ponta. Ela cresceu de 5.935 pedidos por semana no começo
de 2023 para 10.645 no fim de agosto de 2025.

Esse alcance tem um custo, e é o custo de toda estimativa na borda do dado. **Os últimos valores de
uma tendência STL são provisórios**: foram ajustados com vizinhos de um lado só, e o dado do mês que
vem vai mexer neles. O valor mais recente de uma tendência é o mais incerto que ela tem, apesar de
ser o que todo mundo lê.

O STL também traz uma escolha que o método clássico nunca ofereceu: com que rapidez a sazonalidade
pode mudar. Deixe que ela mude fácil demais e uma mudança no negócio é lida como mudança na
sazonalidade. A aula 6 mostra exatamente isso acontecendo com o aumento de preço da Panela.
