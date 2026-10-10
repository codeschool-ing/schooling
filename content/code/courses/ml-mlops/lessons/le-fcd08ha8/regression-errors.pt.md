---
title: O quanto uma quantia está longe
version: 1
---

Uma regressão nunca acerta, só chega perto, então as notas dela medem distância. A lição 2 usou uma,
o **erro absoluto médio**. Outras duas são comuns, e as três discordam de um jeito que vale ver.
Salve isto como `errors.py`; ele importa `examples` do `regress.py` da lição 2, que deve continuar em
`~/ml`:

```python
"""errors.py: three ways to measure how far off the spend regression is."""
from sklearn.dummy import DummyRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, median_absolute_error, root_mean_squared_error

import features
from regress import examples

train, test = examples("2025-09-30"), examples("2025-11-30")
y = test["spend_next_90d"] / 100                      # in reais from here on

for name, model in (("average", DummyRegressor()), ("regression", LinearRegression())):
    model.fit(train[features.NUMERIC], train["spend_next_90d"] / 100)
    guess = model.predict(test[features.NUMERIC])
    print(f"{name:10}  MAE R$ {mean_absolute_error(y, guess):6.2f}   "
          f"RMSE R$ {root_mean_squared_error(y, guess):6.2f}   "
          f"median R$ {median_absolute_error(y, guess):6.2f}")

print(f"largest spends: {', '.join(f'R$ {v:.2f}' for v in y.nlargest(3))}")
```

```
ana@dev:~/ml$ python errors.py
average     MAE R$ 213.76   RMSE R$ 266.37   median R$ 194.21
regression  MAE R$ 179.49   RMSE R$ 231.68   median R$ 149.37
largest spends: R$ 1637.20, R$ 1537.70, R$ 1427.80
```

| nota | como é calculada | a que ela é sensível |
| --- | --- | --- |
| **MAE**, erro absoluto médio | a média das distâncias | a todo erro igualmente |
| **RMSE**, raiz do erro quadrático médio | a raiz quadrada da média das distâncias ao quadrado | a erros grandes, muito mais que a pequenos |
| **erro absoluto mediano** | a distância do meio | a quase nada sobre os maiores erros |

**O RMSE é maior que o MAE nos dois modelos, por uns R$ 50**, porque uns poucos membros gastaram
muito mais do que alguém previu: R$ 1.637,20, R$ 1.537,70 e R$ 1.427,80 em 90 dias, contra uma
predição média perto de R$ 300. Elevados ao quadrado, esses poucos erros dominam. A mediana diz que o
membro típico é previsto com erro de até R$ 149,37, e não se importa nada com aqueles três.

Nenhuma delas é a certa em geral. **O RMSE combina quando um erro grande é muito pior que um
pequeno**, como abastecer uma loja, onde faltar custa mais do que sobrar um pouco. **O MAE combina
quando cada real é um real.** A mediana descreve o membro típico e nunca deve ser a única nota, porque
um modelo pode ser bom para o membro típico e desastroso para os que mais importam.

E cada uma só significa algo ao lado da sua linha de base: a regressão baixa o MAE de R$ 213,76 para
R$ 179,49, o RMSE de R$ 266,37 para R$ 231,68, e a mediana de R$ 194,21 para R$ 149,37. **A melhora é
real e modesta nas três**, o que é mais informação do que qualquer uma delas sozinha.
