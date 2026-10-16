---
title: Bagging, muitas árvores em muitas amostras
version: 1
---

A aula 7 terminou com uma fraqueza: uma árvore sozinha muda bastante quando as linhas de treino
mudam. O **bagging** transforma isso numa força. Sorteie uma amostra bootstrap das linhas de treino, a
mesma reamostragem com reposição que a aula 2 usou para medir a sorte, e ajuste uma árvore nela.
Sorteie outra e ajuste outra. Faça isso cem vezes, e tire a média das previsões das cem árvores. O
nome vem de *bootstrap aggregating*.

Cada árvore é funda e ruidosa, e cada uma é ruidosa do seu jeito, porque cada uma viu um conjunto um
pouco diferente de linhas. **A média fica com aquilo em que as árvores concordam e cancela boa parte
do que cada uma inventou.** Salve isto como `bagging.py`; cada árvore exige 20 linhas por folha, então
é funda, mas não sem limite:

```python
# bagging.py
import pandas as pd
from sklearn.ensemble import BaggingClassifier
from sklearn.tree import DecisionTreeClassifier

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
cut = CREDIT / (SAVED * KEPT)
tree = DecisionTreeClassifier(min_samples_leaf=20, random_state=0)
for n in [1, 10, 100]:
    bag = BaggingClassifier(tree, n_estimators=n, random_state=0, n_jobs=-1)
    bag.fit(train[NUMERIC], train["churned"])
    send = bag.predict_proba(test[NUMERIC])[:, 1] >= cut
    print(f"{n:3} trees, each on a bootstrap sample: {send.sum():5,} credits, "
          f"R$ {net_value(test['churned'], send):8,.0f}")
```

```
ana@lab:~/ml$ python bagging.py
  1 trees, each on a bootstrap sample: 1,090 credits, R$    8,096
 10 trees, each on a bootstrap sample:   791 credits, R$   21,496
100 trees, each on a bootstrap sample:   787 credits, R$   23,384
```

**Uma árvore numa amostra bootstrap faz R$ 8.096. Dez fazem R$ 21.496, e cem R$ 23.384**, mais do que
qualquer modelo isolado até aqui, inclusive o gradient boosting da aula 2. Nada nas árvores
individuais mudou entre as três linhas; só quantas entraram na média.

Duas coisas fazem isso funcionar, e vale nomear as duas porque o resto da aula se apoia nelas.

**As árvores precisam ser diferentes.** A média de cem cópias de uma árvore dá aquela árvore. O
bootstrap faz as linhas de cada árvore serem diferentes, então os erros são diferentes, e erros
diferentes se cancelam em parte.

**Cada árvore precisa ser boa sozinha.** A média de cem palpites que não sabem nada dá um palpite que
não sabe nada. As árvores aqui são fundas o bastante para achar sozinhas a avaliação, as reclamações e
os pulos; o bagging tira o ruído delas, não a ignorância.

Acrescentar árvores nunca faz um modelo de bagging sobreajustar, no sentido da aula 3: a centésima
árvore muda a média menos que a décima, e o valor de teste se assenta em vez de cair. Mais árvores
custam tempo e memória, e depois de algumas centenas quase não compram nada.
