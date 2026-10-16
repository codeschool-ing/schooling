---
title: Um teste é um sorteio
version: 1
---

A comparação de duas seções atrás previu 26 semanas a partir de um ponto de partida, o fim de 2024,
e declarou os dois melhores modelos quase empatados. **Isso é um sorteio.** Comece de outra semana e
outros feriados, outro ruído e outro trecho de tendência caem dentro do teste, e o resultado se mexe.

O remédio padrão é uma **avaliação com origem móvel**, também chamada de validação cruzada de séries
temporais: faça a previsão a partir de muitos pontos de partida, cada um usando só o dado anterior a
ele, e tire a média dos erros de todos. É como a aula 4 mediu revisões, transformado num método de
pontuação.

```schooling-example
{"language": "python", "file": "backtest.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.holtwinters import ExponentialSmoothing\nfrom statsmodels.tsa.statespace.sarimax import SARIMAX\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-08-31\"]"}, {"code": "print(\"origin       Holt-Winters  seasonal ARIMA   (MAE over the next 4 weeks)\")\nfor origin in weekly[\"2024-12-29\":\"2025-06-01\"].index[::4]:\n    history, future = weekly[:origin], weekly[origin:].iloc[1:5]", "note": "Seis origens de previsão, a quatro semanas uma da outra. Cada uma vê tudo até a sua origem e é testada nas quatro semanas depois dela."}, {"code": "    hw = ExponentialSmoothing(history, trend=\"add\", seasonal=\"mul\",\n                              seasonal_periods=52).fit().forecast(4)\n    ar = SARIMAX(history, order=(1, 0, 1), seasonal_order=(0, 1, 0, 52),\n                 trend=\"c\").fit(disp=False).forecast(4)", "note": "Os dois modelos reajustados em toda origem, como seriam no uso."}, {"code": "    hw_mae = abs(hw.values - future.values).mean()\n    ar_mae = abs(ar.values - future.values).mean()\n    print(f\"{origin.date()}   {hw_mae:12.0f}  {ar_mae:14.0f}\")"}], "output": "origin       Holt-Winters  seasonal ARIMA   (MAE over the next 4 weeks)\n2024-12-29            263             289\n2025-01-26            473             427\n2025-02-23            732             834\n2025-03-23            191             282\n2025-04-20            229             164\n2025-05-18            266             178"}
```

**O Holt-Winters vence três das seis origens e o ARIMA as outras três.** A pior origem para os dois é
o fim de fevereiro, cujas quatro semanas seguintes contêm o Carnaval que foi para março. Na média das
seis os dois ficam perto de novo, que é a conclusão honesta: nesta série, neste horizonte, o dado não
os separa.

Duas regras tornam uma avaliação com origem móvel confiável.

- **Nunca deixe um modelo ver o futuro.** Cada origem é ajustada só com dado anterior a ela. Ajustar
  uma vez em tudo e depois "testar" em fatias do mesmo dado é o jeito mais comum de exagerar a
  precisão de uma previsão.
- **Meça no horizonte de que a decisão precisa.** Quatro semanas à frente serve a operações; a
  pergunta da cozinha é uma semana à frente e a de finanças é um ano. Um modelo pode vencer num
  horizonte e perder em outro, como a tendência amortecida da aula 4.

Quando dois modelos ficam tão perto, o desempate não é precisão: qual dos dois o time consegue
manter, qual falha com mais elegância quando acontece algo estranho, e se uma média dos dois, que
muitas vezes é melhor que cada um, compensa o segundo modelo.
