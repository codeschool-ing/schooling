---
title: DBSCAN, e os clientes que não pertencem a lugar nenhum
version: 1
---

O k-means faz três suposições sem dizer: toda linha pertence a algum grupo, grupos são redondos, e você
sabe quantos são. O **DBSCAN** abandona as três. Ele faz crescer grupos a partir de regiões densas. Uma
linha com pelo menos `min_samples` vizinhos a uma distância `eps` é um núcleo. Núcleos perto uns dos
outros formam um grupo, e linhas perto de um núcleo entram nele também. Linhas perto de núcleo nenhum são
**ruído**, com o rótulo −1.

Então ele acha sozinho o número de grupos, segue qualquer forma, e deixa de fora o cliente fora do padrão em vez
de forçá-lo no grupo mais próximo. Em troca ele precisa de `eps`, uma distância nas unidades escaladas, e
esse é um número mais difícil de escolher que *k*. Salve isto como `dbscan.py`:

```python
# dbscan.py
import numpy as np
import pandas as pd
from sklearn.cluster import DBSCAN
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
print(" eps   clusters   noise   sizes")
for eps in [0.8, 1.0, 1.2, 1.5, 2.0]:
    labels = DBSCAN(eps=eps, min_samples=10).fit(scaled).labels_
    sizes = np.bincount(labels[labels >= 0])
    print(f"{eps:4.1f} {labels.max() + 1:8} {(labels == -1).sum():7}   {sizes.tolist()}")
```

```
ana@lab:~/ml$ python dbscan.py
 eps   clusters   noise   sizes
 0.8        4     355   [270, 304, 197, 74]
 1.0        4      54   [309, 336, 341, 160]
 1.2        4       9   [344, 328, 340, 179]
 1.5        3       0   [687, 329, 184]
 2.0        1       0   [1200]
```

**Em 1,2 ele acha quatro grupos de quase os mesmos tamanhos do k-means**, com nove clientes deixados de fora como ruído, e
ninguém precisou dizer quatro a ele. Em 0,8 a exigência de densidade é alta demais: 355 clientes contam
como ruído, e os grandes compradores raros, o grupo menor, encolhem para 74. Em 1,5 dois grupos se tocam e
viram um de 687, e em 2,0 tudo é um grupo só.

A tabela é o jeito honesto de usar o DBSCAN: rode alguns valores de `eps` e procure uma faixa em que a resposta se mantém. Aqui ela fica de 1,0 a 1,2, o que é evidência de que os quatro grupos são traços dos
dados e não do método.

O ruído merece um olhar próprio. Nove clientes que não se parecem com ninguém são ou erros nos dados ou as
linhas mais interessantes do arquivo, e o k-means os teria posto em silêncio no grupo mais próximo e
mexido na média dele.
