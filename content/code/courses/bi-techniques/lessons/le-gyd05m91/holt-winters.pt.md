---
title: Holt-Winters: nível, tendência e sazonalidade
version: 1
---

Holt acrescentou uma tendência à suavização simples em 1957 e Winters acrescentou uma sazonalidade
em 1960, e o método que leva os dois nomes ainda é a previsão padrão em boa parte do varejo e da
logística. A ideia é a da seção anterior, três vezes. **Cada semana atualiza três números, cada um
com a sua memória:**

- o **nível**, suavizado com `alpha`, como antes;
- a **tendência**, a variação do nível por semana, suavizada com `beta`;
- a **sazonalidade**, um índice por semana do ano, suavizada com `gamma`.

Uma previsão `h` semanas à frente é o nível, mais `h` vezes a tendência, vezes o índice sazonal
daquela semana. As escolhas da aula 2 passam direto: a sazonalidade multiplica, porque as
oscilações da Panela crescem com o negócio.

```schooling-example
{"language": "python", "file": "hw.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.holtwinters import ExponentialSmoothing\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"]\ntrain, test = weekly[:\"2024-12-29\"], weekly[\"2025-01-05\":]", "note": "Treina em 2023 e 2024 e guarda 2025 à parte, para que a previsão possa ser conferida contra semanas que ela nunca viu. A mesma divisão é usada nas aulas 4 e 5."}, {"code": "model = ExponentialSmoothing(train, trend=\"add\", seasonal=\"mul\", seasonal_periods=52)\nfit = model.fit()\np = fit.params\nprint(f\"alpha {p['smoothing_level']:.3f}  beta {p['smoothing_trend']:.3f}  gamma {p['smoothing_seasonal']:.3f}\")", "note": "Uma tendência que soma um valor fixo por semana, e uma sazonalidade que multiplica, como a aula 2 encontrou. O `fit` escolhe os três pesos de suavização."}, {"code": "forecast = fit.forecast(8)\ntable = pd.DataFrame({\"forecast\": forecast.round(0), \"actual\": test.iloc[:8]})\nprint(table.rename_axis(None).to_string())", "note": "As oito primeiras semanas de 2025, previsão e real lado a lado."}], "output": "alpha 0.110  beta 0.000  gamma 0.000\n            forecast  actual\n2025-01-05    8171.0    7571\n2025-01-12    8659.0    8796\n2025-01-19    8844.0    8753\n2025-01-26    8587.0    8812\n2025-02-02    8653.0    8422\n2025-02-09    8181.0    8458\n2025-02-16    7669.0    8767\n2025-02-23    8354.0    8582"}
```

**Leia os três pesos antes das previsões.** O `alpha` é 0,110, uma memória longa para o nível. O
`beta` e o `gamma` são 0,000: o método decidiu que a inclinação da tendência e os índices sazonais
não deviam mudar nada ao longo dos dois anos, o que é o mesmo que dizer que eram estáveis o bastante
para serem estimados uma vez. Em outra série, com uma sazonalidade que deriva, o `gamma` sairia
maior.

As previsões acompanham as semanas reais de perto, a poucas centenas de pedidos, com duas exceções
que vale nomear. A semana que termina em 5 de janeiro é prevista alta demais: a semana de Ano-Novo
de 2025 caiu mais fundo que aquela com que o método aprendeu. E **a semana que termina em 16 de
fevereiro é prevista em 7.669 contra 8.767 reais**: em 2024 essa semana do ano teve Carnaval, o
índice sazonal se lembra disso, e em 2025 o Carnaval veio em março. Os resíduos da aula 2 previram
exatamente esse erro. A aula 6 o remove.

Quão bom é "de perto"? A aula 5 responde com números, contra as referências da seção final desta
aula.
