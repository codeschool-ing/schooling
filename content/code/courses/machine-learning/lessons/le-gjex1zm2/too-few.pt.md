---
title: Poucos demais, ou uma parte pequena demais
version: 1
---

Um modelo aprende como é alguém que sai a partir das pessoas que saem que ele vê. Se vê 2.201, é uma
quantidade de evidência; se vê 100, bem menos, faça o que fizerem os que ficam. A parte e a contagem
podem ser separadas: mantenha todos os que ficam e varie os que saem, depois mantenha a parte fixa e
varie tudo. Salve isto como `few.py`:

```python
# few.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, roc_auc_score

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
leavers, stayers = train[train["churned"] == 1], train[train["churned"] == 0]

print("leavers   stayers   share    AUC     AP")
for n_leavers, n_stayers in [(100, 36427), (300, 36427), (1000, 36427), (2201, 36427),
                             (300, 4966), (2201, 4966)]:
    rows = pd.concat([leavers.sample(n_leavers, random_state=0),
                      stayers.sample(n_stayers, random_state=0)])
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    chance = model.fit(rows[features], rows["churned"]).predict_proba(test[features])[:, 1]
    print(f"{n_leavers:7,} {n_stayers:9,} {n_leavers / len(rows):7.1%} "
          f"{roc_auc_score(test['churned'], chance):6.3f} "
          f"{average_precision_score(test['churned'], chance):6.3f}")
```

Todo modelo é medido nos mesmos meses de teste, com todas as 1.484 pessoas que saíram neles, então só
as linhas de treino mudam.

```
ana@lab:~/ml$ python few.py
leavers   stayers   share    AUC     AP
    100    36,427    0.3%  0.593  0.124
    300    36,427    0.8%  0.748  0.219
  1,000    36,427    2.7%  0.791  0.290
  2,201    36,427    5.7%  0.803  0.322
    300     4,966    5.7%  0.737  0.238
  2,201     4,966   30.7%  0.794  0.298
```

Leia as quatro primeiras linhas de cima para baixo. **Com todos os que ficam mantidos, a AUC sobe de
0,593 para 0,803 conforme quem sai vai de 100 a 2.201.** O modelo com 100 pessoas que saem mal passa do
acaso; o com 1.000 já fez a maior parte do caminho.

Agora compare linhas com a mesma contagem e parte diferente. 300 pessoas que saem entre 36.427 que
ficam, uma parte de 0,8%, e 300 entre 4.966, uma parte de 5,7%: AUC 0,748 e 0,737. 2.201 a 5,7% e a
30,7%: 0,803 e 0,794. **Mudar a parte, com a contagem fixa, não fez nada de útil.** Se fizeram alguma diferença, os que ficam a mais ajudaram um pouco, o que faz sentido: eles também são evidência, sobre como é ficar.

Esse é o fato mais importante sobre desbalanceamento, e os remédios das próximas seções não o mudam.
**Reamostrar muda a parte e não muda a contagem.** Duplicar alguém que sai não acrescenta ninguém novo;
jogar fora quem fica joga evidência fora. Quando uma classe é rara porque só há algumas centenas de
exemplos, a cura é mais exemplos: um histórico mais longo, mais meses, um rótulo coletado por mais
tempo. Quando ela é rara só como parte, como aqui, o modelo tem o bastante para aprender, e o que sobra
para resolver é como a saída dele é lida.
