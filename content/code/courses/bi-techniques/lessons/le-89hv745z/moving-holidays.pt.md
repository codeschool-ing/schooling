---
title: Feriados que mudam de lugar
version: 1
---

**Uma sazonalidade supõe que a mesma coisa acontece no mesmo ponto de todo ano.** Os feriados
quebram isso de dois jeitos. Alguns mudam de mês ou de semana: Carnaval, Páscoa, Corpus Christi, e
lá fora o Ano-Novo chinês ou o Ramadã. Outros ficam na sua data e andam pela semana: um Natal num
sábado é outro evento, para um negócio movimentado às segundas, que um Natal numa segunda. Os
resíduos da aula 2 mostraram os dois tipos espalhados pelas semanas que tinham ocupado.

## A armadilha do ano contra ano

O primeiro lugar em que um feriado móvel faz estrago não é um modelo. É a comparação mais comum de
um relatório de negócio, este mês contra o mesmo mês do ano passado:

```schooling-example
{"language": "python", "file": "monthly.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nmonthly = orders.resample(\"MS\").sum()", "note": "Totais mensais, cada um rotulado com o primeiro dia do seu mês."}, {"code": "for months in ([\"02\"], [\"03\"], [\"02\", \"03\"]):\n    now = sum(monthly[f\"2025-{m}\"].iloc[0] for m in months)\n    before = sum(monthly[f\"2024-{m}\"].iloc[0] for m in months)\n    label = \" and \".join({\"02\": \"February\", \"03\": \"March\"}[m] for m in months)\n    print(f\"{label:21} 2024 {before:7,}  2025 {now:7,}  change {now / before - 1:+6.1%}\")", "note": "A variação de um ano para o outro de fevereiro, de março, e dos dois juntos."}], "output": "February              2024  27,933  2025  34,770  change +24.5%\nMarch                 2024  33,306  2025  37,972  change +14.0%\nFebruary and March    2024  61,239  2025  72,742  change +18.8%"}
```

Um diretor lendo a primeira linha vê fevereiro subindo 24,5% e março 14,0%, e pergunta o que deu
tão mais certo em fevereiro. Nada deu. **O Carnaval caiu em fevereiro em 2024 e em março em 2025**,
então fevereiro de 2025 foi comparado com um fevereiro que tinha Carnaval, e março de 2025 carregou
um Carnaval que março de 2024 não teve. Juntos, os dois meses cresceram 18,8%, que é o número
honesto, e ele fica entre os dois enganosos.

A solução num relatório é comparar períodos que contêm o feriado nos dois anos, como faz a terceira
linha, ou dizer ao lado do número que o feriado mudou de lugar. A solução num modelo é a próxima
parte.

## Dizer as datas ao modelo

As datas do Carnaval são conhecidas com décadas de antecedência, então podem ser entregues ao modelo
como dado: uma coluna que diz quantos dias de Carnaval cada semana tem. O statsmodels chama essa
coluna de `exog`, uma série **exógena**, que quer dizer uma que vem de fora da série que está sendo
prevista.

```schooling-example
{"language": "python", "file": "holiday.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.statespace.sarimax import SARIMAX\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"]"}, {"code": "carnival = [\"2023-02-21\", \"2024-02-13\", \"2025-03-04\"]\ndays = pd.Series(0, index=orders.index)\nfor tuesday in pd.to_datetime(carnival):\n    days[tuesday - pd.Timedelta(days=3):tuesday] = 1\nshare = days.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"].to_frame(\"carnival_days\")", "note": "O feriado como dado: um 1 em cada dia de sábado até a terça de Carnaval, somado por semana. Uma semana pode ter quatro dias de Carnaval, ou dois se o feriado atravessa um domingo."}, {"code": "train, test = weekly[:\"2024-12-29\"], weekly[\"2025-01-05\":\"2025-06-29\"]\nfit = SARIMAX(train, exog=share[:\"2024-12-29\"], order=(1, 0, 1),\n              seasonal_order=(0, 1, 0, 52), trend=\"c\").fit(disp=False)\nprint(f\"each Carnival day in a week: {fit.params['carnival_days']:+.0f} orders\")", "note": "O ARIMA sazonal da aula 3, agora com `exog`: uma série de fora que o modelo pode usar. Ele estima quantos pedidos vale um dia de Carnaval."}, {"code": "forecast = fit.forecast(len(test), exog=share[\"2025-01-05\":\"2025-06-29\"])\nplain = SARIMAX(train, order=(1, 0, 1), seasonal_order=(0, 1, 0, 52),\n                trend=\"c\").fit(disp=False).forecast(len(test))\ntable = pd.DataFrame({\"without\": plain, \"with Carnival\": forecast, \"actual\": test}).round(0)\nprint(table[\"2025-02-09\":\"2025-03-16\"].rename_axis(None).to_string())\nfor name, f in ((\"without\", plain), (\"with Carnival\", forecast)):\n    print(f\"MAE {name:14} {(f - test).abs().mean():6.1f}\")", "note": "A previsão também precisa receber os dias de Carnaval de 2025. É esse o ponto: as datas são conhecidas antes, então podem ser dadas ao modelo."}], "output": "each Carnival day in a week: -322 orders\n            without  with Carnival  actual\n2025-02-09   8314.0         8957.0    8458\n2025-02-16   8092.0         8735.0    8767\n2025-02-23   9011.0         9011.0    8582\n2025-03-02   9186.0         8543.0    8189\n2025-03-09   9338.0         8695.0    7794\n2025-03-16   9449.0         9449.0    8723\nMAE without         362.0\nMAE with Carnival   301.3"}
```

**O modelo estima um dia de Carnaval em cerca de −322 pedidos**, e com isso corrige as duas semanas
que a aula 3 errou. A semana que termina em 16 de fevereiro, que teve Carnaval em 2024 e não em
2025, agora é prevista em 8.735 contra 8.767 reais. As semanas em que o Carnaval de fato caiu em
2025 são rebaixadas, mas não o bastante: a semana que termina em 9 de março ainda é prevista em
8.695 contra 7.794, então o efeito por dia fica subestimado com só dois Carnavais nos anos de
treino. Nas 26 semanas o MAE cai de 362,0 para 301,3.

É a mesma ideia da lista de feriados do Prophet da aula 3, montada com peças que você já tem. Vêm
dois cuidados junto. Um regressor precisa **dos seus valores futuros na hora da previsão**: um
calendário de feriados serve, o clima do mês que vem não. E cada feriado acrescentado é mais um
número a estimar com poucas ocorrências, então acrescente os grandes o bastante para aparecer nos
resíduos, e mais nenhum.
