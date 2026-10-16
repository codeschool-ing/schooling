---
title: Pelo que a busca é julgada
version: 1
---

Uma busca compara centenas de ajustes, então, antes de ela começar, duas coisas precisam estar fixas:
**quais linhas julgam cada candidato** e **que nota elas dão**. Mude qualquer uma no meio e a
comparação perde o sentido. As duas vão num módulo pequeno, que é o segundo arquivo compartilhado do
curso. Salve isto como `tuning.py`:

```schooling-example
{
  "language": "python",
  "file": "tuning.py",
  "parts": [
    {
      "code": "# tuning.py\n\"\"\"What every search in lesson 9 shares: the folds, the score and the model.\"\"\"\nimport numpy as np\nfrom sklearn.ensemble import HistGradientBoostingClassifier\n\nfrom feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, net_value\n\nFEATURES = NUMERIC + CATEGORICAL\n",
      "note": "O segundo arquivo compartilhado do curso, depois do `feira.py`. Toda busca desta aula importa estas três coisas, para todo candidato ser julgado exatamente pelas mesmas partes e pela mesma nota."
    },
    {
      "code": "\ndef time_folds(train, last=3):\n    \"\"\"For each of the last months: learn from every month before it, score that month.\"\"\"\n    months = sorted(train[\"snapshot\"].unique())\n    for month in months[-last:]:\n        yield (np.flatnonzero(train[\"snapshot\"] < month),\n               np.flatnonzero(train[\"snapshot\"] == month))\n",
      "note": "**As partes andam para a frente**, como a aula 3 defendeu. Cada um dos três últimos meses de treino é medido por um modelo que aprendeu com todos os meses anteriores. Os meses de teste, de julho a dezembro, não são tocados; o `by_time` já os cortou antes de esta função ver as linhas."
    },
    {
      "code": "\ndef value_per_thousand(model, X, y):\n    \"\"\"The scorer: reais per 1,000 rows, sending the credit at the break-even chance.\"\"\"\n    send = model.predict_proba(X)[:, 1] >= CREDIT / (SAVED * KEPT)\n    return net_value(y, send) / len(y) * 1000\n",
      "note": "**A nota é a do negócio.** O scikit-learn aceita como nota qualquer função de um modelo ajustado, das linhas e das respostas, então a busca otimiza valor líquido por mil linhas em vez de acurácia, como a seção 03 explica."
    },
    {
      "code": "\ndef booster(**settings):\n    return HistGradientBoostingClassifier(categorical_features=\"from_dtype\", early_stopping=False,\n                                          random_state=0, **settings)",
      "note": "O modelo sendo ajustado, com a parada antecipada desligada, para que o número de árvores seja um dos botões que a busca gira, e não algo decidido pelas costas dela."
    }
  ]
}
```

Há duas decisões dentro dele.

**As partes respeitam o tempo.** A aula 3 mostrou que uma divisão ao acaso infla um modelo aqui em
cerca de 13%, e uma busca em partes infladas escolhe o ajuste que melhor explora a inflação. Aqui
abril, maio e junho de 2025 são medidos, cada um, por um modelo ajustado em todos os meses anteriores.
Os meses de teste, de julho a dezembro, ficam intocados até o fim da aula.

**A nota é o valor líquido.** As buscas do scikit-learn maximizam a nota que recebem, e o padrão delas
para um classificador é a acurácia. A aula 2 mostrou que a acurácia quase não se mexe nestes dados
enquanto o dinheiro se mexe muito, então uma busca por acurácia escolheria entre ajustes pela terceira
casa decimal de um número que não interessa a ninguém. O `value_per_thousand` entrega a ela a pergunta
da aula 1.

Antes de buscar qualquer coisa, meça os padrões do mesmo jeito, para haver um número a superar. Salve
isto como `baseline_cv.py`:

```python
# baseline_cv.py
from sklearn.model_selection import cross_val_score

from feira import by_time, load_churn
from tuning import FEATURES, booster, time_folds, value_per_thousand

train, _ = by_time(load_churn())
folds = list(time_folds(train))
for rows, check in folds:
    print(f"learn from {len(rows):,} rows, score {train['snapshot'].iloc[check[0]]:%Y-%m}")
scores = cross_val_score(booster(), train[FEATURES], train["churned"], cv=folds,
                         scoring=value_per_thousand)
print("defaults, R$ per 1,000 rows:", scores.round(0), f"mean {scores.mean():.0f}")
```

```
ana@lab:~/ml$ python baseline_cv.py
learn from 27,797 rows, score 2025-04
learn from 31,300 rows, score 2025-05
learn from 34,906 rows, score 2025-06
defaults, R$ per 1,000 rows: [361. 910. 561.] mean 610
```

**Os padrões fazem R$ 610 por mil linhas em média**, e essa média esconde uma faixa larga: R$ 361 em
abril, R$ 910 em maio. A dispersão entre as partes é o tamanho da sorte em cada comparação que vem, e
ela é grande. Guarde isso quando a busca anunciar o vencedor.
