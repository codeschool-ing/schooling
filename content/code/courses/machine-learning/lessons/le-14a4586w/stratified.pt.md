---
title: Partes estratificadas para uma classe rara
version: 1
---

Corte 38.628 linhas em cinco ao acaso e cada parte fica com mais ou menos um quinto de quem saiu, mas
só mais ou menos. Com quem sai abaixo de 6%, uma parte pode acabar com visivelmente mais que outra, e
uma parte com menos positivos tem nota diferente só por isso. Partes **estratificadas** fixam a
proporção de cada classe em todas as partes, para que elas difiram só nas linhas que contêm. Salve
isto como `leavers_per_fold.py`:

```python
# leavers_per_fold.py
from sklearn.model_selection import KFold, StratifiedKFold

from feira import by_time, load_churn

train, _ = by_time(load_churn())
y = train["churned"]
for name, splitter in [("KFold", KFold(5, shuffle=True, random_state=3)),
                       ("StratifiedKFold", StratifiedKFold(5, shuffle=True, random_state=3))]:
    shares = [y.iloc[rows].mean() for _, rows in splitter.split(train, y)]
    print(f"{name:16} leavers in each fold: " + "  ".join(f"{s:.2%}" for s in shares))
```

```
ana@lab:~/ml$ python leavers_per_fold.py
KFold            leavers in each fold: 5.55%  5.84%  5.41%  5.84%  5.85%
StratifiedKFold  leavers in each fold: 5.71%  5.70%  5.70%  5.70%  5.70%
```

O `KFold` simples dá partes de 5,41% a 5,85% de quem saiu; o `StratifiedKFold` dá 5,70% ou 5,71% em
todas. Aqui a diferença é pequena, porque há mais de dois mil que saíram para dividir. Ela cresce à
medida que a classe rara encolhe: com cinquenta positivos, uma parte ao acaso pode facilmente ficar
com cinco e outra com quinze, e as notas dessas duas passam a medir o sorteio mais que o modelo.

Então **para classificação, estratifique por padrão**. O scikit-learn já faz isso quando pode:
`cross_val_score` e `GridSearchCV`, com um classificador e um número inteiro de partes, usam
`StratifiedKFold` sem precisar pedir. É quando você escreve o laço, como o `folds.py` faz, que precisa
escolher.

Estratificar não resolve o problema da próxima seção, e os dois se combinam: o
`StratifiedGroupKFold` mantém cada assinante inteiro e as proporções das classes perto de iguais.
