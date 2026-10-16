---
title: Regressão: prever um número
version: 1
---

**A regressão prevê um número para cada caso**: aqui, quanto cada cliente vai gastar nos próximos 90
dias. A maquinaria é a mesma da classificação, com um valor no lugar de uma categoria, e ela é julgada
com as medidas da aula 5.

```schooling-example
{"language": "python", "file": "spend_model.py", "parts": [{"code": "import pandas as pd\nfrom sklearn.linear_model import LinearRegression\n\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])"}, {"code": "def snapshot(day):\n    day = pd.Timestamp(day)\n    past = orders[orders[\"date\"] <= day]\n    last_90 = past[past[\"date\"] > day - pd.Timedelta(days=90)]\n    next_90 = orders[(orders[\"date\"] > day) & (orders[\"date\"] <= day + pd.Timedelta(days=90))]\n    t = pd.DataFrame({\"spent_90\": last_90.groupby(\"customer\")[\"value\"].sum(),\n                      \"recency\": (day - past.groupby(\"customer\")[\"date\"].max()).dt.days})\n    t = t.dropna()\n    t[\"next_90\"] = next_90.groupby(\"customer\")[\"value\"].sum().reindex(t.index).fillna(0)\n    return t", "note": "Para cada cliente que pediu nos últimos 90 dias: quanto gastou nesses 90 dias, quantos dias desde o último pedido, e a resposta, quanto gastou nos 90 dias seguintes, zero se nada."}, {"code": "train, test = snapshot(\"2024-12-31\"), snapshot(\"2025-06-30\")\nmodel = LinearRegression().fit(train[[\"spent_90\", \"recency\"]], train[\"next_90\"])\npredicted = model.predict(test[[\"spent_90\", \"recency\"]])", "note": "A mesma divisão no tempo do modelo de churn, com regressão linear, o modelo da aula 19 de `statistics`."}, {"code": "print(f\"{len(test):,} customers who ordered in the 90 days before 30 Jun 2025\")\nprint(f\"coefficients: spent_90 {model.coef_[0]:.2f}, recency {model.coef_[1]:.2f}, \"\n      f\"intercept {model.intercept_:.0f}\")\nprint(f\"MAE of the model:              {abs(predicted - test['next_90']).mean():5.0f} reais\")\nprint(f\"MAE of repeating the last 90:  {abs(test['spent_90'] - test['next_90']).mean():5.0f} reais\")\nprint(f\"total predicted {predicted.sum():,.0f}, total actual {test['next_90'].sum():,.0f}\")", "note": "O erro do modelo contra o palpite mais simples, de que os próximos 90 dias vão repetir os últimos 90, como a aula 5 comparou previsões com a ingênua."}], "output": "2,775 customers who ordered in the 90 days before 30 Jun 2025\ncoefficients: spent_90 0.49, recency -15.24, intercept 711\nMAE of the model:                549 reais\nMAE of repeating the last 90:    591 reais\ntotal predicted 2,927,218, total actual 3,083,457"}
```

Os coeficientes se leem como aritmética simples: cada real gasto nos últimos 90 dias prevê cerca de
0,49 real nos próximos 90, e cada dia de silêncio tira cerca de 15 reais. O primeiro ser menor que 1
diz que os clientes, em média, gastam menos no próximo trimestre que no último, porque alguns deles
vão embora.

**O MAE do modelo é 549 reais, contra 591 do palpite ingênuo** de que o próximo trimestre repete o
último. Uma melhora modesta, e honesta: quase tudo o que se pode saber do próximo trimestre de um
cliente já está no último. Um modelo que batesse o palpite ingênuo por larga margem em dados assim
deveria ser checado à procura de um vazamento, uma entrada que contém a resposta escondida, antes de
alguém acreditar nele.

**O total chega mais perto que os indivíduos.** O gasto previsto somando todos os clientes é
R$ 2.927.218 contra R$ 3.083.457 de fato, cerca de 5% abaixo, enquanto clientes individuais erram por
centenas de reais. Erros em direções diferentes se cancelam numa soma, e por isso um modelo ruidoso
demais para dizer o que um cliente vai fazer ainda pode servir para um orçamento. É o mesmo motivo
pelo qual a aula 4 agregou até o grão da decisão.
