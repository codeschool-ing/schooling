---
title: Quatro previsões para julgar
version: 1
---

As aulas 2, 5 e 8 previram quanto tempo uma entrega leva, e cada uma julgou sua previsão por um
número: quantos minutos de erro, em média. Esta aula é sobre esse número e os outros três que as
pessoas costumam usar, e o jeito de ver o que cada um recompensa é pôr vários modelos lado a lado e
ver as métricas discordarem.

O primeiro programa ajusta quatro deles nas entregas antes de outubro e salva o que cada um prevê para
os meses de teste, para que todo programa seguinte da aula leia as mesmas previsões:

- **`by_hour`**, a melhor referência da aula 2: a mediana do tempo de entrega naquela hora;
- **`line`**, a regressão linear da aula 5, ajustada por erro quadrático, que mira a **média**;
- **`boost_squared`**, o gradient boosting da aula 8 com a perda padrão, também erro quadrático;
- **`boost_absolute`**, o mesmo modelo com `loss="absolute_error"`, que mira a **mediana**.

Salve isto como `predictions.py`:

```python
# predictions.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.linear_model import LinearRegression

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
deliveries["rush"] = deliveries["hour"].isin([11, 12, 17, 18, 19]).astype(int)
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"].copy()
features = ["distance_km", "items", "rush", "rain", "driver_months"]

test["by_hour"] = test["hour"].map(train.groupby("hour")["minutes"].median())
test["line"] = LinearRegression().fit(train[features], train["minutes"]).predict(test[features])
for name, loss in [("boost_squared", "squared_error"), ("boost_absolute", "absolute_error")]:
    model = HistGradientBoostingRegressor(loss=loss, random_state=0)
    test[name] = model.fit(train[features], train["minutes"]).predict(test[features])
columns = ["delivery_id", "minutes", "by_hour", "line", "boost_squared", "boost_absolute"]
test[columns].round(2).to_csv("predictions.csv", index=False)
print(f"{len(test):,} test deliveries, four predictions each; saved predictions.csv")
```

```
ana@lab:~/ml$ python predictions.py
1,540 test deliveries, four predictions each; saved predictions.csv
```

Depois, as quatro métricas que dão nome a esta aula, todas de `sklearn.metrics`. Salve isto como
`errors.py`:

```python
# errors.py
import pandas as pd
from sklearn.metrics import (mean_absolute_error, mean_absolute_percentage_error,
                             mean_squared_error, r2_score)

predictions = pd.read_csv("predictions.csv")
truth = predictions["minutes"]
print("model              MAE    RMSE    MAPE      R²")
for model in ["by_hour", "line", "boost_squared", "boost_absolute"]:
    guess = predictions[model]
    print(f"{model:15} {mean_absolute_error(truth, guess):6.2f} "
          f"{mean_squared_error(truth, guess) ** 0.5:7.2f} "
          f"{mean_absolute_percentage_error(truth, guess):7.1%} {r2_score(truth, guess):7.3f}")
```

```
ana@lab:~/ml$ python errors.py
model              MAE    RMSE    MAPE      R²
by_hour          10.89   18.16   22.8%   0.021
line              5.87   14.25   11.2%   0.397
boost_squared     6.23   14.46   12.2%   0.379
boost_absolute    5.02   14.43    8.7%   0.382
```

Leia por coluna e os vereditos divergem. **MAE e MAPE põem o `boost_absolute` claramente em
primeiro.** O RMSE põe a reta em primeiro, e os três modelos a menos de um quarto de minuto um do
outro. O R² concorda com o RMSE e faz os três parecerem medíocres, explicando menos de 40% de alguma
coisa. Uma tabela, três histórias sobre qual modelo é o melhor.

Nenhuma das quatro está errada. Cada uma mede um tipo diferente de erro, e as próximas quatro seções
as tomam uma de cada vez. Depois vem a pergunta que nenhuma delas responde, e que para uma promessa de
entrega é a que importa: **se o modelo erra para o atraso ou para a antecedência**.
