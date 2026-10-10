---
title: O mesmo membro dos dois lados
version: 1
---

Um corte dá uns três mil exemplos. **Dá para ter mais empilhando cortes**: os membros em cada fim de
mês, nove meses deles, cada linha rotulada pelos seus próprios 90 dias seguintes. Esse é um jeito
comum e razoável de montar um conjunto de treino, e ele cria uma armadilha, porque agora **o mesmo
membro aparece muitas vezes**, uma por corte, com linhas parecidas entre si.

Divida essas linhas ao acaso e alguns meses de um membro vão para o treino enquanto os meses
vizinhos vão para o teste. O modelo é então testado em parte com pessoas que já conheceu, um mês
antes ou depois. Este programa mede o efeito com três divisões dos mesmos nove meses. Salve-o como
`splits.py`:

```python
"""splits.py: nine monthly cutoffs stacked, split three ways, scored on what was held out."""
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import GroupShuffleSplit, train_test_split

import features

CUTOFFS = ["2025-03-31", "2025-04-30", "2025-05-31", "2025-06-30", "2025-07-31",
           "2025-08-31", "2025-09-30", "2025-10-31", "2025-11-30"]
rows = pd.concat([features.build(c).assign(cutoff=c) for c in CUTOFFS], ignore_index=True)
print(f"{len(rows)} rows, {rows['member_id'].nunique()} different members")


def score(train, test):
    forest = RandomForestClassifier(n_estimators=200, random_state=0, n_jobs=-1)
    forest.fit(train[features.NUMERIC], train["lapsed"])
    return roc_auc_score(test["lapsed"], forest.predict_proba(test[features.NUMERIC])[:, 1])


train, test = train_test_split(rows, test_size=0.25, random_state=0)
print(f"random rows:          {score(train, test):.3f}")

keep, held = next(GroupShuffleSplit(test_size=0.25, random_state=0)
                  .split(rows, groups=rows["member_id"]))
print(f"by member:            {score(rows.iloc[keep], rows.iloc[held]):.3f}")

print(f"by time, Nov from <= Aug: "
      f"{score(rows[rows['cutoff'] <= '2025-08-31'], rows[rows['cutoff'] == '2025-11-30']):.3f}")
```

`train_test_split` pega um quarto das linhas ao acaso. `GroupShuffleSplit` pega um quarto dos
**membros** ao acaso, então todas as linhas de um membro ficam de um lado só. A última linha treina
com os cortes até agosto e testa com novembro, do jeito que o modelo vai de fato ser usado: em
membros como estão numa data posterior.

```
ana@dev:~/ml$ python splits.py
24977 rows, 3518 different members
random rows:          0.766
by member:            0.750
by time, Nov from <= Aug: 0.755
```

A divisão aleatória diz 0,766. Dividida de modo que nenhum membro fique dos dois lados, a mesma
floresta tira 0,750, e num mês posterior 0,755. **Dezesseis milésimos é o tamanho da ilusão aqui**,
e não é pouco: é mais ou menos o tamanho das melhorias que quem modela defende ao escolher entre dois
algoritmos. Com um modelo que decora mais, ou um atributo mais próximo da identidade do membro, ela
cresce; uma coluna de id esquecida entre os atributos é o caso extremo.

**A divisão que corresponde ao uso é a certa.** O modelo de afastamento vai pontuar membros que já
conheceu, numa data posterior ao fim dos seus dados de treino, então o teste honesto é uma data
posterior. Um modelo usado em clientes que nunca viu (uma loja nova, digamos) pediria a divisão por
membro. A pergunta a fazer a quem modela não é "você dividiu?", e sim "**o que vai ser diferente nas
linhas em produção, e o teste tem a mesma diferença?**"
