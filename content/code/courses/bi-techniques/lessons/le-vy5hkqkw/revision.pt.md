---
title: Revisão: a previsão muda, e é para isso
version: 1
---

**Uma previsão é feita de novo sempre que chega dado novo**, e a cada vez ela pode dizer algo
diferente. Quem vê uma previsão mudar costuma concluir que a primeira estava errada e que o método
não é confiável. Normalmente é o contrário: um método cuja previsão nunca se mexesse quando chegam
semanas novas estaria ignorando essas semanas.

Isto faz a previsão de uma semana, a última de junho de 2025, sete vezes: primeiro no fim de 2024,
depois a cada quatro semanas conforme 2025 acontece.

```schooling-example
{"language": "python", "file": "revision.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.holtwinters import ExponentialSmoothing\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-08-31\"]\ntarget = pd.Timestamp(\"2025-06-29\")", "note": "Uma semana-alvo, a última de junho de 2025."}, {"code": "print(f\"forecasts of the week ending {target.date()}, actual {weekly[target]}\")\nfor origin in weekly[\"2024-12-29\":\"2025-06-22\"].index[::4]:\n    fit = ExponentialSmoothing(weekly[:origin], trend=\"add\", seasonal=\"mul\",\n                               seasonal_periods=52).fit()\n    h = (target - origin).days // 7\n    print(f\"  made {origin.date()}, {h:2} weeks ahead: {fit.forecast(h).iloc[-1]:7.0f}\")", "note": "A cada quatro semanas, reajusta com tudo o que se sabe até ali e prevê a mesma semana-alvo de novo."}], "output": "forecasts of the week ending 2025-06-29, actual 11166\n  made 2024-12-29, 26 weeks ahead:   11399\n  made 2025-01-26, 22 weeks ahead:   11362\n  made 2025-02-23, 18 weeks ahead:   11561\n  made 2025-03-23, 14 weeks ahead:   11352\n  made 2025-04-20, 10 weeks ahead:   11331\n  made 2025-05-18,  6 weeks ahead:   11307\n  made 2025-06-15,  2 weeks ahead:   11157"}
```

A maioria das revisões mexeu a previsão em algumas dezenas de pedidos. A única exceção tem nome: a
safra de fevereiro saltou cerca de 200, porque a semana que termina em 16 de fevereiro veio alta, sem
Carnaval, e o nível subiu; quatro semanas depois o Carnaval chegou em março e a safra seguinte
desfez o salto. A última safra, duas semanas antes, disse 11.157 contra 11.166 que aconteceram. Esse
é o formato normal: **as revisões se assentam conforme o alvo se aproxima**, e quando uma salta, o
salto deveria ser explicável por algo nas semanas novas. Uma série de revisões que pula sem motivo
que se possa nomear é sinal de que o método está reagindo a ruído.

## Guarde toda safra

Uma previsão feita numa data se chama **safra** (em inglês, *vintage*). O hábito perigoso é
sobrescrever a safra antiga com a nova, de modo que o relatório só mostra o número mais recente.
Três coisas se perdem quando isso acontece:

- **responsabilidade**: o orçamento foi fechado com a safra de janeiro, e agora ninguém sabe dizer o
  que ela dizia;
- **medição**: a aula 5 mede o erro em cada horizonte, o que precisa da previsão como ela foi feita
  naquele horizonte, não como foi revista depois;
- **aprendizado**: um método que é sempre otimista demais três meses à frente só mostra isso se as
  safras de três meses atrás forem guardadas.

A prática é barata: guarde cada previsão com a data em que foi feita, o horizonte e a versão do
modelo, e nunca atualize uma linha. É a mesma disciplina de só acrescentar que mantém qualquer
histórico honesto.
