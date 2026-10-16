---
title: PCA dentro de um modelo
version: 1
---

O segundo motivo para reduzir era alimentar um modelo com menos colunas. O pipeline da aula 15 faz disso
um experimento de uma linha: ponha um passo `PCA` entre a preparação e a regressão logística, e o modelo
aprende com componentes em vez de colunas. Salve isto como `pca_model.py`; ele testa vários números de
componentes no modelo de churn:

```python
# pca_model.py
from sklearn.decomposition import PCA
from sklearn.metrics import roc_auc_score

from churn_model import build
from feira import CREDIT, KEPT, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
print("columns into the model    AUC   net value")
for components in [3, 5, 10, 20, None]:
    model = build()
    if components:
        model.steps.insert(2, ("pca", PCA(n_components=components, random_state=0)))
    chance = model.fit(train, train["churned"]).predict_proba(test)[:, 1]
    label = f"{components} components" if components else "all 36 columns"
    print(f"{label:22} {roc_auc_score(test['churned'], chance):6.3f}"
          f"   R$ {net_value(test['churned'], chance >= CREDIT / (SAVED * KEPT)):,.0f}")
```

O `model.steps.insert(2, …)` põe o passo novo em terceiro, depois de `shapes` e `prepare`, para a PCA ver
as 36 colunas preparadas e ser ajustada só nos meses de treino, como todo o resto do pipeline.

```
ana@lab:~/ml$ python pca_model.py
columns into the model    AUC   net value
3 components            0.790   R$ 17,736
5 components            0.799   R$ 18,456
10 components           0.812   R$ 22,344
20 components           0.815   R$ 23,384
all 36 columns          0.818   R$ 22,184
```

**A AUC nunca passa da do modelo completo, 0,818.** Três componentes perdem bastante, 0,790; dez ficam
quase tão bons, 0,812; vinte ficam dentro do ruído. O valor líquido oscila, R$ 23.384 com vinte
componentes e R$ 22.184 com todas as colunas, dentro da faixa que o bootstrap da aula 2 não separaria.

Então neste problema a PCA dá um modelo menor ao preço de um pouco de acerto. E custa também algo que
importa mais: **os pesos deixam de querer dizer alguma coisa.** A aula 5 leu um peso em `rating_90d` e a aula 14
em `unhappy`; um peso no *componente 7* é um peso numa mistura de 36 colunas, e nenhuma equipe de retenção
consegue agir com ele.

A PCA justifica seu lugar num modelo em dois casos. Um é ter muito mais colunas que isto, centenas ou
milhares que andam juntas, como os pixels de uma imagem ou as palavras do texto da aula 14. O outro é um
método que mede distância e está sofrendo a maldição da aula 6. Com 36 colunas bem escolhidas e 38.628 linhas, nenhuma das
duas coisas vale, e o modelo completo fica.
