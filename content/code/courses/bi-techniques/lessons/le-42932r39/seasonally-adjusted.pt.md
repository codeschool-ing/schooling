---
title: A série dessazonalizada
version: 1
---

Uma tendência responde "para onde o negócio vai" e não tem valor para as últimas semanas. **A série
dessazonalizada responde "como foi esta semana, tirando a sazonalidade"**, e existe para todas as
semanas. É a série observada com só a sazonalidade removida: tendência e ruído ficam.

É o que as estatísticas oficiais publicam quando dizem *com ajuste sazonal*, e é o que você deveria
mostrar quando alguém compara um mês com o mês anterior.

```schooling-example
{"language": "python", "file": "adjusted.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.seasonal import seasonal_decompose\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"]\nparts = seasonal_decompose(weekly, model=\"multiplicative\", period=52)", "note": "A mesma decomposição de antes."}, {"code": "table = pd.DataFrame({\n    \"observed\": weekly,\n    \"seasonal\": parts.seasonal.round(3),\n    \"adjusted\": (weekly / parts.seasonal).round(0),\n})\nprint(table[\"2024-12-08\":\"2025-01-26\"].to_string())", "note": "Dividir pelo índice sazonal dá a série dessazonalizada. Ao contrário da tendência, ela existe para todas as semanas, pontas incluídas."}], "output": "            observed  seasonal  adjusted\ndate                                    \n2024-12-08      8986     0.960    9357.0\n2024-12-15      9175     0.981    9353.0\n2024-12-22     10804     1.104    9789.0\n2024-12-29      7743     0.797    9712.0\n2025-01-05      7571     0.812    9325.0\n2025-01-12      8796     0.913    9639.0\n2025-01-19      8753     0.913    9585.0\n2025-01-26      8812     0.898    9810.0"}
```

Leia só a coluna observada e a virada do ano é um desabamento: de 10.804 pedidos na semana antes do
Natal para 7.571 na primeira semana de 2025, uma queda de 30 por cento. Quem visse isso perguntaria
o que deu errado.

**Nada deu.** Dividida pelo índice sazonal, toda semana da tabela fica entre 9.325 e 9.810. O
desabamento era a sazonalidade: a semana antes do Natal é a mais movimentada do ano e a primeira
semana de janeiro a mais calma. Tirando a sazonalidade, janeiro foi um mês comum.

Dois cuidados vêm junto.

- **Ela ainda carrega o ruído**, então uma semana dessazonalizada subir ou descer não é notícia.
  Compare médias de várias semanas, ou use a tendência quando a pergunta é direção.
- **Ela só é tão boa quanto o índice sazonal.** As semanas de Carnaval da seção anterior ficam mal
  ajustadas exatamente do jeito que os resíduos delas mostraram, e uma série dessazonalizada passa o
  erro adiante em silêncio para quem a lê.
