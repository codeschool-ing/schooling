---
title: Devolvendo as chances ao lugar
version: 1
---

Um modelo treinado numa amostra equilibrada aprende chances para um mundo em que metade das linhas são
de quem sai. Medido no mundo real, toda chance fica alta demais. **Se a reamostragem é conhecida, a
correção é aritmética**, sem dados e sem um segundo modelo.

A subamostragem manteve todos os que saem e uma parte *s* dos que ficam. Isso multiplicou as chances
relativas de sair, a chance sobre um menos a chance, por 1 / *s*. Multiplicar as do modelo por *s*
desfaz isso:

`corrected = chance × s / (chance × s + 1 − chance)`

Salve isto como `correct.py`; ele subamostra, ajusta e corrige:

```python
# correct.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
leavers, stayers = train[train["churned"] == 1], train[train["churned"] == 0]
rows = pd.concat([leavers, stayers.sample(len(leavers), random_state=0)])
share_kept = len(leavers) / len(stayers)

model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
chance = model.fit(rows[features], rows["churned"]).predict_proba(test[features])[:, 1]
corrected = chance * share_kept / (chance * share_kept + 1 - chance)

cut = CREDIT / (SAVED * KEPT)
print(f"stayers kept in the sample: {share_kept:.3f}")
print(f"test months: {test['churned'].mean():.3f} cancelled")
for name, c in [("undersampled", chance), ("corrected", corrected)]:
    print(f"{name:13} mean chance {c.mean():.3f}   sent {(c >= cut).sum():6,}"
          f"   R$ {net_value(test['churned'], c >= cut):9,.0f}")
```

O nome `share_kept` está ali porque `KEPT` já está ocupado: é o quanto vale, no `feira.py`, um
assinante que fica.

```
ana@lab:~/ml$ python correct.py
stayers kept in the sample: 0.060
test months: 0.061 cancelled
undersampled  mean chance 0.342   sent 12,150   R$  -309,024
corrected     mean chance 0.057   sent  1,019   R$    17,992
```

No corte de equilíbrio o modelo sem correção mandou 12.150 créditos, metade das linhas de teste, e
perdeu R$ 309.024. **Corrigido, ele diz 5,7% onde aconteceram 6,1%**, e faz R$ 17.992: o problema de
setembro da aula 11 de novo, um pouco baixo, mas de volta ao mundo certo.

A correção é exata só para o que a reamostragem fez. Ela não sabe nada de outras distorções, e o modelo
treinado com 4.402 linhas continua ordenando pior que o treinado com todas. Então a ordem de preferência
é:

1. **Não reamostre, e escolha o corte** pelos custos, como fez a aula 11.
2. Se os dados forem grandes demais para ajustar, **subamostre e corrija com a fórmula**.
3. Se outra coisa distorceu as chances, pesos de classe incluídos, **calibre** em meses reservados, como
   fez o `calibrate.py` da aula 11.
