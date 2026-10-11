---
title: Florestas aleatórias
version: 1
---

O bagging deixa uma fonte de semelhança no lugar. Quando uma coluna é muito mais forte que as outras,
como a avaliação aqui, **toda árvore a põe na raiz**, e as árvores ficam mais parecidas do que o
bootstrap sozinho as deixaria. Uma **floresta aleatória** (*random forest*) acrescenta um segundo
tipo de acaso: a cada corte, cada árvore só pode considerar um subconjunto aleatório das colunas. Às
vezes a avaliação não está na mesa, e a árvore precisa achar a próxima melhor pergunta, o que deixa
as árvores mais diferentes entre si.

Quantas colunas são oferecidas é o `max_features`. A escolha clássica para classificação é a raiz
quadrada do número de colunas; `1.0` quer dizer todas elas, o que faz a floresta voltar a ser bagging.

Uma floresta aleatória no scikit-learn quer números, então as categorias viram colunas one-hot com o
`get_dummies`; as lacunas ela trata como as árvores da aula 7. E ela traz um conjunto de validação de
graça: o bootstrap de cada árvore deixa de fora cerca de um terço das linhas, e medir cada linha só
com as árvores que não a viram dá a nota **out-of-bag**, uma validação cruzada que não custa nada.
Salve isto como `forest.py`:

```python
# forest.py
import time

import pandas as pd
from sklearn.ensemble import RandomForestClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
X_train = pd.get_dummies(train[NUMERIC + CATEGORICAL], dtype=float)
X_test = pd.get_dummies(test[NUMERIC + CATEGORICAL], dtype=float)
cut = CREDIT / (SAVED * KEPT)

for features in ["sqrt", 1.0]:
    start = time.perf_counter()
    forest = RandomForestClassifier(n_estimators=300, min_samples_leaf=20, max_features=features,
                                    oob_score=True, n_jobs=-1, random_state=0)
    forest.fit(X_train, train["churned"])
    send = forest.predict_proba(X_test)[:, 1] >= cut
    print(f"max_features={str(features):5} out-of-bag accuracy {forest.oob_score_:.4f}, "
          f"test R$ {net_value(test['churned'], send):,.0f}, {time.perf_counter() - start:.0f} s")
```

```
ana@lab:~/ml$ python forest.py
max_features=sqrt  out-of-bag accuracy 0.9438, test R$ 18,584, 4 s
max_features=1.0   out-of-bag accuracy 0.9450, test R$ 21,864, 11 s
```

Aqui o padrão dos livros perde. Com a raiz quadrada das colunas a cada corte, a floresta faz
**R$ 18.584**; com todas as colunas oferecidas, **R$ 21.864**. Nestes dados a avaliação importa tanto
que uma árvore sem ela na raiz cresce pior, e a diferença extra entre as árvores não compensa. Em
dados em que várias colunas são mais ou menos igualmente úteis, a raiz quadrada costuma vencer. **É
por isso que é um ajuste e não uma constante**, e a aula 9 o escolhe em dados de validação.

A acurácia out-of-bag, 0,9438 contra 0,9450, quase não se mexe, e fica um fio acima dos 0,939 da
constante. É a aula 2 de novo: a acurácia não enxerga o que importa aqui. A floresta mede as linhas
out-of-bag por acurácia porque esse é o padrão dela, e outra nota pode ser calculada a partir de
`oob_decision_function_` quando for preciso.

Florestas aleatórias são o modelo mais tolerante deste curso. Não precisam de padronização, lidam
com lacunas e interações, raramente sobreajustam muito, e dão um bom resultado com os padrões na
maioria das tabelas. **Na dúvida, ajuste uma floresta** é um hábito razoável; na maioria dos dados de
negócio, as três próximas seções ainda a superam por pouco.
