---
title: Pesos de classe
version: 1
---

O remédio mais suave não muda nada nos dados. **Um peso de classe multiplica a parte de cada linha na
perda**: com `class_weight="balanced"`, cada pessoa que sai conta tanto quanto 36.427 / 2.201, cerca de
16,6 que ficam, para que as duas classes pesem o mesmo no total. Um modelo que antes ignorava quem sai
passa a pagar por errá-los tanto quanto por todo o resto junto.

A maioria dos classificadores do scikit-learn aceita o argumento: regressão logística, máquinas de
vetores de suporte, árvores, florestas, `HistGradientBoostingClassifier`. O XGBoost o chama de
`scale_pos_weight`, e o LightGBM aceita os dois.

O programa abaixo ajusta o modelo de churn de quatro jeitos: como era, com pesos de classe, e com os
dois tipos de reamostragem que a próxima seção descreve. Para cada um ele imprime as medidas de
ordenação da aula 10, a chance média, o dinheiro no corte padrão e **o melhor corte nos meses de teste,
com o dinheiro ali**. Essa última coluna é a visão de depois da aula 11, e é usada aqui para um único
fim: comparar os quatro modelos cada um no seu melhor, que é a comparação mais justa do que cada um
aprendeu. É um teto, e nenhum deles poderia tê-lo sabido antes. Salve isto como `rebalance.py`:

```python
# rebalance.py
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, roc_auc_score

from feira import CATEGORICAL, NUMERIC, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
leavers, stayers = train[train["churned"] == 1], train[train["churned"] == 0]
cuts = np.round(np.arange(0.02, 0.99, 0.01), 2)

remedies = {
    "none": (train, {}),
    "class weights": (train, {"class_weight": "balanced"}),
    "oversampling": (pd.concat([stayers, leavers.sample(len(stayers), replace=True,
                                                         random_state=0)]), {}),
    "undersampling": (pd.concat([leavers, stayers.sample(len(leavers), random_state=0)]), {}),
}
print("remedy           rows    AUC     AP   mean chance   net at 0.5   ceiling at")
for name, (rows, settings) in remedies.items():
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0,
                                           **settings)
    chance = model.fit(rows[features], rows["churned"]).predict_proba(test[features])[:, 1]
    values = [net_value(test["churned"], chance >= cut) for cut in cuts]
    print(f"{name:14} {len(rows):6,} {roc_auc_score(test['churned'], chance):6.3f} "
          f"{average_precision_score(test['churned'], chance):6.3f} {chance.mean():9.3f}"
          f"   R$ {net_value(test['churned'], chance >= 0.5):8,.0f}"
          f"   {cuts[np.argmax(values)]:.2f}: R$ {max(values):,.0f}")
```

```
ana@lab:~/ml$ python rebalance.py
remedy           rows    AUC     AP   mean chance   net at 0.5   ceiling at
none           38,628  0.804  0.322     0.051   R$    9,088   0.23: R$ 23,832
class weights  38,628  0.797  0.321     0.313   R$  -41,528   0.79: R$ 21,304
oversampling   72,854  0.788  0.315     0.276   R$  -28,784   0.78: R$ 21,616
undersampling   4,402  0.788  0.285     0.342   R$  -73,464   0.84: R$ 18,440
```

Pegue as duas primeiras linhas. **Os pesos não melhoraram a ordenação**: a AUC foi de 0,804 para 0,797,
a precisão média de 0,322 para 0,321. O que eles fizeram foi subir toda chance, de uma média de 0,051
para 0,313, seis vezes a taxa real de saída. Isso muda quais linhas passam de 0,5: o modelo com pesos
manda 4.199 créditos no corte padrão em vez de 194, e perde R$ 41.528 fazendo isso.

O melhor corte dele é 0,79, onde faz R$ 21.304, um pouco menos que o modelo simples em 0,23. Os pesos
mudaram **onde fica o corte útil**, não quanto o modelo sabe. Esse é o efeito inteiro, e é a mesma coisa
que a aula 11 achou pelo outro lado: um modelo com pesos é um modelo distorcido, cujas chances precisam
de calibração antes que um corte calculado dos custos queira dizer alguma coisa.
