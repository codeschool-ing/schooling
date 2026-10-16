---
title: PCA, as direções de maior espalhamento
version: 1
---

A **análise de componentes principais** procura a direção, pela nuvem de linhas, ao longo da qual elas
mais se espalham, e a chama de primeiro componente. Depois procura a direção de maior espalhamento em
ângulo reto com a primeira, o segundo componente, e assim por diante, até haver tantos componentes quanto
colunas. Cada componente é uma soma com pesos das colunas originais, e juntos eles descrevem os dados
exatamente; a vantagem é que os primeiros costumam descrever quase tudo.

Salve isto como `pca.py`; ele ajusta todos os componentes e imprime quanto da variação total cada um
carrega:

```python
# pca.py
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
X = baskets.drop(columns="customer_id")
pca = PCA().fit(StandardScaler().fit_transform(X))

print("component   share of the variation   running total")
for i, (share, total) in enumerate(zip(pca.explained_variance_ratio_,
                                       pca.explained_variance_ratio_.cumsum()), start=1):
    print(f"{i:9}   {share:22.1%}   {total:13.1%}")
weights = pd.DataFrame(pca.components_[:2].T, index=X.columns, columns=["first", "second"])
print(weights.round(2).to_string())
```

```
ana@lab:~/ml$ python pca.py
component   share of the variation   running total
        1                    42.7%           42.7%
        2                    27.8%           70.4%
        3                    18.3%           88.7%
        4                     4.1%           92.8%
        5                     3.5%           96.3%
        6                     2.1%           98.4%
        7                     1.6%          100.0%
        8                     0.0%          100.0%
              first  second
orders_month   0.15   -0.45
avg_basket     0.42   -0.16
fruit         -0.30    0.54
vegetables    -0.35   -0.44
greens        -0.20   -0.52
eggs_dairy     0.45   -0.01
bakery         0.47   -0.02
extras         0.36    0.14
```

**Três componentes carregam 88,7% da variação de oito colunas.** Dois carregam 70,4%, o bastante para um
retrato que deixa de fora menos de um terço do que existe. Depois do terceiro, cada componente acrescenta
alguns por cento, que são detalhe, e parte disso ruído.

**O oitavo componente não carrega nada, 0,0%.** Isso não é acaso. As seis partes somam 100 para todo
cliente, então sabidas cinco delas, a sexta também está sabida: os dados têm só sete dimensões disfarçadas de oito. A PCA achou isso sem ninguém dizer. Sempre que um componente carrega exatamente nada, duas ou mais
colunas estão repetindo umas às outras, e vale saber disso antes de ajustar qualquer modelo.

A tabela de baixo é o assunto da próxima seção: de que são feitos os dois primeiros componentes.
