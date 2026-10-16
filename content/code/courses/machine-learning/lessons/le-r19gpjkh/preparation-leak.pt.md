---
title: O vazamento na preparação
version: 1
---

A terceira porta não tem coluna a quem culpar. Ela acontece quando uma etapa que **aprende com os
dados** é ajustada em todas as linhas, e só depois as linhas são divididas. Padronizar aprende uma
média e uma dispersão; preencher lacunas aprende uma mediana; escolher as melhores colunas aprende
quais têm relação com o alvo. Cada um desses números aprendidos leva um pouco das linhas de validação
para dentro do treino.

O último deles é o que estraga de verdade, e dá para mostrá-lo sem nada a aprender. Pegue 400
linhas, metade de quem saiu, e dê a elas 2.000 colunas de **números aleatórios**. Nenhuma coluna
significa nada. Escolha as 20 colunas mais relacionadas ao alvo e depois faça a validação cruzada de
um modelo nelas. Salve isto como `noise.py`:

```python
# noise.py
import numpy as np
from sklearn.feature_selection import SelectKBest, f_classif
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.pipeline import make_pipeline

from feira import load_churn

churn = load_churn()
rng = np.random.default_rng(0)
sample = churn.groupby("churned").sample(200, random_state=0)   # 200 left, 200 stayed
y = sample["churned"].to_numpy()
X = rng.normal(size=(len(y), 2000))                              # 2,000 columns of nothing
print(f"{X.shape[0]} rows, {X.shape[1]} columns of random numbers, half the rows leavers")

picked = SelectKBest(f_classif, k=20).fit(X, y)                  # chosen with every row
X20 = picked.transform(X)
wrong = cross_val_score(LogisticRegression(), X20, y, cv=5)
print(f"columns picked before the split: accuracy {wrong.mean():.3f}")

honest = make_pipeline(SelectKBest(f_classif, k=20), LogisticRegression())
right = cross_val_score(honest, X, y, cv=5)                      # picked inside each fold
print(f"columns picked inside each fold: accuracy {right.mean():.3f}")
```

```
ana@lab:~/ml$ python noise.py
400 rows, 2000 columns of random numbers, half the rows leavers
columns picked before the split: accuracy 0.688
columns picked inside each fold: accuracy 0.445
```

**68,8% de acurácia a partir de puro ruído**, numa amostra equilibrada em que uma moeda tira 50%.
Entre 2.000 colunas aleatórias, algumas se alinham ao alvo por acaso, e escolhê-las com todas as
linhas é escolher as que se alinham também nas linhas de validação. O modelo é então validado em
linhas cujo ruído foi usado para escolher as colunas dele.

Feito do jeito certo, dentro de cada parte, a escolha é refeita só com as quatro partes de treino e a
quinta fica de fora. A acurácia cai para **44,5%**, que é acaso com um pouco de azar, e é a verdade:
não havia nada para achar.

## Um pipeline é o conserto

O `make_pipeline` colou a escolha e o modelo num objeto só, e o `cross_val_score` ajustou o objeto
inteiro dentro de cada parte. Essa é a cura geral para este tipo de vazamento: **ponha dentro do
pipeline toda etapa que aprende alguma coisa**, e a validação cruzada não consegue ajustá-la em
linhas que ela não deveria ver. A aula 15 monta o pipeline da Feira em Casa desse jeito, com a
padronização e a codificação dentro.

Padronizar e preencher lacunas em todas as linhas vazam bem menos que escolher colunas, porque uma
média calculada com 38.000 linhas quase não se mexe quando se acrescenta um quinto delas. Ainda são
vazamentos, e são consertados no mesmo lugar sem custo, então não há por que discutir o tamanho
deles.
